import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/entities/balloon_entity.dart';
import 'package:martian_climate_dashboard/entities/saved_session.dart';
import 'package:martian_climate_dashboard/enums/ballon_type.dart';
import 'package:martian_climate_dashboard/enums/colomap.dart';
import 'package:martian_climate_dashboard/services/api_service.dart';
import 'package:martian_climate_dashboard/services/balloon_service.dart';
import 'package:martian_climate_dashboard/services/gemini_service.dart';
import 'package:martian_climate_dashboard/services/kml_generatation_service.dart';
import 'package:martian_climate_dashboard/services/tour_service.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/utils/mars_facts.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';
import 'package:martian_climate_dashboard/widgets/dots_indicator.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The main visualization interface for Mars climate data analysis and AI-powered exploration.
///
/// This page serves as the primary interaction hub for visualized Mars climate data,
/// providing a comprehensive interface that combines:
/// - Real-time AI-powered climate data analysis via Gemini API
/// - Interactive chat interface for asking questions about Mars climate patterns
/// - Temporal navigation for date-range visualizations
/// - Liquid Galaxy orbit controls for immersive 3D exploration
/// - Automatic session saving for workflow continuity
/// - Location-based information balloons triggered by AI responses
///
/// The page integrates multiple services to create a seamless experience:
/// - **GeminiService**: AI-powered conversation and image analysis
/// - **BalloonService**: KML balloon generation for Liquid Galaxy
/// - **LgService**: Remote control of Liquid Galaxy system
/// - **ApiService**: Mars Climate Database integration
/// - **KmlGenerationService**: Geographic visualization generation
///
/// Key workflows:
/// 1. **Initial Load**: Generates AI summary of visualization and displays balloon
/// 2. **Chat Interaction**: Processes user questions with context-aware responses
/// 3. **Temporal Navigation**: Updates visualizations for different dates
/// 4. **Location Discovery**: Shows Mars features mentioned in conversations
/// 5. **Session Management**: Automatically saves conversation context
///
/// Example usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (context) => VisualizationPage(
///       base64Image: encodedVisualization,
///       apiEntity: climateDataConfig,
///       colorMap: ColorMap.temperature,
///     ),
///   ),
/// );
/// ```
class VisualizationPage extends StatefulWidget {
  /// Base64-encoded preview image of the Mars climate visualization.
  ///
  /// Used for AI analysis and quick reference. This image provides
  /// visual context for the Gemini AI to generate meaningful summaries
  /// and answer user questions about climate patterns.
  final String base64Image;

  /// Complete API configuration entity containing all visualization parameters.
  ///
  /// Includes climate variable, date range, geographic bounds, and display
  /// options. Used for regenerating visualizations during temporal navigation
  /// and maintaining session context.
  final ApiEntity apiEntity;

  /// Color mapping scheme used for the current visualization.
  ///
  /// Determines the color gradient applied to climate data values.
  /// Consistent with the color scheme used in KML generation and
  /// balloon displays for visual coherence.
  final ColorMap colorMap;

  /// Creates a visualization page with AI-powered analysis capabilities.
  ///
  /// Parameters:
  /// - [base64Image]: Encoded visualization image for AI analysis
  /// - [apiEntity]: Complete climate data configuration
  /// - [colorMap]: Color scheme for consistent visual presentation
  const VisualizationPage({
    super.key,
    required this.base64Image,
    required this.apiEntity,
    required this.colorMap,
  });

  @override
  State<VisualizationPage> createState() => _VisualizationPageState();
}

/// State management for the visualization page's complex interactive features.
///
/// Handles the complete lifecycle of AI-powered Mars climate exploration:
/// - Service initialization and API key validation
/// - Real-time conversation management with context preservation
/// - Temporal navigation with automatic visualization updates
/// - Location-based feature discovery and balloon deployment
/// - Session persistence for workflow continuity
/// - Loading state management with educational content
class _VisualizationPageState extends State<VisualizationPage> {
  /// AI service instance for intelligent climate data analysis.
  ///
  /// Configured with the visualization image and maintains conversation
  /// context throughout the user session. Handles both initial summary
  /// generation and ongoing conversational interactions.
  late GeminiService geminiService;

  /// Text controller for the chat input field.
  ///
  /// Manages user message input with proper text editing capabilities
  /// including submission handling and field clearing after send.
  TextEditingController msgController = TextEditingController();

