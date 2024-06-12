#!/bin/bash
# ANSI颜色码
GREEN='\033[0;32m'
YELLOW='\033[1;33m' # 黄色
NC='\033[0m' # 恢复默认颜色


localFilePath=$1
oneDriveBackupFolder=$2
client_id=$3
client_secret=$4
tenant_id=$5

alist_config_Path='alist/config.json'
alist_data_path='alist/data.db'

ddnsgo_config_path='ddns-go/.ddns-go_config.yaml'

semaphore_config_path='semaphore/config.json'
semaphore_database_path='semaphore/database.boltdb'

echo '正在获取授权'
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
# 检查access_token是否为空
if [ -n "$access_token" ]; then
  echo "授权成功"
  # 输出 access_token
    # echo "Access Token: $access_token"
else
  echo -e "${YELLOW}警告：授权失败${NC}"
fi


# localFilePath $1
# oneDriveBackupFolder $2
download(){
    curl --location --request GET "https://graph.microsoft.com/v1.0/users/me@lvhongyuan.site/drive/root:/$2:/content" \
    --header "Authorization: Bearer $access_token" \
    --header 'User-Agent: Apifox/1.0.0 (https://apifox.com)'
    --output-dir "$1" \
}

# restore alist
mkdir -p alist
echo "restore alist Backup File"
docker stop alist
download $localFilePath/$alist_config_Path $oneDriveBackupFolder/$alist_config_Path
download $localFilePath/$alist_data_path $oneDriveBackupFolder/$alist_data_path
docker start alist

# restore ddns-go
mkdir -p ddns-go
echo "restore alist Backup File"
docker stop ddns-go
download $localFilePath/$ddnsgo_config_path $oneDriveBackupFolder/$ddnsgo_config_path
docker start ddns-go

# restore ddns-go
mkdir -p ddns-go
echo "restore alist Backup File"
docker stop alist
download $localFilePath/$ddnsgo_config_path $oneDriveBackupFolder/$ddnsgo_config_path
docker start alist