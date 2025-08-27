import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/widgets/button.dart';
import 'package:martian_climate_dashboard/widgets/input.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A configuration page for establishing SSH connections to Liquid Galaxy systems.
///
/// This page provides a comprehensive interface for connecting the Martian Climate Dashboard
/// to Liquid Galaxy installations. It supports both manual configuration and QR code scanning
/// for easy setup. All connection parameters are persistently stored and automatically
/// loaded on subsequent app launches.
///
/// Features:
/// - Manual SSH connection configuration (host, port, credentials)
/// - QR code scanning for rapid setup
/// - Persistent storage of connection settings
/// - Connection validation with user feedback
/// - Automatic logo deployment to connected systems
///
/// Example usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const ConnectPage()),
/// );
/// ```
class ConnectPage extends StatefulWidget {
  /// Creates a Liquid Galaxy connection configuration page.
  ///
  /// This stateful widget manages SSH connection parameters and provides
  /// both manual and QR-based configuration options for Liquid Galaxy systems.
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

/// State class managing connection configuration and validation.
///
/// Handles the complete lifecycle of Liquid Galaxy connection setup including:
/// - Loading and saving connection parameters
/// - SSH connection validation
/// - User interface state management
/// - Integration with QR code scanning
class _ConnectPageState extends State<ConnectPage> {
  /// Controller for the SSH host/IP address input field.
  ///
  /// Manages the target Liquid Galaxy master node's IP address or hostname.
  /// Typically an IP address like "192.168.56.121" for local installations.
  TextEditingController hostController = TextEditingController();

  /// Controller for the SSH port number input field.
  ///
  /// Manages the SSH port configuration, defaulting to port 22.
  /// Some installations may use custom ports for security.
  TextEditingController portController = TextEditingController();

  /// Controller for the SSH username input field.
  ///
  /// Manages the username for SSH authentication to the Liquid Galaxy system.
  /// Commonly "lg" for standard Liquid Galaxy installations.
  TextEditingController usernameController = TextEditingController();

  /// Controller for the SSH password input field.
  ///
  /// Manages the password for SSH authentication. In production environments,
  /// key-based authentication is preferred over password authentication.
  TextEditingController passwordController = TextEditingController();

  /// Controller for the screen count input field.
  ///
  /// Manages the number of screens in the Liquid Galaxy installation.
  /// This affects how content is distributed across the display array.
  TextEditingController screenCountController = TextEditingController();

