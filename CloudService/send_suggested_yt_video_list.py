""" Lambda-only code to send List.md contents as JSON. """

import json


def lambda_handler(_event, _context):
    """ Send response to JS (loadSuggestedMusicVideoList). """
    return {
        'statusCode': 200,
        'headers': {
            'Content-Type': 'application/json',
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Headers': 'Content-Type',
            'Access-Control-Allow-Methods': 'GET'
        },
        'body': json.dumps({
            'message': 'Lambda is working!',
            'videos': []
        })
    }
