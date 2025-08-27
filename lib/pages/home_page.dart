import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/entities/saved_session.dart';
import 'package:martian_climate_dashboard/enums/colomap.dart';
import 'package:martian_climate_dashboard/pages/visualization_page.dart';
import 'package:martian_climate_dashboard/services/api_service.dart';
import 'package:martian_climate_dashboard/services/kml_generatation_service.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/utils/atmos_map.dart';
import 'package:martian_climate_dashboard/utils/mars_facts.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';
import 'package:martian_climate_dashboard/utils/quickly_visualize_data.dart';
import 'package:martian_climate_dashboard/widgets/button.dart';
import 'package:martian_climate_dashboard/widgets/check_box.dart';
import 'package:martian_climate_dashboard/widgets/date_picker.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
import 'package:martian_climate_dashboard/widgets/parameter_picker.dart';
import 'package:martian_climate_dashboard/widgets/visualization_card.dart';
import 'package:provider/provider.dart';

/// The main application page for configuring and generating Mars climate visualizations.
///
/// This page serves as the primary interface for the Martian Climate Dashboard, providing
/// comprehensive controls for selecting Mars climate parameters, dates, and visualization
/// options. It integrates with the Mars Climate Database (MCD) API to fetch real-time
/// atmospheric data and renders visualizations on connected Liquid Galaxy systems.
///
/// Features:
/// - Parameter selection (temperature, pressure, wind speed, etc.)
/// - Mars atmospheric scenario configuration
/// - Date and date range selection
/// - Grid overlay and visualization options
/// - Quick access to predefined visualizations
/// - Recently viewed visualizations history
/// - Real-time progress tracking with Mars facts
/// - Cancellable operations for better UX
///
/// The page follows a workflow of: Configure → Fetch Data → Generate KML → Display on LG
///
/// Example usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const HomePage()),
/// );
/// ```
class HomePage extends StatefulWidget {
  /// Creates the main home page for Mars climate visualization configuration.
  ///
  /// This stateful widget manages user input for climate data parameters
  /// and coordinates the visualization generation pipeline.
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

/// State class managing the home page's interactive controls and data flow.
///
/// Handles the complete workflow from user input to Liquid Galaxy visualization:
/// 1. User configuration (parameters, dates, options)
/// 2. API data fetching from Mars Climate Database
/// 3. KML generation for geographic visualization
/// 4. Liquid Galaxy deployment and display
/// 5. Navigation to detailed visualization page
class _HomePageState extends State<HomePage> {
  /// Whether date range visualization is enabled.
  ///
  /// When true, allows users to select both start and end dates for
  /// temporal climate data analysis over extended periods.
  bool isDateRangeEnabled = false;

  /// Whether grid overlay should be displayed on visualizations.
  ///
  /// When true, adds coordinate grid lines to the Mars surface
  /// visualization for improved geographic reference.
  bool isGridEnabled = false;

  /// Loading state indicator for async operations.
  ///
  /// Tracks whether the app is currently processing user requests
  /// (fetching data, generating KML, or deploying to Liquid Galaxy).
  bool _isLoading = false;

  /// Selected start date for climate data visualization.
  ///
  /// Stores the user's selected date in ISO 8601 string format.
  /// This date determines the temporal focus of the climate data.
  String? date;

  /// Selected end date for date range visualizations.
  ///
  /// Only used when [isDateRangeEnabled] is true. Defines the end
  /// boundary for temporal climate data analysis.
  String? toDate;

  /// Currently selected climate parameter for visualization.
  ///
  /// Defaults to 't' (temperature). Other options include 'p' (pressure),
  /// wind components, and other Mars atmospheric variables.
  /// Maps to parameter codes used by the Mars Climate Database API.
  String selectedParameter = 't';

  /// Selected Mars atmospheric scenario for modeling.
  ///
  /// Determines which Mars year and atmospheric conditions to use
  /// for climate modeling. Defaults to 'Martian Year 35'.
  String selectedAtmosScenario = 'Martian Year 35';

  /// Random number generator for selecting loading facts.
  ///
  /// Used to display random Mars facts during data processing
  /// to keep users engaged during loading periods.
  final random = Random();

