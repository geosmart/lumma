import 'package:get/get.dart';

/// GetX 国际化 - 中文
class ZhCN extends Translations {
  @override
  Map<String, Map<String, String>> get keys => {
        'zh_CN': {
          // 应用基础
          'app_name': 'Lumma',
          'app_subtitle': '倾听·疗愈·珍藏',

          // 主页
          'start_writing_diary': '开始写日记',
          'diary_list': '日记列表',
          'calendar_view': '日历视图',
          'data_sync': '数据同步',
          'settings': '设置',

          // 日记相关
          'diary': '日记',
          'diary_content': '内容',
          'diary_chat': '聊天模式',
          'diary_qa': '问答模式',
          'diary_edit': '编辑日记',
          'diary_detail': '日记详情',
          'save': '保存',
          'cancel': '取消',
          'delete': '删除',
          'edit': '编辑',
          'confirm': '确认',

          // 设置相关
          'theme_settings': '主题设置',
          'language_settings': '语言设置',
          'light_mode': '浅色模式',
          'dark_mode': '深色模式',
          'system_mode': '跟随系统',
          'chinese': '中文',
          'english': 'English',

          // LLM 配置
          'llm_config': 'LLM 配置',
          'llm_name': '名称',
          'llm_model': '模型',
          'llm_api_key': 'API Key',
          'llm_base_url': 'Base URL',
          'llm_add': '添加 LLM',
          'llm_edit': '编辑 LLM',

          // 提示词配置
          'prompt_config': '提示词配置',
          'prompt_add': '添加提示词',
          'prompt_edit': '编辑提示词',

          // 同步配置
          'sync_config': '同步配置',
          'sync_now': '立即同步',
          'sync_success': '同步成功',
          'sync_failed': '同步失败',

          // 通用
          'loading': '加载中...',
          'error': '错误',
          'success': '成功',
          'warning': '警告',
          'info': '信息',
        }
      };
}
