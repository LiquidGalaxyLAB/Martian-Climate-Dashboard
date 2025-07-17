import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:martian_climate_dashboard/enums/role.dart';
import 'package:martian_climate_dashboard/services/api_service.dart';

class GeminiService {
  final ApiService apiService;
  final String imageContent;
  final String apiKey;
  http.Client client;

  GeminiService({
    required this.imageContent,
    required this.apiKey,
    required this.apiService,
    http.Client? client,
  }) : client = client ?? http.Client();

  static const String model = 'gemini-2.5-flash';
  static const String geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  List<Map<String, dynamic>> context = [];

  Future<Map> callApi(String prompt) async {
    final uri = Uri.parse(geminiUrl);
    uri.queryParameters.addAll({'key': apiKey});
    final headers = {'Content-Type': 'application/json'};
    String payload = jsonEncode({
      "contents": [
        {
          "role": Role.user.name,
          "parts": [
            {"text": prompt},
            {
              "inline_data": {"mime_type": "image/jpeg", "data": imageContent},
            },
          ],
        },
        ...context,
      ],
    });
    context.add({
      "role": Role.user.name,
      "parts": [
        {"text": prompt},
      ],
    });

    final response = await client.post(uri, headers: headers, body: payload);
    if (response.statusCode != 200) {
      throw Exception(
        "Failed to call Gemini API, status code: ${response.statusCode}",
      );
    }
    final responseData = jsonDecode(response.body);
    final resp = responseData['candidates'][0]['content'];
    context.add(resp);
    return resp;
  }
}
