#!/bin/bash

# Lumma Linux 依赖安装脚本
# Install dependencies for Lumma Linux build

echo "📦 安装 Lumma Linux 构建依赖..."

# 更新包列表
echo "🔄 更新包列表..."
sudo apt-get update

# 安装基础构建工具
echo "🔧 安装基础构建工具..."
sudo apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa

# 安装Flutter Linux桌面依赖
echo "🐧 安装Flutter Linux桌面依赖..."
sudo apt-get install -y \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev

# 安装AppImage相关工具
echo "📦 安装AppImage工具..."
sudo apt-get install -y \
    wget \
    file \
    fuse

# 可选：安装图像处理工具（用于图标转换）
echo "🎨 安装可选的图像处理工具..."
sudo apt-get install -y imagemagick || echo "⚠️ ImageMagick安装失败，将使用在线图标服务"

# 检查Flutter是否已安装
if ! command -v flutter &> /dev/null; then
    echo "⚠️ 未检测到Flutter，请访问以下链接安装:"
    echo "   https://docs.flutter.dev/get-started/install/linux"
    echo ""
    echo "或者运行以下命令快速安装Flutter:"
    echo "   git clone https://github.com/flutter/flutter.git -b stable ~/flutter"
    echo "   echo 'export PATH=\$PATH:~/flutter/bin' >> ~/.bashrc"
    echo "   source ~/.bashrc"
else
    echo "✅ Flutter已安装: $(flutter --version | head -1)"
fi

echo ""
echo "✅ 依赖安装完成!"
echo ""
echo "📋 下一步:"
echo "   1. 如果刚安装了Flutter，请重新打开终端或运行 'source ~/.bashrc'"
echo "   2. 运行 'flutter config --enable-linux-desktop' 启用Linux桌面支持"
echo "   3. 运行 './scripts/test_linux_build.sh' 测试构建"
echo "   4. 运行 './scripts/build_linux_appimage.sh' 构建AppImage"
