#!/bin/bash

localFilePath=$1
oneDriveBackupFolder=$2
client_id=$3
client_secret=$4
tenant_id=$5

alist_config_Path='alist/config.json'
alist_data_path='alist/data.db'

ddnsgo_config_path='ddns-go/.ddnd-go_config.yaml'

semaphore_config_path='semaphore/config.json'
semaphore_database_path='semaphore/database.boldb'

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

# $1 localFilePath
# $2 oneDrivePath 
upload(){
    curl --location --request PUT "https://graph.microsoft.com/v1.0/users/me@lvhongyuan.site/drive/root:/$1:/content" \
    --header "Authorization: Bearer $access_token" \
    --header 'User-Agent: Apifox/1.0.0 (https://apifox.com)' \
    --header 'Content-Type: application/octet-stream' \
    --data-binary "@$2"
}

# 上传 alist
if [[ -e $localFilePath/$alist_config_Path ]]; then
    echo "alist Backup File exists."
    docker stop alist
    upload $localFilePath/$alist_config_Path $oneDriveBackupFolder/$alist_config_Path
    upload $localFilePath/$alist_data_path $oneDriveBackupFolder/$alist_data_path
    docker start alist
else
    echo "alist Backup File does not exist."
fi



# 上传 ddns-go
if [[ -e $localFilePath/$ddnsGo_config_path ]]; then
    echo "ddns-go Backup File exists."
    upload $localFilePath/$ddnsGo_config_path $oneDriveBackupFolder/$ddnsgo_config_path
else
    echo "ddns-go Backup File does not exist."
fi


# 上传 semaphore
if [[ -e $localFilePath/$semaphore_config_path ]]; then
    echo "semaphore Backup File exists."
    upload $localFilePath/$semaphore_config_path $oneDriveBackupFolder/$semaphore_config_path
    upload $localFilePath/$semaphore_database_path $oneDriveBackupFolder/$semaphore_database_path
else
    echo "semaphore Backup File does not exist."
fi


