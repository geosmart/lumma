# GetX 重构说明文档

## 概述

本项目已成功基于 GetX 库进行重构，实现了更高效的状态管理、路由管理、依赖注入和国际化支持。

## 重构内容

### 1. 添加 GetX 依赖

在 `pubspec.yaml` 中添加了 GetX 依赖：
```yaml
get: ^4.6.6
```

### 2. 项目结构

新增了以下目录结构：

```
lib/
├── app/
│   ├── bindings/
│   │   └── initial_binding.dart          # 全局依赖注入绑定
│   ├── controllers/
│   │   ├── theme_controller.dart         # 主题控制器
│   │   └── language_controller.dart      # 语言控制器
│   ├── data/
│   │   └── providers/
│   │       └── api_provider.dart         # 网络请求服务
│   ├── routes/
│   │   ├── app_routes.dart               # 路由名称定义
│   │   └── app_pages.dart                # 路由页面配置
│   └── translations/
│       ├── app_translations.dart         # 国际化配置
│       ├── en_us.dart                    # 英文翻译
│       └── zh_cn.dart                    # 中文翻译
```

### 3. 核心功能重构

#### 3.1 状态管理

使用 GetX 的响应式状态管理替代原有的 ChangeNotifier：

**主题管理** (`lib/app/controllers/theme_controller.dart`):
```dart
class ThemeController extends GetxController {
  final _themeMode = ThemeMode.dark.obs;  // 响应式变量

  ThemeMode get themeMode => _themeMode.value;

  Future<void> toggleTheme() async {
    _themeMode.value = ...;
    Get.changeThemeMode(_themeMode.value);  // GetX 切换主题
  }
}
```

**语言管理** (`lib/app/controllers/language_controller.dart`):
```dart
class LanguageController extends GetxController {
  final _currentLocale = const Locale('zh', 'CN').obs;

  Future<void> setLanguage(Locale locale) async {
    _currentLocale.value = locale;
    Get.updateLocale(locale);  // GetX 更新语言
  }
}
```

#### 3.2 路由管理

使用 GetX 声明式路由替代传统的 Navigator：

**路由定义** (`lib/app/routes/app_routes.dart`):
```dart
abstract class AppRoutes {
  static const main = '/';
  static const diaryChat = '/diary/chat';
  static const settings = '/settings';
  // ... 其他路由
}
```

**路由配置** (`lib/app/routes/app_pages.dart`):
```dart
class AppPages {
  static final routes = [
    GetPage(name: AppRoutes.main, page: () => const MainTabPage()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsPage()),
    // ... 其他页面
  ];
}
```

**使用方式**:
```dart
// 旧方式
Navigator.of(context).push(MaterialPageRoute(builder: (_) => SettingsPage()));

// 新方式 - 使用 GetX
Get.toNamed(AppRoutes.settings);
```

#### 3.3 依赖注入

使用 GetX 的依赖注入系统 (`lib/app/bindings/initial_binding.dart`):
```dart
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ThemeController(), permanent: true);
    Get.put(LanguageController(), permanent: true);
    Get.put(ApiProvider(), permanent: true);
    Get.put(AiApiService(), permanent: true);
  }
}
```

**使用控制器**:
```dart
// 在任何地方获取控制器实例
final themeController = Get.find<ThemeController>();
final languageController = Get.find<LanguageController>();
```

#### 3.4 国际化

使用 GetX 的国际化功能：

**翻译文件** (`lib/app/translations/zh_cn.dart`):
```dart
class ZhCN extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
    'zh_CN': {
      'app_name': 'Lumma',
      'settings': '设置',
      // ... 其他翻译
    }
  };
}
```

**使用方式**:
```dart
// 在代码中使用
Text('settings'.tr);  // GetX 方式

// 仍可使用原有的 AppLocalizations
Text(AppLocalizations.of(context)!.settings);  // 保留兼容性
```

#### 3.5 网络请求

使用 GetX 的 GetConnect (`lib/app/data/providers/api_provider.dart`):
```dart
class ApiProvider extends GetConnect {
  @override
  void onInit() {
    super.onInit();
    timeout = const Duration(seconds: 30);

    // 请求拦截器
    httpClient.addRequestModifier<dynamic>((request) async {
      request.headers['Content-Type'] = 'application/json';
      return request;
    });
  }

  Future<Response> getRequest(String url, {Map<String, String>? headers}) async {
    return await get(url, headers: headers);
  }

  Future<Response> postRequest(String url, dynamic body, {Map<String, String>? headers}) async {
    return await post(url, body, headers: headers);
  }
}
```

