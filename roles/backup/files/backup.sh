#!/bin/bash

localFilePath=$1
oneDrivePath=$2
client_id=$3
client_secret=$4
tenant_id=$5

# echo $localFilePath
# echo $oneDrivePath
# echo $client_id
# echo $client_secret
# echo $tenant_id

# 使用 curl 发送 POST 请求
response=$(curl --location --request POST "https://login.microsoftonline.com/$tenant_id/oauth2/v2.0/token" \
--header 'Host: login.microsoftonline.com' \
--header 'User-Agent: Apifox/1.0.0 (https://apifox.com)' \
--header 'Content-Type: application/x-www-form-urlencoded' \
--data-urlencode "client_id=$client_id" \
--data-urlencode 'scope=https://graph.microsoft.com/.default' \
--data-urlencode "client_secret=$client_secret" \
--data-urlencode 'grant_type=client_credentials')

# 使用 jq 解析 JSON 并提取 access_token
access_token=$(echo $response | jq -r '.access_token')

# 输出 access_token
# echo "Access Token: $access_token"

curl --location --request PUT "https://graph.microsoft.com/v1.0/users/me@lvhongyuan.site/drive/root:/$oneDrivePath:/content" \
--header "Authorization: Bearer $access_token" \
--header 'User-Agent: Apifox/1.0.0 (https://apifox.com)' \
--header 'Content-Type: application/octet-stream' \
--data-binary "@$localFilePath"

