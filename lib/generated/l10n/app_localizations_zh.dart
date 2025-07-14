// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Lumma';

  @override
  String get appSubtitle => 'AI驱动的问答日记';

  @override
  String get settings => '设置';

  @override
  String get syncNotConfigured => '同步未配置';

  @override
  String get syncNotConfiguredMessage => '请在设置中配置同步模式。';

  @override
  String get syncFailed => '同步失败';

  @override
  String get syncFailedMessage => 'WebDAV 同步失败，请检查网络或配置。';

  @override
  String get syncSuccess => '同步成功';

  @override
  String get syncSuccessMessage => 'WebDAV 同步已完成。';

  @override
  String get cannotStartSync => '无法启动同步';

  @override
  String get cannotStartSyncMessage =>
      '未检测到同步配置或 Obsidian 未安装。请在设置中检查同步 URI 并确保 Obsidian 已安装。';

  @override
  String get ok => '确定';

  @override
  String get confirm => '确认';

  @override
  String get cancel => '取消';

  @override
  String get diary => '日记';

  @override
  String get diaryFiles => '日记文件';

  @override
  String get newDiary => '新建日记';

  @override
  String get enterFileName => '输入文件名';

  @override
  String get create => '创建';

  @override
  String get delete => '删除';

  @override
  String get rename => '重命名';

  @override
  String get edit => '编辑';

  @override
  String get save => '保存';

  @override
  String get loading => '加载中...';

  @override
  String get noFilesFound => '未找到文件';

  @override
  String get deleteConfirmTitle => '删除确认';

  @override
  String get deleteConfirmMessage => '确定要删除这个文件吗？';

  @override
  String get theme => '主题';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get language => '语言';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '简体中文';

  @override
  String get syncMethod => '同步方式';

  @override
  String get obsidianSync => 'Obsidian 同步（基于URI唤起Obsidian插件进行同步）';

  @override
  String get webdavSync => 'WebDAV 同步（同步到远程 WebDAV 服务器）';

  @override
  String get syncAddress => '同步地址';

  @override
  String get syncAddressDescription => '设置Obsidian同步的指令对应的AdvanceUri';

  @override
  String get setSyncAddress => '设置地址';

  @override
  String get enterSyncAddress => '设置同步地址';

  @override
  String get syncAddressPlaceholder => '请输入同步地址';

  @override
  String get syncAddressSetSuccess => '同步地址设置成功';

  @override
  String get clear => '清除';

  @override
  String get confirmClear => '确认清除';

  @override
  String get confirmClearSyncAddress => '确定要清除同步地址设置吗？';

  @override
  String get syncAddressCleared => '已清除同步地址设置';

  @override
  String get webdavConfig => 'WebDAV 配置';

  @override
  String get webdavUrl => 'WebDAV 地址';

  @override
  String get webdavUrlPlaceholder => 'https://your-webdav-server.com';

  @override
  String get username => '用户名';

  @override
  String get password => '密码';

  @override
  String get remoteDirectory => '远程目录';

  @override
  String get remoteDirectoryPlaceholder => '/remote/path/';

  @override
  String get localDirectory => '本地目录';

  @override
  String get localDirectoryPlaceholder => '/local/path/';

  @override
  String get select => '选择';

  @override
  String get saveConfig => '保存配置';

  @override
  String get testConnection => '测试连接';

  @override
  String get webdavConfigSaved => 'WebDAV 配置已保存';

  @override
  String get pleaseCompleteWebdavConfig => '请填写完整的 WebDAV 配置信息';

  @override
  String get webdavConnectionSuccess => 'WebDAV 连接成功，目录存在！';

  @override
  String get authenticationFailed => '认证失败，请检查用户名和密码';

  @override
  String get directoryNotFound => '目录不存在';

  @override
  String connectionFailed(int statusCode) {
    return '连接失败，状态码: $statusCode';
  }

  @override
  String connectionError(String error) {
    return '连接异常: $error';
  }

  @override
  String get dataWorkDirectory => '数据工作目录';

  @override
  String get dataWorkDirectoryDescription => '设置应用的数据工作目录：包括模型，提示词，日记等数据';

  @override
  String get selectDataWorkDirectory => '选择数据工作目录';

  @override
  String get dataWorkDirectorySetSuccess => '数据工作目录设置成功';

  @override
  String get confirmClearDataWorkDirectory => '确定要清除数据工作目录设置吗？';

  @override
  String get dataWorkDirectoryCleared => '已清除数据工作目录设置';

  @override
  String get storagePermissionRequired => '需要文件访问权限才能选择目录';

  @override
  String get selectWebdavLocalDirectory => '选择 WebDAV 本地目录';

  @override
  String get webdavLocalDirectorySetSuccess => 'WebDAV 本地目录设置成功';

  @override
  String get diaryMode => '日记模式';

  @override
  String get fixedQA => '固定问答';

  @override
  String get fixedQADescription => '逐条回答预设问题，生成结构化日记';

  @override
  String get aiChat => 'AI问答';

  @override
  String get aiChatDescription => '按问答提示词与AI对话，生成自定义日记';

  @override
  String get startWritingDiary => '开始写日记';

  @override
  String get diaryList => '日记列表';

  @override
  String get sync => '同步';

  @override
  String get chatDiaryTitle => 'AI 问答式日记';

  @override
  String get back => '返回';

  @override
  String get debugTooltip => '调试/查看大模型请求参数';

  @override
  String get viewDiaryList => '查看日记列表';

  @override
  String get llmManage => '模型管理';

  @override
  String get llmNone => '暂无模型';

  @override
  String get llmSetActive => '设为激活';

  @override
  String get llmCopy => '复制';

  @override
  String get llmEdit => '编辑';

  @override
  String get llmDelete => '删除';

  @override
  String get llmAdd => '添加模型';

  @override
  String get llmDeleteConfirmTitle => '确认删除';

  @override
  String get llmDeleteConfirmContent => '确定要删除该模型吗？';

  @override
  String get llmCancel => '取消';

  @override
  String get promptManage => '对话角色';

  @override
  String get promptSystemNotDeletable => '系统提示词不可删除';

  @override
  String get promptSetActive => '设为激活';

  @override
  String get promptCopy => '复制';

  @override
  String get promptEdit => '编辑';

  @override
  String get promptDelete => '删除';

  @override
  String get promptReset => '重置';

  @override
  String get promptAdd => '添加提示词';

  @override
  String get promptNone => '暂无提示词';

  @override
  String promptSetActiveFailed(String error) {
    return '设置激活失败: $error';
  }

  @override
  String get promptAddSuccess => '提示词添加成功';

  @override
  String get promptDeleteConfirm => '确定要删除该提示词吗？';

  @override
  String get promptResetConfirm => '确定要重置该提示词到默认内容吗？此操作不可撤销。';

  @override
  String get promptCancel => '取消';

  @override
  String get qaQuestionList => '问题列表';

  @override
  String get qaNone => '暂无问题';

  @override
  String qaQuestionLabel(int number) {
    return '问题 $number';
  }

  @override
  String get qaDelete => '删除';

  @override
  String get qaAdd => '添加问题';

  @override
  String get qaSave => '保存设置';

  @override
  String get promptCategoryChat => '问答';

  @override
  String get promptCategorySummary => '总结';

  @override
  String get appearanceSettings => '外观设置';

  @override
  String get themePreview => '主题预览';

  @override
  String get themeLightMode => '浅色模式';

  @override
  String get themeLightDesc => '温暖淡雅的浅色主题';

  @override
  String get themeDarkMode => '暗色模式';

  @override
  String get themeDarkDesc => '护眼深邃的暗色主题';

  @override
  String get llmEditPage => '模型编辑页面';

  @override
  String get llmEditAddTitle => '添加模型';

  @override
  String get llmEditEditTitle => '编辑模型';

  @override
  String get llmEditProvider => '供应商';

  @override
  String get llmEditBaseUrl => '模型地址';

  @override
  String get llmEditApiKey => 'API密钥';

  @override
  String get llmEditModel => '模型名称';

  @override
  String get llmEditSave => '保存';

  @override
  String get promptEditPage => '提示词编辑页面';

  @override
  String get promptEditAddTitle => '新建提示词';

  @override
  String get promptEditEditTitle => '编辑提示词';

  @override
  String get promptEditViewTitle => '查看提示词';

  @override
  String get promptEditSystemTitle => '系统提示词';

  @override
  String get promptEditRoleName => '角色名称';

  @override
  String get promptEditCategory => '分类';

  @override
  String get promptEditSetActive => '设为激活';

  @override
  String get promptEditContent => 'Markdown 内容';

  @override
  String get promptEditSave => '保存';

  @override
  String get diaryFileListTitle => '日记文件';

  @override
  String get syncDialogTitle => '同步进度';

  @override
  String syncDialogProgress(int current, int total) {
    return '进度：$current/$total';
  }

  @override
  String syncDialogCurrentFile(String file) {
    return '当前文件：$file';
  }

  @override
  String get syncDialogLogs => '日志';

  @override
  String get commonClose => '关闭';

  @override
  String get commonDone => '完成';

  @override
  String get dataSync => '数据同步';

  @override
  String get startSyncTask => '开始同步任务';

  @override
  String get uploading => '上传中';

  @override
  String get downloading => '下载中';

  @override
  String uploadFile(String file) {
    return '上传: $file';
  }

  @override
  String downloadFile(String file) {
    return '下载: $file';
  }

  @override
  String get syncTaskComplete => '同步任务完成';

  @override
  String get myDiary => '我的日记';

  @override
  String get refresh => '刷新';

  @override
  String get noDiaryYet => '还没有任何日记';

  @override
  String get clickToCreateFirstDiary => '点击右上角的 + 开始写你的第一篇日记吧';

  @override
  String get createSuccess => '新建成功';

  @override
  String get createFailedFileNotCreated => '新建失败，文件未创建';

  @override
  String createFailedWithError(String error) {
    return '新建失败: $error';
  }

  @override
  String get observeDiscovery => '观察发现';

  @override
  String get positiveGains => '积极收获';

  @override
  String get difficultChallenges => '困难挑战';

  @override
  String get reflectionImprovement => '反思改进';

  @override
  String get loadingFailed => '加载失败';

  @override
  String get aiSummary => 'AI 总结';

  @override
  String get aiSummaryResult => 'AI 总结结果';

  @override
  String get editDiary => '编辑日记';

  @override
  String get saveSuccess => '保存成功';

  @override
  String get saveFailed => '保存失败';

  @override
  String get noContent => '无内容';

  @override
  String get dailySummary => '日总结';

  @override
  String get regenerate => '重新生成';

  @override
  String get aiSummaryFailed => 'AI 总结失败';

  @override
  String get aiGenerating => 'AI 正在生成中...';

  @override
  String get dailySummarySaved => '日总结已保存到日记';

  @override
  String get operationFailed => '操作失败';

  @override
  String get aiContentPlaceholder => 'AI 生成的内容将显示在这里...';

  @override
  String get diaryDetail => '日记详情';

  @override
  String get llmRequestParameters => '大模型请求参数';

  @override
  String get copy => '复制';

  @override
  String get close => '关闭';

  @override
  String get requestParametersCopied => '请求参数已复制到剪贴板';

  @override
  String get mermaidMobileOnly => 'Mermaid 仅支持移动端，当前平台不支持渲染';

  @override
  String get mermaidRenderError => 'Mermaid 渲染异常';

  @override
  String get fileName => '文件名';

  @override
  String get editDiaryContent => '编辑日记内容';

  @override
  String get saving => '保存中...';

  @override
  String get confirmDelete => '确认删除';

  @override
  String confirmDeleteFile(String fileName) {
    return '确定要删除日记文件 \"$fileName\" 吗？';
  }

  @override
  String get deleteSuccess => '删除成功';

  @override
  String get deleteFailed => '删除失败';

  @override
  String get enterNewDiaryName => '请输入新日记文件名';

  @override
  String get createFailed => '创建失败';

  @override
  String get newDiaryTooltip => '新建日记';

  @override
  String get loadDiaryFilesFailed => '加载日记文件失败';

  @override
  String get aiThinking => 'AI 正在思考...';

  @override
  String get time => '时间';

  @override
  String get category => '分类';

  @override
  String get diaryContent => '日记内容';

  @override
  String get contentAnalysis => '内容分析';

  @override
  String monthDay(int month, int day) {
    return '$month月$day日';
  }

  @override
  String get qaQuestion1 => '你今天感觉如何？';

  @override
  String get qaQuestion2 => '今天最精彩的事情是什么？';

  @override
  String get qaQuestion3 => '你今天遇到了什么挑战？';

  @override
  String get qaQuestion4 => '你今天感激什么？';

  @override
  String get qaQuestion5 => '你今天学到了什么？';

  @override
  String get qaQuestion6 => '你今天是如何照顾自己的？';

  @override
  String get qaQuestion7 => '你明天想要改进什么？';

  @override
  String get qaQuestion8 => '今天谁或什么激励了你？';

  @override
  String get qaQuestion9 => '你今天帮助了谁？怎么帮助的？';

  @override
  String get qaQuestion10 => '你明天的目标是什么？';

  @override
  String get userInputPlaceholder => '记下此刻的想法';

  @override
  String get llmConfigurationError => '大模型配置错误';

  @override
  String get llmConfigurationErrorMessage =>
      '大模型服务返回错误 (405)，这通常表示当前激活的模型存在配置问题。请检查大模型配置。';

  @override
  String get llmRateLimitError => '大模型限流错误';

  @override
  String get llmRateLimitErrorMessage =>
      '大模型服务因请求过于频繁而暂时不可用 (429)。请稍等片刻后重试，或检查您的API使用限制。';

  @override
  String get goToLlmConfig => '前往大模型配置';

  @override
  String llmServiceError(int statusCode) {
    return '大模型服务错误 ($statusCode)';
  }
}
