#! /bin/bash

set -euo pipefail

URLS=(
    
    'https://randomvideoclipgenerator.com'
    
    'http://randomvideoclipgenerator.com'
)
Failed_urls=()

for url in "${URLS[@]}"
do
    echo "Checking ${url}... "
    return_status=$(curl --fail --silent --output /dev/null \
        --write-out "%{http_code}" --max-time 10 "${url}")
    if [[ "${return_status}" -eq 200 || "${return_status}" -eq 301 ]]
    then
        echo "URL ${url}: OK (${return_status}). "
    else
        Failed_urls+=("${url}")
        echo "URL ${url} not 200: ${return_status}. "
    fi
done

if [[ ${#Failed_urls[@]} -gt 0 ]]
then
    echo "failed_urls=${Failed_urls[*]}" >> $GITHUB_OUTPUT
    exit 1
fi

exit 0
