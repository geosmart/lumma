import 'package:flutter_test/flutter_test.dart';
import 'package:lumma/util/llm_error_dialog.dart';

void main() {
  group('LLM Error Dialog', () {
    test('isLlmConfigurationError should detect 405 and 429 errors', () {
      expect(LlmErrorDialog.isLlmConfigurationError('大模型服务响应错误 (405)'), true);
      expect(LlmErrorDialog.isLlmConfigurationError('LLM Service Error (405)'), true);
      expect(LlmErrorDialog.isLlmConfigurationError('大模型服务请求过于频繁 (429)'), true);
      expect(LlmErrorDialog.isLlmConfigurationError('LLM Service Error (429)'), true);
      expect(LlmErrorDialog.isLlmConfigurationError('API key invalid'), true);
      expect(LlmErrorDialog.isLlmConfigurationError('Rate limit exceeded'), true);
      expect(LlmErrorDialog.isLlmConfigurationError('请求过于频繁'), true);
      expect(LlmErrorDialog.isLlmConfigurationError('Random error message'), false);
    });

    test('extractStatusCode should extract status codes from error messages', () {
      expect(LlmErrorDialog.extractStatusCode('大模型服务响应错误 (405)'), 405);
      expect(LlmErrorDialog.extractStatusCode('大模型服务请求过于频繁 (429)'), 429);
      expect(LlmErrorDialog.extractStatusCode('LLM Service Error (401)'), 401);
      expect(LlmErrorDialog.extractStatusCode('No status code here'), null);
    });
  });
}