  /// Cancellable operation handle for async tasks.
  ///
  /// Allows users to cancel ongoing data fetching or visualization
  /// generation operations, improving user experience and resource management.
  CancelableOperation<void>? _operation;

  /// List of recently visualized climate data sessions.
  ///
  /// Stores user's previous visualization configurations for quick
  /// re-access, loaded from persistent storage on app start.
  List<SavedSession> recentlyVisualized = [];

  /// Whether recent visualization data has been loaded from storage.
  ///
  /// Prevents multiple loading attempts of saved session data
  /// during widget lifecycle events.
  bool _isRecentItemsLoaded = false;

  /// Current progress percentage for ongoing operations.
  ///
  /// Ranges from 0-100 and tracks progress through the visualization
  /// pipeline: API fetch → KML generation → LG deployment → navigation.
  int _progress = 0;

  /// Current Mars fact displayed during loading operations.
  ///
  /// Randomly selected educational content about Mars to keep
  /// users engaged during data processing periods.
  String? _loadingFact;

  /// Updates the progress indicator with bounds checking.
  ///
  /// Ensures progress values stay within 0-100 range and updates
  /// the UI only if the widget is still mounted to prevent errors.
  ///
  /// Parameters:
  /// - [value]: Progress percentage (0-100)
  void _setProgress(int value) {
    if (!mounted) return;
    setState(() {
      _progress = value.clamp(0, 100).toInt();
    });
  }

  @override
  void initState() {
    super.initState();
    // Load previously saved visualization sessions
    _loadRecentSessions();
  }

  /// Loads recently visualized sessions from persistent storage.
  ///
  /// Retrieves saved user sessions to populate the "Recently Visualized"
  /// section, providing quick access to previous climate data configurations.
  /// Only loads data once per widget lifecycle to optimize performance.
  ///
  /// Sessions include visualization parameters, generated images, and
  /// conversation context for seamless session restoration.
  Future<void> _loadRecentSessions() async {
    if (_isRecentItemsLoaded) return;

    final sessions = await SavedSession.loadSessions();
    if (kDebugMode && sessions.isNotEmpty) {
      print('Loaded recent session: ${sessions[0].apiEntity.variable}');
    }

    if (mounted) {
      setState(() {
        recentlyVisualized = sessions;
        _isRecentItemsLoaded = true;
      });
    }
  }

