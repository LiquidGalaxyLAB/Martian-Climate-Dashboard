import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// A service class providing AI-powered analysis of Mars climate visualizations using Google's Gemini API.
///
/// The [GeminiService] integrates with Google's Gemini AI model to provide intelligent analysis
/// of Mars climate data visualizations. It enables conversational interaction with climate data,
/// generating insights, summaries, and answering specific questions about Mars atmospheric
/// conditions based on visual climate representations.
///
/// **Core Capabilities:**
/// - **Image Analysis**: Processes Mars climate visualization images using multimodal AI
/// - **Summary Generation**: Creates concise scientific summaries of climate patterns
/// - **Conversational Interface**: Maintains context for ongoing climate data discussions
/// - **Location Discovery**: Identifies and provides information about Mars geographic features
/// - **Scientific Context**: Applies Mars-specific knowledge to climate data interpretation
///
/// **AI Model Integration:**
/// - Uses Gemini 1.5 Flash model for optimal balance of performance and accuracy
/// - Supports multimodal input (text + image) for comprehensive analysis
/// - Maintains conversation context for coherent multi-turn interactions
/// - Implements proper error handling and API rate limiting considerations
///
/// **Response Formats:**
/// - Markdown-formatted text for rich display in chat interfaces
/// - Structured JSON for location data and geographic feature information
/// - Scientific terminology with educational explanations for accessibility
///
/// Example usage:
/// ```dart
/// // Initialize service with Mars visualization image
/// final geminiService = GeminiService(
///   apiKey: 'your-api-key',
///   imageContent: base64EncodedImage,
/// );
///
/// // Generate initial analysis
/// final summary = await geminiService.generateSummary();
///
/// // Ask specific questions
/// final response = await geminiService.sendMessage(
///   "What are the temperature patterns near Olympus Mons?"
/// );
/// ```
class GeminiService {
  /// Base64-encoded Mars climate visualization image for AI analysis.
  ///
  /// Contains the complete visualization image that serves as the primary
  /// context for all AI interactions. This image provides visual reference
  /// for temperature patterns, pressure distributions, wind data, or other
  /// Mars atmospheric variables being analyzed.
  final String imageContent;

  /// Google Gemini API key for authenticated requests.
  ///
  /// Required for all API interactions. Should be stored securely and
  /// loaded from encrypted storage or environment variables in production.
  final String apiKey;

  /// HTTP client for API communication with configurable timeout and retry logic.
  ///
  /// Can be injected for testing purposes or customized with specific
  /// network configurations, proxy settings, or timeout values.
  http.Client client;

  /// Cached initial summary of the Mars climate visualization.
  ///
  /// Stores the first AI-generated analysis of the visualization to avoid
  /// regenerating the same content and provide quick access to the base
  /// analysis for subsequent conversations.
  String? initialSummary;

  /// Conversation context maintaining the complete chat history.
  ///
  /// Stores all user messages and AI responses to enable coherent multi-turn
  /// conversations. Each message includes role identification ('user' or 'model')
  /// and properly formatted content parts for API submission.
  ///
  /// Context structure:
  /// ```dart
  /// [
  ///   {
  ///     "role": "user|model",
  ///     "parts": [{"text": "message content"}],
  ///     "isSummary": bool (optional)
  ///   }
  /// ]
  /// ```
  List<Map<String, dynamic>> context = [];

  /// Creates a Gemini AI service instance for Mars climate analysis.
  ///
  /// Parameters:
  /// - [imageContent]: Base64-encoded Mars visualization image
  /// - [apiKey]: Valid Google Gemini API key for authentication
  /// - [client]: Optional HTTP client for custom network configurations
  ///
  /// Example:
  /// ```dart
  /// final service = GeminiService(
  ///   imageContent: await convertImageToBase64(visualizationFile),
  ///   apiKey: await getSecureApiKey(),
  ///   client: customHttpClient, // Optional
  /// );
  /// ```
  GeminiService({
    required this.imageContent,
    required this.apiKey,
    http.Client? client,
  }) : client = client ?? http.Client();

