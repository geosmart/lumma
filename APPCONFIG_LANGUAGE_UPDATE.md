# AppConfig 语言配置和持久化更新

## 更新内容

### 1. 添加语言枚举 (lib/model/enums.dart)
- 新增 `LanguageType` 枚举，支持 `zh` (中文) 和 `en` (英文)
- 添加 `languageTypeToString()` 和 `languageTypeFromString()` 转换函数

### 2. 更新 AppConfig 模型 (lib/model/app_config.dart)
- 在 `AppConfig` 类中添加 `LanguageType language` 字段
- 默认语言设置为中文 (`LanguageType.zh`)
- 更新构造函数、`fromMap()` 和 `toMap()` 方法以支持语言配置

### 3. 更新 LanguageService (lib/config/language_service.dart)
- 移除对 `SharedPreferences` 的依赖，改为使用 `AppConfigService`
- 在 `init()` 方法中从 `AppConfig` 加载语言设置
- 在 `setLanguage()` 方法中立即保存到 `AppConfig` 实现持久化
- 支持配置变更的实时生效

### 4. 更新配置服务初始化 (lib/config/config_service.dart)
- 在 `AppConfigService.init()` 中添加 `LanguageService.instance.init()` 调用
- 确保语言服务在应用启动时正确初始化

## 功能特点

### 🎯 立即生效
- 用户在设置页面选择语言后，界面立即切换到对应语言
- 使用 `ChangeNotifier` 模式，所有监听器会立即收到更新通知

### 💾 持久化存储
- 语言选择自动保存到 `lumma_config.json` 文件
- 应用重启后会从配置文件恢复用户的语言选择
- 与其他配置项（主题、模型等）统一管理

### 🔧 配置同步
- 主题和语言配置都通过 `AppConfigService.update()` 方法进行统一管理
- 配置变更时自动保存到配置文件
- 支持配置文件的跨设备同步（通过现有的同步机制）

## 使用方式

### 在代码中获取语言设置
```dart
// 获取当前语言
final currentLocale = LanguageService.instance.currentLocale;

// 切换语言
await LanguageService.instance.setLanguage(const Locale('en', 'US'));
```

### 在 UI 中监听语言变化
```dart
ListenableBuilder(
  listenable: LanguageService.instance,
  builder: (context, child) {
    // UI 会自动响应语言变化
    return Text(AppLocalizations.of(context)!.someText);
  },
)
```

## 配置文件结构

更新后的 `lumma_config.json` 包含语言字段：

```json
{
  "diary_mode": "qa",
  "theme": "light",
  "language": "zh",
  "model": [...],
  "prompt": [...],
  "sync": {...},
  "qa_questions": [...]
}
```

## 迁移说明

- 现有用户的配置会自动迁移，默认语言设置为中文
- 如果配置文件中没有 `language` 字段，会使用默认值 `zh`
- 原有的 `SharedPreferences` 语言设置会被配置文件中的设置覆盖

## 扩展性

要添加新语言（如日语），只需：
1. 在 `LanguageType` 枚举中添加 `ja`
2. 更新转换函数
3. 在 `LanguageService.supportedLocales` 中添加对应的 `Locale`
4. 创建相应的 ARB 文件
