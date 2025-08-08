import 'dart:convert';

import 'package:http/http.dart' as http;

class GeminiService {
  final String imageContent;
  final String apiKey;
  http.Client client;

  String? initialSummary;

  GeminiService({
    required this.imageContent,
    required this.apiKey,
    http.Client? client,
  }) : client = client ?? http.Client();

  static const String model = 'gemini-2.5-pro';
  static const String geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  List<Map<String, dynamic>> context = [];

  void dispose() {
    client.close();
    context.clear();
  }

  Future<void> clearContext() async {
    context.clear();
  }

  Future<String> generateSummary() async {
    print("Generating summary...");
    try {
      final uri = Uri.parse('$geminiUrl?key=$apiKey');
      final headers = {'Content-Type': 'application/json'};

      Map<String, dynamic> requestBody = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text": """
                You are an expert Mars scientist.
                Analyze the Mars climate visualization image and provide a detailed summary of the Martian atmospheric conditions, including any visible features or patterns.
                Keep the summary concise and informative.
                Use the image provided to you as a reference.
                Keep the summary in 75 words or less.
                Always start with "**Summary:**" in bold.
                Focus on scientific analysis of the climate data shown.
                """,
              },
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": imageContent,
                },
              },
            ],
          },
        ],
        "generationConfig": {"temperature": 0.7, "maxOutputTokens": 1000},
      };

      String payload = jsonEncode(requestBody);
      final response = await client.post(uri, headers: headers, body: payload);

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to call Gemini API, status code: ${response.statusCode}, body: ${response.body}",
        );
      }

      final responseData = jsonDecode(response.body);
      print("API Response Structure: ${responseData.keys}");

      if (responseData['candidates'] == null ||
          responseData['candidates'].isEmpty) {
        throw Exception('No candidates in API response');
      }

      final candidate = responseData['candidates'][0];
      if (candidate['content'] == null) {
        throw Exception('No content in first candidate');
      }

      final content = candidate['content'];
      if (content['parts'] == null || content['parts'].isEmpty) {
        throw Exception('No parts in content');
      }

      final part = content['parts'][0];
      if (part['text'] == null) {
        throw Exception('No text in first part');
      }

      final summaryText = part['text'];
      initialSummary = summaryText;

      context.add({
        "role": "model",
        "parts": [
          {"text": summaryText},
        ],
        "isSummary": true,
      });

      return summaryText;
    } catch (e) {
      print('Error generating summary: $e');
      return 'Error generating summary: ${e.toString()}';
    }
  }

  Future<String> sendMessage(String userMessage) async {
    try {
      context.add({
        "role": "user",
        "parts": [
          {"text": userMessage},
        ],
      });

      final uri = Uri.parse('$geminiUrl?key=$apiKey');
      final headers = {'Content-Type': 'application/json'};

      final conversationHistory =
          context.where((msg) => msg["isSummary"] != true).toList();

      Map<String, dynamic> requestBody = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "text":
                    "You are a Mars climate assistant. Answer ONLY the user's specific questions directly. Never answer like you dont know the required answer, Do not provide general observations unless asked. Answer all the questions by using the Image provided to you in the previous context.",
              },
            ],
          },
          ...conversationHistory,
        ],
        "generationConfig": {"temperature": 0.6, "maxOutputTokens": 1000},
      };

      String payload = jsonEncode(requestBody);
      final response = await client.post(uri, headers: headers, body: payload);

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to call Gemini API, status code: ${response.statusCode}, body: ${response.body}",
        );
      }

      final responseData = jsonDecode(response.body);
      print("API Response: ${response.body}");

      if (responseData['candidates'] == null ||
          responseData['candidates'].isEmpty ||
          responseData['candidates'][0]['content'] == null) {
        throw Exception('Invalid response format from Gemini API');
      }

      final resp = responseData['candidates'][0]['content'];

      if (resp['parts'] == null || resp['parts'].isEmpty) {
        throw Exception('Missing parts in response: ${jsonEncode(resp)}');
      }

      final modelResponse = resp['parts'][0]['text'] ?? 'No response';

      context.add({
        "role": "model",
        "parts": [
          {"text": modelResponse},
        ],
      });

      return modelResponse;
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to get response: ${e.toString()}');
    }
  }
}
