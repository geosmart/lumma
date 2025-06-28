# GitHub Actions 自动构建说明

本项目包含三个GitHub Actions工作流，用于自动构建Android APK：

## 🚀 工作流说明

### 1. `build-android.yml` - 完整构建流水线
**触发条件**：
- 推送到 `main`/`master` 分支
- 创建以 `v` 开头的标签
- 手动触发

**功能特性**：
- ✅ 代码分析和测试
- 📱 支持 Release/Debug 构建
- 🔄 自动版本号管理
- 📦 上传构建产物
- 🏷️ 自动创建GitHub Release（标签推送时）

### 2. `quick-build.yml` - 快速构建
**触发条件**：
- 仅手动触发

**功能特性**：
- ⚡ 快速构建，跳过测试
- 🎛️ 可选择构建模式（release/debug/profile）
- 📝 自定义版本名称
- 📦 7天文件保留期

### 3. `release.yml` - 发布构建
**触发条件**：
- 推送标签（如 `v1.0.0`）
- 手动触发

**功能特性**：
- 🎯 专门用于正式发布
- 📱 同时构建 Release 和 Debug APK
- 📋 详细的Release说明
- 📦 90天文件保留期

## 📱 使用方法

### 方式1：创建标签发布
```bash
git tag v1.0.0
git push origin v1.0.0
```

### 方式2：手动触发构建
1. 进入GitHub项目页面
2. 点击 `Actions` 标签
3. 选择对应的工作流
4. 点击 `Run workflow` 按钮
5. 填写参数并启动构建

### 方式3：推送代码自动构建
```bash
git push origin main
```

## 📦 下载APK

构建完成后，可以通过以下方式下载APK：

1. **GitHub Release**（推荐）：
   - 进入项目的 Releases 页面
   - 下载对应版本的APK文件

2. **Actions Artifacts**：
   - 进入对应的Action运行页面
   - 在 Artifacts 部分下载

## 🔧 配置说明

### 环境变量
所有工作流都会自动创建 `.env.release` 文件，包含：
```env
MODEL_PROVIDER=openrouter
MODEL_BASE_URL=https://openrouter.ai/api/v1
MODEL_API_KEY=sk-or-v1
MODEL_NAME=deepseek/deepseek-chat-v3-0324:free
USE_LOCAL_CONFIG=false
```

### Flutter版本
- 使用 Flutter 3.24.0 stable
- Java 17
- 自动缓存依赖

### 签名配置
- 目前使用未签名的APK
- 如需签名，需要在仓库中配置密钥和密码

## 🛠️ 自定义配置

如需修改构建配置，可以编辑对应的工作流文件：

- 修改Flutter版本：更改 `flutter-version`
- 修改Java版本：更改 `java-version`
- 添加签名：配置 `signingConfigs`
- 修改保留期：更改 `retention-days`

## 📝 注意事项

1. **首次运行**可能需要较长时间，后续运行会使用缓存
2. **签名APK**需要额外配置密钥存储
3. **Release构建**会自动创建GitHub Release
4. **网络环境**可能影响构建速度

## 🚨 常见问题

### Q: 构建失败怎么办？
A: 查看Actions日志，常见原因：
- 依赖下载失败
- 代码编译错误
- 环境配置问题

### Q: APK无法安装？
A: 确保：
- 启用"未知来源"安装
- 下载完整的APK文件
- Android版本兼容

### Q: 如何添加签名？
A: 需要：
1. 上传密钥文件到仓库
2. 配置GitHub Secrets
3. 修改工作流文件

---

✨ **Happy Coding!** 🎉
