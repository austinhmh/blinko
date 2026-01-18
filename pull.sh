#!/bin/bash

# pull.sh - 从 GitHub Container Registry 拉取镜像并部署
# 使用方法:
#   ./pull.sh              # 拉取 latest 标签
#   ./pull.sh v1.0.0      # 拉取 v1.0.0 标签

set -e  # 遇到错误立即退出

# 配置变量
IMAGE_NAME="ghcr.io/austinhmh/blinko"
CONTAINER_NAME="blinko-website"
NETWORK_NAME="blinko_blinko-network"
POSTGRES_CONTAINER="blinko-postgres"

# 获取版本标签参数
VERSION_TAG=${1:-latest}

echo "=========================================="
echo "开始拉取并部署 Docker 容器"
echo "=========================================="
echo "镜像地址: $IMAGE_NAME:$VERSION_TAG"
echo "容器名称: $CONTAINER_NAME"
echo "网络名称: $NETWORK_NAME"
echo "=========================================="

# 检查是否已登录 GHCR
echo ""
echo "步骤 1/7: 检查 GHCR 登录状态..."
if ! docker info 2>/dev/null | grep -q "Username"; then
    echo "警告: 可能未登录 GHCR，如果拉取失败请执行: docker login ghcr.io"
fi

# 拉取镜像
echo ""
echo "步骤 2/7: 拉取镜像 $IMAGE_NAME:$VERSION_TAG..."
docker pull $IMAGE_NAME:$VERSION_TAG

# 为本地使用打标签
echo ""
echo "步骤 3/7: 为镜像打本地标签..."
docker tag $IMAGE_NAME:$VERSION_TAG blinko_blinko-website:latest

# 停止并删除旧容器
echo ""
echo "步骤 4/7: 停止并删除旧容器..."
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    echo "发现旧容器，正在停止并删除..."
    docker stop $CONTAINER_NAME 2>/dev/null || true
    docker rm $CONTAINER_NAME 2>/dev/null || true
    echo "旧容器已删除"
else
    echo "未发现旧容器，跳过此步骤"
fi

# 创建网络（如果不存在）
echo ""
echo "步骤 5/7: 检查并创建网络..."
if ! docker network ls | grep -q $NETWORK_NAME; then
    echo "创建网络 $NETWORK_NAME..."
    docker network create $NETWORK_NAME
else
    echo "网络 $NETWORK_NAME 已存在"
fi

# 连接 postgres 到网络
echo ""
echo "步骤 6/7: 连接 postgres 容器到网络..."
if [ "$(docker ps -aq -f name=$POSTGRES_CONTAINER)" ]; then
    if ! docker network inspect $NETWORK_NAME | grep -q $POSTGRES_CONTAINER; then
        docker network connect $NETWORK_NAME $POSTGRES_CONTAINER
        echo "已连接 $POSTGRES_CONTAINER 到 $NETWORK_NAME"
    else
        echo "$POSTGRES_CONTAINER 已在网络中"
    fi
else
    echo "警告: 未找到 $POSTGRES_CONTAINER 容器"
    echo "请确保 postgres 容器正在运行"
fi

# 启动新容器
echo ""
echo "步骤 7/7: 启动新容器..."
docker run -d \
    --name $CONTAINER_NAME \
    --network $NETWORK_NAME \
    -p 0.0.0.0:1111:1111 \
    -e NODE_ENV=production \
    -e NEXTAUTH_URL=http://localhost:1111 \
    -e NEXT_PUBLIC_BASE_URL=http://localhost:1111 \
    -e NEXTAUTH_SECRET=my_ultra_secure_nextauth_secret \
    -e DATABASE_URL=postgresql://postgres:mysecretpassword@blinko-postgres:5432/postgres \
    --restart always \
    blinko_blinko-website:latest

# 等待容器启动
echo ""
echo "等待容器启动..."
sleep 5

# 显示容器状态
echo ""
echo "=========================================="
echo "部署完成！"
echo "=========================================="
docker ps -f name=$CONTAINER_NAME --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "访问地址:"
echo "  本地: http://localhost:1111"
echo "  外部: http://<your-ip>:1111"
echo ""
echo "查看日志:"
echo "  docker logs -f $CONTAINER_NAME"
echo ""
echo "停止容器:"
echo "  ./stop.sh"
echo "=========================================="
