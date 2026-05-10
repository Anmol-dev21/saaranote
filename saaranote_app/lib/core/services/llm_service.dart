import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:http/http.dart' as http;

/// Lightweight client for local Ollama LLM access.
class LlmService {
  static const String defaultBaseUrl = String.fromEnvironment(
    'OLLAMA_BASE_URL',
    defaultValue: 'http://localhost:11434',
  );
  static const String defaultModel = String.fromEnvironment(
    'OLLAMA_MODEL',
    defaultValue: 'phi3',
  );

  LlmService({
    http.Client? client,
    this.baseUrl = defaultBaseUrl,
    this.model = defaultModel,
    this.timeout = const Duration(seconds: 10),
    bool Function()? isAndroid,
  })  : _client = client ?? http.Client(),
        _isAndroid = isAndroid ?? (() => Platform.isAndroid);

  final http.Client _client;
  final bool Function() _isAndroid;
  final String baseUrl;
  final String model;
  final Duration timeout;

  /// Generate a summary from a prompt via Ollama.
  /// Returns an empty string on failure so callers can fall back safely.
  Future<String> generateSummary(String prompt) async {
    final promptTrimmed = prompt.trim();
    if (promptTrimmed.isEmpty) return '';

    for (final candidateBaseUrl in _candidateBaseUrls()) {
      final uri = Uri.parse('$candidateBaseUrl/api/generate');

      try {
        final response = await _client
            .post(
              uri,
              headers: const {'Content-Type': 'application/json'},
              body: jsonEncode({
                'model': model,
                'prompt': promptTrimmed,
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
          developer.log(
            'Ollama non-200 (${response.statusCode}) from $candidateBaseUrl',
            name: 'LlmService',
          );
          continue;
        }

        final decoded = jsonDecode(response.body);
        if (decoded is! Map<String, dynamic>) {
          developer.log(
            'Ollama response was not a JSON object from $candidateBaseUrl',
            name: 'LlmService',
          );
          continue;
        }

        final text = (decoded['response'] as String?)?.trim();
        if (text == null || text.isEmpty) {
          developer.log(
            'Ollama returned empty response from $candidateBaseUrl',
            name: 'LlmService',
          );
          continue;
        }

        return text;
      } on TimeoutException {
        developer.log(
          'Ollama timeout from $candidateBaseUrl',
          name: 'LlmService',
        );
        continue;
      } catch (e) {
        developer.log(
          'Ollama request failed from $candidateBaseUrl: $e',
          name: 'LlmService',
        );
        continue;
      }
    }

    return '';
  }

  List<String> _candidateBaseUrls() {
    final normalized = baseUrl.trim().isEmpty ? defaultBaseUrl : baseUrl.trim();
    Uri? parsed;
    try {
      parsed = Uri.parse(normalized);
    } catch (_) {
      return [defaultBaseUrl];
    }

    if (!_isAndroid()) {
      return [normalized];
    }

    // On Android emulators, the host machine's localhost is reachable via:
    // - 10.0.2.2 (Android Studio emulator)
    // - 10.0.3.2 (Genymotion)
    final host = parsed.host;
    final isLocalhost = host == 'localhost' || host == '127.0.0.1' || host == '::1';
    if (!isLocalhost) {
      return [normalized];
    }

    final scheme = parsed.scheme.isEmpty ? 'http' : parsed.scheme;
    final port = parsed.hasPort ? parsed.port : 11434;

    return [
      '$scheme://10.0.2.2:$port',
      '$scheme://10.0.3.2:$port',
      normalized,
    ];
  }
}
