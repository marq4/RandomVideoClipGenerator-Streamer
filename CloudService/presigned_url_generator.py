""" Generate presigned URL for S3 upload. """

import json
from datetime import datetime
from pathlib import Path

import boto3
import yaml
from botocore.exceptions import BotoCoreError, ClientError

s3_client = boto3.client('s3')

# Load config from repo root:
config_path = Path(__file__).parent / 'config.yml'
with open(config_path, encoding='UTF-8') as f:
    config = yaml.safe_load(f)

BUCKET_NAME = config['upload_bucket_name']

def lambda_handler(_event, _context):
    """Generate presigned S3 URL for uploading list_videos.txt"""

    try:
        # Generate unique filename with timestamp
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        object_key = f'list_videos_{timestamp}.txt'

        # Generate presigned URL (5 minute expiry)
        presigned_url = s3_client.generate_presigned_url(
            'put_object',
            Params={
                'Bucket': BUCKET_NAME,
                'Key': object_key,
                'ContentType': 'text/plain'
            },
            ExpiresIn=300
        )

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': 'https://randomvideoclipgenerator.com',
                'Access-Control-Allow-Headers': 'content-type',
                'Access-Control-Allow-Methods': 'GET, OPTIONS'
            },
            'body': json.dumps({
                'uploadURL': presigned_url
            })
        }

    except (ClientError, BotoCoreError) as e:
        print(f"Error: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': 'https://randomvideoclipgenerator.com'
            },
            'body': json.dumps({
                'error': 'Failed to generate upload URL'
            })
        }
