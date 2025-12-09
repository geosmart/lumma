import 'package:get/get.dart';

/// GetX 国际化 - 英文
class EnUS extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'en_US': {
          // 应用基础
          'app_name': 'Lumma',
          'app_subtitle': 'Hear. Heal. Hold.',

          // 主页
          'start_writing_diary': 'Start Writing',
          'diary_list': 'Diary List',
          'calendar_view': 'Calendar',
          'data_sync': 'Sync',
          'settings': 'Settings',

          // 日记相关
          'diary': 'Diary',
          'diary_content': 'Content',
          'diary_chat': 'Chat Mode',
          'diary_qa': 'Q&A Mode',
          'diary_edit': 'Edit Diary',
          'diary_detail': 'Diary Detail',
          'save': 'Save',
          'cancel': 'Cancel',
          'delete': 'Delete',
          'edit': 'Edit',
          'confirm': 'Confirm',

          // 设置相关
          'theme_settings': 'Theme',
          'language_settings': 'Language',
          'light_mode': 'Light',
          'dark_mode': 'Dark',
          'system_mode': 'System',
          'chinese': 'Chinese',
          'english': 'English',

          // LLM 配置
          'llm_config': 'LLM Config',
          'llm_name': 'Name',
          'llm_model': 'Model',
          'llm_api_key': 'API Key',
          'llm_base_url': 'Base URL',
          'llm_add': 'Add LLM',
          'llm_edit': 'Edit LLM',

          // 提示词配置
          'prompt_config': 'Prompt Config',
          'prompt_add': 'Add Prompt',
          'prompt_edit': 'Edit Prompt',

          // 同步配置
          'sync_config': 'Sync Config',
          'sync_now': 'Sync Now',
          'sync_success': 'Sync Success',
          'sync_failed': 'Sync Failed',

          // 通用
          'loading': 'Loading...',
          'error': 'Error',
          'success': 'Success',
          'warning': 'Warning',
          'info': 'Info',
        }
      };
}