  /// Whether temporal navigation visualization update is in progress.
  ///
  /// Tracks date change operations that require fetching new climate data,
  /// generating updated KML visualizations, and deploying to Liquid Galaxy.
  /// Prevents concurrent update operations.
  bool _isLoading = false;

  /// Whether the AI is currently processing a user message.
  ///
  /// Shows loading indicators and prevents multiple simultaneous requests
  /// to the Gemini API. Includes "thinking" animation while processing.
  bool _isWaitingForResponse = false;

  /// Random number generator for selecting educational Mars facts.
  ///
  /// Used during loading periods to display random educational content
  /// about Mars, keeping users engaged during processing delays.
  final random = Random();

  /// Current date being visualized (for temporal navigation).
  ///
  /// Tracks the active date when date-range visualization is enabled.
  /// Updated during next/previous date navigation and used for display
  /// and boundary checking.
  late DateTime? currentDate;

  /// Service for managing KML balloon deployments to Liquid Galaxy.
  ///
  /// Handles both AI-generated summary balloons and location-specific
  /// information balloons triggered by user conversations.
  late BalloonService balloonService;

  /// Gemini API key loaded from SharedPreferences.
  ///
  /// Required for AI functionality. If null, the page displays an
  /// API key configuration prompt instead of the chat interface.
  String? apiKey;

  @override
  void initState() {
    super.initState();
    // Initialize current date from API entity
    currentDate = widget.apiEntity.date;
    // Start asynchronous service initialization
    initialize();
  }

  @override
  void dispose() {
    // Save current session before disposing (only if AI is configured)
    if (apiKey != null) {
      if (kDebugMode) {
        print('Saving session with ${geminiService.context.length} messages');
      }

      // Persist complete session including conversation context
      SavedSession.saveSessions(
        SavedSession(
          imageBase64: widget.base64Image,
          apiEntity: widget.apiEntity,
          context: geminiService.context,
        ),
      );

      // Clean up AI service resources
      geminiService.dispose();
    }

    // Clean up text controller
    msgController.dispose();
    super.dispose();
  }

