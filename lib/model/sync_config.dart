import 'timestamped.dart';

class SyncConfig extends Timestamped {
  bool enabled;
  String endpoint;

  SyncConfig({
    this.enabled = false,
    this.endpoint = '',
    DateTime? created,
    DateTime? updated,
  }) : super(created: created, updated: updated);

  /// 创建默认的同步配置
  factory SyncConfig.defaultConfig() => SyncConfig(
        enabled: false,
        endpoint: '',
      );

  factory SyncConfig.fromMap(Map map) => SyncConfig(
        enabled: map['enabled'] ?? false,
        endpoint: map['endpoint'] ?? '',
        created: DateTime.tryParse(map['created'] ?? '') ?? DateTime.now(),
        updated: DateTime.tryParse(map['updated'] ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'endpoint': endpoint,
        'created': created.toIso8601String(),
        'updated': updated.toIso8601String(),
      };
}