  /// Loads previously saved connection parameters from SharedPreferences.
  ///
  /// Retrieves all stored connection settings and populates the input fields,
  /// providing a seamless user experience by remembering previous configurations.
  /// This method is called during widget initialization to restore user settings.
  ///
  /// Handles missing values gracefully by providing empty defaults.
  Future<void> _loadSavedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      hostController.text = prefs.getString('host') ?? '';
      portController.text = prefs.getInt('port')?.toString() ?? '';
      usernameController.text = prefs.getString('username') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      screenCountController.text = prefs.getInt('rigs')?.toString() ?? '';
    });
  }

  @override
  void initState() {
    // Load saved connection parameters when the page initializes
    _loadSavedData();
    super.initState();
  }

  @override
  void dispose() {
    // Clean up text controllers to prevent memory leaks
    hostController.dispose();
    portController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    screenCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Access the LgService instance for connection management
    final lgService = Provider.of<LgService>(context);

    return Scaffold(
      /// Simple app bar with page title and back navigation
      appBar: AppBar(title: const Text('Connect')),

      body: SingleChildScrollView(
        child: Column(
          children: [
            /// QR Code scanning option for quick setup
            /// Provides an alternative to manual configuration
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MCDButton(
                textColor: Colors.black,
                onPressed: () {
                  if (kDebugMode) {
                    print("Scan QR Code");
                  }
                  // Navigate to QR code scanning page
                  Navigator.of(context).pushNamed('/scan');
                },
                text: "Scan Using QR",
                color: Theme.of(context).primaryColor,
              ),
            ),

            /// Visual divider between QR scanning and manual input
            ChoiceDivider(),

            /// SSH Host/IP Address input field
            /// Primary connection parameter for identifying the target system
            FormInput(
              hintText: "192.168.56.121",
              labelText: "Host",
              controller: hostController,
            ),

            /// SSH Port input field
            /// Network port for SSH connection (typically 22)
            FormInput(
              hintText: "22",
              labelText: "Port",
              textInputType: TextInputType.number,
              controller: portController,
            ),

            /// SSH Username input field
            /// Authentication username for the Liquid Galaxy system
            FormInput(
              hintText: "lg",
              labelText: "Username",
              controller: usernameController,
            ),

            /// SSH Password input field
            /// Authentication password for the user account
            FormInput(
              hintText: "lg",
              labelText: "Password",
              controller: passwordController,
            ),

            /// Screen count input field
            /// Defines the number of displays in the Liquid Galaxy installation
            FormInput(
              hintText: "3",
              labelText: "Number of Screens",
              textInputType: TextInputType.number,
              controller: screenCountController,
            ),
            const SizedBox(height: 20),

            /// Connection button to validate and establish SSH connection
            /// Performs comprehensive connection testing and setup
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MCDButton(
                text: "CONNECT",
                onPressed: () async {
                  if (kDebugMode) {
                    print(hostController.text);
                  }

                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();

                  try {
                    // Configure LgService with user-provided parameters
                    lgService.host = hostController.text;
                    lgService.port =
                        portController.text.isNotEmpty
                            ? int.parse(portController.text)
                            : 22;
                    lgService.username = usernameController.text;
                    lgService.password = passwordController.text;
                    lgService.rigs =
                        int.tryParse(screenCountController.text) ?? 0;

                    // Persist connection settings for future use
                    await prefs.setString('host', lgService.host);
                    await prefs.setInt('port', lgService.port);
                    await prefs.setString('username', lgService.username);
                    await prefs.setString('password', lgService.password);
                    await prefs.setInt('rigs', lgService.rigs);

                    // Validate SSH connection to the Liquid Galaxy system
                    bool connectionResult = await lgService.checkConnection();

                    if (kDebugMode) {
                      print('Connection result: $connectionResult');
                    }

                    // Update service connection state based on validation result
                    lgService.connected = connectionResult;

                    // Provide user feedback about connection status
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          connectionResult ? 'Connected' : 'Failed to connect',
                        ),
                      ),
                    );

                    // Deploy application logos to the connected Liquid Galaxy system
                    if (connectionResult) {
                      String logoKml = await rootBundle.loadString(
                        'assets/kml/logos.kml',
                      );
                      await lgService.execCommand(
                        "echo '$logoKml' > /var/www/html/kml/slave_${lgService.logoScreen}.kml",
                      );
                    }
                  } catch (e) {
                    // Handle connection errors gracefully
                    if (kDebugMode) {
                      print('Connection error: ${e.toString()}');
                    }

                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A specialized input widget for connection configuration forms.
///
/// Provides consistent styling and layout for SSH connection parameter inputs.
/// Each input includes a label, hint text, and proper keyboard configuration
/// for the expected data type.
///
/// Example usage:
/// ```dart
/// FormInput(
///   labelText: "Host",
///   hintText: "192.168.1.100",
///   controller: hostController,
/// );
/// ```
class FormInput extends StatelessWidget {
  /// Placeholder text displayed when the input field is empty.
  ///
  /// Provides users with examples of expected input format.
  final String? hintText;

  /// Label text displayed above the input field.
  ///
  /// Clearly identifies the purpose of each input field.
  final String labelText;

  /// Text editing controller for managing input state.
  ///
  /// Handles user input and provides programmatic access to field values.
  final TextEditingController? controller;

  /// Keyboard type for optimizing input experience.
  ///
  /// Configures the virtual keyboard for specific data types (e.g., numbers).
  final TextInputType? textInputType;

  /// Creates a form input widget with consistent styling.
  ///
  /// Parameters:
  /// - [labelText]: Required label for the input field
  /// - [hintText]: Optional placeholder text for user guidance
  /// - [controller]: Optional controller for managing input state
  /// - [textInputType]: Optional keyboard type optimization
  const FormInput({
    super.key,
    this.hintText,
    required this.labelText,
    this.controller,
    this.textInputType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// Input field label with consistent styling
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 5),
          child: Text(labelText, style: const TextStyle(color: Colors.black)),
        ),

        /// Main input field with proper configuration
        InputBar(
          controller: controller,
          hintText: hintText,
          showIcon: false,
          textInputType: textInputType,
        ),
        const SizedBox(height: 3),
      ],
    );
  }
}

/// A visual divider widget displaying "or" between configuration options.
///
/// Provides clear visual separation between QR code scanning and manual
/// input sections, improving the page's visual hierarchy and user experience.
///
/// The divider includes horizontal lines on both sides of the "or" text,
/// creating a professional and intuitive interface element.
class ChoiceDivider extends StatelessWidget {
  /// Creates a choice divider with "or" text between horizontal lines.
  const ChoiceDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 28),
      child: Row(
        children: [
          /// Left divider line
          Expanded(child: Divider(color: Colors.black, thickness: 1)),

          /// "or" text with padding
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("or", style: TextStyle(color: Colors.black)),
          ),

          /// Right divider line
          Expanded(child: Divider(color: Colors.black, thickness: 1)),
        ],
      ),
    );
  }
}
