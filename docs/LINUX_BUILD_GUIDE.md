# Lumma Linux AppImage 构建指南

## 📋 系统要求

### 操作系统
- Ubuntu 20.04+ 或其他基于Debian的Linux发行版
- 64位 x86_64 架构

### 依赖软件
- Flutter 3.32.5+
- CMake 3.13+
- Clang/GCC编译器
- GTK 3开发库

## 🚀 快速开始

### 1. 安装系统依赖

```bash
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
```

### 2. 启用Flutter Linux桌面支持

```bash
flutter config --enable-linux-desktop
flutter doctor
```

### 3. 快速测试构建

```bash
# 测试基本的Linux构建
./scripts/test_linux_build.sh
```

### 4. 构建AppImage

```bash
# 构建完整的AppImage安装包
./scripts/build_linux_appimage.sh [版本号] [构建号]

# 示例:
./scripts/build_linux_appimage.sh 1.0.0 1
```

## 📦 AppImage 使用

构建完成后，AppImage文件将位于 `linux/build/` 目录中，同时会在根目录创建一个便捷访问的符号链接:

```bash
# 设置可执行权限
chmod +x lumma-1.0.0-x86_64.AppImage

# 直接运行（根目录符号链接）
./lumma-1.0.0-x86_64.AppImage

# 或者直接运行构建目录中的文件
./linux/build/lumma-1.0.0-x86_64.AppImage
```

## 📁 目录结构

构建过程会创建以下目录结构:

```
linux/
├── build/
│   ├── appimagetool              # AppImage打包工具
│   ├── lumma.AppDir/             # AppImage临时目录
│   └── lumma-1.0.0-x86_64.AppImage  # 最终AppImage文件
└── ...
lumma-1.0.0-x86_64.AppImage      # 根目录便捷访问符号链接
```

## 🔄 GitHub Actions 自动构建

当你推送版本标签时，GitHub Actions会自动构建所有平台的安装包：

```bash
# 创建并推送版本标签
git tag v1.0.0
git push origin v1.0.0
```

这将自动构建：
- 📱 Android APK
- 🐧 Linux AppImage
- 🍎 iOS IPA (在macOS runner上)

## 🛠️ 手动构建步骤

如果你需要手动构建，可以按照以下步骤：

### 1. 准备环境
```bash
flutter pub get
flutter config --enable-linux-desktop
```

### 2. 构建应用
```bash
flutter build linux --release
```

### 3. 创建AppImage结构
```bash
mkdir -p lumma.AppDir/usr/bin
cp -r build/linux/x64/release/bundle/* lumma.AppDir/usr/bin/
```

### 4. 创建桌面文件和图标
```bash
mkdir -p lumma.AppDir/usr/share/applications
mkdir -p lumma.AppDir/usr/share/icons/hicolor/256x256/apps

# 创建.desktop文件
cat > lumma.AppDir/usr/share/applications/lumma.desktop << EOF
[Desktop Entry]
Name=Lumma
Comment=AI-powered Q&A Diary App
Exec=lumma
Icon=lumma
Type=Application
Categories=Office;Productivity;
StartupNotify=true
EOF
```

### 5. 下载并使用AppImageTool
```bash
mkdir -p linux/build
wget -O linux/build/appimagetool https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
chmod +x linux/build/appimagetool
./linux/build/appimagetool linux/build/lumma.AppDir linux/build/lumma-1.0.0-x86_64.AppImage
```

## 🐛 问题排查

### 构建失败
- 确保所有系统依赖已安装
- 检查Flutter版本是否支持Linux桌面
- 运行 `flutter doctor` 检查环境

### AppImage无法运行
- 确保文件有可执行权限
- 检查系统是否支持AppImage
- 尝试在终端运行查看错误信息

### 缺少图标或桌面集成
- 确保图标文件存在于正确路径
- 检查.desktop文件格式是否正确

## 📚 更多信息

- [Flutter Linux桌面开发文档](https://docs.flutter.dev/platform-integration/linux)
- [AppImage官方文档](https://appimage.org/)
- [项目GitHub仓库](https://github.com/your-username/lumma)

## 📝 注意事项

1. **性能优化**: Release构建已启用优化，但首次启动可能较慢
2. **文件权限**: AppImage需要可执行权限才能运行
3. **系统兼容性**: AppImage兼容大多数Linux发行版，但可能在某些旧版本系统上遇到问题
4. **依赖库**: AppImage会打包必要的依赖，但某些系统库仍需要系统提供

---

🎉 享受使用Lumma在Linux平台上的体验！