  /// Initializes all required services and generates initial AI summary.
  ///
  /// This method orchestrates the complete setup process:
  /// 1. **API Key Loading**: Retrieves Gemini API key from storage
  /// 2. **Service Configuration**: Initializes GeminiService and BalloonService
  /// 3. **Summary Generation**: Creates AI-powered visualization analysis
  /// 4. **Balloon Deployment**: Displays summary balloon on Liquid Galaxy
  /// 5. **Error Handling**: Provides user feedback for configuration issues
  ///
  /// The method gracefully handles missing API keys by showing configuration
  /// prompts and handles network/API errors with user-friendly messages.
  Future<void> initialize() async {
    // Load API key from persistent storage
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('api_key');
    });

    // Show configuration prompt if API key is missing
    if (apiKey == null) {
      setState(() {
        _isWaitingForResponse = false;
      });
      return;
    }

    // Initialize AI service with visualization image
    geminiService = GeminiService(
      apiKey: apiKey!,
      imageContent: widget.base64Image,
    );

    // Initialize balloon service for LG integration
    balloonService = BalloonService(
      BalloonEntity(
        type: BalloonType.info,
        colorMap: ColorMap.redyellowgreenblue,
        apiEntity: widget.apiEntity,
      ),
    );

    // Show loading state during summary generation
    setState(() {
      _isWaitingForResponse = true;
    });

    try {
      // Generate AI-powered summary of the visualization
      String response = await geminiService.generateSummary();
      if (kDebugMode) {
        print(
          'Generated summary: ${response.substring(0, min(100, response.length))}...',
        );
      }

      // Deploy summary balloon to Liquid Galaxy
      await balloonService.showVisBalloon(
        // ignore: use_build_context_synchronously
        Provider.of<LgService>(context, listen: false),
        response,
        widget.colorMap,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error generating summary: $e');
      }

      // Provide user feedback for initialization errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating summary: ${e.toString()}')),
      );
    } finally {
      // Clear loading state regardless of success/failure
      setState(() {
        _isWaitingForResponse = false;
      });
    }
  }

  /// Advances to the next date in a date-range visualization sequence.
  ///
  /// This method handles temporal navigation for date-range enabled visualizations:
  /// 1. **Date Validation**: Ensures next date is within allowed range
  /// 2. **Data Fetching**: Retrieves climate data for the new date
  /// 3. **Visualization Generation**: Creates updated KML with same parameters
  /// 4. **LG Deployment**: Updates the Liquid Galaxy display
  /// 5. **AI Context Update**: Regenerates summary for new date
  /// 6. **Balloon Update**: Shows updated summary balloon
  ///
  /// The method preserves all original visualization parameters (color scheme,
  /// grid settings, etc.) while updating only the temporal component.
  ///
  /// Features comprehensive error handling for network failures, API limits,
  /// and KML generation issues with user-friendly feedback messages.
  Future<void> _buildNextDate() async {
    // Only proceed if date range navigation is enabled
    if (!widget.apiEntity.dateRangeEnabled) return;

    try {
      final nextDate = currentDate!.add(const Duration(days: 1));

      // Show loading overlay with educational content
      setState(() {
        _isLoading = true;
      });

      // Create updated API entity with new date
      ApiEntity apiEntity = widget.apiEntity.copyWith(date: nextDate);

      // Fetch climate data for new date
      ApiService apiService = ApiService();
      String data = await apiService.fetchData(apiEntity);

      // Generate KML with consistent color mapping
      final service = KmlGenerationService(
        input: data,
        interpFactor: 4, // Smooth interpolation
        skipFactor: 2, // Performance optimization
        colorMap:
            apiEntity.variable == 't'
                ? ColorMap
                    .redyellowgreenblue // Temperature colors
                : ColorMap.yelloworangered, // Generic parameter colors
      );
      String kml = (await service.generateKml())["kml"];

      // Deploy updated visualization to Liquid Galaxy
      // ignore: use_build_context_synchronously
      LgService lgService = Provider.of<LgService>(context, listen: false);
      await lgService.sendFile('/var/www/html/heatmap.kml', utf8.encode(kml));

      // Configure Mars environment
      await lgService.changeToMars();

      // Register heatmap for display
      await lgService.execCommand(
        'echo "http://lg1:81/heatmap.kml" > /var/www/html/kmls.txt',
      );

      // Add grid overlay if enabled
      if (widget.apiEntity.isGridEnabled) {
        await lgService.execCommand(
          'echo "http://lg1:81/grid.kml" >> /var/www/html/kmls.txt',
        );
      }

      // Update UI with new date
      setState(() {
        _isLoading = false;
        currentDate = nextDate;
      });

      // Update AI context and balloon for new date
      if (apiKey != null) {
        await geminiService.clearContext();
        String newSummary = await geminiService.generateSummary();
        await balloonService.showVisBalloon(
          // ignore: use_build_context_synchronously
          Provider.of<LgService>(context, listen: false),
          newSummary,
          widget.colorMap,
        );
      }
    } catch (e) {
      // Handle errors gracefully with user feedback
      setState(() {
        _isLoading = false;
      });
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating date: ${e.toString()}')),
      );
    }
  }

  /// Moves to the previous date in a date-range visualization sequence.
  ///
  /// Similar to [_buildNextDate] but navigates backward in time.
  /// Maintains the same workflow of data fetching, visualization generation,
  /// and AI context updates while moving to the previous day.
  ///
  /// Note: This method doesn't check lower date boundaries, allowing
  /// users to navigate back to the start date of their range.
  Future<void> _buildPrevDate() async {
    if (widget.apiEntity.dateRangeEnabled) {
      final prevDate = currentDate!.subtract(const Duration(days: 1));
      if (kDebugMode) {
        print('Navigating to previous date: ${prevDate.toIso8601String()}');
      }

      setState(() {
        _isLoading = true;
      });

      // Follow same workflow as next date but with previous date
      ApiEntity apiEntity = widget.apiEntity.copyWith(date: prevDate);
      ApiService apiService = ApiService();
      String data = await apiService.fetchData(apiEntity);

      final service = KmlGenerationService(
        input: data,
        interpFactor: 4,
        skipFactor: 2,
        colorMap:
            apiEntity.variable == 't'
                ? ColorMap.redyellowgreenblue
                : ColorMap.yelloworangered,
      );
      String kml = (await service.generateKml())["kml"];

      // ignore: use_build_context_synchronously
      LgService lgService = Provider.of<LgService>(context, listen: false);
      await lgService.sendFile('/var/www/html/heatmap.kml', utf8.encode(kml));

      await lgService.changeToMars();

      await lgService.execCommand(
        'echo "http://lg1:81/heatmap.kml" > /var/www/html/kmls.txt',
      );
      if (widget.apiEntity.isGridEnabled) {
        await lgService.execCommand(
          'echo "http://lg1:81/grid.kml" >> /var/www/html/kmls.txt',
        );
      }

      setState(() {
        _isLoading = false;
        currentDate = prevDate;
      });
    }
  }

  /// Processes user messages through the AI conversation system.
  ///
  /// This method handles the complete conversational workflow:
  /// 1. **Input Validation**: Ensures API key is configured and message is valid
  /// 2. **Context Management**: Maintains conversation history for coherent responses
  /// 3. **AI Processing**: Sends message to Gemini with visualization context
  /// 4. **Location Detection**: Identifies Mars locations mentioned in responses
  /// 5. **Balloon Deployment**: Shows location-specific information balloons
  /// 6. **Camera Control**: Navigates Liquid Galaxy to mentioned locations
  /// 7. **Error Handling**: Provides feedback for API failures or network issues
  ///
  /// The method supports both general questions about Mars climate and specific
  /// location queries, automatically detecting when location information should
  /// be displayed on the Liquid Galaxy system.
  ///
  /// Parameters:
  /// - [text]: User's message text to be processed by the AI
  ///
  /// Example responses that trigger location balloons:
  /// - "Tell me about Olympus Mons temperature"
  /// - "What's the weather like at Valles Marineris?"
  /// - "Show me the polar ice caps"
  void _sendMessage(String text) async {
    // Require API key for AI functionality
    if (apiKey == null) return;

    // Clear input and show processing state
    setState(() {
      msgController.clear();
      _isWaitingForResponse = true;
    });

    try {
      // Process message through AI with full context
      final response = await geminiService.sendMessage(text);

      // Handle location-specific responses
      if (!response['location'].isEmpty) {
        try {
          if (kDebugMode) {
            print('Location detected: ${response['location']['name']}');
          }

          // Deploy location balloon to Liquid Galaxy
          // ignore: use_build_context_synchronously
          LgService lgService = Provider.of<LgService>(context, listen: false);
          BalloonService.showLocationBalloon(
            lgService,
            response['location']['info'],
            response['location']['name'],
            response['location']['coordinates'],
          );

          // Navigate to location coordinates
          await lgService.execCommand(
            'echo "flytoview=<LookAt><longitude>${response['location']['coordinates'][0]}</longitude><latitude>${response['location']['coordinates'][1]}</latitude><range>3529400.3297285</range><tilt>0</tilt><heading>0</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>" > /tmp/query.txt',
          );
        } catch (e) {
          if (kDebugMode) {
            print('Error showing location balloon: $e');
          }
        }
      }

      setState(() {
        _isWaitingForResponse = false;
      });
    } catch (e) {
      // Handle API errors gracefully
      setState(() {
        _isWaitingForResponse = false;
      });

      if (kDebugMode) {
        print('Chat error: $e');
      }

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  /// Stops any active orbital tour animation on the Liquid Galaxy system.
  ///
  /// Sends a command to immediately halt orbital camera movement,
  /// returning control to manual navigation. Useful when users want
  /// to stop automated tours to examine specific features.
  Future<void> _stopOrbit() async {
    LgService lgService = Provider.of<LgService>(context, listen: false);
    await lgService.execCommand('echo "exittour=true" > /tmp/query.txt');
  }

  /// Initiates an orbital tour around Mars following the prime meridian.
  ///
  /// Creates and deploys a KML tour that smoothly orbits around Mars,
  /// providing an immersive overview of the climate visualization.
  /// The orbit follows the prime meridian (0° longitude) for consistent
  /// geographic reference during the automated tour.
  ///
  /// Workflow:
  /// 1. Generate prime meridian orbit KML tour
  /// 2. Deploy tour file to Liquid Galaxy web server
  /// 3. Register tour in the KML playlist
  /// 4. Start tour playback with named tour reference
  Future<void> _startOrbit() async {
    LgService lgService = Provider.of<LgService>(context, listen: false);

    // Generate orbital tour KML
    String kmlData = KmlService.generatePrimeMeridianOrbit();
    await lgService.sendFile('/var/www/html/orbit.kml', utf8.encode(kmlData));

    // Register tour for display
    await lgService.execCommand(
      'echo "http://lg1:81/orbit.kml" >> /var/www/html/kmls.txt',
    );

    // Start tour playback
    await lgService.execCommand('echo "playtour=Orbit" > /tmp/query.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Navigation drawer for additional app features
      drawer: MCDDrawer(),

      /// Standard app bar with application title
      appBar: AppBar(title: const Text('Mars Vision')),

      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                /// Visualization title with parameter name
                Text(
                  '${parameterMap[widget.apiEntity.variable] ?? "Temperature"} Visualization',
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                /// Current date display with formatted presentation
                Text(
                  (() {
                    const monthNames = [
                      'January',
                      'February',
                      'March',
                      'April',
                      'May',
                      'June',
                      'July',
                      'August',
                      'September',
                      'October',
                      'November',
                      'December',
                    ];
                    return '${monthNames[currentDate!.month - 1]} ${currentDate!.day}, ${currentDate!.year}';
                  })(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),

                /// Main content area: Chat interface or API key prompt
                Expanded(
                  child:
                      apiKey == null
                          ? const Center(
                            child: Text(
                              "API key required, please configure it.",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                          : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount:
                                geminiService.context.length +
                                (_isWaitingForResponse ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show loading indicator at end during AI processing
                              if (index == geminiService.context.length &&
                                  _isWaitingForResponse) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 12,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.7,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 3),
                                        const Text("Thinking "),
                                        JumpingDots(
                                          color: Colors.black54,
                                          radius: 4,
                                          numberOfDots: 3,
                                          animationDuration: const Duration(
                                            milliseconds: 200,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // Render conversation messages
                              final message = geminiService.context[index];
                              final isUser = message['role'] == 'user';

                              final messageText =
                                  message['parts'] != null &&
                                          message['parts'].isNotEmpty &&
                                          message['parts'][0]['text'] != null
                                      ? message['parts'][0]['text']
                                      : "Empty message";

                              return Align(
                                alignment:
                                    isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 12,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        isUser
                                            ? Colors.grey[200]
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  child: MarkdownBody(data: messageText),
                                ),
                              );
                            },
                          ),
                ),

                /// Chat input area with send button and options menu
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      /// Text input field for user messages
                      Expanded(
                        child: TextField(
                          controller: msgController,
                          decoration: const InputDecoration(
                            fillColor: Colors.white24,
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(
                                Radius.circular(8),
                              ),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (text) {
                            if (text.trim().isEmpty) return;
                            _sendMessage(text);
                          },
                        ),
                      ),

                      /// Send message button
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          final text = msgController.text;
                          if (text.trim().isEmpty) return;
                          _sendMessage(text);
                          FocusScope.of(context).unfocus();
                        },
                      ),

                      /// Options menu with orbit controls and temporal navigation
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz),
                        tooltip: "More options",
                        offset: const Offset(0, -120),
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              /// Stop orbital tour option
                              PopupMenuItem<String>(
                                value: 'stop_orbit',
                                onTap: () async => await _stopOrbit(),
                                child: const ListTile(
                                  leading: Icon(Icons.stop),
                                  title: Text('Stop Orbit'),
                                ),
                              ),

                              /// Start orbital tour option
                              PopupMenuItem<String>(
                                value: 'start_orbit',
                                onTap: () async => await _startOrbit(),
                                child: const ListTile(
                                  leading: Icon(Icons.track_changes),
                                  title: Text('Start Orbit'),
                                ),
                              ),

                              /// Next date navigation (only for date-range visualizations)
                              if (widget.apiEntity.dateRangeEnabled)
                                PopupMenuItem<String>(
                                  value: 'next_date',
                                  onTap: () async => await _buildNextDate(),
                                  child: ListTile(
                                    enabled: currentDate!.isBefore(
                                      widget.apiEntity.toDate!,
                                    ),
                                    leading: const Icon(Icons.arrow_forward),
                                    title: const Text('Next Date'),
                                  ),
                                ),

                              /// Previous date navigation (only for date-range visualizations)
                              if (widget.apiEntity.dateRangeEnabled)
                                PopupMenuItem<String>(
                                  value: 'prev_date',
                                  onTap: () async => await _buildPrevDate(),
                                  child: const ListTile(
                                    leading: Icon(Icons.arrow_back),
                                    title: Text('Previous Date'),
                                  ),
                                ),
                            ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          /// Loading overlay for temporal navigation operations
          if (_isLoading)
            Container(
              /// Semi-transparent overlay preventing user interaction
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.05),
              width: MediaQuery.of(context).size.width,
              height: double.infinity,
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.8,
                  ),
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 32.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          /// Circular progress indicator
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                              strokeWidth: 5,
                            ),
                          ),
                          const SizedBox(height: 20),

                          /// Loading status message
                          const Text(
                            'Generating Visualization...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),

                          /// Educational Mars fact during loading
                          Text(
                            facts[random.nextInt(facts.length)],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