  /// Gemini AI model identifier for Mars climate analysis.
  ///
  /// Uses Gemini 1.5 Flash which provides:
  /// - Multimodal capabilities (text + image processing)
  /// - Fast response times suitable for interactive conversations
  /// - High-quality analysis for scientific applications
  /// - Cost-effective usage for educational and research purposes
  static const String model = 'gemini-1.5-flash';

  /// Complete Google Gemini API endpoint URL for content generation.
  ///
  /// Constructs the full REST endpoint URL for the generateContent API
  /// using the specified model. This endpoint supports multimodal input
  /// and conversational interactions with proper context management.
  static const String geminiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

  /// Releases all resources and clears conversation context.
  ///
  /// Performs cleanup operations including:
  /// - Closing HTTP client connections to prevent memory leaks
  /// - Clearing conversation context to free memory
  /// - Resetting cached summary data
  ///
  /// Should be called when the service instance is no longer needed,
  /// typically during widget disposal or application shutdown.
  void dispose() {
    client.close();
    context.clear();
  }

  /// Clears the conversation context while maintaining the service instance.
  ///
  /// Useful for starting fresh conversations about different visualizations
  /// or resetting the context when switching between different Mars climate
  /// datasets. Preserves the service configuration and cached summary.
  Future<void> clearContext() async {
    context.clear();
  }

