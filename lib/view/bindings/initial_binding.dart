import 'package:get/get.dart';
import 'package:lumma/controller/theme_controller.dart';
import 'package:lumma/controller/language_controller.dart';
import 'package:lumma/service/api_provider.dart';

/// 全局依赖绑定
/// 在应用启动时初始化的核心服务
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    // 注入主题控制器（永久存在）
    Get.put(ThemeController(), permanent: true);

    // 注入语言控制器（永久存在）
    Get.put(LanguageController(), permanent: true);

    // 注入 API 提供者（永久存在）
    Get.put(ApiProvider(), permanent: true);
  }
}
