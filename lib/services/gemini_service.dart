import 'dart:convert';

import 'package:flutter/foundation.dart';
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

  static const String model = 'gemini-1.5-flash';
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
    if (kDebugMode) {
      print("Generating summary...");
    }
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
              // for the second part of the summarry I want you to give a json obect with the major takeaways along with the summary key, the json object should be seprated from the summary using "===" and then new line

              // example output:
              // **Summary:** The Martian atmosphere shows significant temperature variations, with colder regions indicating potential frost formation. The data suggests a stable atmosphere with minimal dust activity at this time.
              // ===
              // {
              //   "summary": "The Martian atmosphere shows significant temperature variations, with colder regions indicating potential frost formation. The data suggests a stable atmosphere with minimal dust activity at this time.",
              //   "Min Temperature": "Around 142K",
              //   "Max Temperature": "Around 298K",
              //   "Hotspots": "Localized warm regions",
              //   "Topography correlations": "Craters show lower temperatures",
              //   "Temperature gradients": "Strong latitudinal gradients"
              // }
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
      if (kDebugMode) {
        print("Request Payload: $payload");
      }
      final response = await client.post(uri, headers: headers, body: payload);

      if (kDebugMode) {
        print("API Status Code: ${response.statusCode}");
      }
      final responseData = jsonDecode(response.body);
      if (kDebugMode) {
        print("API Response: ${response.body}");
      }

      if (response.statusCode != 200) {
        throw Exception(
          "Failed to call Gemini API, status code: ${response.statusCode}, body: ${response.body}",
        );
      }

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
        if (kDebugMode) {
          print('Full content object: $content');
        }
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
      if (kDebugMode) {
        print('Error generating summary: $e');
      }
      return 'Error generating summary: ${e.toString()}';
    }
  }

  Future<Map<String, dynamic>> sendMessage(String userMessage) async {
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
                "text": """
                    You are an expert Mars climate assistant analyzing transformed KML imagery from Mars. The image provided is a visualization being displayed on Liquid Galaxy so never say "image", always refer to it as visualization.

                    ## RESPONSE REQUIREMENTS:
                    - Answer the user's specific questions with precise information based on the visualization
                    - Always reference visual elements visible in the provided visualization
                    - Use scientific terminology and explain Mars-specific phenomena
                    - Format your response using markdown for readability
                    - Never claim inability to answer - if uncertain, provide your best analysis based on visible data and in case of coordinates you could also give a wild guess.
                    - never use markdown after the "===" separator in the second part
                    - do not wrap the JSON in ```json code blocks - provide raw JSON only

                    ## OUTPUT FORMAT:
                    Your response MUST contain two parts separated by "===":

                    1. PART ONE: A concise, informative analysis directly answering the user's question
                      - Use **bold**, *italics*, and bullet points for clarity
                      - Include specific measurements/values visible in the imagery
                      - Reference geographical features by their proper Martian nomenclature

                    2. PART TWO: A JSON object containing location data when relevant:
                      {
                        "name": "Feature Name",
                        "coordinates": [latitude, longitude],
                        "info": "Brief scientific description",
                        "classification": "Type of feature (crater/basin/canyon/etc)",
                        "dimensions": "Size information if visible"
                      }

                    Example response to "What are the temperature patterns in Valles Marineris?":
                    **Temperature Analysis: Valles Marineris**

                    The visualization shows a *distinct thermal gradient* across Valles Marineris with:
                    * **Warmer temperatures** (250-270K) along the canyon floor
                    * **Cooler readings** (210-230K) on the surrounding plateaus
                    * Notable **thermal anomalies** at the intersections of tributary canyons

                    The temperature pattern aligns with the topographical features, showing how the canyon's depth affects local atmospheric conditions.==={"name":"Valles Marineris","coordinates":[-13.8, -59.2],"info":"Mars' largest canyon system showing significant temperature variations",}
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
      List responseList = modelResponse.split("===");

      final output = responseList[0].trim();
      final jsonPart = responseList.length < 2 ? '{}' : responseList[1].trim();
      if (kDebugMode) {
        print("response: $jsonPart, $output");
      }

      Map<String, dynamic> locationData = jsonDecode(jsonPart);

      context.add({
        "role": "model",
        "parts": [
          {"text": output},
        ],
      });

      return {"summary": output, "location": locationData};
    } catch (e) {
      if (kDebugMode) {
        print('Error sending message: $e');
      }
      throw Exception('Failed to get response: ${e.toString()}');
    }
  }
}
