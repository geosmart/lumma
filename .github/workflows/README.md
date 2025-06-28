# GitHub Actions 自动构建说明

本项目包含四个GitHub Actions工作流，用于自动构建Android APK：

## 🚀 工作流说明

### 1. `commit-build.yml` - 提交自动构建 ⭐推荐
**触发条件**：
- 推送到 `main`/`master`/`develop` 分支
- 自动忽略文档和配置文件更改

**功能特性**：
- 🔄 每次提交自动构建
- ⚡ 快速构建，专注APK生成
- 📱 生成开发版APK
- 📦 15天文件保留期
- 🏷️ 使用commit hash命名

### 2. `build-android.yml` - 完整构建流水线
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

### 3. `quick-build.yml` - 快速构建
**触发条件**：
- 仅手动触发

**功能特性**：
- ⚡ 快速构建，跳过测试
- 🎛️ 可选择构建模式（release/debug/profile）
- 📝 自定义版本名称
- 📦 7天文件保留期

### 4. `release.yml` - 发布构建
**触发条件**：
- 推送到 `main`/`master` 分支（仅构建，不创建Release）
- 推送标签（如 `v1.0.0`）（构建并创建Release）
- 手动触发

**功能特性**：
- 🎯 专门用于正式发布
- 📱 同时构建 Release 和 Debug APK
- 📋 详细的Release说明
- 📦 90天文件保留期

## 📱 使用方法

### 🔥 最简单方式：直接提交代码
```bash
git add .
git commit -m "更新功能"
git push origin main
```
**结果**：自动触发`commit-build.yml`，生成开发版APK

### 方式2：创建标签发布
```bash
git tag v1.0.0
git push origin v1.0.0
```
**结果**：同时触发多个工作流，创建正式Release

### 方式3：手动触发构建
1. 进入GitHub项目页面
2. 点击 `Actions` 标签
3. 选择对应的工作流
4. 点击 `Run workflow` 按钮
5. 填写参数并启动构建

## 📦 下载APK

### 提交构建的APK（开发版）
1. 进入 `Actions` 页面
2. 点击对应的构建记录
3. 在 `Artifacts` 部分下载APK

### 正式发布的APK
1. **GitHub Release**（推荐）：
   - 进入项目的 Releases 页面
   - 下载对应版本的APK文件

2. **Actions Artifacts**：
   - 进入对应的Action运行页面
   - 在 Artifacts 部分下载

## 🔧 工作流选择指南

| 场景 | 推荐工作流 | 触发方式 | APK类型 |
|------|------------|----------|---------|
| 日常开发测试 | `commit-build.yml` | 提交代码 | 开发版 |
| 快速验证 | `quick-build.yml` | 手动触发 | 自选模式 |
| 完整测试 | `build-android.yml` | 手动触发 | 完整版 |
| 正式发布 | `release.yml` | 推送标签 | 发布版 |

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

### 忽略触发
以下文件变更不会触发自动构建：
- Markdown文档 (`**.md`)
- 文档目录 (`docs/**`)
- Git配置 (`.gitignore`)
- GitHub Actions配置 (`.github/**`)

### Flutter版本
- 使用 Flutter 3.24.0 stable
- Java 17
- 自动缓存依赖

## 🛠️ 自定义配置

如需修改构建配置，可以编辑对应的工作流文件：

- 修改Flutter版本：更改 `flutter-version`
- 修改Java版本：更改 `java-version`
- 添加签名：配置 `signingConfigs`
- 修改保留期：更改 `retention-days`
- 修改触发分支：更改 `branches` 配置

## 📝 注意事项

1. **提交构建**：每次推送代码到主分支都会自动构建APK
2. **首次运行**可能需要较长时间，后续运行会使用缓存
3. **开发版APK**：提交构建生成的是开发版，适合测试
4. **正式版APK**：通过标签发布生成，适合分发
5. **网络环境**可能影响构建速度

## 🚨 常见问题

### Q: 每次提交都会构建吗？
A: 是的，除非是文档或配置文件的更改

### Q: 如何避免某次提交触发构建？
A: 在提交信息中添加 `[skip ci]` 或 `[ci skip]`

### Q: 开发版和发布版APK有什么区别？
A: 
- 开发版：包含调试信息，文件较大，适合开发测试
- 发布版：优化过的版本，文件较小，适合正式使用

### Q: APK在哪里下载？
A: 
- 开发版：Actions页面的Artifacts
- 发布版：Releases页面或Artifacts

---

✨ **现在可以直接通过 `git push` 自动构建APK了！** 🎉
