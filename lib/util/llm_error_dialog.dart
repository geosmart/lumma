import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';
import '../config/settings_page.dart';

/// LLM Configuration Error Dialog Utility
class LlmErrorDialog {
  /// Show LLM configuration error dialog with option to navigate to settings
  static Future<void> showLlmConfigurationError(
    BuildContext context, {
    required String errorMessage,
    int? statusCode,
  }) async {
    final bool is405Error = statusCode == 405 || errorMessage.contains('405');
    final bool is429Error = statusCode == 429 || errorMessage.contains('429');

    // Determine dialog title and message based on error type
    final String dialogTitle;
    final String dialogMessage;
    final List<String> troubleshootingTips;

    if (is429Error) {
      dialogTitle = AppLocalizations.of(context)!.llmRateLimitError;
      dialogMessage = AppLocalizations.of(context)!.llmRateLimitErrorMessage;
      troubleshootingTips = [
        '• Wait a few minutes before trying again',
        '• Check your API usage limits and quotas',
        '• Consider upgrading your API plan if needed',
        '• Switch to a different model if available',
      ];
    } else if (is405Error) {
      dialogTitle = AppLocalizations.of(context)!.llmConfigurationError;
      dialogMessage = AppLocalizations.of(context)!.llmConfigurationErrorMessage;
      troubleshootingTips = [
        '• Check if the model name is correct',
        '• Verify the API endpoint URL',
        '• Ensure the API key is valid',
        '• Check if the model supports the requested features',
      ];
    } else {
      dialogTitle = AppLocalizations.of(context)!.llmConfigurationError;
      dialogMessage = errorMessage;
      troubleshootingTips = [
        '• Check your LLM configuration',
        '• Verify API credentials and endpoints',
        '• Ensure network connectivity',
      ];
    }

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            dialogTitle,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: is429Error ? Colors.orange : Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dialogMessage,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Icon(
                is429Error ? Icons.hourglass_empty : Icons.info_outline,
                color: is429Error ? Colors.orange : Colors.orange,
                size: 20,
              ),
              const SizedBox(height: 8),
              Text(
                troubleshootingTips.join('\n'),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(AppLocalizations.of(context)!.llmCancel),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to LLM configuration page (Settings page, LLM tab)
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SettingsPage(initialTabIndex: 2), // LLM config is tab 2
                  ),
                );
              },
              icon: const Icon(Icons.settings),
              label: Text(AppLocalizations.of(context)!.goToLlmConfig),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Check if error message indicates an LLM configuration issue
  static bool isLlmConfigurationError(String errorMessage) {
    return errorMessage.contains('405') ||
           errorMessage.contains('429') ||
           errorMessage.contains('API') ||
           errorMessage.contains('配置') ||
           errorMessage.contains('configuration') ||
           errorMessage.contains('密钥') ||
           errorMessage.contains('key') ||
           errorMessage.contains('地址') ||
           errorMessage.contains('URL') ||
           errorMessage.contains('模型') ||
           errorMessage.contains('model') ||
           errorMessage.contains('rate limit') ||
           errorMessage.contains('限流') ||
           errorMessage.contains('频繁');
  }

  /// Extract status code from error message
  static int? extractStatusCode(String errorMessage) {
    final match = RegExp(r'\((\d{3})\)').firstMatch(errorMessage);
    if (match != null) {
      return int.tryParse(match.group(1)!);
    }
    return null;
  }
}
