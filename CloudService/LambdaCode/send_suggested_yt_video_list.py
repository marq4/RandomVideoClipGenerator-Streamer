""" Lambda-only code to send List.md contents as JSON. """

import json


def cloud_main(_event, _context):
    """ Send response to JS (loadSuggestedMusicVideoList). """
    try:
        with open('List.md', 'r', encoding='UTF-8') as file:
            content = file.read()

        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'GET'
            },
            'body': json.dumps({
                'content': content
            })
        }

    except FileNotFoundError:
        return {
            'statusCode': 404,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'List.md not found!'
            })
        }

    except (IOError, OSError) as ex:
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': 'Error reading video list file: ' + str(ex)
            })
        }

# Tmp removing quiet to see why zip is failing.
