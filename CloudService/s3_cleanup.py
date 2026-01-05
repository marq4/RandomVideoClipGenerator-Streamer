""" Delete clips.xspf (S3) after user download. """

import json
from pathlib import Path
from time import sleep

import boto3
import yaml

KEY = 'clips.xspf'

# Load config from repo root:
config_path = Path(__file__).parent / 'config.yml'
with open(config_path, encoding='UTF-8') as f:
    config = yaml.safe_load(f)

BUCKET = config['playlist_bucket_name']


s3 = boto3.client('s3')

def lambda_handler(event, _context):
    """ Main entry point for Lambda. """
    print("Received event:", event)
    sleep(12)
    try:
        response = s3.delete_object(Bucket=BUCKET, Key=KEY)
        print("Delete response:", response)
        return {
            'statusCode': 200,
            'body': json.dumps('Playlist successfully deleted.')
        }
    except FileNotFoundError as e:
        print(e)
        return {
            'statusCode': 500,
            'body': json.dumps('Error deleting playlist.')
        }
