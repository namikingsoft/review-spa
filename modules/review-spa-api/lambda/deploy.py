import os
import time
import uuid
import json
import boto3
import base64
import tarfile
import mimetypes
import urllib.request

print('Loading function')

s3 = boto3.resource('s3')
origin_bucket = s3.Bucket(os.environ['ORIGIN_BUCKET_NAME'])
temp_archive_bucket = s3.Bucket(os.environ['TEMP_ARCHIVE_BUCKET_NAME'])

dynamodb = boto3.resource('dynamodb')
temp_archive_table = dynamodb.Table(os.environ['TEMP_ARCHIVE_TABLE_NAME'])

cf = boto3.client('cloudfront')

def lambda_handler(event, context):
    print("Received event: " + json.dumps(event))

    key = urllib.parse.unquote_plus(event['Records'][0]['s3']['object']['key'], encoding='utf-8')
    archive_item = temp_archive_table.get_item(Key={ 'Key': key })['Item']

    param = json.loads(archive_item['ParamJson'])
    github_token = param['github_token']
    github_username = param['github_username']
    github_reponame = param['github_reponame']
    github_sha1 = param['github_sha1']
    statuses_context = param['statuses_context']
    public_path = param['public_path']
    sub_domain = param['sub_domain']
    review_spa_url = param['review_spa_url']
    use_github_oauth = param['use_github_oauth']

    # Extract dist from archive
    temp_archive_dir = f"/tmp/{key}"
    temp_archive_file = f"/tmp/{key}.tar.gz"
    temp_archive_dir_public = f"/tmp/{key}/{public_path}"

    temp_archive_bucket.download_file(key, temp_archive_file)
    with tarfile.open(temp_archive_file, 'r:gz') as f:
        f.extractall(path=temp_archive_dir)

    # Write settings json
    if use_github_oauth is not None:
        settings = {
            'useGitHubOAuth': use_github_oauth,
        }
        with open(f"{temp_archive_dir_public}/{os.environ['CDN_SETTINGS_JSON_FILENAME']}", 'w') as f:
            json.dump(settings, f)

    # Clear temp archive
    temp_archive_table.delete_item(Key={ 'Key': key })
    temp_archive_bucket.Object(key).delete()

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
    if github_sha1 is not None:
        github_statuses_url = f"https://api.github.com/repos/{github_username}/{github_reponame}/statuses/{github_sha1}"
        github_statuses_data = {
            'state': 'success',
            'target_url': review_spa_url,
            'description': 'Ready for Review',
            'context': statuses_context if statuses_context is not None else 'Review App',
        }
        github_headers = {
            'Accept': 'application/json',
            'Authorization': f"token {github_token}",
        }
        req = urllib.request.Request(github_statuses_url, json.dumps(github_statuses_data).encode(), github_headers, method='POST')
        urllib.request.urlopen(req)
