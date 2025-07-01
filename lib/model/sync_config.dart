import 'timestamped.dart';

enum SyncType { obsidian, webdav }

class SyncConfig extends Timestamped {
  // 配置文件存储目录
  String configDir;

  // 日记文件存储目录
  String diaryDir;

  // 同步地址
  String syncUri;

  // 新增 WebDAV 字段
  String webdavUrl;
  String webdavUsername;
  String webdavPassword;
  String webdavDirectory;

  // 新增同步类型字段
  SyncType syncType;

  SyncConfig({
    this.configDir = '',
    this.diaryDir = '',
    this.syncUri = '',
    this.webdavUrl = '',
    this.webdavUsername = '',
    this.webdavPassword = '',
    this.webdavDirectory = '',
    this.syncType = SyncType.obsidian,
    super.created,
    super.updated,
  });

  /// 创建默认的同步配置
  factory SyncConfig.defaultConfig() => SyncConfig(
        configDir: '',
        diaryDir: '',
        syncUri: 'obsidian://adv-uri?vault=mobile&commandid=nutstore-sync%3Astart-sync',
        webdavUrl: '',
        webdavUsername: '',
        webdavPassword: '',
        webdavDirectory: '',
        syncType: SyncType.obsidian,
      );

  factory SyncConfig.fromMap(Map map) => SyncConfig(
        configDir: map['config_dir'] ?? '',
        diaryDir: map['diary_dir'] ?? '',
        syncUri: map['sync_uri'] ?? '',
        webdavUrl: map['webdav_url'] ?? '',
        webdavUsername: map['webdav_username'] ?? '',
        webdavPassword: map['webdav_password'] ?? '',
        webdavDirectory: map['webdav_directory'] ?? '',
        syncType: (map['sync_type'] == 'webdav') ? SyncType.webdav : SyncType.obsidian,
        created: DateTime.tryParse(map['created'] ?? '') ?? DateTime.now(),
        updated: DateTime.tryParse(map['updated'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'config_dir': configDir,
        'diary_dir': diaryDir,
        'sync_uri': syncUri,
        'webdav_url': webdavUrl,
        'webdav_username': webdavUsername,
        'webdav_password': webdavPassword,
        'webdav_directory': webdavDirectory,
        'sync_type': syncType == SyncType.webdav ? 'webdav' : 'obsidian',
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };
}
