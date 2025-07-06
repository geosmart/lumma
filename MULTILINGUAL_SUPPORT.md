# 多语言支持实现说明

## 添加的功能

为 Lumma 项目添加了完整的多语言支持，支持中文（简体中文）和英语两种语言。

## 实现的功能

### 1. 国际化框架设置
- 在 `pubspec.yaml` 中添加了 `flutter_localizations` 和 `intl` 依赖
- 创建了 `l10n.yaml` 配置文件
- 添加了 `generate: true` 以启用自动代码生成

### 2. 语言资源文件
- `lib/l10n/app_en.arb` - 英语翻译文件
- `lib/l10n/app_zh.arb` - 中文翻译文件
- 包含了应用中所有用户界面文本的翻译

### 3. 语言管理服务
- `lib/config/language_service.dart` - 语言切换管理服务
- 提供语言切换功能
- 持久化保存用户的语言选择
- 支持动态语言切换

### 4. 更新的文件
- `lib/main.dart` - 添加了国际化支持和语言服务初始化
- `lib/main_page.dart` - 主页面文本本地化
- `lib/config/settings_page.dart` - 设置页面添加了语言切换选项
- `lib/widgets/diary_file_manager.dart` - 日记文件管理组件文本本地化

### 5. 新增的界面功能
在设置页面的外观标签下添加了语言选择功能：
- 支持中文（简体中文）和英语切换
- 实时语言切换，无需重启应用
- 美观的UI设计，与应用整体风格一致

## 如何使用

1. **查看当前语言**：应用启动时会根据系统设置或用户之前的选择显示相应语言
2. **切换语言**：进入设置 → 外观，在语言设置区域选择想要的语言
3. **持久化**：语言选择会自动保存，下次启动应用时会记住用户的选择

## 支持的语言

- **中文（简体中文）** - `zh_CN`
- **英语** - `en_US`

## 技术实现

- 使用 Flutter 标准的国际化框架
- 采用 ARB（Application Resource Bundle）格式存储翻译
- 通过 `ChangeNotifier` 实现语言切换的响应式更新
- 使用 `SharedPreferences` 持久化存储用户语言偏好

## 扩展性

要添加新语言（例如日语），只需：
1. 创建 `lib/l10n/app_ja.arb` 文件
2. 在 `LanguageService.supportedLocales` 中添加 `Locale('ja', 'JP')`
3. 在设置页面添加对应的语言选择项
4. 运行 `flutter gen-l10n` 重新生成本地化文件

## 注意事项

- 所有用户可见的文本都应该使用 `AppLocalizations.of(context)!.keyName` 的方式
- 新增文本时需要同时更新英文和中文的 ARB 文件
- 修改 ARB 文件后需要运行 `flutter gen-l10n` 重新生成代码
