#! /bin/bash

set -euo pipefail

Failed_urls=$1
discord_webhook_url=$2
Nice_list=$(echo ${Failed_urls} tr ' ' "\n" | sed 's/^/  */')

curl -H 'Content-Type: application/json' \
    -d '{
        "content": "Website down alert",
        "embeds": [{
            "title": "RVCG/S website health check failed!",
            "description": "GitHub website check notification.",
            "color": 15158332,
            "fields": [
                {
                    "name": "Unreachable URLs:",
                    "value": "${Nice_list}",
                    "inline": false
                }
            ]
        }]
    }' \
    ${discord_webhook_url}

exit 0
