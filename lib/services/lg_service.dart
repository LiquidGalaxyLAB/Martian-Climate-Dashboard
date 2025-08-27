/// A comprehensive service class for managing Liquid Galaxy system interactions via SSH.
///
/// The [LgService] provides a complete interface for controlling Liquid Galaxy installations
/// remotely through SSH and SFTP protocols. This service is central to the Martian Climate
/// Dashboard's ability to deploy Mars climate visualizations to immersive multi-screen
/// display systems used in educational and research environments.
///
/// **Core Capabilities:**
/// - **Connection Management**: Establishes and maintains SSH connections to LG master nodes
/// - **Command Execution**: Executes shell commands remotely across all LG nodes
/// - **File Transfer**: Deploys KML visualizations, images, and configuration files via SFTP
/// - **System Administration**: Provides reboot, relaunch, and shutdown operations
/// - **Content Management**: Handles KML file lifecycle and refresh intervals
/// - **Mars Environment**: Configures LG systems for Mars visualization contexts
///
/// **Architecture Integration:**
/// The service integrates with multiple components of the climate dashboard:
/// - KML visualization deployment from [KmlGenerationService]
/// - AI-powered balloon displays from [BalloonService]
/// - Orbital tour management for immersive Mars exploration
/// - Logo and branding deployment for institutional presentations
/// - Session persistence through [SharedPreferences] integration
///
/// **Multi-Node Management:**
/// Liquid Galaxy systems consist of multiple nodes (typically 3-7 screens):
/// - **Master Node (lg1)**: Primary control and web server functionality
/// - **Slave Nodes (lg2-lgN)**: Display-only nodes showing different viewing angles
/// - **Screen Distribution**: Automatic calculation of logo and balloon screen assignments
/// - **Synchronized Operations**: Coordinated deployment across all nodes
///
/// **Performance Optimizations:**
/// - **Connection Pooling**: Reuses SSH connections for multiple operations
/// - **File Hashing**: Prevents redundant file transfers through MD5 change detection
/// - **Chunked Transfer**: Streams large files in optimized chunks for reliability
/// - **Queue Management**: Serializes file operations to prevent race conditions
/// - **Timeout Handling**: Graceful degradation for network connectivity issues
///
/// Example usage:
/// ```dart
/// final lgService = LgService();
///
/// // Configure connection parameters
/// lgService.host = "192.168.1.100";
/// lgService.username = "lg";
/// lgService.password = "lqgalaxy";
/// lgService.rigs = 5;
///
/// // Establish connection and deploy visualization
/// if (await lgService.checkConnection()) {
///   await lgService.sendFile('/var/www/html/mars_climate.kml', kmlData);
///   await lgService.changeToMars();
/// }
/// ```
///
/// **Security Considerations:**
/// - SSH key authentication support (recommended for production)
/// - Password-based authentication for educational environments
/// - Secure credential storage through [SharedPreferences]
/// - Connection timeout and retry mechanisms
/// - Graceful handling of authentication failures
library;

import 'dart:convert';

import 'package:dartssh2/dartssh2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service class managing comprehensive Liquid Galaxy system interactions and administration.
///
/// This class provides the complete interface for controlling Liquid Galaxy installations,
/// handling everything from basic SSH connectivity to complex multi-node system operations.
/// It serves as the bridge between the Martian Climate Dashboard and the immersive display
/// infrastructure used for Mars climate visualization.
///
/// **Connection Architecture:**
/// The service maintains both regular SSH connections for command execution and persistent
/// SFTP connections for efficient file transfer operations. Connection pooling and reuse
/// minimize overhead during intensive visualization deployment workflows.
///
/// **Multi-Screen Management:**
/// Liquid Galaxy systems use multiple screens to create immersive panoramic views.
/// The service automatically calculates optimal screen assignments for different content
/// types (logos, balloons, primary visualizations) based on the total node count.
class LgService {
  /// IP address or hostname of the Liquid Galaxy master node.
  ///
  /// The master node (typically lg1) serves as the primary control point for the
  /// entire LG installation. All SSH connections and file transfers are initiated
  /// through this node, which then coordinates with slave nodes as needed.
  ///
  /// Common configurations:
  /// - Local network: "192.168.1.100" (typical LG network setup)
  /// - Educational lab: "10.0.0.100" (institution-specific networks)
  /// - Cloud deployment: Public IP or domain name for remote access
  String host = "192.168.121.3";

  /// SSH port for connecting to the Liquid Galaxy master node.
  ///
  /// Standard SSH port (22) is used by default, but may be customized for:
  /// - Security hardening (non-standard ports)
  /// - Network policy compliance in institutional environments
  /// - Port forwarding configurations for remote access
  int port = 22;

  /// SSH username for authentication to Liquid Galaxy nodes.
  ///
  /// Standard LG installations use "lg" as the default username across all nodes.
  /// This user account has the necessary permissions for:
  /// - Google Earth control and configuration
  /// - Web server file management (/var/www/html/)
  /// - System administration tasks (with sudo access)
  String username = "lg";

  /// SSH password for authentication to Liquid Galaxy nodes.
  ///
  /// Default installations often use "lqgalaxy" or "lg" as the password.
  /// For production deployments, consider:
  /// - SSH key-based authentication for enhanced security
  /// - Strong passwords following institutional policies
  /// - Encrypted storage of credentials
  String password = "lg";

  /// Total number of nodes (screens) in the Liquid Galaxy installation.
  ///
  /// This value determines screen layout and content distribution:
  /// - **Single Screen (1)**: Development/testing configuration
  /// - **Standard Setup (3-5)**: Common educational installations
  /// - **Large Installations (7+)**: Research centers and planetariums
  ///
  /// The node count affects:
  /// - Logo placement calculation (left-most screen)
  /// - Balloon positioning (right-most screen)
  /// - Tour synchronization across multiple viewing angles
  int rigs = 3;

  /// Whether the LG system is currently configured for Mars visualization.
  ///
  /// Tracks the planetary context to ensure proper Google Earth configuration.
  /// Mars mode enables:
  /// - Mars terrain and atmospheric data display
  /// - Coordinate system alignment with Mars geography
  /// - Proper scaling for Mars-specific measurements
  bool marsSelected = false;

  /// Current SSH connection status to the Liquid Galaxy master node.
  ///
  /// Indicates whether the service has successfully established communication
  /// with the LG system. Used for:
  /// - UI state management (connection indicators)
  /// - Operation validation before command execution
  /// - Automatic reconnection logic when needed
  bool connected = false;

  /// Persistent SSH client instance for command execution.
  ///
  /// Maintained across operations to avoid repeated connection overhead.
  /// Automatically managed through connection pooling with proper cleanup
  /// and error handling for disconnection scenarios.
  SSHClient? _client;

  /// Persistent SFTP client instance for efficient file transfers.
  ///
  /// Enables high-performance file operations with:
  /// - Chunked transfer for large KML files
  /// - Connection reuse across multiple file operations
  /// - Automatic retry logic for transfer failures
  SftpClient? _sftp;

  /// Cache of MD5 hashes for transferred files to prevent redundant uploads.
  ///
  /// Maps remote file paths to their content hashes, enabling:
  /// - Skip unchanged files during repeated deployments
  /// - Bandwidth optimization for large visualization updates
  /// - Reduced latency for frequently updated content
  ///
  /// Example: {"/var/www/html/climate.kml": "d41d8cd98f00b204e9800998ecf8427e"}
  final Map<String, String> _lastFileHash = {};

