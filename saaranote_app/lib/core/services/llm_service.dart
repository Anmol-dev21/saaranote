import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Lightweight client for local Ollama LLM access.
class LlmService {
  LlmService({
    http.Client? client,
    this.baseUrl = 'http://localhost:11434',
    this.model = 'phi3',
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;
  final String model;
  final Duration timeout;

  /// Generate a summary from a prompt via Ollama.
  /// Returns an empty string on failure so callers can fall back safely.
  Future<String> generateSummary(String prompt) async {
    final uri = Uri.parse('$baseUrl/api/generate');

    try {
      final response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode({
              'model': model,
              'prompt': prompt,
              'stream': false,
              'options': {
                'temperature': 0.2,
                'top_p': 0.9,
                'num_ctx': 2048,
              },
            }),
          )
          .timeout(timeout);

      if (response.statusCode != 200) {
        return '';
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final text = (decoded['response'] as String?)?.trim();
      return text ?? '';
    } on TimeoutException {
      return '';
    } catch (_) {
      return '';
    }
  }
}
