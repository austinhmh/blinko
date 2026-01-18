#!/bin/bash

# stop.sh - 停止并清理 blinko-website Docker 容器
# 使用方法:
#   ./stop.sh

set -e  # 遇到错误立即退出

# 配置变量
CONTAINER_NAME="blinko-website"

echo "=========================================="
echo "停止并清理 Blinko 容器"
echo "=========================================="
echo "容器名称: $CONTAINER_NAME"
echo "=========================================="

# 检查容器是否存在
echo ""
echo "检查容器状态..."
if [ "$(docker ps -aq -f name=$CONTAINER_NAME)" ]; then
    
    # 检查容器是否正在运行
    if [ "$(docker ps -q -f name=$CONTAINER_NAME)" ]; then
        echo ""
        echo "步骤 1/2: 停止容器 $CONTAINER_NAME..."
        docker stop $CONTAINER_NAME
        echo "容器已停止"
    else
        echo ""
        echo "容器 $CONTAINER_NAME 未运行"
    fi
    
    # 删除容器
    echo ""
    echo "步骤 2/2: 删除容器 $CONTAINER_NAME..."
    docker rm $CONTAINER_NAME
    echo "容器已删除"
    
    echo ""
    echo "=========================================="
    echo "清理完成！"
    echo "容器 $CONTAINER_NAME 已被停止并删除"
    echo "=========================================="
    echo ""
    echo "数据卷和数据库未被删除，可以安全地重新部署"
    echo "使用 ./pull.sh 重新部署容器"
    
else
    echo ""
    echo "未找到容器 $CONTAINER_NAME"
    echo "无需清理"
fi

echo ""
echo "当前运行的 blinko 相关容器:"
docker ps -f name=blinko --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" || echo "无"