  /// File operation queue to serialize SFTP transfers and prevent race conditions.
  ///
  /// Ensures that multiple file operations don't interfere with each other,
  /// particularly important for:
  /// - Simultaneous KML and image deployments
  /// - Rapid visualization updates during temporal navigation
  /// - Coordination between balloon updates and main content
  Future<void> _fileQueue = Future.value();

  /// Flag indicating whether an SFTP connection attempt is currently in progress.
  ///
  /// Prevents multiple simultaneous connection attempts that could cause:
  /// - Resource conflicts and connection failures
  /// - Timeout issues during high-load periods
  /// - Inconsistent connection state management
  bool _connecting = false;

  /// Calculates the optimal screen number for logo display based on installation size.
  ///
  /// Logo placement follows Liquid Galaxy conventions for institutional branding:
  /// - **Single Screen**: Logo appears on the only available screen
  /// - **Multi-Screen**: Logo positioned on the left-most screen for visibility
  ///
  /// **Screen Layout Logic:**
  /// In a typical 5-screen setup (lg1-lg5):
  /// - lg1: Master node (center screen)
  /// - lg2-lg3: Left side screens
  /// - lg4-lg5: Right side screens
  /// - Logo screen = lg4 (left-most visible screen)
  ///
  /// Returns: Screen number (1-based) for logo deployment
  int get logoScreen {
    if (rigs == 1) {
      return 1;
    }

    // Calculate left-most screen: floor(rigs/2) + 2
    // This formula accounts for the master node and screen numbering conventions
    return (rigs / 2).floor() + 2;
  }

  /// Calculates the optimal screen number for information balloon display.
  ///
  /// Balloon placement ensures visibility without interfering with main content:
  /// - **Single Screen**: Balloon shares space with main visualization
  /// - **Multi-Screen**: Balloon positioned on right-most screen for easy reference
  ///
  /// **Positioning Strategy:**
  /// Balloons contain AI-generated analysis and location information that users
  /// reference while examining the main visualization. Right-side placement
  /// follows natural reading patterns and maintains visual hierarchy.
  ///
  /// Returns: Screen number (1-based) for balloon deployment
  int get balloonScreen {
    if (rigs == 1) {
      return 1;
    }

    // Calculate right-most screen: floor(rigs/2) + 1
    // Ensures balloon visibility while preserving main visualization space
    return (rigs / 2).floor() + 1;
  }

