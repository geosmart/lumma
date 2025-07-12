import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Lumma'**
  String get appTitle;

  /// The subtitle description of the application
  ///
  /// In en, this message translates to:
  /// **'AI-Driven Q&A Diary'**
  String get appSubtitle;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Dialog title when sync is not configured
  ///
  /// In en, this message translates to:
  /// **'Sync Not Configured'**
  String get syncNotConfigured;

  /// Dialog message when sync is not configured
  ///
  /// In en, this message translates to:
  /// **'Please configure sync mode in settings.'**
  String get syncNotConfiguredMessage;

  /// Dialog title when sync fails
  ///
  /// In en, this message translates to:
  /// **'Sync Failed'**
  String get syncFailed;

  /// Dialog message when sync fails
  ///
  /// In en, this message translates to:
  /// **'WebDAV sync failed, please check network or configuration.'**
  String get syncFailedMessage;

  /// Dialog title when sync succeeds
  ///
  /// In en, this message translates to:
  /// **'Sync Success'**
  String get syncSuccess;

  /// Dialog message when sync succeeds
  ///
  /// In en, this message translates to:
  /// **'WebDAV sync completed.'**
  String get syncSuccessMessage;

  /// Dialog title when sync cannot be started
  ///
  /// In en, this message translates to:
  /// **'Cannot Start Sync'**
  String get cannotStartSync;

  /// Dialog message when sync cannot be started
  ///
  /// In en, this message translates to:
  /// **'No sync configuration detected or Obsidian not installed. Please check sync URI in settings and ensure Obsidian is installed.'**
  String get cannotStartSyncMessage;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Confirm button text
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Diary tab title
  ///
  /// In en, this message translates to:
  /// **'Diary'**
  String get diary;

  /// Diary files page title
  ///
  /// In en, this message translates to:
  /// **'Diary Files'**
  String get diaryFiles;

  /// New diary button text
  ///
  /// In en, this message translates to:
  /// **'New Diary'**
  String get newDiary;

  /// Placeholder for file name input
  ///
  /// In en, this message translates to:
  /// **'Enter file name'**
  String get enterFileName;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Rename button text
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Loading indicator text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Message when no diary files are found
  ///
  /// In en, this message translates to:
  /// **'No files found'**
  String get noFilesFound;

  /// Delete confirmation dialog title
  ///
  /// In en, this message translates to:
  /// **'Delete Confirmation'**
  String get deleteConfirmTitle;

  /// Delete confirmation dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this file?'**
  String get deleteConfirmMessage;

  /// Theme setting label
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Light theme option
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// Dark theme option
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Chinese language option
  ///
  /// In en, this message translates to:
  /// **'简体中文'**
  String get languageChinese;

  /// Sync method section title
  ///
  /// In en, this message translates to:
  /// **'Sync Method'**
  String get syncMethod;

  /// Obsidian sync option description
  ///
  /// In en, this message translates to:
  /// **'Obsidian Sync (URI-based sync via Obsidian plugin)'**
  String get obsidianSync;

  /// WebDAV sync option description
  ///
  /// In en, this message translates to:
  /// **'WebDAV Sync (Sync to remote WebDAV server)'**
  String get webdavSync;

  /// Sync address section title
  ///
  /// In en, this message translates to:
  /// **'Sync Address'**
  String get syncAddress;

  /// Sync address description
  ///
  /// In en, this message translates to:
  /// **'Set the AdvanceUri for Obsidian sync command'**
  String get syncAddressDescription;

  /// Set sync address button text
  ///
  /// In en, this message translates to:
  /// **'Set Address'**
  String get setSyncAddress;

  /// Sync address input hint
  ///
  /// In en, this message translates to:
  /// **'Enter sync address'**
  String get enterSyncAddress;

  /// Sync address input placeholder
  ///
  /// In en, this message translates to:
  /// **'Please enter sync address'**
  String get syncAddressPlaceholder;

  /// Sync address set success message
  ///
  /// In en, this message translates to:
  /// **'Sync address set successfully'**
  String get syncAddressSetSuccess;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Confirm clear dialog title
  ///
  /// In en, this message translates to:
  /// **'Confirm Clear'**
  String get confirmClear;

  /// Confirm clear sync address message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the sync address setting?'**
  String get confirmClearSyncAddress;

  /// Sync address cleared message
  ///
  /// In en, this message translates to:
  /// **'Sync address setting cleared'**
  String get syncAddressCleared;

  /// WebDAV configuration section title
  ///
  /// In en, this message translates to:
  /// **'WebDAV Configuration'**
  String get webdavConfig;

  /// WebDAV URL field label
  ///
  /// In en, this message translates to:
  /// **'WebDAV URL'**
  String get webdavUrl;

  /// WebDAV URL placeholder
  ///
  /// In en, this message translates to:
  /// **'https://your-webdav-server.com'**
  String get webdavUrlPlaceholder;

  /// Username field label
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Remote directory field label
  ///
  /// In en, this message translates to:
  /// **'Remote Directory'**
  String get remoteDirectory;

  /// Remote directory placeholder
  ///
  /// In en, this message translates to:
  /// **'/remote/path/'**
  String get remoteDirectoryPlaceholder;

  /// Local directory field label
  ///
  /// In en, this message translates to:
  /// **'Local Directory'**
  String get localDirectory;

  /// Local directory placeholder
  ///
  /// In en, this message translates to:
  /// **'/local/path/'**
  String get localDirectoryPlaceholder;

  /// Select button text
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Save config button text
  ///
  /// In en, this message translates to:
  /// **'Save Config'**
  String get saveConfig;

  /// Test connection button text
  ///
  /// In en, this message translates to:
  /// **'Test Connection'**
  String get testConnection;

  /// WebDAV config saved message
  ///
  /// In en, this message translates to:
  /// **'WebDAV configuration saved'**
  String get webdavConfigSaved;

  /// Incomplete WebDAV config error message
  ///
  /// In en, this message translates to:
  /// **'Please fill in complete WebDAV configuration'**
  String get pleaseCompleteWebdavConfig;

  /// WebDAV connection success message
  ///
  /// In en, this message translates to:
  /// **'WebDAV connection successful, directory exists!'**
  String get webdavConnectionSuccess;

  /// Authentication failed error message
  ///
  /// In en, this message translates to:
  /// **'Authentication failed, please check username and password'**
  String get authenticationFailed;

  /// Directory not found error message
  ///
  /// In en, this message translates to:
  /// **'Directory not found'**
  String get directoryNotFound;

  /// Connection failed error message
  ///
  /// In en, this message translates to:
  /// **'Connection failed, status code: {statusCode}'**
  String connectionFailed(int statusCode);

  /// Connection error message
  ///
  /// In en, this message translates to:
  /// **'Connection error: {error}'**
  String connectionError(String error);

  /// Data work directory section title
  ///
  /// In en, this message translates to:
  /// **'Work Directory'**
  String get dataWorkDirectory;

  /// Data work directory description
  ///
  /// In en, this message translates to:
  /// **'Set the application\'s data work directory: including models, prompts, diary and other data'**
  String get dataWorkDirectoryDescription;

  /// Select data work directory dialog title
  ///
  /// In en, this message translates to:
  /// **'Select data work directory'**
  String get selectDataWorkDirectory;

  /// Data work directory set success message
  ///
  /// In en, this message translates to:
  /// **'Data work directory set successfully'**
  String get dataWorkDirectorySetSuccess;

  /// Confirm clear data work directory message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to clear the data work directory setting?'**
  String get confirmClearDataWorkDirectory;

  /// Data work directory cleared message
  ///
  /// In en, this message translates to:
  /// **'Data work directory setting cleared'**
  String get dataWorkDirectoryCleared;

  /// Storage permission required message
  ///
  /// In en, this message translates to:
  /// **'File access permission required to select directory'**
  String get storagePermissionRequired;

  /// Select WebDAV local directory dialog title
  ///
  /// In en, this message translates to:
  /// **'Select WebDAV local directory'**
  String get selectWebdavLocalDirectory;

  /// WebDAV local directory set success message
  ///
  /// In en, this message translates to:
  /// **'WebDAV local directory set successfully'**
  String get webdavLocalDirectorySetSuccess;

  /// Diary mode page title
  ///
  /// In en, this message translates to:
  /// **'Diary Mode'**
  String get diaryMode;

  /// Fixed Q&A mode title
  ///
  /// In en, this message translates to:
  /// **'Fixed Q&A'**
  String get fixedQA;

  /// Fixed Q&A mode description
  ///
  /// In en, this message translates to:
  /// **'Answer preset questions one by one to generate structured diary'**
  String get fixedQADescription;

  /// AI chat mode title
  ///
  /// In en, this message translates to:
  /// **'AI Chat'**
  String get aiChat;

  /// AI chat mode description
  ///
  /// In en, this message translates to:
  /// **'Chat with AI using Q&A prompts to generate custom diary'**
  String get aiChatDescription;

  /// Main action button text
  ///
  /// In en, this message translates to:
  /// **'Start Writing'**
  String get startWritingDiary;

  /// Diary list button text
  ///
  /// In en, this message translates to:
  /// **'Diary List'**
  String get diaryList;

  /// Sync button text
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync;

  /// No description provided for @chatDiaryTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Q&A Diary'**
  String get chatDiaryTitle;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @debugTooltip.
  ///
  /// In en, this message translates to:
  /// **'Debug/View Model Request'**
  String get debugTooltip;

  /// No description provided for @viewDiaryList.
  ///
  /// In en, this message translates to:
  /// **'View Diary List'**
  String get viewDiaryList;

  /// No description provided for @llmManage.
  ///
  /// In en, this message translates to:
  /// **'LLM Model'**
  String get llmManage;

  /// No description provided for @llmNone.
  ///
  /// In en, this message translates to:
  /// **'No models yet'**
  String get llmNone;

  /// No description provided for @llmSetActive.
  ///
  /// In en, this message translates to:
  /// **'Set Active'**
  String get llmSetActive;

  /// No description provided for @llmCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get llmCopy;

  /// No description provided for @llmEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get llmEdit;

  /// No description provided for @llmDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get llmDelete;

  /// No description provided for @llmAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Model'**
  String get llmAdd;

  /// No description provided for @llmDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get llmDeleteConfirmTitle;

  /// No description provided for @llmDeleteConfirmContent.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this model?'**
  String get llmDeleteConfirmContent;

  /// No description provided for @llmCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get llmCancel;

  /// No description provided for @promptManage.
  ///
  /// In en, this message translates to:
  /// **'Prompts'**
  String get promptManage;

  /// No description provided for @promptSystemNotDeletable.
  ///
  /// In en, this message translates to:
  /// **'System prompt cannot be deleted'**
  String get promptSystemNotDeletable;

  /// No description provided for @promptSetActive.
  ///
  /// In en, this message translates to:
  /// **'Set Active'**
  String get promptSetActive;

  /// No description provided for @promptCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get promptCopy;

  /// No description provided for @promptEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get promptEdit;

  /// No description provided for @promptDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get promptDelete;

  /// No description provided for @promptAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Prompt'**
  String get promptAdd;

  /// No description provided for @promptNone.
  ///
  /// In en, this message translates to:
  /// **'No prompts yet'**
  String get promptNone;

  /// Error message when setting active prompt fails
  ///
  /// In en, this message translates to:
  /// **'Failed to set active: {error}'**
  String promptSetActiveFailed(String error);

  /// No description provided for @promptAddSuccess.
  ///
  /// In en, this message translates to:
  /// **'Prompt added successfully'**
  String get promptAddSuccess;

  /// No description provided for @promptDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this prompt?'**
  String get promptDeleteConfirm;

  /// No description provided for @promptCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get promptCancel;

  /// No description provided for @qaQuestionList.
  ///
  /// In en, this message translates to:
  /// **'Question List'**
  String get qaQuestionList;

  /// No description provided for @qaNone.
  ///
  /// In en, this message translates to:
  /// **'No questions yet'**
  String get qaNone;

  /// Label for question number
  ///
  /// In en, this message translates to:
  /// **'Question {number}'**
  String qaQuestionLabel(int number);

  /// No description provided for @qaDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get qaDelete;

  /// No description provided for @qaAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Question'**
  String get qaAdd;

  /// No description provided for @qaSave.
  ///
  /// In en, this message translates to:
  /// **'Save Settings'**
  String get qaSave;

  /// No description provided for @promptCategoryQa.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get promptCategoryQa;

  /// No description provided for @promptCategorySummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get promptCategorySummary;

  /// No description provided for @appearanceSettings.
  ///
  /// In en, this message translates to:
  /// **'Appearance Settings'**
  String get appearanceSettings;

  /// No description provided for @themePreview.
  ///
  /// In en, this message translates to:
  /// **'Theme Preview'**
  String get themePreview;

  /// No description provided for @themeLightMode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get themeLightMode;

  /// No description provided for @themeLightDesc.
  ///
  /// In en, this message translates to:
  /// **'A warm and elegant light theme'**
  String get themeLightDesc;

  /// No description provided for @themeDarkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get themeDarkMode;

  /// No description provided for @themeDarkDesc.
  ///
  /// In en, this message translates to:
  /// **'Eye-friendly deep dark theme'**
  String get themeDarkDesc;

  /// No description provided for @llmEditPage.
  ///
  /// In en, this message translates to:
  /// **'Model Edit Page'**
  String get llmEditPage;

  /// No description provided for @llmEditAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Model'**
  String get llmEditAddTitle;

  /// No description provided for @llmEditEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Model'**
  String get llmEditEditTitle;

  /// No description provided for @llmEditProvider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get llmEditProvider;

  /// No description provided for @llmEditBaseUrl.
  ///
  /// In en, this message translates to:
  /// **'Base URL'**
  String get llmEditBaseUrl;

  /// No description provided for @llmEditApiKey.
  ///
  /// In en, this message translates to:
  /// **'API Key'**
  String get llmEditApiKey;

  /// No description provided for @llmEditModel.
  ///
  /// In en, this message translates to:
  /// **'Model'**
  String get llmEditModel;

  /// No description provided for @llmEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get llmEditSave;

  /// No description provided for @promptEditPage.
  ///
  /// In en, this message translates to:
  /// **'Prompt Edit Page'**
  String get promptEditPage;

  /// No description provided for @promptEditAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add Prompt'**
  String get promptEditAddTitle;

  /// No description provided for @promptEditEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit Prompt'**
  String get promptEditEditTitle;

  /// No description provided for @promptEditViewTitle.
  ///
  /// In en, this message translates to:
  /// **'View Prompt'**
  String get promptEditViewTitle;

  /// No description provided for @promptEditSystemTitle.
  ///
  /// In en, this message translates to:
  /// **'System Prompt'**
  String get promptEditSystemTitle;

  /// No description provided for @promptEditRoleName.
  ///
  /// In en, this message translates to:
  /// **'Role Name'**
  String get promptEditRoleName;

  /// No description provided for @promptEditCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get promptEditCategory;

  /// No description provided for @promptEditSetActive.
  ///
  /// In en, this message translates to:
  /// **'Set Active'**
  String get promptEditSetActive;

  /// No description provided for @promptEditContent.
  ///
  /// In en, this message translates to:
  /// **'Markdown Content'**
  String get promptEditContent;

  /// No description provided for @promptEditSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get promptEditSave;

  /// No description provided for @diaryFileListTitle.
  ///
  /// In en, this message translates to:
  /// **'Diary Files'**
  String get diaryFileListTitle;

  /// No description provided for @syncDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Sync Progress'**
  String get syncDialogTitle;

  /// No description provided for @syncDialogProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress: {current}/{total}'**
  String syncDialogProgress(int current, int total);

  /// No description provided for @syncDialogCurrentFile.
  ///
  /// In en, this message translates to:
  /// **'Current file: {file}'**
  String syncDialogCurrentFile(String file);

  /// No description provided for @syncDialogLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get syncDialogLogs;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @dataSync.
  ///
  /// In en, this message translates to:
  /// **'Data Sync'**
  String get dataSync;

  /// No description provided for @startSyncTask.
  ///
  /// In en, this message translates to:
  /// **'Starting sync task'**
  String get startSyncTask;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading'**
  String get uploading;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @uploadFile.
  ///
  /// In en, this message translates to:
  /// **'Upload: {file}'**
  String uploadFile(String file);

  /// No description provided for @downloadFile.
  ///
  /// In en, this message translates to:
  /// **'Download: {file}'**
  String downloadFile(String file);

  /// No description provided for @syncTaskComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync task completed'**
  String get syncTaskComplete;

  /// No description provided for @myDiary.
  ///
  /// In en, this message translates to:
  /// **'My Diary'**
  String get myDiary;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @noDiaryYet.
  ///
  /// In en, this message translates to:
  /// **'No diary yet'**
  String get noDiaryYet;

  /// No description provided for @clickToCreateFirstDiary.
  ///
  /// In en, this message translates to:
  /// **'Click the + button in the upper right corner to start writing your first diary'**
  String get clickToCreateFirstDiary;

  /// No description provided for @createSuccess.
  ///
  /// In en, this message translates to:
  /// **'Created successfully'**
  String get createSuccess;

  /// No description provided for @createFailedFileNotCreated.
  ///
  /// In en, this message translates to:
  /// **'Creation failed, file not created'**
  String get createFailedFileNotCreated;

  /// No description provided for @createFailedWithError.
  ///
  /// In en, this message translates to:
  /// **'Creation failed: {error}'**
  String createFailedWithError(String error);

  /// Title for observe category in diary summary
  ///
  /// In en, this message translates to:
  /// **'Observe & Discovery'**
  String get observeDiscovery;

  /// Title for good category in diary summary
  ///
  /// In en, this message translates to:
  /// **'Positive Gains'**
  String get positiveGains;

  /// Title for difficult category in diary summary
  ///
  /// In en, this message translates to:
  /// **'Difficult Challenges'**
  String get difficultChallenges;

  /// Title for different category in diary summary
  ///
  /// In en, this message translates to:
  /// **'Reflection & Improvement'**
  String get reflectionImprovement;

  /// Error message when loading fails
  ///
  /// In en, this message translates to:
  /// **'Loading failed'**
  String get loadingFailed;

  /// AI summary button tooltip
  ///
  /// In en, this message translates to:
  /// **'AI Summary'**
  String get aiSummary;

  /// AI summary result page title
  ///
  /// In en, this message translates to:
  /// **'AI Summary Result'**
  String get aiSummaryResult;

  /// Edit diary label text
  ///
  /// In en, this message translates to:
  /// **'Edit Diary'**
  String get editDiary;

  /// Success message when saving
  ///
  /// In en, this message translates to:
  /// **'Save successful'**
  String get saveSuccess;

  /// Error message when saving fails
  ///
  /// In en, this message translates to:
  /// **'Save failed'**
  String get saveFailed;

  /// Message when there is no content
  ///
  /// In en, this message translates to:
  /// **'No content'**
  String get noContent;

  /// Daily summary section title
  ///
  /// In en, this message translates to:
  /// **'Daily Summary'**
  String get dailySummary;

  /// Regenerate button text
  ///
  /// In en, this message translates to:
  /// **'Regenerate'**
  String get regenerate;

  /// Error message when AI summary fails
  ///
  /// In en, this message translates to:
  /// **'AI summary failed'**
  String get aiSummaryFailed;

  /// Status message when AI is generating content
  ///
  /// In en, this message translates to:
  /// **'AI is generating...'**
  String get aiGenerating;

  /// Success message when daily summary is saved
  ///
  /// In en, this message translates to:
  /// **'Daily summary saved to diary'**
  String get dailySummarySaved;

  /// Error message when operation fails
  ///
  /// In en, this message translates to:
  /// **'Operation failed'**
  String get operationFailed;

  /// Placeholder text for AI content input field
  ///
  /// In en, this message translates to:
  /// **'AI generated content will be displayed here...'**
  String get aiContentPlaceholder;

  /// Title for diary detail page
  ///
  /// In en, this message translates to:
  /// **'Diary Detail'**
  String get diaryDetail;

  /// Title for LLM request parameters dialog
  ///
  /// In en, this message translates to:
  /// **'LLM Request Parameters'**
  String get llmRequestParameters;

  /// Copy button text
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Success message when request parameters are copied
  ///
  /// In en, this message translates to:
  /// **'Request parameters copied to clipboard'**
  String get requestParametersCopied;

  /// Error message when Mermaid is not supported on current platform
  ///
  /// In en, this message translates to:
  /// **'Mermaid is only supported on mobile, current platform does not support rendering'**
  String get mermaidMobileOnly;

  /// Error message when Mermaid rendering fails
  ///
  /// In en, this message translates to:
  /// **'Mermaid rendering error'**
  String get mermaidRenderError;

  /// Label for file name input field
  ///
  /// In en, this message translates to:
  /// **'File Name'**
  String get fileName;

  /// Placeholder text for diary content editing
  ///
  /// In en, this message translates to:
  /// **'Edit diary content'**
  String get editDiaryContent;

  /// Status text when saving is in progress
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// Title for delete confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Confirm Delete'**
  String get confirmDelete;

  /// Confirmation message for deleting a file
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the diary file \"{fileName}\"?'**
  String confirmDeleteFile(String fileName);

  /// Success message when delete operation succeeds
  ///
  /// In en, this message translates to:
  /// **'Delete successful'**
  String get deleteSuccess;

  /// Error message when delete operation fails
  ///
  /// In en, this message translates to:
  /// **'Delete failed'**
  String get deleteFailed;

  /// Placeholder text for new diary name input
  ///
  /// In en, this message translates to:
  /// **'Please enter new diary file name'**
  String get enterNewDiaryName;

  /// Error message when create operation fails
  ///
  /// In en, this message translates to:
  /// **'Create failed'**
  String get createFailed;

  /// Tooltip text for new diary button
  ///
  /// In en, this message translates to:
  /// **'New Diary'**
  String get newDiaryTooltip;

  /// Error message when loading diary files fails
  ///
  /// In en, this message translates to:
  /// **'Failed to load diary files'**
  String get loadDiaryFilesFailed;

  /// Status text when AI is processing
  ///
  /// In en, this message translates to:
  /// **'AI is thinking...'**
  String get aiThinking;

  /// Label for time field
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Label for category field
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// Label for diary content field
  ///
  /// In en, this message translates to:
  /// **'Diary Content'**
  String get diaryContent;

  /// Label for content analysis field
  ///
  /// In en, this message translates to:
  /// **'Content Analysis'**
  String get contentAnalysis;

  /// Format for displaying month and day in Chinese style
  ///
  /// In en, this message translates to:
  /// **'{month}/{day}'**
  String monthDay(int month, int day);

  /// Question 1
  ///
  /// In en, this message translates to:
  /// **'How do you feel today?'**
  String get qaQuestion1;

  /// Question 2
  ///
  /// In en, this message translates to:
  /// **'What was the highlight of your day?'**
  String get qaQuestion2;

  /// Question 3
  ///
  /// In en, this message translates to:
  /// **'Did you face any challenges today?'**
  String get qaQuestion3;

  /// Question 4
  ///
  /// In en, this message translates to:
  /// **'What are you grateful for today?'**
  String get qaQuestion4;

  /// Question 5
  ///
  /// In en, this message translates to:
  /// **'What did you learn today?'**
  String get qaQuestion5;

  /// Question 6
  ///
  /// In en, this message translates to:
  /// **'How did you take care of yourself today?'**
  String get qaQuestion6;

  /// Question 7
  ///
  /// In en, this message translates to:
  /// **'What would you like to improve tomorrow?'**
  String get qaQuestion7;

  /// Question 8
  ///
  /// In en, this message translates to:
  /// **'Who or what inspired you today?'**
  String get qaQuestion8;

  /// Question 9
  ///
  /// In en, this message translates to:
  /// **'Did you help someone today? How?'**
  String get qaQuestion9;

  /// Question 10
  ///
  /// In en, this message translates to:
  /// **'What is your goal for tomorrow?'**
  String get qaQuestion10;

  /// Placeholder for user input in chat text field
  ///
  /// In en, this message translates to:
  /// **'Jot down your thoughts...'**
  String get userInputPlaceholder;

  /// Title for LLM configuration error dialog
  ///
  /// In en, this message translates to:
  /// **'LLM Configuration Error'**
  String get llmConfigurationError;

  /// Error message when LLM service returns 405 error
  ///
  /// In en, this message translates to:
  /// **'The LLM service returned an error (405). This usually indicates a configuration issue with the current active model. Please check your LLM configuration.'**
  String get llmConfigurationErrorMessage;

  /// Title for LLM rate limit error dialog
  ///
  /// In en, this message translates to:
  /// **'LLM Rate Limit Error'**
  String get llmRateLimitError;

  /// Error message when LLM service returns 429 error
  ///
  /// In en, this message translates to:
  /// **'The LLM service is temporarily unavailable due to rate limiting (429). Please wait a moment and try again, or check your API usage limits.'**
  String get llmRateLimitErrorMessage;

  /// Button text to navigate to LLM configuration page
  ///
  /// In en, this message translates to:
  /// **'Go to LLM Configuration'**
  String get goToLlmConfig;

  /// Generic LLM service error message with status code
  ///
  /// In en, this message translates to:
  /// **'LLM Service Error ({statusCode})'**
  String llmServiceError(int statusCode);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
