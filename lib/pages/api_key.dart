import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// A settings page for managing the Gemini API key required for AI-powered Mars climate analysis.
///
/// This page provides a user interface for configuring the Google Gemini API key that enables
/// the application's intelligent climate data interpretation and chat functionality. The API
/// key is securely stored locally using SharedPreferences and is essential for generating
/// smart responses about Mars climate visualizations.
///
/// Features:
/// - Secure local storage of API keys
/// - Direct link to Google AI Studio for key generation
/// - Input validation and user feedback
/// - Loading states for better UX
///
/// Example usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const ApiKeyPage()),
/// );
/// ```
class ApiKeyPage extends StatefulWidget {
  /// Creates an API key configuration page.
  ///
  /// This stateful widget manages the user's Gemini API key configuration
  /// with persistent storage and validation.
  const ApiKeyPage({super.key});

  @override
  State<ApiKeyPage> createState() => _ApiKeyPageState();
}

/// State class managing API key input, validation, and persistence.
///
/// Handles the complete lifecycle of API key management including:
/// - Loading existing keys from storage
/// - User input and validation
/// - Secure storage operations
/// - User feedback and navigation
class _ApiKeyPageState extends State<ApiKeyPage> {
  /// Text controller for the API key input field.
  ///
  /// Manages the user's API key input with proper text editing capabilities.
  /// The controller is populated with any existing stored API key on page load.
  final TextEditingController controller = TextEditingController();

  /// Loading state indicator for async operations.
  ///
  /// Tracks whether the page is currently performing storage operations
  /// (loading or saving) to provide appropriate UI feedback and prevent
  /// multiple simultaneous operations.
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Load any existing API key when the page initializes
    _loadApiKey();
  }

  /// Loads the stored API key from SharedPreferences.
  ///
  /// Retrieves any previously saved Gemini API key from local storage
  /// and populates the input field. Shows loading state during the
  /// asynchronous storage operation.
  ///
  /// This method is called automatically when the page initializes,
  /// ensuring users see their current API key configuration.
  Future<void> _loadApiKey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Populate the text field with stored API key or empty string
      controller.text = prefs.getString("api_key") ?? '';
    } catch (e) {
      // Handle storage errors gracefully
      debugPrint('Error loading API key: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Saves the entered API key to SharedPreferences.
  ///
  /// Persists the user's Gemini API key to local storage for use across
  /// app sessions. Provides user feedback through SnackBar and automatically
  /// navigates back to the previous screen upon successful save.
  ///
  /// Shows loading state during the operation and handles errors gracefully.
  /// The API key is required for the application's AI-powered climate analysis
  /// features to function properly.
  Future<void> _saveApiKey() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Store the API key with a consistent key name
      await prefs.setString("api_key", controller.text.trim());

      setState(() {
        _isLoading = false;
      });

      // Show success feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('API Key saved successfully!'),
            duration: Duration(seconds: 2),
          ),
        );

        // Return to previous screen after successful save
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      // Show error feedback if save fails
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save API key: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Simple app bar with page title and back navigation
      appBar: AppBar(title: const Text('API Key')),

      body: Padding(
        /// Consistent padding for visual balance
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            /// Main content area with input field and instructions
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Section title for API key input
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      'Mars Climate Database API Key',
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  /// API key input field with info button
                  /// Includes direct link to Google AI Studio for key generation
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Enter API Key',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),

                      /// Info button linking to Google AI Studio
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.info_outline),
                        tooltip: 'Get API Key from Google AI Studio',
                        onPressed: () {
                          // Open Google AI Studio in browser for API key generation
                          launchUrl(
                            Uri.parse("https://aistudio.google.com/apikey"),
                            mode: LaunchMode.externalApplication,
                          );
                        },
                      ),
                    ),

                    /// Obscure the API key for security (optional)
                    // obscureText: true,
                  ),
                  const SizedBox(height: 16),

                  /// Instructional text explaining API key purpose and acquisition
                  const Text(
                    'Gemini API key is required to generate smart responses. '
                    'Visit the website by clicking the info icon to get the API key.',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),

            /// Save button at bottom of screen
            /// Full-width button with loading state support
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveApiKey,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : const Text(
                          'SAVE',
                          style: TextStyle(
                            fontSize: 16.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller to prevent memory leaks
    controller.dispose();
    super.dispose();
  }
}
