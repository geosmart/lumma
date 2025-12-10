import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:lumma/model/app_config.dart';
import 'package:lumma/model/llm_config.dart';
import 'package:lumma/model/enums.dart';
import 'package:lumma/service/theme_service.dart';
import 'package:lumma/service/language_service.dart';
import 'package:lumma/service/prompt_config_service.dart';
import 'package:lumma/util/storage_service.dart';

const String kLummaConfigFileName = 'lumma_config.json';

/// AppConfigService is responsible for managing the loading, saving, and updating of application configuration
///
/// Configuration file storage path priority:
/// 1. User-defined configuration directory (config.sync.configDir)
/// 2. Application documents directory
///
/// When the configuration file does not exist or fails to load, a default configuration is created and persisted to the configuration file
/// 系统其他地方应尽量使用此服务获取配置文件路径，以保持一致性
class AppConfigService {
  static AppConfig? _cache;

  /// 获取配置文件，集中管理配置文件的访问逻辑
  /// 优先使用自定义配置目录，其次使用应用文档目录
  static Future<File> getConfigFile() async {
    // 优先使用 StorageService.getWorkDir()
    String? workDir = await StorageService.getWorkDir();
    String? confPath;
    if (workDir != null && workDir.isNotEmpty) {
      confPath = await StorageService.getAppConfigFilePath(workDir: workDir);
    } else {
      // 使用统一的数据存储目录结构
      final dir = await getApplicationDocumentsDirectory();
      final configDir = Directory('${dir.path}/config');
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
      }
      confPath = '${configDir.path}/$kLummaConfigFileName';
    }
    print('[AppConfigService] 配置文件路径: $confPath');
    return File(confPath);
  }

  /// 获取应用数据根目录
  static Future<Directory> getAppDataDir() async {
    String? customDir = await StorageService.getWorkDir();
    if (customDir != null && customDir.isNotEmpty) {
      final dir = Directory(customDir);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      return dir;
    }
  }

  static Future<AppConfig> load() async {
    try {
      if (_cache != null) return _cache!;
      final file = await getConfigFile();
      if (!await file.exists()) {
        _cache = AppConfig.defaultConfig();
        // 将默认配置持久化到文件
        await file.create(recursive: true);
        await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_cache!.toMap()));
        print('[AppConfigService] 创建默认配置文件');
        return _cache!;
      }
      final content = await file.readAsString();
      final map = content.isNotEmpty ? jsonDecode(content) : {};
      _cache = AppConfig.fromMap(map);
      return _cache!;
    } catch (e, stack) {
      // 日志输出异常，返回默认配置
      print('[AppConfigService] 加载配置异常: $e\n$stack');
      _cache = AppConfig.defaultConfig();

      // 尝试将默认配置持久化
      try {
        final file = await getConfigFile();
        await file.create(recursive: true);
        await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_cache!.toMap()));
        print('[AppConfigService] 加载异常后创建默认配置文件');
      } catch (saveError) {
        print('[AppConfigService] 创建默认配置文件失败: $saveError');
      }

      return _cache!;
    }
  }

  static Future<void> save() async {
    try {
      print('[AppConfigService] save() called');
      if (_cache != null) {
        final file = await getConfigFile();
        await file.writeAsString(const JsonEncoder.withIndent('  ').convert(_cache!.toMap()));
        print('[AppConfigService] 保存配置: ${const JsonEncoder.withIndent('  ').convert(_cache!.toMap())}');
      }
    } catch (e, stack) {
      print('[AppConfigService] 保存配置异常: $e\n$stack');
      rethrow;
    }
  }

  static Future<void> update(void Function(AppConfig) updater) async {
    try {
      final config = await load();
      updater(config);
      await save();
    } catch (e, stack) {
      print('[AppConfigService] 更新配置异常: $e\n$stack');
      rethrow;
    }
  }

  static Future<void> clearCache() async {
    _cache = null;
  }

  /// 确保应用的标准数据目录结构存在
  static Future<void> ensureDataDirectories() async {
    try {
      final appDataDir = await getAppDataDir();
      final dataDirPath = appDataDir.path;

      // 确保配置目录存在
      final configDir = Directory('$dataDirPath/config');
      if (!await configDir.exists()) {
        await configDir.create(recursive: true);
        print('[AppConfigService] 创建配置目录: ${configDir.path}');
      }

      // 确保 prompt 目录存在
      final promptDir = Directory('$dataDirPath/config/prompt');
      if (!await promptDir.exists()) {
        await promptDir.create(recursive: true);
        print('[AppConfigService] 创建 prompt 目录: ${promptDir.path}');
      }

      // 确保日记目录存在
      final diaryDir = Directory('$dataDirPath/data/diary');
      if (!await diaryDir.exists()) {
        await diaryDir.create(recursive: true);
        print('[AppConfigService] 创建日记目录: ${diaryDir.path}');
      }
    } catch (e) {
      print('[AppConfigService] 创建数据目录失败: $e');
    }
  }

  static Future<void> init() async {
    // 确保数据目录结构存在
    await ensureDataDirectories();

    // 迁移旧的数据到新的标准目录结构
    await StorageService.migrateToStandardDirectories();

    // 主入口，初始化所有配置
    await _initLlmConfig();
    await PromptConfigService.init();
    // await QaQuestionsService.init(); // Needs BuildContext, must be called from app-level init
    await ThemeService.instance.init();
    await LanguageService.instance.init();
    // DiaryModeConfigService.init() - no longer needed, default is set in AppConfig
    // 可扩展：如有其它配置类，继续调用其 init
    // 例如：await SyncConfigService.init?.call();

    // TODO: QaQuestionsService.init(context) must be called from app-level with BuildContext
    print('[AppConfigService] 系统初始化完成，使用统一的数据存储目录结构');
  }

  // ============================================================================
  // Diary Mode Configuration Methods
  // ============================================================================

  /// Load the current diary mode from app config
  static Future<DiaryMode> loadDiaryMode() async {
    final config = await load();
    return config.diaryMode;
  }

  /// Save the diary mode to app config
  static Future<void> saveDiaryMode(DiaryMode mode) async {
    await update((config) {
      config.diaryMode = mode;
    });
  }

  // ============================================================================
  // LLM Configuration Methods
  // ============================================================================

  static Future<void> _initLlmConfig() async {
    final config = await load();
    if (config.model.isEmpty) {
      final env = await _readEnv();
      final llm = LLMConfig(
        provider: env['MODEL_PROVIDER'] ?? '',
        baseUrl: env['MODEL_BASE_URL'] ?? '',
        apiKey: env['MODEL_API_KEY'] ?? '',
        model: env['MODEL_NAME'] ?? '',
        active: true,
      );
      await update((c) => c.model = [llm]);
    }
  }

  /// 创建缺少的系统LLM配置
  static Future<int> createMissingSystemLlmConfigs() async {
    final config = await load();
    final systemConfigs = LLMConfig.getAllSystemConfigs();

    int createdCount = 0;

    for (final systemConfig in systemConfigs) {
      // 检查是否已经存在相同的系统配置
      final exists = config.model.any(
        (llm) =>
            llm.provider == systemConfig.provider &&
            llm.baseUrl == systemConfig.baseUrl &&
            llm.model == systemConfig.model &&
            llm.isSystem == true,
      );

      if (!exists) {
        print('[AppConfigService] 创建缺少的系统LLM配置: ${systemConfig.provider} - ${systemConfig.model}');
        config.model.add(systemConfig);
        createdCount++;
      }
    }

    if (createdCount > 0) {
      await save();
      print('[AppConfigService] 成功创建了 $createdCount 个系统LLM配置');
    }

    return createdCount;
  }

  static Future<Map<String, String>> _readEnv() async {
    final file = File('.env');
    if (!await file.exists()) return {};
    final lines = await file.readAsLines();
    final map = <String, String>{};
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
      final idx = trimmed.indexOf('=');
      if (idx > 0) {
        final key = trimmed.substring(0, idx).trim();
        final value = trimmed.substring(idx + 1).trim();
        map[key] = value;
      }
    }
    return map;
  }
}
