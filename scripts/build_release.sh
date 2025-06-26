#!/bin/bash
# 用于生产环境 release 打包，自动切换 .env.release
set -e
cd "$(dirname "$0")/.."

# 拷贝 release 环境变量到 .env
cp .env.release .env

echo "[release] 环境变量已切换为 .env.release"

# Flutter release 构建
flutter clean
flutter pub get
flutter build apk --release
# 如需桌面端可加: flutter build linux --release

echo "[release] 打包完成，环境变量为 .env.release"
