#!/bin/bash
clear
set -e
echo "
     __    .___         ___.
    |__| __| _/         \_ |__ _____    ______ ____
    |  |/ __ |   ______  | __ \\__  \  /  ___// __ \
    |  / /_/ |  /_____/  | \_\ \/ __ \_\___ \\  ___/
/\__|  \____ |           |___  (____  /____  >\___  >
\______|    \/               \/     \/     \/     \/

"

if ! [ -x "$(command -v git)" ]; then
    echo 'Error: git is not installed.' >&2
    exit 1
fi
DOCKER_IMG_NAME="martin888/jd-nginx-php"
JD_PATH=""
SHELL_FOLDER=$(pwd)
CONTAINER_NAME="jd-base-nginx-php"
CONFIG_PATH=""
LOG_PATH=""
TAG="1020"
PHP_CODE_URL="https://gitee.com/ioser_net/jd_php_script.git"

HAS_IMAGE=false
PULL_IMAGE=true

HAS_CONTAINER=false
DEL_CONTAINER=true
INSTALL_WATCH=false

#TEST_BEAN_CHAGE=false

log() {
    echo -e "\e[32m$1 \e[0m\n"
}

inp() {
    echo -e "\e[33m$1 \e[0m\n"
}

warn() {
    echo -e "\e[31m$1 \e[0m\n"
}

cancelrun() {
    if [ $# -gt 0 ]; then
        echo "\033[31m $1 \033[0m"
    fi
    exit 1
}

docker_install() {
    echo "检查Docker......"
    if [ -x "$(command -v docker)" ]; then
        echo "检查到Docker已安装!"
    else
        if [ -r /etc/os-release ]; then
            lsb_dist="$(. /etc/os-release && echo "$ID")"
        fi
        if [ "$lsb_dist" == "openwrt" ]; then
            echo "openwrt 环境请自行安装docker"
            #exit 1
        else
            echo "安装docker环境..."
            curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
            echo "安装docker环境...安装完成!"
            systemctl enable docker
            systemctl start docker
        fi
    fi
}

docker_install
warn "注意如果你什么都不清楚，建议所有选项都直接回车，使用默认选择！！！"
warn "有疑问+q: 517093030"
#配置文件目录
echo -n -e "\e[33m一.请输入配置文件保存的绝对路径,直接回车为当前目录:\e[0m"
read -r jd_path
JD_PATH=$jd_path
if [ -z "$jd_path" ]; then
    JD_PATH=$SHELL_FOLDER
fi
CONFIG_PATH=$JD_PATH/jd/config
SCRIPTS_PATH=$JD_PATH/jd/scripts
LOG_PATH=$JD_PATH/jd/log
WEB_ROOT_PATH=$JD_PATH/jd/web

echo -n -e "\e[33m微信企业版服务端配置页面：https://work.weixin.qq.com/wework_admin/frame#apps  应用管理->接收消息->启用API接收 \e[0m\n"
echo -n -e "\e[33m请先去本网页获取应用服务端Token和aes-key\e[0m\n"
echo -n -e "\e[33m请输入访问域名或本机外网ip,内网机器请手动配置端口转发到本机5679端口,填写示例：api.xx.com:5679:\e[0m"
read -r HOST_URL
if [ -z "$HOST_URL" ]; then
    warn "参数错误"
else
    log "HOST_URL: $HOST_URL"
fi
#检测config文件
logConfig() {
    log "CorpId: $WX_CORPID"
    log "CorpSecret: $WX_CORPSECRET"
    log "AgentId: $WX_AGENT_ID"
    log "ThumbMediaId: $WX_THUMB_MEDIA_ID"
    log "ServerToken: $WX_SERVER_TOKEN"
    log "AesKey: $WX_SERVER_AES_KEY"
    log "YOU_WX_USER_ID: $YOU_WX_USER_ID"
    log "DDAccessToken: $DD_ACCCESS_TOKEN"
    log "DDSecret: $DD_SECRET"
}

warn "请提前申请钉钉通知和企业微信应用通知，配置相关参数！！！"
#配置文件目录

if [[ -f $1 ]]; then
    echo "检测到config参数，开始读取config配置文件..."
    source $1
    logConfig
elif [[ -f ./php_config ]];then
    echo "检测到config参数，开始读取config配置文件..."
    source ./php_config
    logConfig
fi

if [[ -z $PANEL_PORT ]]; then
    read -p "请输入面板端口: " PANEL_PORT
    log "面板端口: $PANEL_PORT"
fi

if [[ -z $WX_CORPID ]]; then
    read -p "请输入企业微信CorpId: " WX_CORPID
    log "CorpId: $WX_CORPID"
fi

if [[ -z $WX_CORPSECRET ]]; then
    read -p "请输入企业微信CorpSecret: " WX_CORPSECRET
    log "CorpSecret: $WX_CORPSECRET"
fi


if [[ -z $WX_AGENT_ID ]]; then
    read -p "请输入企业微信应用AgentId: " WX_AGENT_ID
    log "AgentId: $WX_AGENT_ID"
fi

if [[ -z $WX_THUMB_MEDIA_ID ]]; then
    read -p "请输入企业微信ThumbMediaId: " WX_THUMB_MEDIA_ID
    log "ThumbMediaId: $WX_THUMB_MEDIA_ID"
fi

if [[ -z $WX_SERVER_TOKEN ]]; then
    read -p "请输入企业微信服务端Token: " WX_SERVER_TOKEN
    log "ServerToken: $WX_SERVER_TOKEN"
fi
if [[ -z $WX_SERVER_AES_KEY ]]; then
    read -p "请输入企业微信服务端AesKey: " WX_SERVER_AES_KEY
    log "AesKey: $WX_SERVER_AES_KEY"
fi

if [[ -z $YOU_WX_USER_ID ]]; then
    read -p "请输入你自己的企业微信用户ID,企业后台用户详情里面账号就是用户ID: " YOU_WX_USER_ID
    log "YOU_WX_USER_ID: $YOU_WX_USER_ID"
fi

if [[ -z $DD_ACCCESS_TOKEN ]]; then
    read -p "请输入钉钉AccessToken（可选）: " DD_ACCCESS_TOKEN
    log "DDAccessToken: $DD_ACCCESS_TOKEN"
fi

if [[ -z $DD_SECRET ]]; then
    read -p "请输入钉钉Secret（可选）: " DD_SECRET
    log "DDSecret: $DD_SECRET"
fi




#检测容器是否存在
check_container_name() {
    # shellcheck disable=SC2143
    if [ -n "$(docker ps -a | grep $CONTAINER_NAME 2>/dev/null)" ]; then
        HAS_CONTAINER=true
        inp "检测到先前已经存在的容器，是否删除先前的容器：\n1) 是[默认]\n2) 不要"
        echo -n -e "\e[33m输入您的选择->\e[0m"
        read -r update
        if [ "$update" = "2" ]; then
            PULL_IMAGE=false
            inp "您选择了不要删除之前的容器，需要重新输入容器名称"
            input_container_name
        fi
    fi
}

#容器名称
input_container_name() {
    echo -n -e "\e[33m三.请输入要创建的Docker容器名称[默认为：jd-base-nginx-php]->\e[0m"
    read -r container_name
    if [ -z "$container_name" ]; then
        CONTAINER_NAME="jd-base-nginx-php"
    else
        CONTAINER_NAME=$container_name
    fi
    check_container_name
}
input_container_name

#配置已经创建完成，开始执行

log "1.开始创建配置文件目录"
mkdir -p "$CONFIG_PATH"
mkdir -p "$LOG_PATH"

if [ $HAS_IMAGE = true ] && [ $PULL_IMAGE = true ]; then
    log "2.1.开始拉取最新的镜像"
    docker pull $DOCKER_IMG_NAME:$TAG
fi

if [ $HAS_CONTAINER = true ] && [ $DEL_CONTAINER = true ]; then
    log "2.2.删除先前的容器"
    docker stop "$CONTAINER_NAME" >/dev/null
    docker rm "$CONTAINER_NAME" >/dev/null
fi

if [ -z "$PHP_CODE_URL" ]; then
    log "2.3.未填写PHP代码仓库地址，不拉取"
else
    log "2.3.开始拉取仓库PHP代码，$PHP_CODE_URL"
    git clone $PHP_CODE_URL "$WEB_ROOT_PATH"
    touch "$WEB_ROOT_PATH"/JDAccount.json
    log "2.3.1.正在生成config.php文件"
    cat >"$WEB_ROOT_PATH/config.php" <<EOF
<?php
define('CONFIG_PATH', '/jd/config/config.sh');// config.sh文件路径
define('TMP_CONFIG_PATH', '/jd/config/tmpConfig.sh'); // 临时config.sh文件路径
define('DD_TOKEN', '${DD_ACCCESS_TOKEN}');// 钉钉webhook access-token
define('DD_SECRET', '${DD_SECRET}');// 钉钉webhook secret
define('WX_CORPID', '${WX_CORPID}');// 企业微信id
define('WX_CORPSECRET', '${WX_CORPSECRET}'); // 企业微信secret
define('WX_THUMB_MEDIA_ID', '${WX_THUMB_MEDIA_ID}'); //企业微信文章媒体图片
define('WX_AGENT_ID', '${WX_AGENT_ID}'); //企业微信应用agent_id
define('WX_SERVER_TOKEN','${WX_SERVER_TOKEN}'); //企业微信服务端token
define('WX_SERVER_AES_KEY','${WX_SERVER_AES_KEY}'); //企业微信服务端aes-key
define('YOU_WX_USER_ID','${YOU_WX_USER_ID}'); //你自己的企业微信用户id
EOF

  log "2.3.2.正在生成php_config文件"
  cat >"./php_config" <<EOF
DD_TOKEN=${DD_ACCCESS_TOKEN}
DD_SECRET=${DD_SECRET}
WX_CORPID=${WX_CORPID}
WX_CORPSECRET=${WX_CORPSECRET}
WX_THUMB_MEDIA_ID=${WX_THUMB_MEDIA_ID}
WX_AGENT_ID=${WX_AGENT_ID}
WX_SERVER_TOKEN=${WX_SERVER_TOKEN}
WX_SERVER_AES_KEY=${WX_SERVER_AES_KEY}
YOU_WX_USER_ID=${YOU_WX_USER_ID}
EOF

fi



log "3.开始创建容器并执行,若出现Unable to find image请耐心等待"
docker run -dit \
    -v "$CONFIG_PATH":/jd/config \
    -v "$LOG_PATH":/jd/log \
    -v "$SCRIPTS_PATH":/jd/scripts \
    -v "$WEB_ROOT_PATH":/usr/share/nginx/html \
    -p $PANEL_PORT:5678 \
    -p 5679:80 \
    --name "$CONTAINER_NAME" \
    --hostname jd-nginx \
    -e ENABLE_HANGUP=true \
    -e ENABLE_WEB_PANEL=true \
    --restart always \
    "$DOCKER_IMG_NAME":"$TAG"

if [ $INSTALL_WATCH = true ]; then
    log "3.1.开始创建容器并执行"
    docker run -d \
        --name watchtower \
        -v /var/run/docker.sock:/var/run/docker.sock \
        containrrr/watchtower
fi

#检查config文件是否存在

if [ ! -f "$CONFIG_PATH/config.sh" ]; then
    docker cp "$CONTAINER_NAME":/jd/sample/config.sh.sample "$CONFIG_PATH"/config.sh

fi

log "4.下面列出所有容器"
docker ps

log "5.安装已经完成。\n现在你可以访问设备的 ip:5678 用户名：admin  密码：shuye72  来添加cookie，和其他操作。感谢使用！"
log "6.企业微信服务端回调URL: http://${HOST_URL}/reciveMsg.php,请前去https://work.weixin.qq.com/wework_admin/frame#apps填写验证"
log "7.上传cookie地址为：http://${HOST_URL}/index.php,首次安装完成请先打开一下这个地址,首次打开会把以上所有参数写入config.sh"
warn "有疑问+q: 517093030"
chmod -R 777 "$JD_PATH"
git config --global core.fileMode false
