#!/bin/bash


# 默认值
verbose=0
file=""


# 显示帮助信息
show_help() {
    echo "Usage: $0 [-o option] [-e client_id,client_secret,tenant_id,localFilePath,oneDriveBackupFolder,backup_soft_name]"
    echo ""
    echo "  -o  选择备份软件"
    echo "      1 - alist"
    echo "      2 - ddns-go"
    echo "      3 - semaphore"
    echo "      4 - uptime-kuma"
    echo ""
    echo "  -e  提供 OneDrive 备份的详细信息，用逗号分隔"
    echo "      client_id,client_secret,tenant_id,localFilePath,oneDriveBackupFolder,backup_soft_name"
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
                *)
                    echo "无效的备份软件名称: $OPTARG" >&2
                    exit 1
                    ;;
            esac
            ;;
        e )
            # 处理 -e 选项
            IFS=',' read -r client_id client_secret tenant_id localFilePath oneDriveBackupFolder backup_soft_name <<< "$OPTARG"
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



# 根据备份软件名称设置软件


system_env=""

# ANSI颜色码
GREEN='\033[0;32m'
YELLOW='\033[1;33m' # 黄色
NC='\033[0m' # 恢复默认颜色

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
    exit 1
    fi
}


urlencode() {
    src_url=$(echo -n "$1" | xxd -plain | tr -d '\n' | sed 's/\(..\)/%\1/g')
    echo $src_url
}



# localFilePath $1
# oneDriveBackupFolder $2
download(){
    echo "下载 onedrive $2"
    response=$(curl --location --request GET "https://graph.microsoft.com/v1.0/users/me@lvhongyuan.site/drive/root:/$2:/content" \
    --header "Authorization: Bearer $access_token" \
    --header 'User-Agent: Apifox/1.0.0 (https://apifox.com)' \
    --output "$1" \
    -w "%{http_code}" \
    -o /dev/null)

    # 检查响应状态码并输出相应信息
    if [ "$response" -eq 200 ]; then
        echo "文件下载成功 保存路径 $1"
    elif [ "$response" -eq 404 ]; then
        echo "onedrive $2 文件不存在"
    else
        echo "下载失败，状态码：$response"
    fi
}


alist_restore(){
    echo "恢复alist备份文件"
    # 检查 alist 容器是否在运行
    stoprunning alist
    mkdir -p alist
    download "$localFilePath/$alist_config_Path" "$(urlencode $oneDriveBackupFolder)/$alist_config_Path"
    download "$localFilePath/$alist_data_path" "$(urlencode $oneDriveBackupFolder)/$alist_data_path"
    download "$localFilePath/$alist_composefile_path" "$(urlencode $oneDriveBackupFolder)/$alist_composefile_path"
    # echo "开始运行 alist 容器"
    docker_run $localFilePath/$alist_composefile_path
    # docker compose -f "$localFilePath/$alist_composefile_path" up -d
}

ddns_go_restore(){
    echo "恢复ddns-go备份文件"
    # 检查 ddns-go 容器是否存在
    stoprunning ddns-go
    mkdir -p ddns-go
    download "$localFilePath/$ddnsgo_config_path" "$(urlencode $oneDriveBackupFolder)/$ddnsgo_config_path"
    download "$localFilePath/$ddnsgo_composefile_path" "$(urlencode $oneDriveBackupFolder)/$ddnsgo_composefile_path"
    echo "开始运行 ddns-go 容器"
    docker_run $localFilePath/$ddnsgo_composefile_path
    # docker compose -f "$localFilePath/$ddnsgo_composefile_path" up -d
}

semaphore_restore(){
    echo "恢复semaphore备份文件"
    # 检查 semaphore 容器是否在运行
    stoprunning semaphore
    mkdir -p semaphore
    download "$localFilePath/$semaphore_config_path" "$(urlencode $oneDriveBackupFolder)/$semaphore_config_path"
    download "$localFilePath/$semaphore_database_path" "$(urlencode $oneDriveBackupFolder)/$semaphore_database_path"
    download "$localFilePath/$semaphore_composefile_path" "$(urlencode $oneDriveBackupFolder)/$semaphore_composefile_path"
    echo "开始运行 semaphore 容器"
    docker_run $localFilePath/$semaphore_composefile_path
    # docker compose -f "$localFilePath/$semaphore_composefile_path" up -d
}

uptime_kuma_restore(){
    stoprunning uptime-kuma
    mkdir -p uptime-kuma
    download "$localFilePath/$uptimekuma_composefile_path" "$(urlencode $oneDriveBackupFolder)/$uptimekuma_composefile_path"
    download "$localFilePath/$uptimekuma_database_path" "$(urlencode $oneDriveBackupFolder)/$uptimekuma_database_path"
    # download "$localFilePath/$uptimekuma_composefile_path" "$(urlencode $oneDriveBackupFolder)/$uptimekuma_composefile_path"
    echo "开始运行 semaphore 容器"
    docker_run $localFilePath/$uptimekuma_composefile_path
}

restore(){
    echo '开始恢复或安装'
    case $1 in
        "alist")
            alist_restore
            ;;
        "ddns-go")
            ddns_go_restore
            ;;
        "semaphore")
            semaphore_restore
            ;;
        "uptime-kuma")
            uptime_kuma_restore
            ;;
        "restore_all")
            alist_restore
            ddns_go_restore
            semaphore_restore
            ;;
        *)
            echo "未匹配到任何恢复数据名"
            ;;
    esac
}

# mkdir -p ddns-go
# download "$localFilePath/$ddnsgo_config_path" "$(urlencode $oneDriveBackupFolder)/$ddnsgo_config_path"
# download "$localFilePath/$ddnsgo_composefile_path" "$oneDriveBackupFolder/$ddnsgo_composefile_path"
check_sysem
check_soft_env
auth
restore $backup_soft_name







# docker stop alist
# download $localFilePath/$alist_config_Path $oneDriveBackupFolder/$alist_config_Path
# download $localFilePath/$alist_data_path $oneDriveBackupFolder/$alist_data_path
# download $localFilePath/$alist_composefile_path $oneDriveBackupFolder/$alist_composefile_path
# docker start alist

# restore ddns-go





# restore semaphore




# mkdir -p ddns-go
# echo "restore alist Backup File"
# docker stop alist
# download $localFilePath/$ddnsgo_config_path $oneDriveBackupFolder/$ddnsgo_config_path
# download $localFilePath/$semaphore_composefile_path $oneDriveBackupFolder/$semaphore_composefile_path
# docker start alist