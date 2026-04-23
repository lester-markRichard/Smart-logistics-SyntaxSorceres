import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/logistics_models.dart';

class GeminiService {
  static String get _apiKey => dotenv.env['GEMINI_API_KEY'] ?? '';

  // ✅ FIXED ENDPOINT (v1 + stable model)
  static String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=$_apiKey';

  /// Calls Gemini and returns {'prediction': ..., 'strategy': ...}.
  static Future<Map<String, String>> generatePredictionAndStrategy({
    required String source,
    required String destination,
    required Vehicle truck,
  }) async {
    developer.log('[GeminiService] Calling Gemini for route: $source -> $destination');
    developer.log('[GeminiService] Endpoint: $_endpoint');

    final prompt =
        'You are a Smart Supply Chain AI assistant. Analyze the following '
        'logistics route and truck parameters, then respond ONLY with a valid '
        'JSON object containing exactly two fields: "prediction" and "strategy".\n\n'
        'Route Details:\n'
        '- Source: $source\n'
        '- Destination: $destination\n\n'
        'Truck Details:\n'
        '- Asset Number: ${truck.number}\n'
        '- Fuel Type: ${truck.fuelType}\n'
        '- Cargo Capacity: ${truck.capacity} Tonnes\n'
        '- Vehicle Age: ${truck.age} years\n\n'
        'Context:\n'
        '- Mock Weather: Partly cloudy, 70% humidity, scattered rain advisory.\n'
        '- Mock Traffic: Moderate congestion near urban entry points.\n\n'
        'Your response MUST be a raw JSON object only. No markdown fences. '
        'No extra text. Example:\n'
        '{"prediction": "...", "strategy": "..."}\n\n'
        'Both fields: 2-3 concise sentences each.';

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      developer.log('[GeminiService] Status: ${response.statusCode}');
      developer.log('[GeminiService] Raw Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'];

        if (rawText == null) {
          return _fallback('Invalid AI response format');
        }

        // Clean accidental markdown
        final cleaned = rawText
            .toString()
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final parsed = jsonDecode(cleaned) as Map<String, dynamic>;

        return {
          'prediction': parsed['prediction']?.toString() ??
              'No prediction generated.',
          'strategy': parsed['strategy']?.toString() ??
              'No strategy generated.',
        };
      } else {
        return _fallback('HTTP ${response.statusCode}');
      }
    } catch (e) {
      developer.log('[GeminiService] Exception: $e');
      return _fallback('Network/Parsing Error');
    }
  }

  static Map<String, String> _fallback(String reason) {
    return {
      'prediction':
          'AI analysis unavailable. [$reason] Expect standard route conditions.',
      'strategy': 'Proceed with standard operating parameters.',
    };
  }
}