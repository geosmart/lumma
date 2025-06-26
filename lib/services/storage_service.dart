import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _key = 'user_diary_dir';

  /// 获取已选目录（无则返回null）
  static Future<String?> getUserDiaryDir() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  /// 保存用户选定目录
  static Future<void> setUserDiaryDir(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, path);
  }

  /// 清除用户目录
  static Future<void> clearUserDiaryDir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
