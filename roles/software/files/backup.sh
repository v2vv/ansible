#!/bin/bash

# 获取脚本所在的目录
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# 切换工作目录为脚本所在目录
cd "$SCRIPT_DIR"

# 默认值
verbose=0
file=""


# 显示帮助信息
show_help() {
    echo "Usage: $0 [-o option] [-e client_id,client_secret,tenant_id,backup_soft_name]"
    echo ""
    echo "  -o  选择备份软件"
    echo "      1 - alist"
    echo "      2 - ddns-go"
    echo "      3 - semaphore"
    echo "      4 - uptime-kuma"
    echo "      5 - auto_backup"
    echo ""
    echo "  -e  提供 OneDrive 备份的详细信息，用逗号分隔"
    echo "      client_id,client_secret,tenant_id,localPath,oneDriveBackupFolder,backup_soft_name"
    echo ""
    echo "  -h  显示此帮助信息"
}

while getopts ":o:e:h" opt; do
    case ${opt} in
        o )
            # 判断文件是否存在
            if [ -e ".env" ]; then
                source .env
            else
                echo ".env 文件不存在, 请先上传 .env 文件"
                exit 1
            fi
            case $OPTARG in
                1)
                    backup_soft_name="alist"
                    ;;
                2)
                    backup_soft_name="ddns-go"
                    ;;
                3)
                    backup_soft_name="semaphore"
                    ;;
                4)
                    backup_soft_name="uptime-kuma"
                    ;;
                5)
                    backup_soft_name="auto_backup"
                    ;;
                *)
                    echo "无效的备份软件名称: $OPTARG" >&2
                    exit 1
                    ;;
            esac
            ;;
        e )
            # 处理 -e 选项
            IFS=',' read -r client_id client_secret tenant_id backup_soft_name <<< "$OPTARG"
            ;;
        h )
            show_help
            exit 0
            ;;
        \? ) # 未知选项
            echo "Invalid option: -$OPTARG" >&2
            show_help
            exit 1
            ;;
        : ) # 缺少参数
            echo "Option -$OPTARG requires an argument." >&2
            show_help
            exit 1
            ;;
    esac
done
shift $((OPTIND -1))

# ANSI颜色码
GREEN='\033[0;32m'
YELLOW='\033[1;33m' # 黄色
NC='\033[0m' # 恢复默认颜色

# client_id=$1
# client_secret=$2
# tenant_id=$3
# localPath=$4
# oneDriveBackupFolder=$5
# backup_soft_name=$6

localPath="$HOME/data"
oneDriveBackupFolder="文档/backup"

alist_config_Path='alist/config.json'
alist_data_path='alist/data.db'
alist_composefile_path='alist/docker-compose.yaml'

ddnsgo_config_path='ddns-go/.ddns_go_config.yaml'
ddnsgo_composefile_path='ddns-go/docker-compose.yaml'

semaphore_config_path='semaphore/config.json'
semaphore_database_path='semaphore/database.boltdb'
semaphore_composefile_path='semaphore/docker-compose.yaml'

uptimekuma_composefile_path='uptime-kuma/docker-compose.yaml'
uptimekuma_database_path='uptime-kuma/kuma.db'

echo "localPath $localPath"
echo "oneDriveBackupFolder $oneDriveBackupFolder"
# echo $client_id
# echo $client_secret
# echo $tenant_id


check_sysem(){
    # 检查系统环境
    if [ -f /etc/os-release ]; then
        system_env="Linux"
        source /etc/os-release
        if [ "$NAME" = "Debian GNU/Linux" ]; then
            echo "当前环境是 Debian"
        fi
    elif [ "$MSYSTEM" = "MINGW64" ] || [ "$MSYSTEM" = "MINGW32" ]; then
        system_env="MINGW"
        echo "当前环境是 Git Bash"
    fi
}

check_soft_env(){
    # 检查是否存在 xxd 命令
    if command -v xxd >/dev/null 2>&1; then
        echo "xxd 工具已安装"
    else
        if [ "$system_env" = "Linux" ]; then
            echo "安装 xxd"
            apt install xxd -y
        else
            echo "xxd 工具未安装"
            exit 1
        fi
    fi
}


auth(){
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
}

# 通过 docker 运行
docker_run(){
    if command -v docker >/dev/null 2>&1; then
        docker -v
        docker compose version
        eval "docker compose -f $1 up -d"
    else
        docker_exit="nodocker"
        echo "Docker 未安装 ,跳过运行"
    fi
}

# 检查alist是否运行
stoprunning(){
    if command -v docker >/dev/null 2>&1; then
        docker -v
        # 检查alist是否运行
        container=$(docker ps -a --filter "name=$1" --format "{{.Names}}")
        if [ "$container" == "$1" ]; then
            echo "$1 容器正在运行，停止容器..."
            eval "docker stop $1"
            echo "删除 $1 容器."
            eval "docker rm  $1"
        else 
            echo "$1 未运行"
        fi
    else
        docker_exit="nodocker"
        echo "Docker 未安装"
    fi
}


