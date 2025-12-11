#! /bin/bash

set -euo pipefail

Failed_urls=$1
discord_webhook_url=$2
Nice_list=$(echo "${Failed_urls}" | tr ' ' "\n" | sed 's/^/  */')

response=$(curl --write-out "\n%{http_code}" \
    -H 'Content-Type: application/json' \
    -d @- "${discord_webhook_url}" <<EOM
{
    "content": "🚨 Website down alert!",
    "embeds": [{
        "title": "RVCG/S website health check failed!",
        "description": "GitHub website check notification.",
        "color": 15158332,
        "fields": [{
            "name": "Unreachable URLs:",
            "value": "${Nice_list}",
            "inline": false
        }]
    }]
}
EOM
)

http_code=$(echo "$response" | tail -n1)
response_body=$(echo "$response" | head -n-1)

echo "Discord API response: $http_code:"
echo "$response_body"

if [[ "${http_code}" -ge 200 && "${http_code}" -lt 300 ]]
then
    echo "Discord notification sent successfully. "
else
    echo "Failed to send Discord notification. "
    exit 1
fi

exit 0
