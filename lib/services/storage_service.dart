import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _key = 'user_diary_dir';
  static const _obsidianDirKey = 'obsidian_diary_dir';
  static const _backupDirKey = 'system_backup_dir';

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

  /// 获取Obsidian日记目录
  static Future<String?> getObsidianDiaryDir() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_obsidianDirKey);
  }

  /// 设置Obsidian日记目录
  static Future<void> setObsidianDiaryDir(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_obsidianDirKey, path);
  }

  /// 清除Obsidian日记目录
  static Future<void> clearObsidianDiaryDir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_obsidianDirKey);
  }

  /// 获取系统备份目录
  static Future<String?> getSystemBackupDir() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_backupDirKey);
  }

  /// 设置系统备份目录
  static Future<void> setSystemBackupDir(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_backupDirKey, path);
  }

  /// 清除系统备份目录
  static Future<void> clearSystemBackupDir() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_backupDirKey);
  }
}