urlencode() {
    src_url=$(echo -n "$1" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')
    echo $src_url
}

# $1 localPath
# $2 oneDrivePath 
upload(){
    echo 上传文件$1 到 oneDrive $2
    response=$(curl --location --request PUT "https://graph.microsoft.com/v1.0/users/me@lvhongyuan.site/drive/root:/$2:/content" \
    --header "Authorization: Bearer $access_token" \
    --header 'User-Agent: Apifox/1.0.0 (https://apifox.com)' \
    --header 'Content-Type: application/octet-stream' \
    --data-binary "@$1" \
    -w "%{http_code}" \
    -o /dev/null)

    # 检查响应状态码并输出相应信息
    if [ $response -eq 200 ]; then
    echo "文件上传成功"
    elif [ $response -eq 201 ]; then
    echo "文件上传并创建成功"
    else
    echo "上传失败，状态码：$response"
    fi
}


alist_backup(){
    # 上传 alist
    if [[ -e $localPath/$alist_config_Path ]]; then
        echo "alist Backup File exists."
        upload $localPath/$alist_config_Path $(urlencode $oneDriveBackupFolder)/$alist_config_Path
        upload $localPath/$alist_data_path $(urlencode $oneDriveBackupFolder)/$alist_data_path
        upload $localPath/$alist_composefile_path $(urlencode $oneDriveBackupFolder)/$alist_composefile_path
    else
        echo -e "${YELLOW}alist Backup File does not exist.${NC}"
        # echo "alist Backup File does not exist."
    fi
}

ddns_go_backup(){
    # 上传 ddns-go
    if [[ -e $localPath/$ddnsgo_config_path ]]; then
        echo "ddns-go Backup File exists."
        stoprunning $backup_soft_name
        # echo $(urlencode $oneDriveBackupFolder/$ddnsgo_config_path)
        # upload $localPath/$ddnsgo_config_path $(urlencode $oneDriveBackupFolder/$ddnsgo_config_path)
        # echo $(urlencode $oneDriveBackupFolder)/$ddnsgo_config_path
        # upload $localPath/$ddnsgo_config_path $(urlencode $oneDriveBackupFolder)/$ddnsgo_config_path
        upload $localPath/$ddnsgo_config_path $(urlencode $oneDriveBackupFolder)/$ddnsgo_config_path
        upload $localPath/$ddnsgo_composefile_path $(urlencode $oneDriveBackupFolder)/$ddnsgo_composefile_path
        docker_run $localPath/$semaphore_composefile_path
    else
        echo -e "${YELLOW}ddns-go Backup File $localPath/$ddnsgo_config_path does not exist.${NC}"
        # echo "ddns-go Backup File does not exist."
    fi
}

semaphore_backup(){
    # 上传 semaphore
    if [[ -e $localPath/$semaphore_config_path ]]; then
        echo "semaphore Backup File exists."
        upload $localPath/$semaphore_config_path $(urlencode $oneDriveBackupFolder)/$semaphore_config_path
        upload $localPath/$semaphore_database_path $(urlencode $oneDriveBackupFolder)/$semaphore_database_path
        upload $localPath/$semaphore_composefile_path $(urlencode $oneDriveBackupFolder)/$semaphore_composefile_path
    else
        echo -e "${YELLOW}semaphore Backup File does not exist.${NC}"
        # echo "semaphore Backup File does not exist."
    fi
}

uptime_kuma_backup(){
    # 上传 semaphore
    if [[ -e $localPath/$uptimekuma_composefile_path ]]; then
        echo "uptime-kuma Backup File exists."
        upload $localPath/$uptimekuma_composefile_path $(urlencode $oneDriveBackupFolder)/$uptimekuma_composefile_path
        upload $localPath/$uptimekuma_database_path $(urlencode $oneDriveBackupFolder)/$uptimekuma_database_path
        # upload $localPath/$semaphore_composefile_path $(urlencode $oneDriveBackupFolder)/$semaphore_composefile_path
    else
        echo -e "${YELLOW}uptime-kuma Backup File does not exist.${NC}"
    fi

}


backup(){
    echo "开始备份 $(date +”%Y/%m/%d/%H:%M:%S”)"
    case  $1 in
        "alist")
            alist_backup
            ;;
        "ddns-go")
            ddns_go_backup
            ;;
        "semaphore")
            semaphore_backup
            ;;
        "uptime-kuma")
            uptime_kuma_backup
            ;;
        "auto_backup")
            alist_backup
            ddns_go_backup
            semaphore_backup
            uptime_kuma_backup
            ;;
        *)
            echo "未匹配到任何备份名"
            ;;
    esac
    echo '备份完成'
}



check_sysem
check_soft_env
auth
backup $backup_soft_name



