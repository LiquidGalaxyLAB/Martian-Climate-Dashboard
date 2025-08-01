import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:martian_climate_dashboard/enums/role.dart';
import 'package:martian_climate_dashboard/services/api_service.dart';

class GeminiService {
  // final ApiService apiService;
  final String imageContent;
  final String apiKey;
  http.Client client;

  GeminiService({
    required this.imageContent,
    required this.apiKey,
    // required this.apiService,
    http.Client? client,
  }) : client = client ?? http.Client();

  static const String model = 'gemini-2.5-flash';
  static const String geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  List<Map<String, dynamic>> context = [];

  void dispose() {
    client.close();
    context.clear();
  }

  Future<Map> generateSummary() async {
    print("object");
    final response = await callApi("""
      You are an expert mars scientist.
      Analyze the image and provide a detailed summary of the Martian climate, including any visible features.
      keep the summary concise and informative.
      Use the image provided to you as a reference.
      keep the summary in 50 words or less.
      in the beginning always start with "Summary:" in bold.
      """, addPrompt: false);
    return response;
  }

  Future<Map> callApi(
    String prompt, {
    bool addPrompt = true,
    String? image,
  }) async {
    print("Calling Gemini API with prompt: $prompt");
    final uri = Uri.parse('$geminiUrl?key=$apiKey');
    final headers = {'Content-Type': 'application/json'};
    String payload = jsonEncode({
      "contents": [
        {
          "role": Role.user.name,
          "parts": [
            {"text": prompt},
            {
              "inline_data": {
                "mime_type": "image/jpeg",
                "data": image ?? imageContent,
              },
            },
          ],
        },
        ...context,
      ],
    });
    if (addPrompt) {
      context.add({
        "role": Role.user.name,
        "parts": [
          {"text": prompt},
        ],
      });
    }
    print(context);
    final response = await client.post(uri, headers: headers, body: payload);
    if (response.statusCode != 200) {
      throw Exception(
        "Failed to call Gemini API, status code: ${response.statusCode}, body: ${response.body}",
      );
    }
    final responseData = jsonDecode(response.body);
    final resp = responseData['candidates'][0]['content'];
    context.add(resp);
    return resp;
  }
}