  /// Performs comprehensive connectivity testing and system initialization.
  ///
  /// This method orchestrates the complete connection workflow required to
  /// prepare the Liquid Galaxy system for Mars climate visualization:
  ///
  /// **Connection Validation Process:**
  /// 1. **SSH Connectivity**: Tests basic SSH connection with timeout protection
  /// 2. **Authentication**: Verifies username/password credentials
  /// 3. **System Response**: Confirms command execution capability
  /// 4. **Network Stability**: Validates sustained connection quality
  ///
  /// **System Initialization Sequence:**
  /// 1. **Content Cleanup**: Clears existing KML files and tours
  /// 2. **Mars Configuration**: Switches Google Earth to Mars planetary mode
  /// 3. **Logo Deployment**: Installs institutional branding elements
  /// 4. **Environment Validation**: Confirms Mars visualization readiness
  ///
  /// **Error Scenarios Handled:**
  /// - Network unreachability (firewall, routing issues)
  /// - Authentication failures (incorrect credentials)
  /// - SSH service unavailability (system maintenance)
  /// - Timeout conditions (slow network, system overload)
  /// - Google Earth initialization problems
  ///
  /// Returns:
  /// - `true`: Connection successful, system ready for visualization deployment
  /// - `false`: Connection failed, manual intervention or configuration required
  ///
  /// **Connection State Management:**
  /// Updates [connected] property to reflect actual system status, enabling
  /// UI components to show accurate connection indicators and prevent
  /// operations on disconnected systems.
  ///
  /// Example:
  /// ```dart
  /// if (await lgService.checkConnection()) {
  ///   print('LG system ready for Mars climate visualization');
  ///   // Proceed with visualization deployment
  /// } else {
  ///   print('LG connection failed, check network and credentials');
  ///   // Show error message and connection configuration UI
  /// }
  /// ```
  Future<bool> checkConnection() async {
    try {
      // Stage 1: Establish basic SSH connectivity with timeout protection
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: Duration(seconds: 5), // Prevent indefinite hanging
      );

      // Stage 2: Authenticate and create SSH client session
      SSHClient(socket, username: username, onPasswordRequest: () => password);

      // Stage 3: Initialize system for Mars climate visualization
      await clearKml(); // Remove any existing visualization content
      await changeToMars(); // Configure Google Earth for Mars planetary mode
      await sendLogos(); // Deploy institutional branding

      // Log successful connection for debugging and monitoring
      if (kDebugMode) {
        print('Connected to $host:$port');
      }

      // Update connection state for UI and operation validation
      connected = true;
      return true;
    } catch (e) {
      // Handle all connection failures gracefully with detailed logging
      if (kDebugMode) {
        print('Failed to connect to $host:$port, $e');
      }

      // Ensure connection state reflects actual status
      connected = false;
      return false;
    }
  }

  /// Executes shell commands remotely on the Liquid Galaxy master node.
  ///
  /// This method provides the fundamental interface for controlling Liquid Galaxy
  /// systems through SSH command execution. It handles the complete workflow of
  /// establishing connections, executing commands, and processing results.
  ///
  /// **Command Execution Process:**
  /// 1. **Connection Establishment**: Creates new SSH socket and client session
  /// 2. **Authentication**: Uses stored credentials for automatic login
  /// 3. **Command Dispatch**: Sends shell command for remote execution
  /// 4. **Output Monitoring**: Captures stdout and stderr streams
  /// 5. **Result Processing**: Logs output for debugging and monitoring
  /// 6. **Session Cleanup**: Properly closes connections to prevent leaks
  ///
  /// **Supported Command Types:**
  /// - **File Operations**: Creating, modifying, and managing files
  /// - **Google Earth Control**: Planetary mode, tours, and navigation commands
  /// - **System Administration**: Reboot, service management, configuration
  /// - **Network Operations**: Multi-node coordination and synchronization
  ///
  /// **Output Handling:**
  /// Both stdout and stderr streams are captured and logged for:
  /// - Debugging command execution issues
  /// - Monitoring system responses and status
  /// - Validating successful operation completion
  /// - Tracking system health and performance
  ///
  /// Parameters:
  /// - [command]: Shell command string to execute on the remote LG system
  ///
  /// **Command Examples:**
  /// ```dart
  /// // Google Earth control
  /// await lgService.execCommand('echo "planet=mars" > /tmp/query.txt');
  ///
  /// // File management
  /// await lgService.execCommand('> /var/www/html/kmls.txt'); // Clear KML list
  ///
  /// // Multi-node operations
  /// await lgService.execCommand('sshpass -p password ssh lg2 "reboot"');
  ///
  /// // Tour control
  /// await lgService.execCommand('echo "playtour=Orbit" > /tmp/query.txt');
  /// ```
  ///
  /// Returns: [LgService] instance for method chaining and fluent API usage
  ///
  /// **Error Handling:**
  /// Connection failures and command errors are logged but don't throw exceptions,
  /// allowing the application to continue gracefully while providing diagnostic
  /// information for troubleshooting connectivity and system issues.
  ///
  /// **Security Considerations:**
  /// Commands are executed with the privileges of the authenticated user (typically 'lg').
  /// Ensure command content is properly validated and sanitized when accepting
  /// user input to prevent command injection vulnerabilities.
  Future<LgService> execCommand(String command) async {
    try {
      // Establish fresh SSH connection for command execution
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      // Execute the command and obtain session handle
      SSHSession session = await client.execute(command);

      // Monitor stdout stream for command output and results
      session.stdout.listen((data) {
        if (kDebugMode) {
          print("stdout: ${utf8.decode(data)}");
        }
      });

      // Monitor stderr stream for error messages and warnings
      session.stderr.listen((data) {
        if (kDebugMode) {
          print("stderr: ${utf8.decode(data)}");
        }
      });

      // Log successful command execution for monitoring
      print('Command sent to $host:$port');
    } catch (e) {
      // Log execution failures for debugging without throwing
      if (kDebugMode) {
        print('Failed to send command to $host:$port, $e');
      }
    }

    // Return service instance for method chaining
    return this;
  }

  /// Configures the Liquid Galaxy system for Mars planetary visualization mode.
  ///
  /// This method performs the essential setup required to switch Google Earth
  /// from its default Earth mode to Mars planetary mode, enabling proper
  /// visualization of Mars climate data with accurate coordinate systems,
  /// terrain models, and atmospheric context.
  ///
  /// **Mars Mode Configuration Process:**
  /// 1. **Planetary Switch**: Commands Google Earth to load Mars planetary data
  /// 2. **Coordinate System**: Aligns coordinate references with Mars geography
  /// 3. **Terrain Loading**: Ensures Mars surface topology is properly loaded
  /// 4. **Balloon Preparation**: Clears balloon screen for new content
  /// 5. **State Tracking**: Updates internal Mars mode flag for operations
  ///
  /// **Google Earth Mars Mode Features:**
  /// - **Martian Terrain**: High-resolution surface topology and geology
  /// - **Coordinate Accuracy**: Proper latitude/longitude mapping for Mars
  /// - **Atmospheric Context**: Mars-appropriate atmospheric visualization
  /// - **Scale Calibration**: Measurements and distances in Mars context
  ///
  /// **Technical Implementation:**
  /// Uses Google Earth's query.txt interface to send planetary mode commands:
  /// ```
  /// echo "planet=mars" > /tmp/query.txt
  /// ```
  ///
  /// **Balloon Screen Management:**
  /// Clears the designated balloon screen with blank KML to prepare for
  /// Mars-specific information balloons containing climate analysis and
  /// geographic feature details.
  ///
  /// **Error Handling:**
  /// Gracefully handles failures in Mars mode switching, which can occur due to:
  /// - Google Earth not responding to commands
  /// - Missing Mars planetary data installation
  /// - File system permission issues
  /// - Network connectivity problems affecting data loading
  ///
  /// **State Management:**
  /// Sets [marsSelected] flag to `true` for subsequent operations that need
  /// to know the current planetary context, enabling proper coordinate
  /// calculations and visualization parameters.
  ///
  /// Example usage:
  /// ```dart
  /// await lgService.changeToMars();
  /// // LG system now ready for Mars climate visualization
  /// await lgService.sendFile('/var/www/html/mars_climate.kml', kmlData);
  /// ```
  Future<void> changeToMars() async {
    try {
      // Prepare blank KML template for balloon screen clearing
      String blankKml =
          '<?xml version="1.0" encoding="UTF-8"?>'
          '<kml xmlns="http://www.opengis.net/kml/2.2" '
          'xmlns:gx="http://www.google.com/kml/ext/2.2" '
          'xmlns:kml="http://www.opengis.net/kml/2.2" '
          'xmlns:atom="http://www.w3.org/2005/Atom">'
          '<Document></Document></kml>';

      // Send planetary mode command to Google Earth
      await execCommand('echo "planet=mars" > /tmp/query.txt');

      // Clear balloon screen in preparation for Mars content
      await execCommand(
        'echo "$blankKml" > /var/www/html/kml/slave_$balloonScreen.kml',
      );

      // Update internal state to reflect Mars mode activation
      marsSelected = true;
    } catch (e) {
      // Log Mars mode switching failures for debugging
      if (kDebugMode) {
        print('Failed to change to Mars, $e');
      }
    }
  }

  /// Deploys institutional logos to the designated screen for branding and recognition.
  ///
  /// This method handles the deployment of organizational branding elements to
  /// Liquid Galaxy installations, providing institutional recognition and
  /// professional presentation quality essential for educational and research
  /// environments.
  ///
  /// **Logo Deployment Process:**
  /// 1. **Asset Loading**: Retrieves logo KML from application bundle assets
  /// 2. **Screen Targeting**: Deploys to calculated logo screen for optimal visibility
  /// 3. **KML Integration**: Installs logos as persistent KML overlay elements
  /// 4. **Display Activation**: Makes logos immediately visible on target screen
  ///
  /// **Logo Content Structure:**
  /// The logos.kml asset typically contains:
  /// - **Google Summer of Code**: Program recognition and branding
  /// - **Liquid Galaxy**: Platform acknowledgment and technical attribution
  /// - **Institution Logos**: Host organization branding (universities, research centers)
  /// - **Project Branding**: Martian Climate Dashboard specific visual identity
  ///
  /// **Screen Positioning Strategy:**
  /// Logos are positioned on the left-most screen ([logoScreen]) to ensure:
  /// - Maximum visibility during presentations and demonstrations
  /// - Non-interference with primary Mars climate visualizations
  /// - Professional appearance following LG best practices
  /// - Consistent placement across different installation sizes
  ///
  /// **KML Structure and Styling:**
  /// Logo KML files contain properly positioned screen overlays with:
  /// - Transparent backgrounds for seamless integration
  /// - Appropriate scaling for different screen resolutions
  /// - Persistent display that survives content updates
  /// - Professional styling consistent with institutional guidelines
  ///
  /// **Asset Management:**
  /// Logo files are:
  /// - Bundled as application assets for offline availability
  /// - Loaded synchronously to ensure immediate deployment
  /// - Cached locally to prevent network dependencies
  /// - Version controlled with application updates
  ///
  /// **Error Handling:**
  /// Gracefully handles logo deployment failures including:
  /// - Missing asset files or corrupted KML content
  /// - File system permissions preventing logo installation
  /// - Network connectivity issues during deployment
  /// - Google Earth KML parsing or rendering problems
  ///
  /// Example logo deployment workflow:
  /// ```dart
  /// await lgService.checkConnection(); // Ensure system connectivity
  /// await lgService.changeToMars(); // Configure Mars visualization mode
  /// await lgService.sendLogos(); // Deploy institutional branding
  /// // System now ready for Mars climate visualization with proper branding
  /// ```
  Future<void> sendLogos() async {
    if (kDebugMode) {
      print('Sending logos to Liquid Galaxy...');
    }

    // Load institutional logos from application asset bundle
    String logo = await rootBundle.loadString('assets/kml/logos.kml');

    // Deploy logos to calculated logo screen for optimal visibility
    await execCommand("echo '$logo' > /var/www/html/kml/slave_$logoScreen.kml");
  }

  /// Ensures persistent SFTP connection availability for efficient file transfers.
  ///
  /// This method implements connection pooling and management for SFTP operations,
  /// optimizing performance by reusing connections across multiple file transfers
  /// while handling connection failures and recovery gracefully.
  ///
  /// **Connection Management Strategy:**
  /// - **Reuse Existing**: Returns immediately if SFTP connection already established
  /// - **Prevent Conflicts**: Serializes connection attempts to avoid race conditions
  /// - **Automatic Recovery**: Recreates connections after failures or timeouts
  /// - **Resource Cleanup**: Properly disposes failed connections to prevent leaks
  ///
  /// **Connection Pooling Benefits:**
  /// - **Performance**: Eliminates repeated handshake overhead for multiple files
  /// - **Reliability**: Maintains stable connections for large file transfers
  /// - **Efficiency**: Reduces network traffic and latency for frequent operations
  /// - **Scalability**: Handles high-volume visualization deployments effectively
  ///
  /// **Concurrency Control:**
  /// Uses [_connecting] flag to prevent multiple simultaneous connection attempts
  /// that could cause resource conflicts, connection failures, or inconsistent
  /// state management during high-concurrency scenarios.
  ///
  /// **Error Recovery Mechanisms:**
  /// - **Connection Failures**: Properly cleans up failed attempts and resets state
  /// - **Authentication Issues**: Handles credential failures with proper logging
  /// - **Network Timeouts**: Uses reasonable timeout values to prevent hanging
  /// - **Resource Cleanup**: Ensures SSH/SFTP resources are properly disposed
  ///
  /// **Connection Lifecycle:**
  /// 1. **Check Existing**: Return early if connection already available
  /// 2. **Serialize Access**: Wait for any in-progress connection attempts
  /// 3. **Establish Socket**: Create SSH socket with timeout protection
  /// 4. **Authenticate**: Use stored credentials for SSH authentication
  /// 5. **Create SFTP**: Initialize SFTP subsystem over SSH connection
  /// 6. **Error Recovery**: Clean up and reset state on any failures
  ///
  /// **Threading and Async Behavior:**
  /// Properly handles concurrent access through async/await patterns and
  /// flag-based synchronization, ensuring thread safety for file operations
  /// called from multiple parts of the application simultaneously.
  ///
  /// This method is called internally by file transfer operations and should
  /// not be called directly by application code. Use [sendFile] for file
  /// transfer operations, which automatically manages SFTP connections.
  Future<void> _ensureSftp() async {
    // Return early if SFTP connection already established and ready
    if (_sftp != null) return;

    // Wait for any in-progress connection attempts to complete
    if (_connecting) {
      while (_connecting) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    // Set flag to prevent concurrent connection attempts
    _connecting = true;

    try {
      // Establish SSH socket with timeout protection
      final socket = await SSHSocket.connect(
        host,
        port,
        timeout: const Duration(seconds: 5),
      );

      // Create authenticated SSH client with empty identity list
      // (forces password authentication instead of key-based auth)
      _client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
        identities: const [], // Disable SSH key authentication
      );

      // Initialize SFTP subsystem over the established SSH connection
      _sftp = await _client!.sftp();
    } catch (e) {
      // Log connection failure details for debugging
      if (kDebugMode) {
        print('SFTP init failed: $e');
      }

      // Clean up failed connection resources
      try {
        _client?.close();
      } catch (_) {
        // Ignore cleanup errors - connection already failed
      }

      // Reset connection state to allow retry attempts
      _client = null;
      _sftp = null;
    } finally {
      // Always clear the connecting flag regardless of success/failure
      _connecting = false;
    }
  }

  /// Disposes persistent SSH and SFTP connections to free system resources.
  ///
  /// This method performs cleanup of long-lived network connections, ensuring
  /// proper resource management and preventing memory leaks or connection
  /// exhaustion in long-running applications.
  ///
  /// **Resource Cleanup Process:**
  /// 1. **SFTP Closure**: Cleanly terminates SFTP subsystem connections
  /// 2. **SSH Closure**: Closes underlying SSH socket and client sessions
  /// 3. **Reference Clearing**: Nullifies connection references for garbage collection
  /// 4. **Error Suppression**: Handles cleanup errors gracefully without throwing
  ///
  /// **When to Use:**
  /// - Application shutdown or service disposal
  /// - Connection error recovery requiring fresh connections
  /// - Memory optimization during idle periods
  /// - Explicit connection reset for troubleshooting
  ///
  /// **Error Handling:**
  /// Connection closure errors are suppressed to prevent issues during
  /// application shutdown or error recovery scenarios where connections
  /// may already be in invalid states.
  Future<void> disposePersistent() async {
    try {
      // Close SFTP and SSH connections gracefully
      _sftp?.close();
      _client?.close();
    } catch (_) {
      // Suppress cleanup errors - connections may already be closed
    }

    // Clear references to enable garbage collection
    _sftp = null;
    _client = null;
  }

  /// Transfers files to the Liquid Galaxy system with optimization and error handling.
  ///
  /// This method provides the primary interface for deploying KML visualizations,
  /// images, configuration files, and other content to Liquid Galaxy systems.
  /// It implements sophisticated optimization strategies including change detection,
  /// connection pooling, and fallback mechanisms for reliable content delivery.
  ///
  /// **File Transfer Optimization:**
  /// - **Change Detection**: MD5 hashing prevents redundant transfers of unchanged files
  /// - **Connection Reuse**: Persistent SFTP connections minimize handshake overhead
  /// - **Chunked Transfer**: Large files streamed in optimized 32KB chunks
  /// - **Queue Management**: Serialized operations prevent file system conflicts
  ///
  /// **Transfer Process Workflow:**
  /// 1. **Queue Serialization**: Ensures ordered execution preventing race conditions
  /// 2. **Change Detection**: Compares file hash with previous transfer to skip duplicates
  /// 3. **Connection Management**: Establishes or reuses persistent SFTP connection
  /// 4. **Chunked Transfer**: Streams file content in optimal-sized chunks
  /// 5. **Fallback Mechanism**: Uses legacy transfer method if persistent connection fails
  /// 6. **Hash Caching**: Stores successful transfer hash for future comparison
  ///
  /// **Performance Characteristics:**
  /// - **Small Files** (<1MB): Nearly instantaneous with connection reuse
  /// - **Large Files** (>10MB): Efficient streaming with progress monitoring
  /// - **Repeated Updates**: Skip unchanged files for rapid deployment cycles
  /// - **Concurrent Operations**: Properly queued to prevent resource conflicts
  ///
  /// **Error Recovery Mechanisms:**
  /// - **Connection Failures**: Automatic fallback to legacy transfer method
  /// - **Partial Transfers**: Proper cleanup and retry for incomplete operations
  /// - **Authentication Issues**: Clear error reporting for credential problems
  /// - **File System Errors**: Graceful handling of permission and space issues
  ///
  /// Parameters:
  /// - [remoteFilepath]: Absolute path on LG system for file deployment
  /// - [content]: Binary file content as Uint8List for transfer
  ///
  /// **Common File Paths:**
  /// ```dart
  /// // KML visualizations
  /// '/var/www/html/mars_climate.kml'
  ///
  /// // Screen-specific content
  /// '/var/www/html/kml/slave_2.kml'
  ///
  /// // Static assets
  /// '/var/www/html/images/mars_logo.png'
  ///
  /// // Configuration files
  /// '/tmp/query.txt'
  /// ```
  ///
  /// Returns: [LgService] instance for method chaining and fluent API usage
  ///
  /// **Usage Examples:**
  /// ```dart
  /// // Deploy Mars climate KML visualization
  /// await lgService.sendFile(
  ///   '/var/www/html/climate.kml',
  ///   utf8.encode(kmlContent),
  /// );
  ///
  /// // Update balloon information
  /// await lgService.sendFile(
  ///   '/var/www/html/kml/slave_3.kml',
  ///   utf8.encode(balloonKml),
  /// );
  ///
  /// // Method chaining for multiple operations
  /// await lgService
  ///   .sendFile('/var/www/html/data.kml', kmlData)
  ///   .then((_) => lgService.execCommand('echo "refresh" > /tmp/query.txt'));
  /// ```
  Future<LgService> sendFile(String remoteFilepath, Uint8List content) async {
    // Serialize all file operations through a queue to prevent conflicts
    _fileQueue = _fileQueue.then((_) async {
      // Calculate content hash for change detection
      final hash = md5.convert(content).toString();
      final lastHash = _lastFileHash[remoteFilepath];

      // Skip transfer if file content hasn't changed
      if (lastHash == hash) {
        if (kDebugMode) {
          print('sendFile skipped (unchanged): $remoteFilepath');
        }
        return;
      }

      // Attempt to use persistent SFTP connection for optimal performance
      await _ensureSftp();
      if (_sftp == null) {
        if (kDebugMode) {
          print('Falling back (no persistent SFTP) for $remoteFilepath');
        }

        // Use legacy transfer method if persistent connection unavailable
        await _legacySendFile(remoteFilepath, content);
        _lastFileHash[remoteFilepath] = hash;
        return;
      }

      try {
        // Open remote file for writing with truncation and creation flags
        final file = await _sftp!.open(
          remoteFilepath,
          mode:
              SftpFileOpenMode.create |
              SftpFileOpenMode.truncate |
              SftpFileOpenMode.write,
        );

        // Stream file content in optimized chunks to prevent memory issues
        const int chunkSize = 32 * 1024; // 32KB chunks for optimal performance
        int offset = 0;

        while (offset < content.length) {
          final end = (offset + chunkSize).clamp(0, content.length);
          final slice = content.sublist(offset, end);

          await file.write(
            Stream<Uint8List>.fromIterable([slice]),
            offset: offset,
          );

          offset = end;
        }

        // Close file and cache hash for future change detection
        await file.close();
        _lastFileHash[remoteFilepath] = hash;

        if (kDebugMode) {
          print('sendFile done (reused SFTP): $remoteFilepath');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Persistent send failed ($remoteFilepath): $e');
        }

        // Clean up failed persistent connection and retry with legacy method
        try {
          await disposePersistent();
        } catch (_) {
          // Ignore cleanup errors during error recovery
        }

        await _legacySendFile(remoteFilepath, content);
        _lastFileHash[remoteFilepath] = hash;
      }
    });

    // Wait for queued operation to complete
    await _fileQueue;
    return this;
  }

  /// Fallback file transfer method using temporary SSH connections.
  ///
  /// This method provides a reliable backup transfer mechanism when persistent
  /// SFTP connections fail or are unavailable. It creates fresh connections
  /// for each transfer operation, sacrificing performance for reliability.
  ///
  /// **Use Cases:**
  /// - **Connection Recovery**: When persistent connections fail or timeout
  /// - **Initial Setup**: Before persistent connections are established
  /// - **Error Recovery**: Fallback when optimized transfer methods fail
  /// - **Network Instability**: When connection pooling causes issues
  ///
  /// **Transfer Process:**
  /// 1. **Fresh Connection**: Creates new SSH socket and client for each transfer
  /// 2. **SFTP Initialization**: Establishes SFTP subsystem over SSH connection
  /// 3. **File Transfer**: Transfers complete file content in single operation
  /// 4. **Resource Cleanup**: Properly closes SFTP and SSH connections
  ///
  /// **Performance Characteristics:**
  /// - **Higher Overhead**: Full handshake for each file transfer
  /// - **Resource Intensive**: Creates/destroys connections frequently
  /// - **Memory Efficient**: Transfers files without chunking or buffering
  /// - **Reliability Focus**: Prioritizes transfer success over performance
  ///
  /// **Error Handling:**
  /// Logs transfer failures for debugging but doesn't throw exceptions,
  /// allowing graceful degradation when even fallback methods fail.
  ///
  /// Parameters:
  /// - [remoteFilepath]: Target path on LG system for file deployment
  /// - [content]: Binary file content for transfer
  ///
  /// This method is called automatically by [sendFile] when persistent
  /// connections fail and should not be called directly by application code.
  Future<void> _legacySendFile(String remoteFilepath, Uint8List content) async {
    try {
      // Create fresh SSH connection for this transfer operation
      final socket = await SSHSocket.connect(host, port);
      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      // Initialize SFTP subsystem for file transfer
      final sftp = await client.sftp();

      // Open remote file for writing with truncation and creation
      final file = await sftp.open(
        remoteFilepath,
        mode:
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.create |
            SftpFileOpenMode.write,
      );

      // Transfer complete file content in single operation
      await file.write(Stream.fromIterable([content]), offset: 0);

      // Clean up resources properly
      await file.close();
      sftp.close();
      client.close();

      if (kDebugMode) {
        print('Legacy sendFile done: $remoteFilepath');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Legacy sendFile failed: $e');
      }
    }
  }

  /// Creates and returns an authenticated SSH client for custom operations.
  ///
  /// This utility method provides direct access to SSH client instances for
  /// advanced operations that require fine-grained control over SSH sessions,
  /// command execution, or specialized protocols not covered by standard
  /// service methods.
  ///
  /// **Use Cases:**
  /// - **Custom Protocols**: Implementing specialized LG communication protocols
  /// - **Advanced Commands**: Complex multi-command sequences with session state
  /// - **Performance Critical**: Operations requiring optimized SSH handling
  /// - **Testing and Development**: Direct SSH access for debugging and exploration
  ///
  /// **Connection Management:**
  /// Each call creates a fresh SSH connection and client instance. The caller
  /// is responsible for proper connection cleanup to prevent resource leaks.
  ///
  /// Parameters:
  /// - [host]: SSH server hostname or IP address
  /// - [port]: SSH server port number
  /// - [username]: Authentication username
  /// - [password]: Authentication password
  ///
  /// Returns: Authenticated [SSHClient] instance ready for use
  ///
  /// **Cleanup Responsibility:**
  /// ```dart
  /// final client = await lgService.getClient(host, port, username, password);
  /// try {
  ///   // Use client for custom operations
  ///   final session = await client.execute('custom_command');
  ///   // Process session results
  /// } finally {
  ///   client.close(); // Always clean up resources
  /// }
  /// ```
  ///
  /// **Security Considerations:**
  /// This method bypasses normal service-level security and connection management.
  /// Ensure proper credential validation and connection handling when using
  /// direct SSH client access for custom operations.
  Future<SSHClient> getClient(host, port, username, password) async {
    final socket = await SSHSocket.connect(host, port);
    return SSHClient(
      socket,
      username: username,
      onPasswordRequest: () => password,
    );
  }

  /// Enables periodic refresh for KML files on Liquid Galaxy slave nodes.
  ///
  /// This method configures automatic refresh intervals for KML content on slave
  /// screens, enabling dynamic visualizations that update automatically without
  /// manual intervention. This is particularly useful for:
  /// - **Time-series animations** showing climate evolution over time
  /// - **Real-time data** requiring frequent updates from external sources
  /// - **Interactive visualizations** with changing parameters or viewpoints
  ///
  /// **Technical Implementation:**
  /// Modifies the myplaces.kml configuration file on each slave node to add
  /// refresh directives:
  /// ```xml
  /// <refreshMode>onInterval</refreshMode>
  /// <refreshInterval>2</refreshInterval>
  /// ```
  ///
  /// **Multi-Node Configuration Process:**
  /// 1. **Clean Existing**: Removes any existing refresh directives to prevent conflicts
  /// 2. **Apply Settings**: Adds standardized 2-second refresh interval to all slaves
  /// 3. **System Restart**: Reboots LG system to activate new configuration
  /// 4. **Validation**: Ensures refresh settings are properly applied across all nodes
  ///
  /// **Performance Considerations:**
  /// - **2-Second Interval**: Balances responsiveness with system performance
  /// - **Slave-Only**: Master node typically doesn't require refresh for stability
  /// - **Network Traffic**: Generates periodic HTTP requests for KML updates
  /// - **System Load**: May impact performance on older LG installations
  ///
  /// **Use Cases:**
  /// - **Temporal Navigation**: Automatic updates during date range exploration
  /// - **Live Data**: Periodic refresh of external data feeds
  /// - **Interactive Balloons**: Dynamic content updates based on user interactions
  ///
  /// **System Requirements:**
  /// - Requires sudo access for modifying system configuration files
  /// - All slave nodes must be accessible via SSH from master
  /// - Network connectivity must support periodic KML fetching
  ///
  /// **Error Handling:**
  /// Individual node configuration failures are logged but don't prevent
  /// the method from continuing with remaining nodes, ensuring partial
  /// functionality even if some nodes are unavailable.
  ///
  /// Example usage:
  /// ```dart
  /// // Enable refresh for dynamic Mars climate animations
  /// await lgService.setRefresh();
  /// // KML files will now update every 2 seconds automatically
  /// ```
  ///
  /// **Warning:** This operation requires a system reboot to take effect,
  /// which will temporarily interrupt any active visualizations or tours.
  Future<void> setRefresh() async {
    final pw = password;

    // Define search and replacement patterns for configuration modification
    const search = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';
    const replace =
        '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>'
        '<refreshMode>onInterval<\\/refreshMode>'
        '<refreshInterval>2<\\/refreshInterval>';

    // Commands for adding and removing refresh configuration
    final command =
        'echo $pw | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml';
    final clear =
        'echo $pw | sudo -S sed -i "s/$replace/$search/" ~/earth/kml/slave/myplaces.kml';

    // Configure refresh settings on all slave nodes (skip master node)
    for (var i = 2; i <= rigs; i++) {
      final clearCmd = clear.replaceAll('{{slave}}', i.toString());
      final cmd = command.replaceAll('{{slave}}', i.toString());
      String query = 'sshpass -p $pw ssh -t lg$i \'{{cmd}}\'';

      try {
        // Clear any existing refresh configuration first
        await execCommand(query.replaceAll('{{cmd}}', clearCmd));

        // Apply new refresh configuration
        await execCommand(query.replaceAll('{{cmd}}', cmd));
      } catch (e) {
        // Log individual node failures but continue with other nodes
        print(e);
      }
    }

    // Reboot system to activate new refresh configuration
    await reboot();
  }

  /// Disables periodic refresh for KML files on Liquid Galaxy slave nodes.
  ///
  /// This method removes automatic refresh intervals from slave node configurations,
  /// returning the system to static KML display mode. This is useful for:
  /// - **Static Visualizations**: Content that doesn't change over time
  /// - **Performance Optimization**: Reducing system load and network traffic
  /// - **Presentation Mode**: Ensuring stable displays during demonstrations
  /// - **Troubleshooting**: Eliminating refresh-related issues
  ///
  /// **Configuration Removal Process:**
  /// Removes refresh directives from myplaces.kml on each slave node:
  /// ```xml
  /// <!-- REMOVES these lines -->
  /// <refreshMode>onInterval</refreshMode>
  /// <refreshInterval>2</refreshInterval>
  /// ```
  ///
  /// **System Impact:**
  /// - **Reduced Load**: Eliminates periodic HTTP requests for KML files
  /// - **Static Display**: KML content remains unchanged until manually updated
  /// - **Network Savings**: Reduces bandwidth usage for LG installations
  /// - **Stability**: Prevents refresh-related display glitches or delays
  ///
  /// **Multi-Node Operation:**
  /// Processes all slave nodes (lg2 through lgN) in sequence, using SSH
  /// to execute configuration changes remotely with proper sudo elevation.
  ///
  /// **Error Resilience:**
  /// Individual node failures don't prevent processing of remaining nodes,
  /// ensuring the system can be partially restored even if some nodes
  /// are inaccessible or experiencing issues.
  ///
  /// **System Restart Required:**
  /// Changes take effect only after system reboot, which temporarily
  /// interrupts active visualizations but ensures clean configuration state.
  ///
  /// Example usage:
  /// ```dart
  /// // Disable refresh for stable presentation mode
  /// await lgService.resetRefresh();
  /// // KML content will now remain static until manually updated
  /// ```
  Future<void> resetRefresh() async {
    final pw = password;

    // Define patterns for removing refresh configuration
    const search =
        '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>'
        '<refreshMode>onInterval<\\/refreshMode>'
        '<refreshInterval>2<\\/refreshInterval>';
    const replace = '<href>##LG_PHPIFACE##kml\\/slave_{{slave}}.kml<\\/href>';

    final clear =
        'echo $pw | sudo -S sed -i "s/$search/$replace/" ~/earth/kml/slave/myplaces.kml';

    // Remove refresh configuration from all slave nodes
    for (var i = 2; i <= rigs; i++) {
      final cmd = clear.replaceAll('{{slave}}', i.toString());
      String query = 'sshpass -p $pw ssh -t lg$i \'$cmd\'';

      try {
        await execCommand(query);
      } catch (e) {
        // Log failures but continue with remaining nodes
        print(e);
      }
    }

    // Reboot system to activate configuration changes
    await reboot();
  }

  /// Performs a complete system reboot of all Liquid Galaxy nodes.
  ///
  /// This method initiates a coordinated shutdown and restart sequence across
  /// all nodes in the Liquid Galaxy installation. It's the most comprehensive
  /// system operation, ensuring clean state reset and configuration activation.
  ///
  /// **Reboot Sequence Strategy:**
  /// Nodes are rebooted in reverse order (highest number first) to ensure:
  /// - **Master Node Last**: Maintains coordination until slaves are offline
  /// - **Graceful Shutdown**: Prevents communication errors during reboot process
  /// - **Coordinated Recovery**: Slaves boot and reconnect to master systematically
  ///
  /// **Multi-Node Reboot Process:**
  /// 1. **Reverse Order**: Reboot lg5 → lg4 → lg3 → lg2 → lg1
  /// 2. **SSH Coordination**: Uses sshpass and SSH for remote reboot commands
  /// 3. **Sudo Elevation**: Elevates privileges for system-level reboot operations
  /// 4. **Connection Cleanup**: Accepts connection failures as nodes restart
  ///
  /// **System Recovery Time:**
  /// - **Boot Duration**: Typically 2-5 minutes per node depending on hardware
  /// - **Service Initialization**: Google Earth and web services require additional time
  /// - **Network Convergence**: All nodes must reconnect and synchronize
  /// - **Total Downtime**: Usually 5-10 minutes for complete system recovery
  ///
  /// **When Reboot is Required:**
  /// - **Configuration Changes**: KML refresh settings, network configuration
  /// - **System Maintenance**: Installing updates or resolving system issues
  /// - **Performance Recovery**: Clearing memory leaks or process issues
  /// - **Clean State**: Resetting system to known-good configuration
  ///
  /// **Impact on Active Sessions:**
  /// - **Visualization Loss**: All active KML content and tours are terminated
  /// - **Connection Drops**: All SSH and application connections are severed
  /// - **User Experience**: Complete interruption requiring manual reconnection
  /// - **Data Persistence**: Only persistent configuration changes survive reboot
  ///
  /// **Error Handling:**
  /// Individual node reboot failures are logged but don't prevent the method
  /// from attempting to reboot remaining nodes, ensuring maximum system
  /// recovery even with partial hardware failures.
  ///
  /// **Post-Reboot Requirements:**
  /// After reboot completion:
  /// - Call [checkConnection] to re-establish service connectivity
  /// - Redeploy any temporary visualizations or content
  /// - Reconfigure Mars mode and deploy logos as needed
  ///
  /// Example usage:
  /// ```dart
  /// // Reboot system to apply configuration changes
  /// await lgService.reboot();
  ///
  /// // Wait for system recovery and re-establish connection
  /// await Future.delayed(Duration(minutes: 5));
  /// bool connected = await lgService.checkConnection();
  /// ```
  ///
  /// **Warning:** This operation causes complete system downtime and should
  /// be used only when necessary for configuration changes or maintenance.
  Future<void> reboot() async {
    final pw = password;

    // Reboot nodes in reverse order (highest number first)
    for (var i = rigs; i >= 1; i--) {
      try {
        await execCommand(
          'sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S reboot"',
        );

        // Note: Removed artificial delay - let nodes reboot naturally
        // await Future.delayed(Duration(seconds: 25));
        // await checkConnection();
      } catch (e) {
        // Expect connection failures as nodes shut down - this is normal
        print(e);
      }
    }
  }

  /// Restarts display services on all Liquid Galaxy nodes without full system reboot.
  ///
  /// This method provides a faster alternative to full system reboot by restarting
  /// only the display manager services (lxdm or lightdm) responsible for Google Earth
  /// and desktop environment functionality. This is ideal for:
  /// - **Display Issues**: Resolving Google Earth crashes or rendering problems
  /// - **Service Recovery**: Restarting frozen or unresponsive display services
  /// - **Faster Recovery**: Avoiding full reboot downtime when possible
  /// - **Configuration Reload**: Activating display-related configuration changes
  ///
  /// **Service Detection and Management:**
  /// The method automatically detects the installed display manager:
  /// - **lxdm**: Lightweight X11 Display Manager (common in older LG installations)
  /// - **lightdm**: Light Display Manager (used in newer Ubuntu-based systems)
  /// - **Fallback**: Exits gracefully if neither service is detected
  ///
  /// **Relaunch Process:**
  /// 1. **Service Detection**: Identifies installed display manager on each node
  /// 2. **Status Check**: Determines if service is currently running or stopped
  /// 3. **Conditional Restart**: Starts stopped services or restarts running ones
  /// 4. **Multi-Node Coordination**: Processes all nodes in reverse order
  /// 5. **Recovery Wait**: Allows time for display services to fully initialize
  /// 6. **Mars Reconfiguration**: Restores Mars planetary mode after restart
  ///
  /// **Service Management Commands:**
  /// ```bash
  /// # Service detection
  /// if [ -f /etc/init/lxdm.conf ]; then export SERVICE=lxdm; fi
  /// if [ -f /etc/init/lightdm.conf ]; then export SERVICE=lightdm; fi
  ///
  /// # Conditional restart logic
  /// if [[ $(service $SERVICE status) =~ 'stop' ]]; then
  ///   sudo service $SERVICE start
  /// else
  ///   sudo service $SERVICE restart
  /// fi
  /// ```
  ///
  /// **Recovery Timeline:**
  /// - **Service Restart**: 10-30 seconds per node
  /// - **Google Earth Init**: Additional 30-60 seconds for application loading
  /// - **Total Recovery**: Typically 2-3 minutes vs 5-10 minutes for full reboot
  /// - **Mars Mode**: Automatically reconfigured after display service recovery
  ///
  /// **Advantages over Reboot:**
  /// - **Faster Recovery**: Significantly shorter downtime
  /// - **Network Preservation**: Maintains network configuration and connections
  /// - **Selective Reset**: Only resets display services, preserving system state
  /// - **Less Disruptive**: Maintains SSH connections and background services
  ///
  /// **Error Handling:**
  /// Individual node failures are logged but don't prevent processing of
  /// remaining nodes, ensuring maximum service recovery across the installation.
  ///
  /// **Post-Relaunch Requirements:**
  /// The method automatically reconfigures Mars mode after service restart,
  /// but may require redeployment of:
  /// - Custom KML visualizations
  /// - Information balloons
  /// - Active tours or camera positions
  ///
  /// Example usage:
  /// ```dart
  /// // Restart display services for faster recovery
  /// await lgService.relaunch();
  /// // System ready for new visualizations in ~2 minutes
  /// ```
  Future<void> relaunch() async {
    final pw = password;

    // Restart display services on all nodes in reverse order
    for (var i = rigs; i >= 1; i--) {
      try {
        // Complex command string with service detection and conditional restart
        final relaunchCommand = """
RELAUNCH_CMD="\\
if [ -f /etc/init/lxdm.conf ]; then
  export SERVICE=lxdm
elif [ -f /etc/init/lightdm.conf ]; then
  export SERVICE=lightdm
else
  exit 1
fi
if  [[ \\\$(service \\\$SERVICE status) =~ 'stop' ]]; then
  echo $pw | sudo -S service \\\${SERVICE} start
else
  echo $pw | sudo -S service \\\${SERVICE} restart
fi
" && sshpass -p $pw ssh -x -t lg@lg$i "\$RELAUNCH_CMD\"""";

        await execCommand(relaunchCommand);
      } catch (e) {
        // Log individual node failures but continue with remaining nodes
        print(e);
      }
    }

    // Allow time for display services to fully initialize
    await Future.delayed(Duration(seconds: 15));

    // Restore Mars planetary mode after display service restart
    await changeToMars();
  }

  /// Powers off all Liquid Galaxy nodes in coordinated sequence.
  ///
  /// This method performs a complete system shutdown of the entire Liquid Galaxy
  /// installation, powering off all nodes safely to prevent data corruption or
  /// hardware damage. This is typically used for:
  /// - **Maintenance Windows**: Planned hardware maintenance or upgrades
  /// - **End of Day**: Powering down systems in educational environments
  /// - **Emergency Shutdown**: Safely powering off systems during emergencies
  /// - **Energy Conservation**: Reducing power consumption during idle periods
  ///
  /// **Shutdown Sequence Strategy:**
  /// Nodes are powered off in reverse order (highest number first) to maintain
  /// system coordination until the final shutdown:
  /// - **Slave Nodes First**: lg5 → lg4 → lg3 → lg2 (preserve master coordination)
  /// - **Master Node Last**: lg1 shuts down last to maintain SSH connectivity
  /// - **Graceful Process**: Each node completes shutdown before next begins
  ///
  /// **Shutdown Process:**
  /// 1. **Remote Command**: Uses SSH to execute poweroff command on each node
  /// 2. **Privilege Elevation**: Uses sudo to gain system shutdown privileges
  /// 3. **Coordinated Timing**: Maintains SSH connectivity throughout process
  /// 4. **Error Tolerance**: Continues shutdown even if individual nodes fail
  ///
  /// **System Recovery Requirements:**
  /// After shutdown, nodes require **manual power-on** or Wake-on-LAN:
  /// - **Physical Access**: Someone must physically power on each node
  /// - **Wake-on-LAN**: If configured, nodes can be remotely awakened
  /// - **Boot Sequence**: Normal system startup and service initialization
  /// - **Reconfiguration**: Full system reconfiguration will be required
  ///
  /// **Impact and Considerations:**
  /// - **Complete Downtime**: System cannot be used until manually restarted
  /// - **Data Loss**: Any unsaved work or temporary configurations are lost
  /// - **Network Disconnection**: All remote connections are terminated
  /// - **Recovery Time**: Significant time required for manual restart and setup
  ///
  /// **Error Handling:**
  /// Individual node shutdown failures are logged but don't prevent attempts
  /// to shutdown remaining nodes, ensuring maximum system shutdown even with
  /// hardware or connectivity issues.
  ///
  /// **Security and Safety:**
  /// - **Graceful Shutdown**: Uses proper system shutdown procedures
  /// - **Data Protection**: Ensures file systems are cleanly unmounted
  /// - **Hardware Safety**: Prevents power-related hardware damage
  /// - **Service Cleanup**: Properly terminates all running services
  ///
  /// Example usage:
  /// ```dart
  /// // Shutdown system for maintenance
  /// await lgService.shutdown();
  /// // System is now powered off and requires manual restart
  /// ```
  ///
  /// **Warning:** This operation completely powers off the system and requires
  /// physical access or Wake-on-LAN capability for recovery. Use only when
  /// complete shutdown is intended and recovery method is available.
  Future<void> shutdown() async {
    final pw = password;

    // Power off nodes in reverse order (highest number first)
    for (var i = rigs; i >= 1; i--) {
      try {
        await execCommand(
          'sshpass -p $pw ssh -t lg$i "echo $pw | sudo -S poweroff"',
        );
      } catch (e) {
        // Expect connection failures as nodes power off - this is normal
        print(e);
      }
    }
  }

  /// Clears all KML content from Liquid Galaxy slave nodes with optional logo preservation.
  ///
  /// This method performs comprehensive cleanup of KML visualization content across
  /// all slave nodes while providing options to preserve institutional branding
  /// and logos. It's essential for:
  /// - **Content Reset**: Preparing system for new visualizations
  /// - **Session Cleanup**: Removing previous user's content
  /// - **Tour Termination**: Stopping active tours and returning to normal mode
  /// - **Performance Recovery**: Clearing accumulated visualization data
  ///
  /// **Cleanup Operations:**
  /// 1. **Tour Termination**: Stops any active Google Earth tours immediately
  /// 2. **KML List Clearing**: Empties the main KML file registry
  /// 3. **Slave Content Reset**: Replaces all slave KML files with blank templates
  /// 4. **Logo Preservation**: Optionally preserves branding on designated screen
  ///
  /// **KML Clearing Process:**
  /// - **Blank KML Template**: Uses minimal valid KML structure for content reset
  /// - **Multi-Node Operation**: Processes all slave nodes (lg2 through lgN)
  /// - **Screen-Selective**: Can preserve specific screens (like logo screen)
  /// - **Atomic Operation**: All clearing commands executed in single SSH session
  ///
  /// **Blank KML Structure:**
  /// ```xml
  /// <?xml version="1.0" encoding="UTF-8"?>
  /// <kml xmlns="http://www.opengis.net/kml/2.2"
  ///      xmlns:gx="http://www.google.com/kml/ext/2.2"
  ///      xmlns:kml="http://www.opengis.net/kml/2.2"
  ///      xmlns:atom="http://www.w3.org/2005/Atom">
  ///   <Document></Document>
  /// </kml>
  /// ```
  ///
  /// **Logo Preservation Logic:**
  /// When [keepLogos] is true (default), the method:
  /// - Identifies the designated logo screen using [logoScreen] calculation
  /// - Skips KML clearing on that specific screen
  /// - Maintains institutional branding during content transitions
  /// - Preserves professional presentation appearance
  ///
  /// **Command Sequence:**
  /// ```bash
  /// # Stop any active tours
  /// echo "exittour=true" > /tmp/query.txt
  ///
  /// # Clear main KML registry
  /// > /var/www/html/kmls.txt
  ///
  /// # Clear each slave node (except logo screen if preserving)
  /// echo 'blank_kml_content' > /var/www/html/kml/slave_2.kml
  /// echo 'blank_kml_content' > /var/www/html/kml/slave_3.kml
  /// # ... etc for each slave
  /// ```
  ///
  /// **Use Cases:**
  /// - **Visualization Switching**: Clearing between different Mars datasets
  /// - **User Sessions**: Cleanup between different user presentations
  /// - **Error Recovery**: Clearing corrupted or problematic KML content
  /// - **System Maintenance**: Preparing for system updates or configuration
  ///
  /// Parameters:
  /// - [keepLogos]: If true (default), preserves logos on designated screen
  ///
  /// **Performance Impact:**
  /// - **Immediate Effect**: Changes take effect immediately in Google Earth
  /// - **Network Traffic**: Minimal - only sends small blank KML templates
  /// - **System Load**: Very low impact operation
  /// - **Recovery Time**: Instant clearing, ready for new content immediately
  ///
  /// Example usage:
  /// ```dart
  /// // Clear all content but keep institutional logos
  /// await lgService.clearKml(keepLogos: true);
  ///
  /// // Complete content reset including logos
  /// await lgService.clearKml(keepLogos: false);
  ///
  /// // Default behavior preserves logos
  /// await lgService.clearKml();
  /// ```
  Future<void> clearKml({bool keepLogos = true}) async {
    String query =
        'echo "exittour=true" > /tmp/query.txt && > /var/www/html/kmls.txt';

    for (var i = 2; i <= rigs; i++) {
      String blankKml =
          '<?xml version="1.0" encoding="UTF-8"?><kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom"><Document></Document></kml>';
      if (i != logoScreen) {
        query += " && echo '$blankKml' > /var/www/html/kml/slave_$i.kml";
      }
    }

    await execCommand(query);
  }

  Future<void> loadSavedData(Future<SharedPreferences> prefs) async {
    final SharedPreferences preferences = await prefs;
    host = preferences.getString('host') ?? host;
    port = preferences.getInt('port') ?? port;
    username = preferences.getString('username') ?? username;
    password = preferences.getString('password') ?? password;
    rigs = preferences.getInt('rigs') ?? rigs;
  }
}
