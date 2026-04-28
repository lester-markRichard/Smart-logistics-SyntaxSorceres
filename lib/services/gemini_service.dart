import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // SECURITY IMPORT
import '../models/logistics_models.dart';

class GeminiService {
  /// Calls Gemini and returns {'prediction': ..., 'strategy': ...}.
  static Future<Map<String, String>> generatePredictionAndStrategy({
    required String source,
    required String destination,
    required Vehicle truck,
  }) async {
    // 1. SECURELY LOAD API KEY
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      developer.log('[GeminiService] Error: API Key missing from .env');
      return _fallback('API Key Missing');
    }

    // 2. THE CORRECT FLASH ENDPOINT
    final endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey';

    developer.log('[GeminiService] Calling Gemini for route: $source -> $destination');

    // 3. MENTOR'S HACKATHON SIMULATION
    final weatherOptions = [
      'High Humidity', 'Clear Skies', 'Heavy Rain', 
      'Thunderstorms', 'Foggy Conditions', 'Light Snow'
    ];
    final trafficOptions = [
      'Moderate Traffic', 'Heavy Congestion', 'Smooth Flow', 
      'Accident Ahead', 'Road Work'
    ];
    
    final random = Random();
    final randomWeather = weatherOptions[random.nextInt(weatherOptions.length)];
    final randomTraffic = trafficOptions[random.nextInt(trafficOptions.length)];

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
        '- Weather: $randomWeather\n'
        '- Traffic: $randomTraffic\n\n'
        'Your response MUST be a raw JSON object only. No markdown fences. '
        'No extra text. Format the JSON exactly like this:\n'
        '{\n'
        '  "prediction": "your 2-3 sentence prediction here",\n'
        '  "strategy": "your 2-3 sentence strategy here"\n'
        '}\n';

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
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
        },
        body: body,
      );

      developer.log('[GeminiService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        if (data['candidates'] == null || (data['candidates'] as List).isEmpty) { 
          throw Exception('API returned empty or invalid shape'); 
        }

        final rawText = data['candidates'][0]['content']['parts'][0]['text'];

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

  /// Task 2: Simple Chat Logic using raw HTTP (Now completely static!)
  static Future<String> sendChatMessage(String userMessage) async {
    try {
      // 1. Securely load the key
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        return "Error: API Key missing from .env";
      }

      // 2. The exact, verified endpoint
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

      // 3. The Secret Hackathon Demo Context
      final systemInstruction = "System Context: You are 'LogiBot', an expert AI assistant for a truck driver. The driver is on a route from Mumbai to Pune. Note: A recent reroute occurred due to a severe accident near Lonavala causing a 3-hour gridlock on the main Expressway. You rerouted them via the Old Highway to keep them moving, which adds 45 mins. Answer the driver's prompt conversationally, professionally, and briefly (under 3 sentences).";

      // 4. Construct the JSON payload
      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "$systemInstruction\n\nDriver asks: $userMessage"}
            ]
          }
        ]
      });

      // 5. Send the request
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      // 6. Parse the response safely
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] == null || (data['candidates'] as List).isEmpty) {
          return "Error: API returned empty response";
        }
        return data['candidates'][0]['content']['parts'][0]['text'];
      } else {
        return "Error: HTTP ${response.statusCode}";
      }
    } catch (e) {
      return "Connection Error: Check your internet or API key.";
    }
  }

  // 7. Re-added the missing Fallback method!
  static Map<String, String> _fallback(String reason) {
    return {
      'prediction':
          'AI analysis unavailable. [$reason] Expect standard route conditions.',
      'strategy': 'Proceed with standard operating parameters.',
    };
  }
}