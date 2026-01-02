""" Delete clips.xspf (S3) after user download. """

import json
from time import sleep

import boto3

BUCKET = 'rvcgs-marq-xspf-playlist-31122025'
KEY = 'clips.xspf'

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