  /// Starts a cancellable visualization generation task.
  ///
  /// Wraps the main [onSubmit] operation in a cancellable wrapper,
  /// allowing users to abort long-running operations. Handles proper
  /// cleanup of loading states when operations are cancelled.
  void startCancelableTask() {
    _operation = CancelableOperation.fromFuture(
      onSubmit(),
      onCancel: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _loadingFact = null;
          });
        }
      },
    );
  }

  /// Cancels any ongoing visualization generation task.
  ///
  /// Provides users with the ability to abort data fetching or
  /// visualization generation, particularly useful for slow network
  /// connections or when users change their mind about parameters.
  void stopTask() async {
    await _operation?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingFact = null;
      });
    }
  }

  /// Main method orchestrating the complete visualization generation workflow.
  ///
  /// Coordinates the following pipeline:
  /// 1. Input validation (dates, parameters)
  /// 2. API entity configuration with Mars-specific parameters
  /// 3. Data fetching from Mars Climate Database
  /// 4. Visualization generation and Liquid Galaxy deployment
  /// 5. Navigation to detailed visualization page
  ///
  /// Features comprehensive error handling for network issues,
  /// server errors, and user input validation problems.
  ///
  /// Progress tracking provides real-time feedback with Mars facts
  /// to maintain user engagement during processing.
  Future<void> onSubmit() async {
    // Validate required date selection
    if (date == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date.')));
      return;
    }

    // Validate date range configuration if enabled
    if (isDateRangeEnabled && toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a "to" date for the range.'),
        ),
      );
      return;
    }

    // Initialize loading state with random Mars fact
    setState(() {
      _isLoading = true;
      _progress = 0;
      _loadingFact = facts[random.nextInt(facts.length)];
    });
    _setProgress(5);

    if (kDebugMode) {
      print("Starting visualization generation process");
    }

    try {
      ApiService apiService = ApiService();
      _setProgress(10);

      // Configure API entity with comprehensive Mars climate parameters
      // These parameters match the Mars Climate Database API specification
      final apiEntity =
          ApiEntity()
            ..variable = selectedParameter
            ..datekeyhtml = 1
            ..ls =
                99.5 // Solar longitude
            ..localtime =
                DateTime.parse(date!).hour +
                DateTime.parse(date!).minute / 60 +
                DateTime.parse(date!).second / 3600
            ..year = DateTime.parse(date!).year
            ..month = DateTime.parse(date!).month
            ..day = DateTime.parse(date!).day
            ..hours = DateTime.parse(date!).hour
            ..minutes = DateTime.parse(date!).minute
            ..seconds = DateTime.parse(date!).second
            ..julian =
                2460847.0714930557 // Julian day number
            ..martianyear = 38
            ..sol =
                215 // Mars solar day
            ..latitude =
                "all" // Global latitude coverage
            ..longitude =
                "all" // Global longitude coverage
            ..altitude =
                10.0 // Altitude in kilometers
            ..zkey = 3
            ..spacecraft = "none"
            ..isfixedlt = "off"
            ..dust =
                "1" // Dust scenario
            ..hrkey = 1
            ..averaging = "off"
            ..dpi =
                80 // Visualization resolution
            ..islog = "off"
            ..colorm =
                "jet" // Color mapping scheme
            ..minval = ""
            ..maxval = ""
            ..proj =
                "cyl" // Cylindrical projection
            ..palt = null
            ..plon = null
            ..plat = null
            ..atomsScenario = selectedAtmosScenario
            ..date = DateTime.parse(date!)
            ..isGridEnabled = isGridEnabled
            ..dateRangeEnabled = isDateRangeEnabled
            ..toDate = isDateRangeEnabled ? DateTime.parse(toDate!) : null;

      _setProgress(25);

      // Fetch climate data from Mars Climate Database
      String data = await apiService.fetchData(apiEntity);
      _setProgress(60);

      // Extract base64-encoded visualization image
      String imageBase64 = apiService.imageBase64;

      // Generate and deploy visualization to Liquid Galaxy
      await visualizeData(apiEntity, imageBase64, data: data);
      _setProgress(100);
    } catch (e) {
      // Handle specific network and API errors
      if (e is ClientException) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error: Could not connect to server'),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      // Clean up loading state regardless of success/failure
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingFact = null;
        });
      }
    }
  }

  /// Generates KML visualizations and deploys them to connected Liquid Galaxy systems.
  ///
  /// This method handles the complex process of converting Mars climate data into
  /// geographic visualizations suitable for immersive display. The workflow includes:
  ///
  /// 1. **Connection Validation**: Ensures Liquid Galaxy connectivity
  /// 2. **Color Map Selection**: Chooses appropriate colors based on data type
  /// 3. **KML Generation**: Creates geographic markup from climate data
  /// 4. **File Deployment**: Transfers visualization files to LG system
  /// 5. **Mars Environment Setup**: Configures LG to display Mars surface
  /// 6. **Optional Grid Overlay**: Adds coordinate grid if requested
  /// 7. **Navigation**: Transitions to detailed visualization interface
  ///
  /// Parameters:
  /// - [apiEntity]: Complete climate data configuration
  /// - [imageBase64]: Encoded preview image for the visualization
  /// - [data]: Optional raw climate data (fetched if not provided)
  ///
  /// Color mapping strategy:
  /// - Temperature ('t'): Blue-green-yellow-red gradient
  /// - Pressure ('p'): Red-yellow-green-blue gradient
  /// - Other parameters: Yellow-orange-red gradient
  ///
  /// Throws exceptions for connection failures, KML generation errors,
  /// or file deployment issues, which are handled by the calling method.
  Future<void> visualizeData(
    ApiEntity apiEntity,
    String imageBase64, {
    String? data,
  }) async {
    try {
      if (kDebugMode) {
        print("Starting visualization data processing");
      }

      // Access Liquid Galaxy service and validate connection
      LgService lgService = Provider.of<LgService>(context, listen: false);
      await lgService.checkConnection();
      if (!lgService.connected) {
        throw Exception('Not connected to the LG server');
      }
      _setProgress(65);

      // Select appropriate color mapping based on climate parameter
      ColorMap colorMap;
      if (apiEntity.variable == 't') {
        colorMap = ColorMap.bluegreenyellowred; // Temperature gradient
      } else if (apiEntity.variable == 'p') {
        colorMap = ColorMap.redyellowgreenblue; // Pressure gradient
      } else {
        colorMap = ColorMap.yelloworangered; // Generic parameter gradient
      }

      // Initialize KML generation service with interpolation settings
      final service = KmlGenerationService(
        input: data ?? await ApiService().fetchData(apiEntity),
        interpFactor: 4, // Interpolation smoothness
        skipFactor: 2, // Data point sampling rate
        colorMap: colorMap,
      );

      _setProgress(70);

      // Generate KML geographic markup from climate data
      String kml = (await service.generateKml())["kml"];
      _setProgress(80);

      // Deploy primary heatmap visualization to Liquid Galaxy
      await lgService.sendFile('/var/www/html/heatmap.kml', utf8.encode(kml));
      _setProgress(85);

      // Configure Liquid Galaxy environment for Mars visualization
      await lgService.changeToMars();
      _setProgress(90);

      // Register heatmap for display in LG system
      await lgService.execCommand(
        'echo "http://lg1:81/heatmap.kml" > /var/www/html/kmls.txt',
      );
      _setProgress(92);

      // Optional: Deploy coordinate grid overlay
      if (apiEntity.isGridEnabled) {
        String content = await rootBundle.loadString(
          'assets/kml/grid_overlay.kml',
        );
        await lgService.sendFile(
          '/var/www/html/grid.kml',
          utf8.encode(content),
        );
        _setProgress(94);

        // Add grid to display queue
        await lgService.execCommand(
          'echo "http://lg1:81/grid.kml" >> /var/www/html/kmls.txt',
        );
        _setProgress(96);

        // Set optimal viewing position for Mars with grid
        await lgService.execCommand(
          'echo "flytoview=<LookAt><longitude>0.0</longitude><latitude>0.0</latitude><range>3529400.3297285</range><tilt>0</tilt><heading>0</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>" > /tmp/query.txt',
        );
        _setProgress(98);
      }

      // Navigate to detailed visualization interface
      if (mounted) {
        _setProgress(99);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => VisualizationPage(
                  base64Image: imageBase64,
                  apiEntity: apiEntity,
                  colorMap: colorMap,
                ),
          ),
        );
      }
    } catch (e) {
      // Provide user feedback for visualization errors
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visualization error: ${e.toString()}')),
        );
      }
      rethrow; // Re-throw for upstream error handling
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Standard app bar with application title
      appBar: AppBar(title: const Text('Mars Vision')),

      /// Navigation drawer for additional app features
      drawer: MCDDrawer(),

      body: Stack(
        children: [
          /// Main content area with configuration controls
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                /// Scrollable configuration area
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        /// Section: Climate Parameter Configuration
                        const Text(
                          "Visualize Mars Conditions",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),

                        /// Climate parameter dropdown (temperature, pressure, etc.)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13.0),
                          child: ParameterPicker(
                            hintText: 'Select Parameter',
                            selectedParameter: selectedParameter,
                            parameters: parameterMap,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedParameter = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),

                        /// Mars atmospheric scenario selection
                        Padding(
                          padding: const EdgeInsets.all(13.0),
                          child: ParameterPicker(
                            hintText: 'Mars Atmospheric Scenario',
                            selectedParameter: selectedAtmosScenario,
                            parameters: atmosMap,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedAtmosScenario = value;
                                });
                              }
                            },
                          ),
                        ),

                        /// Section: Date Configuration
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 13.0),
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),

                        /// Dual date picker layout (start date and optional end date)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              /// Primary date picker (always enabled)
                              Expanded(
                                child: DatePicker(
                                  enabled: true,
                                  onDateSelected:
                                      (d) => setState(() {
                                        date = d.toIso8601String();
                                      }),
                                ),
                              ),
                              const SizedBox(width: 16),

                              /// Secondary date picker (enabled when range is selected)
                              Expanded(
                                child: DatePicker(
                                  enabled: isDateRangeEnabled,
                                  onDateSelected:
                                      (d) => setState(() {
                                        toDate = d.toIso8601String();
                                      }),
                                ),
                              ),
                            ],
                          ),
                        ),

                        /// Section: Visualization Options
                        const SizedBox(height: 20),

                        /// Date range visualization toggle
                        CheckBox(
                          onChange: (value) {
                            setState(() {
                              isDateRangeEnabled = value ?? false;
                            });
                          },
                          isChecked: isDateRangeEnabled,
                          text: "Visualize data over a date range",
                          isEnabled: true,
                        ),
                        const SizedBox(height: 7),

                        /// Grid overlay toggle
                        CheckBox(
                          onChange:
                              (value) => setState(() {
                                isGridEnabled = value ?? false;
                              }),
                          isChecked: isGridEnabled,
                          text: "Show grid lines",
                          isEnabled: true,
                        ),

                        /// Section: Quick Access Visualizations
                        const SizedBox(height: 10),
                        const Text(
                          "Quick Visualizations",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),

                        /// Predefined quick visualization cards
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: quicklyVisualizeData.length,
                          itemBuilder: (context, index) {
                            final item = quicklyVisualizeData[index];
                            return RecentVisualizationCard(
                              item: item,
                              onTap: () async {
                                // Handle quick visualization with progress tracking
                                setState(() {
                                  _isLoading = true;
                                  _progress = 0;
                                  _loadingFact =
                                      facts[random.nextInt(facts.length)];
                                });

                                try {
                                  await visualizeData(
                                    item.apiEntity,
                                    item.imageBase64,
                                  );
                                  _setProgress(100);
                                } catch (e) {
                                  if (kDebugMode) {
                                    print('Quick visualization error: $e');
                                  }
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                    _loadingFact = null;
                                  });
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),

                        /// Section: Recently Visualized (conditional display)
                        if (recentlyVisualized.isNotEmpty)
                          const Text(
                            "Recently Visualized",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (recentlyVisualized.isNotEmpty)
                          const SizedBox(height: 10),

                        /// Recent visualization history cards (max 5 items)
                        if (recentlyVisualized.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: min(recentlyVisualized.length, 5),
                            itemBuilder: (context, index) {
                              final item = recentlyVisualized[index];
                              return RecentVisualizationCard(
                                item: item,
                                onTap: () async {
                                  // Handle recent visualization restoration
                                  setState(() {
                                    _isLoading = true;
                                    _progress = 0;
                                    _loadingFact =
                                        facts[random.nextInt(facts.length)];
                                  });

                                  try {
                                    await visualizeData(
                                      item.apiEntity,
                                      item.imageBase64,
                                    );
                                    _setProgress(100);
                                  } catch (e) {
                                    if (kDebugMode) {
                                      print('Recent visualization error: $e');
                                    }
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                      _loadingFact = null;
                                    });
                                  }
                                },
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),

                /// Primary action button for visualization generation
                MCDButton(
                  onPressed: _isLoading ? null : startCancelableTask,
                  text: 'Visualize Data',
                ),
              ],
            ),
          ),

          /// Overlay: Loading progress dialog
          if (_isLoading)
            Container(
              // Semi-transparent overlay preventing interaction
              color: Colors.black.withOpacity(0.5),
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
                        vertical: 20.0,
                        horizontal: 32.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(height: 20),

                          /// Loading status text
                          const Text(
                            'Generating Visualization...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),

                          /// Progress percentage display
                          Text(
                            '$_progress% done',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 8),

                          /// Educational Mars fact display
                          Text(
                            _loadingFact ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),

                          /// Cancel operation button
                          TextButton(
                            onPressed: stopTask,
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
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
