import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class LlmService {
  static const String _model = 'qwen2.5:3b';
  static const String _endpointPath = '/api/generate';

  final http.Client _client;
  final List<Uri> _baseUrls;
  final Duration _timeout;

  LlmService({
    http.Client? client,
    List<Uri>? baseUrls,
    Duration timeout = const Duration(seconds: 10),
  })  : _client = client ?? http.Client(),
        _baseUrls = baseUrls ?? _defaultBaseUrls(),
        _timeout = timeout;

  static List<Uri> _defaultBaseUrls() {
    return [
      // Desktop / Codespaces localhost
      Uri.parse('http://localhost:11434'),

      // Android emulator loopback
      Uri.parse('http://10.0.2.2:11434'),

      // Direct loopback fallback
      Uri.parse('http://127.0.0.1:11434'),
    ];
  }

  Future<String?> generateSummary(String prompt) async {
    final trimmedPrompt = prompt.trim();

    if (trimmedPrompt.isEmpty) {
      debugPrint('LlmService: Empty prompt received.');
      return null;
    }

    final body = jsonEncode({
      'model': _model,
      'prompt': trimmedPrompt,
      'stream': false,

      // Reduce hallucination / creativity
      'temperature': 0.05,

      // Tighter token selection
      'top_p': 0.5,

      // Avoid repetitive wording
      'repeat_penalty': 1.15,

      // Keep summaries short
      'num_predict': 120,
    });

    for (final baseUrl in _baseUrls) {
      final uri = baseUrl.replace(path: _endpointPath);

      try {
        debugPrint('LlmService: Trying ${uri.toString()}');

        final response = await _client
            .post(
              uri,
              headers: {
                HttpHeaders.contentTypeHeader: 'application/json',
              },
              body: body,
            )
            .timeout(_timeout);

        if (response.statusCode < 200 || response.statusCode >= 300) {
          debugPrint(
            'LlmService: ${uri.host} responded with ${response.statusCode}.',
          );
          continue;
        }

        final decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          debugPrint(
            'LlmService: Unexpected response payload from ${uri.host}.',
          );
          continue;
        }

        final responseText = decoded['response'];

        if (responseText is! String) {
          debugPrint(
            'LlmService: Missing response text from ${uri.host}.',
          );
          continue;
        }

        final summary = responseText.trim();

        if (summary.isEmpty) {
          debugPrint(
            'LlmService: Empty response from ${uri.host}.',
          );
          continue;
        }

        // Cleanup excessive spacing/newlines
        final cleaned = summary
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            .trim();

        debugPrint(
          'LlmService: Successfully generated summary using ${uri.host}.',
        );

        return cleaned;
      } on SocketException catch (e) {
        debugPrint(
          'LlmService: Socket error while reaching ${uri.host}: $e',
        );
      } on HttpException catch (e) {
        debugPrint(
          'LlmService: HTTP error from ${uri.host}: $e',
        );
      } on FormatException catch (e) {
        debugPrint(
          'LlmService: Invalid JSON from ${uri.host}: $e',
        );
      } catch (e) {
        debugPrint(
          'LlmService: Failed to reach ${uri.host}: $e',
        );
      }
    }

    debugPrint(
      'LlmService: All Ollama endpoints failed. Falling back.',
    );

    return null;
  }

  void dispose() {
    _client.close();
  }
}