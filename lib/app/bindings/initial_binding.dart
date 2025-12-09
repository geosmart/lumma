import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import '../controllers/language_controller.dart';
import '../data/providers/api_provider.dart';

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

    // 注入 AI API 服务（永久存在）
    Get.put(AiApiService(), permanent: true);
  }
}
