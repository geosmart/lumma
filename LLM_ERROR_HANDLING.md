# LLM Configuration Error Handler Implementation

## Overview

This implementation adds user-friendly error handling for LLM configuration issues, specifically targeting HTTP 405 errors but applicable to other configuration-related errors. When users encounter LLM service errors, they will now see a helpful dialog that guides them to check and fix their LLM configuration.

## Features

### 1. Error Detection
- Automatically detects LLM configuration-related errors (405, API key issues, URL problems, etc.)
- Parses error messages to extract HTTP status codes
- Provides context-aware error handling

### 2. User-Friendly Dialog
- Shows clear error messages in both English and Chinese
- Provides helpful troubleshooting tips for 405 errors:
  - Check if the model name is correct
  - Verify the API endpoint URL
  - Ensure the API key is valid
  - Check if the model supports the requested features
- Includes a direct button to navigate to LLM configuration settings

### 3. Localization Support
- Error messages available in both English and Chinese
- Added to existing localization system (app_en.arb and app_zh.arb)

## Files Modified/Created

### New Files
1. `lib/util/llm_error_dialog.dart` - Utility class for LLM error dialog
2. `test/llm_error_dialog_test.dart` - Unit tests for the error dialog functionality

### Modified Files
1. `lib/l10n/app_en.arb` - Added English error messages
2. `lib/l10n/app_zh.arb` - Added Chinese error messages
3. `lib/util/ai_service.dart` - Enhanced 405 error handling
4. `lib/diary/diary_chat_service.dart` - Added error dialog integration
5. `lib/diary/diary_chat_page.dart` - Integrated error dialog in chat UI
6. `lib/config/prompt_config_page.dart` - Fixed type error for error handling

## New Localization Keys

### English (app_en.arb)
- `llmConfigurationError`: "LLM Configuration Error"
- `llmConfigurationErrorMessage`: "The LLM service returned an error (405)..."
- `goToLlmConfig`: "Go to LLM Configuration"
- `llmServiceError`: "LLM Service Error ({statusCode})"

### Chinese (app_zh.arb)
- `llmConfigurationError`: "大模型配置错误"
- `llmConfigurationErrorMessage`: "大模型服务返回错误 (405)，这通常表示当前激活的模型存在配置问题..."
- `goToLlmConfig`: "前往大模型配置"
- `llmServiceError`: "大模型服务错误 ({statusCode})"

## Usage

When a user encounters an LLM error (like 405), the system will:

1. Detect if the error is configuration-related
2. Show a user-friendly dialog with:
   - Clear error explanation
   - Troubleshooting tips (for 405 errors)
   - "Cancel" button to dismiss
   - "Go to LLM Configuration" button to navigate to settings
3. Navigate to the Settings page where users can configure their LLM models

## Testing

Unit tests verify:
- Error detection functionality
- Status code extraction from error messages
- Various error message patterns

Run tests with:
```bash
flutter test test/llm_error_dialog_test.dart
```

## Integration Points

The error handling is integrated into:
- Chat interface (`DiaryChatPage`)
- LLM service layer (`AiService`)
- Error parsing (`DiaryChatService`)

This provides comprehensive coverage for LLM configuration errors throughout the application.
