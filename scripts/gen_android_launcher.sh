#!/bin/bash
# 自动生成 Android ic_launcher PNG 图标（基于 assets/icon/icon.png）
# 需要安装 ImageMagick（convert 命令）

set -e

ICON_SRC="assets/icon/icon.png"
ANDROID_RES="android/app/src/main/res"

if [ ! -f "$ICON_SRC" ]; then
  echo "未找到 $ICON_SRC"
  exit 1
fi

sizes=(
  "mipmap-mdpi:48"
  "mipmap-hdpi:72"
  "mipmap-xhdpi:96"
  "mipmap-xxhdpi:144"
  "mipmap-xxxhdpi:192"
)

for item in "${sizes[@]}"; do
  dir="${item%%:*}"
  size="${item##*:}"
  mkdir -p "$ANDROID_RES/$dir"
  convert "$ICON_SRC" -resize ${size}x${size} "$ANDROID_RES/$dir/ic_launcher.png"
  echo "生成 $ANDROID_RES/$dir/ic_launcher.png (${size}x${size})"
done

echo "全部 ic_launcher PNG 已生成。"
