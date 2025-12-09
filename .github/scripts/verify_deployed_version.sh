#! /bin/bash

set -euo pipefail

SUBFOLDER_NAME=$1
SCRIPT_NAME=$2
BUCKET=$3

script_from_src="${SUBFOLDER_NAME}/${SCRIPT_NAME}"
echo "Script from SCM => ${script_from_src} "

# Expected version:
top_result=$(grep version $script_from_src | head -1)
cut_result=$(echo $top_result | cut -d= -f 2)
expected_version=$(echo $cut_result | tr -d " '")
echo "Expected version => ${expected_version} "

# Actual version:
proto='https://'
s3_endpoint='.s3.us-east-2.amazonaws.com'
partial_url="${proto}${BUCKET}${s3_endpoint}"
download_endpoint="${partial_url}/${SCRIPT_NAME}"
echo $download_endpoint
curl -X GET ${download_endpoint} -o rvcg.py
actual_version=$(python rvcg.py --version)
echo "Actual version => ${actual_version} "

if [[ "X${expected_version}" != "X${actual_version}" ]]
then
    exp="Expected ${expected_version} version,"
    act="but instead found ${actual_version}."
    err_msg="${exp} ${act} "
    echo ${err_msg}
    exit 1
fi

echo "Version verification complete. "
