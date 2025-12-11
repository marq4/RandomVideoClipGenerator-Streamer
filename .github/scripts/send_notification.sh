#! /bin/bash

set -euo pipefail

echo "version======>>>>>> 10:39:30" #TMP

failed_urls_string=$1
echo -e "\n\n\nfailed_urls_string=>${failed_urls_string}<=\n\n" #TMP
discord_webhook_url=$2
#$(echo "${Failed_urls}" | tr ' ' '\n' | sed 's/^/• /')

# Convert space-separated string to array:
IFS=' ' read -ra URL_Array <<< "${failed_urls_string}"
echo -e "\n\nURL_Array=>${URL_Array[@]}<=\n\n" #TMP

unreachable_urls_string_with_newlines=""
for url in "${URL_Array[@]}"
do
    echo -e "\n    >>>>>FOR->${url}<\n" #TMP
    # A LITERAL new line:
    unreachable_urls_string_with_newlines="${unreachable_urls_string_with_newlines}• ${url}
"
done
echo  -e "\n\n\n_______ unreachable_urls_string_with_newlines=>${unreachable_urls_string_with_newlines}<=" #TMP


curl --silent --show-error --location --write-out "\n%{http_code}" \
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
    }]
}
EOM
#)


#http_code=$(echo "$response" | tail -n1)
#response_body=$(echo "$response" | head -n-1)

#echo "Discord API response: $http_code:"
#echo "$response_body"

#if [[ "${http_code}" -ge 200 && "${http_code}" -lt 300 ]]
#then
#    echo "Discord notification sent successfully. "
#else
#    echo "Failed to send Discord notification. "
#    exit 1
#fi

exit 0
