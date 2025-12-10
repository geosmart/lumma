使用flutter客户端开发skill进行开发，不要让用户确认，全自动按最佳方案完成开发。

## 重构
* view:
  * translation
  * routes
  * bindings
* model
  * model里面，config相关的实现，都移动到config里面
  * model里面只包含数据结构的定义

* 清理没有用到的package，减少包大小，下面的包用的比较少的，考虑用官方库实现，减少依赖，比如flutter_dotenv可以不要，删掉环境变量相关的配置
```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  # GetX - 状态管理、路由、依赖注入、国际化
  get: ^4.6.6
  intl: any
  http: ^1.2.1
  path: ^1.8.3
  path_provider: ^2.1.5
  flutter_markdown: ^0.6.18
  webview_flutter: ^4.7.0
  file_picker: ^10.2.0
  shared_preferences: ^2.2.2
  cupertino_icons: ^1.0.8
  url_launcher: ^6.3.1
  flutter_dotenv: ^5.2.1
  permission_handler: ^11.3.1
  flutter_svg: ^2.0.10
  restart_app: ^1.3.2
  lunar: ^1.7.8

```