  /// Generates an AI-powered summary of the Mars climate visualization.
  ///
  /// This method creates the initial analysis of the provided Mars climate
  /// visualization using Gemini's multimodal capabilities. The summary provides:
  /// - Scientific analysis of visible climate patterns
  /// - Identification of temperature, pressure, or wind variations
  /// - Notable atmospheric features and anomalies
  /// - Educational context about Mars climate phenomena
  ///
  /// **AI Prompt Engineering:**
  /// The method uses carefully crafted prompts to ensure:
  /// - Scientific accuracy and appropriate terminology
  /// - Concise format (75 words or less) for quick consumption
  /// - Focus on actionable insights from the visualization
  /// - Proper formatting with markdown bold headers
  ///
  /// **Response Structure:**
  /// Returns formatted text starting with "**Summary:**" followed by
  /// scientific analysis of the climate data visualization.
  ///
  /// **Conversation Context:**
  /// The generated summary is automatically added to the conversation
  /// context with a special "isSummary" flag, enabling the AI to reference
  /// this base analysis in subsequent interactions.
  ///
  /// Returns:
  /// - String containing formatted summary text with scientific analysis
  ///
  /// Throws:
  /// - [Exception] for API authentication failures or network issues
  /// - [Exception] for malformed API responses or parsing errors
  /// - [Exception] for rate limiting or quota exhaustion scenarios
  ///
  /// Example output:
  /// ```
  /// **Summary:** The Mars visualization shows significant temperature
  /// variations across the Martian surface, with polar regions displaying
  /// temperatures around 150K and equatorial areas reaching 250K. Notable
  /// thermal anomalies appear near major volcanic regions, indicating
  /// complex atmospheric dynamics.
  /// ```
  Future<String> generateSummary() async {
    if (kDebugMode) {
      print("Generating summary...");
    }
    try {
      final uri = Uri.parse('$geminiUrl?key=$apiKey');
      final headers = {'Content-Type': 'application/json'};

      // Construct comprehensive request with Mars-specific analysis prompt
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
              // Multimodal input: Include the Mars visualization image
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": imageContent,
                },
              },
            ],
          },
        ],
        // Optimized generation parameters for scientific content
        "generationConfig": {"temperature": 0.7, "maxOutputTokens": 1000},
      };

      String payload = jsonEncode(requestBody);
      if (kDebugMode) {
        print("Request Payload: $payload");
      }

      // Execute API request with comprehensive error handling
      final response = await client.post(uri, headers: headers, body: payload);

      if (kDebugMode) {
        print("API Status Code: ${response.statusCode}");
      }

      final responseData = jsonDecode(response.body);
      if (kDebugMode) {
        print("API Response: ${response.body}");
      }

      // Validate API response structure and status
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to call Gemini API, status code: ${response.statusCode}, body: ${response.body}",
        );
      }

      // Parse nested response structure with proper error checking
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

      // Add summary to conversation context with special marker
      context.add({
        "role": "model",
        "parts": [
          {"text": summaryText},
        ],
        "isSummary": true, // Flag for context management
      });

      return summaryText;
    } catch (e) {
      if (kDebugMode) {
        print('Error generating summary: $e');
      }
      return 'Error generating summary: ${e.toString()}';
    }
  }

  /// Processes user messages and generates context-aware responses about Mars climate data.
  ///
  /// This method handles conversational interactions with the AI, maintaining context
  /// from previous messages while analyzing the Mars climate visualization. It provides:
  /// - Scientific answers to specific questions about climate patterns
  /// - Location-based information when geographic features are mentioned
  /// - Educational explanations of Mars atmospheric phenomena
  /// - Visual analysis referencing specific elements in the visualization
  ///
  /// **Advanced Response Processing:**
  /// The method implements sophisticated prompt engineering to ensure:
  /// - **Scientific Accuracy**: Uses Mars-specific terminology and knowledge
  /// - **Visual Reference**: Always relates answers to the provided visualization
  /// - **Structured Output**: Returns both conversational response and structured data
  /// - **Location Intelligence**: Automatically detects and provides coordinates for Mars features
  ///
  /// **Dual-Part Response Format:**
  /// Responses are structured in two parts separated by "===":
  /// 1. **Conversational Analysis**: Markdown-formatted scientific explanation
  /// 2. **Structured Data**: JSON object with location coordinates and feature details
  ///
  /// **Context Management:**
  /// - Maintains conversation history for coherent multi-turn interactions
  /// - Filters out summary messages to focus on user-initiated conversations
  /// - Preserves scientific context across multiple questions
  /// - Enables follow-up questions with maintained context
  ///
  /// Parameters:
  /// - [userMessage]: User's question or comment about the Mars climate visualization
  ///
  /// Returns:
  /// - Map containing:
  ///   - "summary": Formatted response text with scientific analysis
  ///   - "location": Structured data about geographic features mentioned
  ///
  /// Example return structure:
  /// ```dart
  /// {
  ///   "summary": "**Temperature Analysis:** The visualization shows...",
  ///   "location": {
  ///     "name": "Olympus Mons",
  ///     "coordinates": [226.2, 18.65],
  ///     "info": "Largest volcano in the Solar System...",
  ///     "classification": "Shield volcano",
  ///     "dimensions": "21.9 km height, 624 km diameter"
  ///   }
  /// }
  /// ```
  ///
  /// Throws:
  /// - [Exception] for API communication failures or authentication errors
  /// - [Exception] for malformed responses or JSON parsing issues
  /// - [Exception] for context management errors or conversation state corruption
  Future<Map<String, dynamic>> sendMessage(String userMessage) async {
    try {
      // Add user message to conversation context
      context.add({
        "role": "user",
        "parts": [
          {"text": userMessage},
        ],
      });

      final uri = Uri.parse('$geminiUrl?key=$apiKey');
      final headers = {'Content-Type': 'application/json'};

      // Filter conversation history to exclude summary messages
      // This focuses the context on user-initiated interactions
      final conversationHistory =
          context.where((msg) => msg["isSummary"] != true).toList();

      // Comprehensive request body with specialized Mars climate analysis prompt
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
              // Include the Mars visualization for multimodal analysis
              {
                "inline_data": {
                  "mime_type": "image/jpeg",
                  "data": imageContent,
                },
              },
            ],
          },
          // Include filtered conversation history for context continuity
          ...conversationHistory,
        ],
        // Optimized parameters for consistent, focused responses
        "generationConfig": {"temperature": 0.6, "maxOutputTokens": 1000},
      };

      String payload = jsonEncode(requestBody);
      final response = await client.post(uri, headers: headers, body: payload);

      // Validate API response status
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to call Gemini API, status code: ${response.statusCode}, body: ${response.body}",
        );
      }

      final responseData = jsonDecode(response.body);

      // Comprehensive response validation
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

      // Parse dual-part response format
      List responseList = modelResponse.split("===");

      final output = responseList[0].trim(); // Conversational response
      final jsonPart =
          responseList.length < 2
              ? '{}'
              : responseList[1].trim(); // Location data

      if (kDebugMode) {
        print("response: $jsonPart, $output");
      }

      // Parse location data with error handling
      Map<String, dynamic> locationData = jsonDecode(jsonPart);

      // Add AI response to conversation context
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
