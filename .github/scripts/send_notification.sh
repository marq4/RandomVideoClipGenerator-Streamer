#! /bin/bash

set -euo pipefail

failed_urls_string=$1
discord_webhook_url=$2

# Convert space-separated string to array:
IFS=' ' read -ra URL_Array <<< "${failed_urls_string}"

unreachable_urls_string_with_newlines=""
for url in "${URL_Array[@]}"
do
    unreachable_urls_string_with_newlines="${unreachable_urls_string_with_newlines}• ${url}\n"
done


response=$(curl --silent --show-error --location --write-out "\n%{http_code}" \
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
            "value": "${unreachable_urls_string_with_newlines}",
            "inline": false
        }]
    }];;;
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
