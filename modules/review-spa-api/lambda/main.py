import os
import uuid
import json
import time
import boto3
import base64
import tarfile
import mimetypes
import urllib.request

print('Loading function')

s3 = boto3.resource('s3')
origin_bucket = s3.Bucket(os.environ['ORIGIN_BUCKET_NAME'])

cf = boto3.client('cloudfront')

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
    try:
        with urllib.request.urlopen(req) as res:
            repo = json.loads(res.read().decode('utf-8'))
            if not repo['permissions']['push']:
                raise Exception
    except:
        return error_response(401, 'Unauthorized')

    # Extract dist from archive
    uuidstr = uuid.uuid4()
    archive_data = base64.b64decode(body['archive_base64'])

    temp_archive_dir = f"/tmp/{uuidstr}"
    temp_archive_file = f"/tmp/{uuidstr}.tar.gz"
    temp_archive_dir_public = f"/tmp/{uuidstr}/{body['public_path']}"

    with open(temp_archive_file, mode='wb') as f:
        f.write(archive_data)

    with tarfile.open(temp_archive_file, 'r:gz') as tf:
        tf.extractall(path=temp_archive_dir)

    sub_domain = f"{body['identifier']}--{body['github_reponame'].replace('.', '-')}--{body['github_username']}"
    review_spa_url = 'https://' + os.environ['CDN_WILDCARD_DOMAIN'].replace('*', sub_domain)

    # Remove previous dist on S3
    origin_bucket.objects.filter(Prefix=f"{sub_domain}/").delete()

    # Upload to S3
    for root, dirs, files in os.walk(temp_archive_dir_public):
        for filename in files:
            full_path = os.path.join(root, filename)
            key_path = full_path.replace(temp_archive_dir_public, '')
            key_path = sub_domain + key_path
            mimetype, _ = mimetypes.guess_type(full_path)
            origin_bucket.upload_file(full_path, key_path, ExtraArgs={
                'ContentType': 'binary/octet-stream' if mimetype is None else mimetype
            })
            print('done: ' + key_path)

    # Invalidation CloudFront
    invalidation = cf.create_invalidation(
        DistributionId=os.environ['CF_DISTRIBUTION_ID'],
        InvalidationBatch={
            'Paths': {
                'Quantity': 1,
                'Items': [f"/{sub_domain}/*"]
            },
            'CallerReference': str(time.time())
        }
    )
    print(invalidation)

    # Notify GitHub statuses
    if 'github_sha1' in body:
        github_statuses_url = f"{github_repos_url}/statuses/{body['github_sha1']}"
        github_statuses_data = {
            'state': 'success',
            'target_url': review_spa_url,
            'description': 'Ready for Review',
            'context': body['statuses_context'] if 'statuses_context' in body else 'Review App',
        }
        req = urllib.request.Request(github_statuses_url, json.dumps(github_statuses_data).encode(), github_headers, method='POST')

        try:
            urllib.request.urlopen(req)
        except:
            return error_response(401, 'Failed to post github statuses')

    return json_response(200, { 'url': review_spa_url })
