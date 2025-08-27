import 'dart:convert';
import 'package:flutter/foundation.dart'; // for compute()
import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// A QR code scanning page for configuring Liquid Galaxy connections automatically.
///
/// This page provides a camera-based QR code scanner that allows users to quickly
/// configure their Liquid Galaxy connection parameters by scanning a QR code containing
/// connection details. It eliminates the need for manual entry of host, port, username,
/// password, and screen count information.
///
/// Features:
/// - Real-time QR code scanning with camera overlay
/// - Automatic connection validation after scanning
/// - Persistent storage of connection parameters
/// - Debounced scanning to prevent duplicate detections
/// - Lifecycle-aware camera management
/// - Custom visual cutout for scan area indication
/// - Progress indication during connection attempts
///
/// Expected QR code format (JSON):
/// ```json
/// {
///   "ip": "192.168.1.100",
///   "port": 22,
///   "username": "lg",
///   "password": "lqgalaxy",
///   "screens": 5
/// }
/// ```
///
/// Example usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const QRPage()),
/// );
/// ```
class QRPage extends StatefulWidget {
  /// Creates a QR code scanning page for Liquid Galaxy configuration.
  ///
  /// This stateful widget manages camera lifecycle, QR detection, and
  /// automatic connection establishment with debouncing and error handling.
  const QRPage({super.key});

  @override
  State<QRPage> createState() => _QRPageState();
}

