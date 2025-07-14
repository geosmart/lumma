#!/bin/bash

# Lumma Linux AppImage Build Script
# 用于在本地Linux环境构建AppImage安装包

set -e

APP_NAME="lumma"
VERSION=${1:-"1.0.0"}
BUILD_NUMBER=${2:-"1"}

echo "🚀 开始构建 Lumma Linux AppImage..."
echo "版本: $VERSION"
echo "构建号: $BUILD_NUMBER"

# 检查Flutter环境
echo "📋 检查Flutter环境..."
if ! command -v flutter &> /dev/null; then
    echo "❌ 未找到Flutter，请先安装Flutter"
    exit 1
fi

flutter --version
flutter config --enable-linux-desktop

# 安装依赖
echo "📦 安装依赖..."
sudo apt-get update
sudo apt-get install -y \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    wget \
    file

# 安装Flutter依赖
echo "📥 安装Flutter依赖..."
flutter pub get

# 创建环境文件
echo "⚙️ 创建环境配置..."
cat > .env.release << EOF
MODEL_PROVIDER=openrouter
MODEL_BASE_URL=https://openrouter.ai/api/v1
MODEL_API_KEY=sk-or-v1
MODEL_NAME=deepseek/deepseek-chat-v3-0324:free
USE_LOCAL_CONFIG=false
EOF

# 构建Linux应用
echo "🔨 构建Linux应用..."
flutter build linux \
    --release \
    --build-name="$VERSION" \
    --build-number="$BUILD_NUMBER" \
    --verbose

# 创建Linux构建目录
mkdir -p linux/build

# 下载AppImageTool
echo "📥 下载AppImageTool..."
if [ ! -f "linux/build/appimagetool" ]; then
    wget -O linux/build/appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x linux/build/appimagetool
fi

# 创建AppImage结构
echo "📁 创建AppImage结构..."
APP_DIR="linux/build/${APP_NAME}.AppDir"
rm -rf "$APP_DIR"

mkdir -p "$APP_DIR/usr/bin"
mkdir -p "$APP_DIR/usr/lib"
mkdir -p "$APP_DIR/usr/share/applications"
mkdir -p "$APP_DIR/usr/share/icons/hicolor/256x256/apps"

# 复制构建的应用
echo "📋 复制应用文件..."
cp -r build/linux/x64/release/bundle/* "$APP_DIR/usr/bin/"

# 创建桌面文件
echo "🖥️ 创建桌面文件..."
cat > "$APP_DIR/usr/share/applications/$APP_NAME.desktop" << EOF
[Desktop Entry]
Name=Lumma
Comment=AI-powered Q&A Diary App
Exec=$APP_NAME
Icon=$APP_NAME
Type=Application
Categories=Office;
StartupNotify=true
EOF

# 创建AppRun脚本
echo "📜 创建AppRun脚本..."
cat > "$APP_DIR/AppRun" << 'EOF'
#!/bin/bash
HERE="$(dirname "$(readlink -f "${0}")")"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${LD_LIBRARY_PATH}"
exec "${HERE}/usr/bin/lumma" "$@"
EOF
chmod +x "$APP_DIR/AppRun"

# 复制图标
echo "🎨 设置应用图标..."
if [ -f "assets/icon/icon.jpg" ]; then
    cp "assets/icon/icon.jpg" "$APP_DIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
else
    echo "⚠️ 未找到应用图标，创建占位图标..."
    # 创建简单的占位图标
    if command -v convert &> /dev/null; then
        convert -size 256x256 xc:lightblue -pointsize 72 -fill darkblue -gravity center -annotate +0+0 "L" "$APP_DIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png"
    else
        wget -O "$APP_DIR/usr/share/icons/hicolor/256x256/apps/$APP_NAME.png" "https://via.placeholder.com/256x256/lightblue/darkblue?text=L"
    fi
fi

# 创建根级别的符号链接
ln -sf "usr/share/applications/$APP_NAME.desktop" "$APP_DIR/"
ln -sf "usr/share/icons/hicolor/256x256/apps/$APP_NAME.png" "$APP_DIR/"

echo "📂 AppDir结构:"
find "$APP_DIR" -type f | head -20

# 创建AppImage
echo "📦 创建AppImage..."
OUTPUT_FILE="linux/build/${APP_NAME}-${VERSION}-x86_64.AppImage"
./linux/build/appimagetool "$APP_DIR" "$OUTPUT_FILE"

# 验证AppImage
if [ -f "$OUTPUT_FILE" ]; then
    echo "✅ AppImage创建成功!"
    echo "📄 文件信息:"
    ls -la "$OUTPUT_FILE"
    file "$OUTPUT_FILE"

    # 创建便捷访问的符号链接
    CONVENIENCE_LINK="${APP_NAME}-${VERSION}-x86_64.AppImage"
    if [ -L "$CONVENIENCE_LINK" ] || [ -f "$CONVENIENCE_LINK" ]; then
        rm -f "$CONVENIENCE_LINK"
    fi
    ln -sf "$OUTPUT_FILE" "$CONVENIENCE_LINK"

    echo ""
    echo "🎉 构建完成!"
    echo "📁 AppImage位置: ./$OUTPUT_FILE"
    echo "🔗 便捷访问: ./$CONVENIENCE_LINK"
    echo ""
    echo "💡 使用方法:"
    echo "   chmod +x $CONVENIENCE_LINK"
    echo "   ./$CONVENIENCE_LINK"
else
    echo "❌ AppImage创建失败"
    exit 1
fi
