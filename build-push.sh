#!/bin/bash

# build-push.sh - 构建 Docker 镜像并推送到 GitHub Container Registry
# 使用方法:
#   ./build-push.sh              # 推送 latest 标签
#   ./build-push.sh v1.0.0      # 推送 v1.0.0 标签

set -e  # 遇到错误立即退出

# 配置变量
IMAGE_NAME="ghcr.io/austinhmh/blinko"
PROXY="http://10.224.125.61:7897"
DOCKERFILE="dockerfile"

# 获取版本标签参数
VERSION_TAG=${1:-latest}

echo "=========================================="
echo "开始构建并推送 Docker 镜像"
echo "=========================================="
echo "镜像名称: $IMAGE_NAME"
echo "版本标签: $VERSION_TAG"
echo "代理地址: $PROXY"
echo "=========================================="

# 检查 dockerfile 是否存在
if [ ! -f "$DOCKERFILE" ]; then
    echo "错误: 找不到 $DOCKERFILE 文件"
    exit 1
fi

# 设置代理环境变量
export HTTP_PROXY=$PROXY
export HTTPS_PROXY=$PROXY
export http_proxy=$PROXY
export https_proxy=$PROXY

echo ""
echo "步骤 1/4: 使用 Dockerfile 构建 Docker 镜像..."
echo "这可能需要几分钟时间，请耐心等待..."
docker build \
    -f $DOCKERFILE \
    --build-arg USE_MIRROR=true \
    --build-arg HTTP_PROXY=$PROXY \
    --build-arg HTTPS_PROXY=$PROXY \
    -t blinko:$VERSION_TAG \
    --progress=plain \
    . 2>&1 | tee /tmp/docker-build.log

echo ""
echo "步骤 2/4: 为镜像打标签..."
docker tag blinko:$VERSION_TAG $IMAGE_NAME:$VERSION_TAG

if [ "$VERSION_TAG" != "latest" ]; then
    echo "同时打上 latest 标签..."
    docker tag blinko:$VERSION_TAG $IMAGE_NAME:latest
fi

echo ""
echo "步骤 3/4: 检查是否已登录 GitHub Container Registry..."
if ! docker logout https://ghcr.io 2>/dev/null | grep -q "Removing"; then
    echo "提示: 如果推送失败，请先执行: docker login ghcr.io"
    echo "需要 GitHub Personal Access Token (PAT) 具有 write:packages 权限"
fi

echo ""
echo "步骤 4/4: 推送镜像到 GitHub Container Registry..."
docker push $IMAGE_NAME:$VERSION_TAG

if [ "$VERSION_TAG" != "latest" ]; then
    echo "同时推送 latest 标签..."
    docker push $IMAGE_NAME:latest
fi

echo ""
echo "=========================================="
echo "构建和推送完成！"
echo "镜像地址: $IMAGE_NAME:$VERSION_TAG"
if [ "$VERSION_TAG" != "latest" ]; then
    echo "镜像地址: $IMAGE_NAME:latest"
fi
echo "=========================================="
echo ""
echo "使用以下命令拉取并部署:"
echo "  ./pull.sh              # 拉取 latest"
echo "  ./pull.sh $VERSION_TAG   # 拉取 $VERSION_TAG"
