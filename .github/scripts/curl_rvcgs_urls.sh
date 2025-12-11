#! /bin/bash

set -euo pipefail

# http://www.randomvideoclipgenerator.com: FALSE POSITIVE (curl => 301, Firefox => 404) !!!

#======================================================================================
CURL_TIMEOUT_SECONDS=3 #XXX
URLS=(
    https://randomvideoclipgenerator.com
    http://randomvideoclipgenerator.com
    https://www.randomvideoclipgenerator.com
    http://www.randomvideoclipgenerator.com
)
#======================================================================================

CURL_TIMEOUT_ERROR_CODE=28
CURL_DNS_RESOLUTION_FAILED_ERROR_CODE=6
CURL_SSL_CONNECTION_ERROR_CODE=35
CURL_EMPTY_REPLY_ERROR_CODE=52

HTTP_NOT_FOUND=404
HTTP_INTERNAL_SERVER_ERROR=500
HTTP_SERVICE_UNAVAILABLE=503
# HTTPS no-www:
HTTP_OK=200
# HTTP no-www:
HTTP_MOVED=301
HTTP_TEMP_REDIRECT=302

SERVER_ERROR_MESSAGE='500 or 503 SERVER ERROR!!'

declare -A ERROR_MESSAGES=(
    [$CURL_TIMEOUT_ERROR_CODE]='timeout'
    [$HTTP_NOT_FOUND]='404 not found'
    [$CURL_DNS_RESOLUTION_FAILED_ERROR_CODE]='DNS resolution failed'
    [$HTTP_INTERNAL_SERVER_ERROR]=$SERVER_ERROR_MESSAGE
    [$HTTP_SERVICE_UNAVAILABLE]=$SERVER_ERROR_MESSAGE
    [$CURL_SSL_CONNECTION_ERROR_CODE]='TLS/SSL broken!'
    [$CURL_EMPTY_REPLY_ERROR_CODE]='empty reply from server'
)

Failed_urls=()

function append_url_to_failed_list() {
    add_this_url=$1
    code=$2
    Failed_urls+=("${add_this_url}")
    local message="${ERROR_MESSAGES[$code]:-"error code $code"}"
    echo -e "\n\n    >>> URL could not be reached: ${message}! \n"
}

for url in "${URLS[@]}"
do
    echo -n "Checking ${url}... "
    # Temporarily disable exit-on-error or whole script halts on timeout:
    set +e
    return_status=$(curl --silent --output /dev/null \
        --write-out "%{http_code}" \
        --max-time ${CURL_TIMEOUT_SECONDS} \
        "${url}")
    curl_exit_code=$?
    set -e
    # Check if curl itself failed (timeout, DNS):
    if [[ $curl_exit_code -ne 0 ]]
    then
        append_url_to_failed_list $url $curl_exit_code
    elif [[ "${return_status}" -eq $HTTP_OK || \
        "${return_status}" -eq $HTTP_MOVED || \
        "${return_status}" -eq $HTTP_TEMP_REDIRECT ]]
    then
        echo "OK (${return_status}). "
    else
        append_url_to_failed_list $url $return_status
    fi
done

if [[ ${#Failed_urls[@]} -gt 0 ]]
then
    echo "failed_urls=${Failed_urls[*]}" >> $GITHUB_OUTPUT
    exit 1
fi

exit 0
