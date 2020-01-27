import os
import re
import time
import uuid
import json
import boto3
import base64
import urllib.request

print('Loading function')

s3_client = boto3.client('s3')
s3_resource = boto3.resource('s3')
temp_archive_bucket = s3_resource.Bucket(os.environ['TEMP_ARCHIVE_BUCKET_NAME'])

dynamodb = boto3.resource('dynamodb')
temp_archive_table = dynamodb.Table(os.environ['TEMP_ARCHIVE_TABLE_NAME'])

def json_response(status_code, dictionary):
    return {
        'isBase64Encoded': False,
        'statusCode': status_code,
        'headers': {
            'Content-Type': 'application/json; charset=utf-8',
        },
        'body': json.dumps(dictionary),
    }

def error_response(status_code, message):
    return json_response(status_code, { 'message': message })

def lambda_handler(event, context):
    # print("Received event: " + json.dumps(event))
    if not (event['httpMethod'] == 'POST' and event['path'] == '/upload'):
        return error_response(404, 'Not found')

    body = json.loads(event['body'])

    # Authorize by GitHub
    github_repos_url = f"https://api.github.com/repos/{body['github_username']}/{body['github_reponame']}"
    github_headers = {
        'Accept': 'application/json',
        'Authorization': f"token {body['github_token']}",
    }
    req = urllib.request.Request(github_repos_url, headers=github_headers, method='GET')
    repo_id = None
    try:
        with urllib.request.urlopen(req) as res:
            repo = json.loads(res.read().decode('utf-8'))
            if not repo['permissions']['push']:
                raise Exception
            repo_id = hex(repo['id'])[2:] # strip 0x
    except:
        return error_response(401, 'Unauthorized')

    # Upload temp archive
    uuidstr = str(uuid.uuid4())
    identifier = re.sub('[^a-zA-Z0-9]', '-', body['identifier'])
    identifier = re.sub('-+', '-', identifier)
    sub_domain = f"{identifier}--{repo_id}"
    review_spa_url = 'https://' + os.environ['CDN_WILDCARD_DOMAIN'].replace('*', sub_domain)
    temp_archive_table.put_item(
        Item={
            'Key': uuidstr,
            'ParamJson': json.dumps({
                'github_token': body['github_token'],
                'github_username': body['github_username'],
                'github_reponame': body['github_reponame'],
                'github_sha1': body['github_sha1'] if 'github_sha1' in body else None,
                'statuses_context': body['statuses_context'] if 'statuses_context' in body else None,
                'public_path': body['public_path'],
                'sub_domain': sub_domain,
                'review_spa_url': review_spa_url,
                'use_github_oauth': body['use_github_oauth'] if 'use_github_oauth' in body else False,
            }),
            'TimeToExist': int(time.time()) + (60 * 3), 
        }
    )

    if 'archive_base64' in body:
        archive_data = base64.b64decode(body['archive_base64'])
        temp_archive_bucket.put_object(Key=uuidstr, Body=archive_data)
        return json_response(201, { 'url': review_spa_url })
    else:
        upload_archive_url = s3_client.generate_presigned_url(
            ClientMethod = 'put_object',
            Params = { 'Bucket': os.environ['TEMP_ARCHIVE_BUCKET_NAME'], 'Key': uuidstr },
            ExpiresIn = 3600,
            HttpMethod = 'PUT',
        )
        return json_response(201, { 'url': review_spa_url, 'upload_archive_url': upload_archive_url })
