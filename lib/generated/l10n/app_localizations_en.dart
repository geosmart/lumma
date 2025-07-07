// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Lumma';

  @override
  String get appSubtitle => 'AI-Driven Q&A Diary';

  @override
  String get settings => 'Settings';

  @override
  String get syncNotConfigured => 'Sync Not Configured';

  @override
  String get syncNotConfiguredMessage =>
      'Please configure sync mode in settings.';

  @override
  String get syncFailed => 'Sync Failed';

  @override
  String get syncFailedMessage =>
      'WebDAV sync failed, please check network or configuration.';

  @override
  String get syncSuccess => 'Sync Success';

  @override
  String get syncSuccessMessage => 'WebDAV sync completed.';

  @override
  String get cannotStartSync => 'Cannot Start Sync';

  @override
  String get cannotStartSyncMessage =>
      'No sync configuration detected or Obsidian not installed. Please check sync URI in settings and ensure Obsidian is installed.';

  @override
  String get ok => 'OK';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get diary => 'Diary';

  @override
  String get diaryFiles => 'Diary Files';

  @override
  String get newDiary => 'New Diary';

  @override
  String get enterFileName => 'Enter file name';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get loading => 'Loading...';

  @override
  String get noFilesFound => 'No files found';

  @override
  String get deleteConfirmTitle => 'Delete Confirmation';

  @override
  String get deleteConfirmMessage =>
      'Are you sure you want to delete this file?';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get language => 'Language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageChinese => '简体中文';

  @override
  String get syncMethod => 'Sync Method';

  @override
  String get obsidianSync =>
      'Obsidian Sync (URI-based sync via Obsidian plugin)';

  @override
  String get webdavSync => 'WebDAV Sync (Sync to remote WebDAV server)';

  @override
  String get syncAddress => 'Sync Address';

  @override
  String get syncAddressDescription =>
      'Set the AdvanceUri for Obsidian sync command';

  @override
  String get setSyncAddress => 'Set Address';

  @override
  String get enterSyncAddress => 'Enter sync address';

  @override
  String get syncAddressPlaceholder => 'Please enter sync address';

  @override
  String get syncAddressSetSuccess => 'Sync address set successfully';

  @override
  String get clear => 'Clear';

  @override
  String get confirmClear => 'Confirm Clear';

  @override
  String get confirmClearSyncAddress =>
      'Are you sure you want to clear the sync address setting?';

  @override
  String get syncAddressCleared => 'Sync address setting cleared';

  @override
  String get webdavConfig => 'WebDAV Configuration';

  @override
  String get webdavUrl => 'WebDAV URL';

  @override
  String get webdavUrlPlaceholder => 'https://your-webdav-server.com';

  @override
  String get username => 'Username';

  @override
  String get password => 'Password';

  @override
  String get remoteDirectory => 'Remote Directory';

  @override
  String get remoteDirectoryPlaceholder => '/remote/path/';

  @override
  String get localDirectory => 'Local Directory';

  @override
  String get localDirectoryPlaceholder => '/local/path/';

  @override
  String get select => 'Select';

  @override
  String get saveConfig => 'Save Config';

  @override
  String get testConnection => 'Test Connection';

  @override
  String get webdavConfigSaved => 'WebDAV configuration saved';

  @override
  String get pleaseCompleteWebdavConfig =>
      'Please fill in complete WebDAV configuration';

  @override
  String get webdavConnectionSuccess =>
      'WebDAV connection successful, directory exists!';

  @override
  String get authenticationFailed =>
      'Authentication failed, please check username and password';

  @override
  String get directoryNotFound => 'Directory not found';

  @override
  String connectionFailed(int statusCode) {
    return 'Connection failed, status code: $statusCode';
  }

  @override
  String connectionError(String error) {
    return 'Connection error: $error';
  }

  @override
  String get dataWorkDirectory => 'Work Directory';

  @override
  String get dataWorkDirectoryDescription =>
      'Set the application\'s data work directory: including models, prompts, diary and other data';

  @override
  String get selectDataWorkDirectory => 'Select data work directory';

  @override
  String get dataWorkDirectorySetSuccess =>
      'Data work directory set successfully';

  @override
  String get confirmClearDataWorkDirectory =>
      'Are you sure you want to clear the data work directory setting?';

  @override
  String get dataWorkDirectoryCleared => 'Data work directory setting cleared';

  @override
  String get storagePermissionRequired =>
      'File access permission required to select directory';

  @override
  String get selectWebdavLocalDirectory => 'Select WebDAV local directory';

  @override
  String get webdavLocalDirectorySetSuccess =>
      'WebDAV local directory set successfully';

  @override
  String get diaryMode => 'Diary Mode';

  @override
  String get fixedQA => 'Fixed Q&A';

  @override
  String get fixedQADescription =>
      'Answer preset questions one by one to generate structured diary';

  @override
  String get aiChat => 'AI Chat';

  @override
  String get aiChatDescription =>
      'Chat with AI using Q&A prompts to generate custom diary';

  @override
  String get startWritingDiary => 'Start Writing';

  @override
  String get diaryList => 'Diary List';

  @override
  String get sync => 'Sync';

  @override
  String get chatDiaryTitle => 'AI Q&A Diary';

  @override
  String get back => 'Back';

  @override
  String get debugTooltip => 'Debug/View Model Request';

  @override
  String get viewDiaryList => 'View Diary List';

  @override
  String get llmManage => 'LLM Model';

  @override
  String get llmNone => 'No models yet';

  @override
  String get llmSetActive => 'Set Active';

  @override
  String get llmCopy => 'Copy';

  @override
  String get llmEdit => 'Edit';

  @override
  String get llmDelete => 'Delete';

  @override
  String get llmAdd => 'Add Model';

  @override
  String get llmDeleteConfirmTitle => 'Confirm Delete';

  @override
  String get llmDeleteConfirmContent =>
      'Are you sure you want to delete this model?';

  @override
  String get llmCancel => 'Cancel';

  @override
  String get promptManage => 'Prompts';

  @override
  String get promptSystemNotDeletable => 'System prompt cannot be deleted';

  @override
  String get promptSetActive => 'Set Active';

  @override
  String get promptCopy => 'Copy';

  @override
  String get promptEdit => 'Edit';

  @override
  String get promptDelete => 'Delete';

  @override
  String get promptAdd => 'Add Prompt';

  @override
  String get promptNone => 'No prompts yet';

  @override
  String promptSetActiveFailed(Object error) {
    return 'Failed to set active: $error';
  }

  @override
  String get promptAddSuccess => 'Prompt added successfully';

  @override
  String get promptDeleteConfirm =>
      'Are you sure you want to delete this prompt?';

  @override
  String get promptCancel => 'Cancel';

  @override
  String get qaQuestionList => 'Question List';

  @override
  String get qaNone => 'No questions yet';

  @override
  String qaQuestionLabel(Object number) {
    return 'Question $number';
  }

  @override
  String get qaDelete => 'Delete';

  @override
  String get qaAdd => 'Add Question';

  @override
  String get qaSave => 'Save Settings';

  @override
  String get promptCategoryQa => 'Chat';

  @override
  String get promptCategorySummary => 'Summary';

  @override
  String get appearanceSettings => 'Appearance Settings';

  @override
  String get themePreview => 'Theme Preview';

  @override
  String get themeLightMode => 'Light Mode';

  @override
  String get themeLightDesc => 'A warm and elegant light theme';

  @override
  String get themeDarkMode => 'Dark Mode';

  @override
  String get themeDarkDesc => 'Eye-friendly deep dark theme';

  @override
  String get llmEditPage => 'Model Edit Page';

  @override
  String get llmEditAddTitle => 'Add Model';

  @override
  String get llmEditEditTitle => 'Edit Model';

  @override
  String get llmEditProvider => 'Provider';

  @override
  String get llmEditBaseUrl => 'Base URL';

  @override
  String get llmEditApiKey => 'API Key';

  @override
  String get llmEditModel => 'Model';

  @override
  String get llmEditSave => 'Save';

  @override
  String get promptEditPage => 'Prompt Edit Page';

  @override
  String get promptEditAddTitle => 'Add Prompt';

  @override
  String get promptEditEditTitle => 'Edit Prompt';

  @override
  String get promptEditViewTitle => 'View Prompt';

  @override
  String get promptEditSystemTitle => 'System Prompt';

  @override
  String get promptEditRoleName => 'Role Name';

  @override
  String get promptEditCategory => 'Category';

  @override
  String get promptEditSetActive => 'Set Active';

  @override
  String get promptEditContent => 'Markdown Content';

  @override
  String get promptEditSave => 'Save';

  @override
  String get diaryFileListTitle => 'Diary Files';

  @override
  String get syncDialogTitle => 'Sync Progress';

  @override
  String syncDialogProgress(int current, int total) {
    return 'Progress: $current/$total';
  }

  @override
  String syncDialogCurrentFile(String file) {
    return 'Current file: $file';
  }

  @override
  String get syncDialogLogs => 'Logs';

  @override
  String get commonClose => 'Close';

  @override
  String get commonDone => 'Done';

  @override
  String get dataSync => 'Data Sync';

  @override
  String get startSyncTask => 'Starting sync task';

  @override
  String get uploading => 'Uploading';

  @override
  String get downloading => 'Downloading';

  @override
  String uploadFile(String file) {
    return 'Upload: $file';
  }

  @override
  String downloadFile(String file) {
    return 'Download: $file';
  }

  @override
  String get syncTaskComplete => 'Sync task completed';

  @override
  String get myDiary => 'My Diary';

  @override
  String get refresh => 'Refresh';

  @override
  String get noDiaryYet => 'No diary yet';

  @override
  String get clickToCreateFirstDiary =>
      'Click the + button in the upper right corner to start writing your first diary';

  @override
  String get createSuccess => 'Create successful';

  @override
  String get createFailedFileNotCreated => 'Creation failed, file not created';

  @override
  String createFailedWithError(String error) {
    return 'Creation failed: $error';
  }

  @override
  String get observeDiscovery => 'Observe & Discovery';

  @override
  String get positiveGains => 'Positive Gains';

  @override
  String get difficultChallenges => 'Difficult Challenges';

  @override
  String get reflectionImprovement => 'Reflection & Improvement';

  @override
  String get loadingFailed => 'Loading failed';

  @override
  String get aiSummary => 'AI Summary';

  @override
  String get aiSummaryResult => 'AI Summary Result';

  @override
  String get editDiary => 'Edit Diary';

  @override
  String get saveSuccess => 'Save successful';

  @override
  String get saveFailed => 'Save failed';

  @override
  String get noContent => 'No content';

  @override
  String get dailySummary => 'Daily Summary';

  @override
  String get regenerate => 'Regenerate';

  @override
  String get aiSummaryFailed => 'AI summary failed';

  @override
  String get aiGenerating => 'AI is generating...';

  @override
  String get dailySummarySaved => 'Daily summary saved to diary';

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get aiContentPlaceholder =>
      'AI generated content will be displayed here...';

  @override
  String get diaryDetail => 'Diary Detail';

  @override
  String get llmRequestParameters => 'LLM Request Parameters';

  @override
  String get copy => 'Copy';

  @override
  String get close => 'Close';

  @override
  String get requestParametersCopied =>
      'Request parameters copied to clipboard';

  @override
  String get mermaidMobileOnly =>
      'Mermaid is only supported on mobile, current platform does not support rendering';

  @override
  String get mermaidRenderError => 'Mermaid rendering error';

  @override
  String get fileName => 'File Name';

  @override
  String get editDiaryContent => 'Edit diary content';

  @override
  String get saving => 'Saving...';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String confirmDeleteFile(String fileName) {
    return 'Are you sure you want to delete the diary file \"$fileName\"?';
  }

  @override
  String get deleteSuccess => 'Delete successful';

  @override
  String get deleteFailed => 'Delete failed';

  @override
  String get enterNewDiaryName => 'Please enter new diary file name';

  @override
  String get createFailed => 'Create failed';

  @override
  String get newDiaryTooltip => 'New Diary';

  @override
  String get loadDiaryFilesFailed => 'Failed to load diary files';

  @override
  String get aiThinking => 'AI is thinking...';

  @override
  String get time => 'Time';

  @override
  String get category => 'Category';

  @override
  String get diaryContent => 'Diary Content';

  @override
  String get contentAnalysis => 'Content Analysis';

  @override
  String monthDay(int month, int day) {
    return '$month/$day';
  }

  @override
  String get qaQuestion1 => 'How do you feel today?';

  @override
  String get qaQuestion2 => 'What was the highlight of your day?';

  @override
  String get qaQuestion3 => 'Did you face any challenges today?';

  @override
  String get qaQuestion4 => 'What are you grateful for today?';

  @override
  String get qaQuestion5 => 'What did you learn today?';

  @override
  String get qaQuestion6 => 'How did you take care of yourself today?';

  @override
  String get qaQuestion7 => 'What would you like to improve tomorrow?';

  @override
  String get qaQuestion8 => 'Who or what inspired you today?';

  @override
  String get qaQuestion9 => 'Did you help someone today? How?';

  @override
  String get qaQuestion10 => 'What is your goal for tomorrow?';

  @override
  String get userInputPlaceholder => 'Jot down your thoughts...';
}
