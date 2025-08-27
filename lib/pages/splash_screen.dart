import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A splash screen widget that displays the application logo while performing initialization tasks.
///
/// This screen serves as the entry point for the Martian Climate Dashboard application,
/// providing a branded loading experience while essential background operations complete.
/// It displays organizational logos and performs critical initialization tasks including:
///
/// - Loading saved Liquid Galaxy connection parameters
/// - Testing existing LG connections in the background
/// - Providing a professional branded experience during app startup
/// - Ensuring smooth transition to the main application interface
///
/// The splash screen duration is fixed at 5 seconds, providing sufficient time for
/// initialization while maintaining a professional appearance. After the delay,
/// users are automatically navigated to the home page regardless of connection status.
///
/// Example usage:
/// ```dart
/// // Typically set as the initial route in main.dart
/// MaterialApp(
///   initialRoute: '/splash',
///   routes: {
///     '/splash': (context) => const SplashScreen(),
///     '/home': (context) => const HomePage(),
///   },
/// );
/// ```
class SplashScreen extends StatefulWidget {
  /// Creates a splash screen with automatic initialization and navigation.
  ///
  /// This stateful widget manages the initialization sequence and provides
  /// visual feedback during the app's startup process.
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

/// State class managing splash screen timing and background initialization tasks.
///
/// Coordinates the following initialization sequence:
/// 1. **Visual Display**: Shows branded logo immediately
/// 2. **Delayed Navigation**: Schedules automatic transition to home page
/// 3. **Background Loading**: Loads saved Liquid Galaxy connection parameters
/// 4. **Connection Testing**: Validates existing LG connections asynchronously
///
/// All initialization tasks run in parallel to minimize startup time while
/// ensuring the splash screen remains visible for the full branded experience.
class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Schedule automatic navigation to home page after splash duration
    _scheduleNavigation();

    // Initialize background services after the widget tree is built
    _initializeServices();
  }

  /// Schedules automatic navigation to the home page after a fixed delay.
  ///
  /// Uses a 5-second delay to provide sufficient time for users to see the
  /// branded splash screen and for background initialization to complete.
  /// The navigation uses `pushReplacementNamed` to prevent users from
  /// navigating back to the splash screen.
  ///
  /// Note: The `use_build_context_synchronously` warning is suppressed as
  /// this is a controlled delay within the widget's lifecycle and the
  /// context is guaranteed to be valid after the short delay.
  void _scheduleNavigation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        // ignore: use_build_context_synchronously
        Navigator.pushReplacementNamed(context, '/home');
      }
    });
  }

  /// Initializes background services after the widget framework is ready.
  ///
  /// Uses `addPostFrameCallback` to ensure the widget tree is fully built
  /// before accessing the Provider context and performing initialization.
  /// This prevents potential race conditions during app startup.
  ///
  /// The initialization sequence:
  /// 1. **SharedPreferences Access**: Gets the preferences instance
  /// 2. **Service Retrieval**: Accesses LgService from Provider context
  /// 3. **Data Loading**: Restores saved connection parameters
  /// 4. **Connection Testing**: Validates existing connections asynchronously
  ///
  /// All operations are non-blocking to maintain splash screen responsiveness.
  void _initializeServices() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        // Access SharedPreferences for loading saved connection data
        final prefs = SharedPreferences.getInstance();

        // Get LgService instance from Provider without triggering rebuilds
        final lgService = Provider.of<LgService>(context, listen: false);

        // Load previously saved Liquid Galaxy connection parameters
        // This includes host, port, username, password, and screen count
        await lgService.loadSavedData(prefs);

        // Test the loaded connection in the background
        // Results are stored in lgService.connected but don't block navigation
        lgService.checkConnection();
      } catch (e) {
        // Silently handle initialization errors to prevent splash screen crashes
        // Errors will be handled gracefully in the main application
        debugPrint('Splash initialization error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      /// Clean white background for professional appearance
      backgroundColor: Colors.white,

      /// Centered logo display as the primary visual element
      body: Center(
        child: Image(
          /// Organizational logos including GSoC, Liquid Galaxy, and project branding
          /// This asset contains partner logos and provides institutional recognition
          image: AssetImage('assets/Logos.png'),

          /// Note: Consider adding explicit dimensions and error handling:
          /// height: 300,
          /// fit: BoxFit.contain,
          /// errorBuilder: (context, error, stackTrace) =>
          ///   const Text('Martian Climate Dashboard'),
        ),
      ),
    );
  }
}