/// State class managing QR scanning, connection validation, and UI lifecycle.
///
/// Implements WidgetsBindingObserver to handle app lifecycle changes and
/// properly manage camera resources when the app is paused or resumed.
///
/// Key responsibilities:
/// - Camera controller management with safe start/stop operations
/// - QR code detection with duplicate prevention
/// - JSON parsing and connection parameter extraction
/// - Connection testing and validation
/// - UI state management during connection attempts
class _QRPageState extends State<QRPage> with WidgetsBindingObserver {
  /// Mobile scanner controller for QR code detection.
  ///
  /// Configured with specific settings for optimal QR scanning:
  /// - No duplicate detection within timeout period
  /// - 800ms detection timeout for performance
  /// - QR code format restriction for efficiency
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 800,
    formats: const [BarcodeFormat.qrCode],
  );

  /// Last successfully scanned QR code content.
  ///
  /// Used for duplicate detection to prevent processing the same
  /// QR code multiple times in quick succession.
  String? _lastCode;

  /// Whether a connection attempt is currently in progress.
  ///
  /// Prevents concurrent connection attempts and provides UI feedback
  /// with loading indicators during the connection validation process.
  bool _connecting = false;

  /// Timestamp of the last successful QR code scan.
  ///
  /// Used in combination with [_debounce] to implement scan rate limiting
  /// and prevent rapid successive scans of the same or different codes.
  DateTime _lastScan = DateTime.fromMillisecondsSinceEpoch(0);

  /// Minimum time between QR code scan attempts.
  ///
  /// Prevents rapid scanning that could lead to UI flickering or
  /// multiple concurrent connection attempts. Set to 900ms for optimal UX.
  static const _debounce = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    // Register for app lifecycle events to manage camera properly
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Clean up lifecycle observer and camera controller
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  /// Handles app lifecycle state changes for proper camera management.
  ///
  /// Automatically stops the camera when the app is paused (e.g., user switches
  /// apps or phone goes to sleep) and resumes scanning when the app becomes
  /// active again. This prevents battery drain and camera access conflicts.
  ///
  /// Parameters:
  /// - [state]: The new app lifecycle state
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _safeStop();
    } else if (state == AppLifecycleState.resumed) {
      _safeStart();
    }
  }

  /// Safely stops the camera scanner with timeout protection.
  ///
  /// Attempts to stop the scanner gracefully but will timeout after 500ms
  /// to prevent the UI from hanging if the camera becomes unresponsive.
  /// Only attempts to stop if the scanner is currently running.
  Future<void> _safeStop() async {
    if (!_controller.value.isRunning) return;
    try {
      await _controller.stop().timeout(const Duration(milliseconds: 500));
    } catch (_) {
      // Silently handle timeout or other stop failures
    }
  }

  /// Safely starts the camera scanner with timeout protection.
  ///
  /// Attempts to start the scanner gracefully but will timeout after 700ms
  /// to prevent the UI from hanging if camera initialization fails.
  /// Only attempts to start if the scanner is not currently running.
  Future<void> _safeStart() async {
    if (_controller.value.isRunning) return;
    try {
      await _controller.start().timeout(const Duration(milliseconds: 700));
    } catch (_) {
      // Silently handle timeout or other start failures
    }
  }

  /// Persists Liquid Galaxy connection parameters to SharedPreferences.
  ///
  /// Saves all connection settings for automatic restoration on app restart.
  /// This ensures users don't need to re-scan QR codes every time they
  /// use the application.
  ///
  /// Parameters:
  /// - [lgService]: The LgService instance containing connection parameters
  ///
  /// Stored parameters:
  /// - host: IP address or hostname
  /// - port: SSH port number
  /// - username: SSH authentication username
  /// - password: SSH authentication password
  /// - rigs: Number of screens in the LG installation
  Future<void> _setPrefs(LgService lgService) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('host', lgService.host);
    await prefs.setInt('port', lgService.port);
    await prefs.setString('username', lgService.username);
    await prefs.setString('password', lgService.password);
    await prefs.setInt('rigs', lgService.rigs);
  }

  /// Processes detected QR codes and attempts Liquid Galaxy connection.
  ///
  /// This method orchestrates the complete QR-to-connection workflow:
  /// 1. **Duplicate Detection**: Prevents processing identical codes
  /// 2. **Debouncing**: Rate-limits scan attempts for better UX
  /// 3. **JSON Parsing**: Decodes QR content using background isolate
  /// 4. **Parameter Application**: Updates LgService with scanned values
  /// 5. **Connection Testing**: Validates SSH connectivity
  /// 6. **Persistence**: Saves working parameters for future use
  /// 7. **User Feedback**: Shows connection status via SnackBar
  /// 8. **Navigation**: Returns to previous screen on success
  ///
  /// Parameters:
  /// - [capture]: The barcode capture result from mobile_scanner
  ///
  /// Error handling covers JSON parsing failures, network connectivity
  /// issues, and SSH authentication problems with user-friendly feedback.
  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    final now = DateTime.now();
    // Prevent duplicate processing and rapid scanning
    if (_connecting ||
        code == _lastCode ||
        now.difference(_lastScan) < _debounce) {
      return;
    }
    _lastScan = now;
    _lastCode = code;

    setState(() => _connecting = true);

    try {
      // Parse JSON in background isolate to prevent UI blocking
      final data = await compute(_decodeJson, code);

      if (!mounted) return;

      // Apply scanned parameters to LgService with fallback defaults
      final lgService = context.read<LgService>();
      lgService
        ..host = (data['ip'] as String?) ?? lgService.host
        ..port = (data['port'] as int?) ?? 22
        ..username = (data['username'] as String?) ?? 'lg'
        ..password = (data['password'] as String?) ?? 'lqgalaxy'
        ..rigs = (data['screens'] as int?) ?? 5;

      // Provide immediate feedback about connection attempt
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Connecting to ${lgService.host}...')),
      );

      // Persist connection parameters for future app sessions
      await _setPrefs(lgService);

      // Test actual SSH connectivity to validate parameters
      final ok = await lgService.checkConnection();
      if (!mounted) return;

      // Provide final connection status feedback
      messenger.hideCurrentSnackBar();
      if (ok) {
        messenger.showSnackBar(
          SnackBar(content: Text('Connected to ${lgService.host}')),
        );
        // Return to previous screen on successful connection
        Navigator.of(context).pop();
        return;
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to connect to ${lgService.host}')),
        );
      }
    } catch (e) {
      // Handle JSON parsing errors or connection failures
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to parse/connect: $e')));
    } finally {
      // Always clear connecting state regardless of success/failure
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// Simple app bar with scan context
      appBar: AppBar(title: const Text('Scan QR')),

      body: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive scan window dimensions
          final w = constraints.maxWidth;
          final h = constraints.maxHeight;
          final cutoutSize = w * 0.75; // 75% of screen width
          final left = (w - cutoutSize) / 2; // Center horizontally
          final top = (h - cutoutSize) / 2; // Center vertically
          final scanWindow = Rect.fromLTWH(left, top, cutoutSize, cutoutSize);

          return Stack(
            children: [
              /// Camera preview with restricted scan area
              MobileScanner(
                controller: _controller,
                fit: BoxFit.cover, // Fill available space
                scanWindow: scanWindow, // Limit detection to cutout area
                onDetect: _onDetect,
              ),

              /// Visual overlay with cutout for scan area
              IgnorePointer(
                child: CustomPaint(size: Size(w, h), painter: CutoutPainter()),
              ),

              /// Instructional text at bottom of screen
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black54, // Semi-transparent background
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    "Scan LG QR code to connect",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),

              /// Modal barrier during connection attempts
              if (_connecting)
                const ModalBarrier(dismissible: false, color: Colors.black38),

              /// Connection progress dialog
              if (_connecting)
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: w * 0.6,
                      minHeight: w * 0.3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Connecting...'),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Background isolate function for JSON parsing without blocking the UI.
///
/// Decodes JSON strings in a separate isolate to prevent UI freezing
/// during parsing operations. This is particularly important for complex
/// or malformed JSON that might take time to process.
///
/// Parameters:
/// - [s]: JSON string to decode
///
/// Returns: Parsed JSON as Map<String, dynamic>
///
/// Throws: FormatException for invalid JSON format
Map<String, dynamic> _decodeJson(String s) =>
    jsonDecode(s) as Map<String, dynamic>;

/// Custom painter creating a visual cutout overlay for the QR scan area.
///
/// Draws a semi-transparent overlay across the entire screen with a
/// rounded rectangular cutout in the center. This helps users understand
/// where to position QR codes and provides visual focus on the scan area.
///
/// The cutout is 75% of screen width, centered both horizontally and
/// vertically, with rounded corners for a modern appearance.
class CutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Create full-screen background path
    final outer = Path()..addRect(Offset.zero & size);

    // Calculate centered cutout dimensions
    final cutoutSize = size.width * 0.75;
    final left = (size.width - cutoutSize) / 2;
    final top = (size.height - cutoutSize) / 2;

    // Create rounded rectangular cutout
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cutoutSize, cutoutSize),
      const Radius.circular(20),
    );
    final cut = Path()..addRRect(rrect);

    // Apply semi-transparent overlay with cutout
    final shade = Paint()..color = Colors.black45;
    canvas.drawPath(Path.combine(PathOperation.xor, outer, cut), shade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