#### 3.6 UI 状态监听

使用 Obx Widget 监听状态变化：

```dart
// 旧方式 - 使用 ListenableBuilder
ListenableBuilder(
  listenable: ThemeService.instance,
  builder: (context, child) {
    return Text('Current theme: ${ThemeService.instance.themeMode}');
  },
)

// 新方式 - 使用 Obx
Obx(() => Text('Current theme: ${themeController.themeMode}'))
```

### 4. 主应用入口重构

**main.dart** 已更新为使用 GetMaterialApp:
```dart
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Lumma',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,

      // GetX 国际化
      translations: AppTranslations.translations.first,
      locale: const Locale('zh', 'CN'),
      fallbackLocale: AppTranslations.fallbackLocale,

      // GetX 路由
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,

      // 全局依赖注入
      initialBinding: InitialBinding(),

      defaultTransition: Transition.cupertino,
    );
  }
}
```

### 5. 已重构的页面

以下页面已使用 GetX 进行重构：

1. **main_page.dart** - 主页，使用 Get.toNamed() 进行路由导航
2. **settings_page.dart** - 设置页，使用 Get.find() 获取控制器，使用 Obx 监听状态

## 使用指南

### 安装依赖

```bash
flutter pub get
```

### 导航到新页面

```dart
// 跳转到页面
Get.toNamed(AppRoutes.settings);

// 跳转并传参
Get.toNamed(AppRoutes.diaryDetail, arguments: {'id': 123});

// 在目标页面获取参数
final args = Get.arguments;

// 返回上一页
Get.back();

// 返回并传递数据
Get.back(result: {'success': true});
```

### 使用控制器

```dart
// 获取控制器
final themeController = Get.find<ThemeController>();

// 调用控制器方法
themeController.toggleTheme();

// 访问控制器属性
bool isDark = themeController.isDarkMode;
```

### 监听状态变化

```dart
// 使用 Obx
Obx(() => Text('当前主题: ${themeController.themeMode}'))

// 使用 GetX Widget
GetX<ThemeController>(
  builder: (controller) {
    return Text('当前主题: ${controller.themeMode}');
  },
)
```

### 国际化

```dart
// 使用 GetX 国际化
Text('settings'.tr)

// 切换语言
Get.updateLocale(Locale('en', 'US'));
```

## 迁移建议

对于尚未重构的页面，建议按照以下步骤进行迁移：

1. **路由迁移**：将 `Navigator.push()` 替换为 `Get.toNamed()`
2. **状态管理迁移**：
   - 将自定义 Service 改为继承 GetxController
   - 使用 `.obs` 使变量成为响应式
   - 使用 `Obx` 或 `GetX` Widget 监听状态
3. **依赖注入**：在 Binding 中注册控制器
4. **国际化**：使用 GetX 的 `.tr` 方法

## 优势

1. **更少的样板代码** - 不需要 BuildContext
2. **更好的性能** - 智能的状态更新，只重建需要的 Widget
3. **内存管理** - 自动销毁不再使用的控制器
4. **依赖注入** - 简单高效的依赖管理
5. **路由管理** - 命名路由，更清晰的导航结构
6. **国际化** - 内置的国际化支持

## 注意事项

1. 运行 `flutter pub get` 安装 GetX 依赖
2. 原有的 AppLocalizations 仍然可用，保持向后兼容
3. 原有的 ThemeService 和 LanguageService 已被新的 Controller 替代
4. 建议逐步迁移其他页面到 GetX 架构

## 下一步工作

可以继续重构以下内容：

1. 将其他配置相关的 Service 转换为 GetX Controller
2. 将日记相关的 Service 转换为 GetX Controller
3. 重构其他页面的路由导航
4. 优化网络请求层，充分利用 GetConnect 的特性
5. 添加更多的国际化翻译

## 参考资源

- [GetX 官方文档](https://github.com/jonataslaw/getx)
- [GetX 中文文档](https://github.com/jonataslaw/getx/blob/master/README.zh-cn.md)
