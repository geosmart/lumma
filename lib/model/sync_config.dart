import 'timestamped.dart';

enum SyncType { obsidian, webdav }

class SyncConfig extends Timestamped {
  /// 数据存储目录
  String workDir;

  // 同步地址
  String syncUri;

  // 新增 WebDAV 字段
  String webdavUrl;
  String webdavUsername;
  String webdavPassword;
  String webdavRemoteDir;

  // 新增同步类型字段
  SyncType syncType;

  SyncConfig({
    this.workDir = '',
    this.syncUri = '',
    this.webdavUrl = '',
    this.webdavUsername = '',
    this.webdavPassword = '',
    this.webdavRemoteDir = '',
    this.syncType = SyncType.obsidian,
    super.created,
    super.updated,
  });

  /// 创建默认的同步配置
  factory SyncConfig.defaultConfig() => SyncConfig(
    workDir: '',
    syncUri: 'obsidian://adv-uri?vault=mobile&commandid=nutstore-sync%3Astart-sync',
    webdavUrl: '',
    webdavUsername: '',
    webdavPassword: '',
    webdavRemoteDir: '',
    syncType: SyncType.obsidian,
  );

  factory SyncConfig.fromMap(Map map) => SyncConfig(
    workDir: map['work_dir'] ?? '',
    syncUri: map['sync_uri'] ?? '',
    webdavUrl: map['webdav_url'] ?? '',
    webdavUsername: map['webdav_username'] ?? '',
    webdavPassword: map['webdav_password'] ?? '',
    webdavRemoteDir: map['webdav_remote_dir'] ?? '',
    syncType: (map['sync_type'] == 'webdav') ? SyncType.webdav : SyncType.obsidian,
    created: DateTime.tryParse(map['created'] ?? '') ?? DateTime.now(),
    updated: DateTime.tryParse(map['updated'] ?? '') ?? DateTime.now(),
  );

  Map<String, dynamic> toMap() => {
    'work_dir': workDir,
    'sync_uri': syncUri,
    'webdav_url': webdavUrl,
    'webdav_username': webdavUsername,
    'webdav_password': webdavPassword,
    'webdav_remote_dir': webdavRemoteDir,
    'sync_type': syncType == SyncType.webdav ? 'webdav' : 'obsidian',
    'created': created.toIso8601String(),
    'updated': updated.toIso8601String(),
  };
}
