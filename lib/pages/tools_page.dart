import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:provider/provider.dart';

/// A utility page providing system administration tools for Liquid Galaxy installations.
///
/// This page offers essential maintenance and control functions for managing Liquid Galaxy
/// systems remotely from the Martian Climate Dashboard. It provides secure access to
/// critical system operations including power management, content clearing, and refresh
/// control. All operations require explicit user confirmation to prevent accidental
/// system disruptions.
///
/// Available tools include:
/// - System lifecycle management (relaunch, reboot, shutdown)
/// - Content management (KML clearing and refresh control)
/// - Connection validation and status checking
///
/// Features:
/// - Confirmation dialogs for all destructive operations
/// - Clear visual feedback with descriptive icons
/// - Secure operation execution through SSH
/// - Automatic connection status updates after system operations
///
/// Example usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(builder: (context) => const ToolsPage()),
/// );
/// ```
class ToolsPage extends StatelessWidget {
  /// Creates a Liquid Galaxy tools administration page.
  ///
  /// This stateless widget provides a clean interface for system administration
  /// operations with appropriate security measures and user confirmation flows.
  const ToolsPage({super.key});

  /// Displays a confirmation dialog for potentially destructive operations.
  ///
  /// Implements a standardized confirmation pattern for all system administration
  /// actions. The dialog follows Material Design principles with clear messaging,
  /// prominent action buttons, and appropriate visual hierarchy.
  ///
  /// Dialog features:
  /// - Rounded corners for modern appearance
  /// - Bottom-aligned positioning for mobile accessibility
  /// - Full-width action buttons with clear Yes/No options
  /// - Descriptive title and explanation text
  /// - Colored button styling to indicate action severity
  ///
  /// Parameters:
  /// - [context]: Build context for dialog display
  /// - [title]: Primary question displayed to the user
  /// - [description]: Detailed explanation of the operation and its consequences
  /// - [onConfirm]: Async function to execute if user confirms the action
  ///
  /// The dialog returns a boolean indicating user choice, with `null` treated
  /// as cancellation. Only executes the confirmation callback for explicit `true`.
  ///
  /// Example:
  /// ```dart
  /// await _showConfirmationDialog(
  ///   context,
  ///   "Reboot System?",
  ///   "This will restart all Liquid Galaxy nodes.",
  ///   () => lgService.reboot(),
  /// );
  /// ```
  Future<void> _showConfirmationDialog(
    BuildContext context,
    String title,
    String description,
    Future<void> Function() onConfirm,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            /// Modern rounded dialog appearance
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),

            /// Bottom-aligned positioning for mobile accessibility
            alignment: Alignment.bottomCenter,
            insetPadding: const EdgeInsets.only(
              bottom: 0.0,
              left: 20.0,
              right: 20.0,
            ),

            /// Clear, prominent title question
            title: Text(title, textAlign: TextAlign.center),

            /// Remove default action area for custom button layout
            actions: null,
            actionsPadding: EdgeInsets.zero,
            buttonPadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            actionsAlignment: MainAxisAlignment.center,

            /// Custom content with description and action buttons
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                /// Detailed operation description
                Text(description, textAlign: TextAlign.center),
                const SizedBox(height: 20),

                /// Primary confirmation button (destructive action)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Yes'),
                  ),
                ),
                const SizedBox(height: 8),

                /// Secondary cancellation button (safe action)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Colors.black, width: 2.0),
                    ),
                    child: const Text(
                      'No, take me back',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );

    // Execute the operation only if user explicitly confirmed
    if (confirmed == true) {
      await onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access LG service for system operations (listen: false for performance)
    LgService lgService = Provider.of<LgService>(context, listen: false);

    return Scaffold(
      /// Standard app bar with application title
      appBar: AppBar(title: const Text("Mars Vision")),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),

          /// Page section header
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.0),
            child: Text(
              "Liquid Galaxy Tools",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),

          /// Tool tiles container with consistent padding
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                /// System Relaunch Tool
                /// Restarts Google Earth instances without full system reboot
                /// Less disruptive than full reboot but may clear active content
                ToolTile(
                  toolName: "Relaunch LG",
                  iconData: Icons.autorenew,
                  onTap: () async {
                    await _showConfirmationDialog(
                      context,
                      "Are you sure you want to relaunch?",
                      "This will relaunch the system and may interrupt any running visualizations.",
                      () async {
                        // Perform relaunch and validate new connection status
                        await lgService.relaunch();
                        await lgService.checkConnection();
                      },
                    );
                  },
                ),

                /// System Reboot Tool
                /// Full system restart of all Liquid Galaxy nodes
                /// Most disruptive operation, clears all content and connections
                ToolTile(
                  toolName: "Reboot LG",
                  iconData: Icons.refresh_outlined,
                  onTap:
                      () => _showConfirmationDialog(
                        context,
                        "Are you sure you want to reboot?",
                        "This will reboot the system and may interrupt any running visualizations.",
                        lgService.reboot,
                      ),
                ),

                /// System Shutdown Tool
                /// Powers off all Liquid Galaxy nodes
                /// Requires physical access or Wake-on-LAN to restart
                ToolTile(
                  toolName: "Power Off",
                  iconData: Icons.power_settings_new,
                  onTap:
                      () => _showConfirmationDialog(
                        context,
                        "Are you sure you want to power off?",
                        "This will power off the system and may interrupt any running visualizations.",
                        lgService.shutdown,
                      ),
                ),

                /// KML Content Clearing Tool
                /// Removes visualization data while preserving system logos
                /// Useful for clearing outdated or test visualizations
                ToolTile(
                  toolName: "Clean KMLs",
                  iconData: Icons.cleaning_services,
                  onTap:
                      () => _showConfirmationDialog(
                        context,
                        "Are you sure you want to clear KMLs?",
                        "This will clear all KML files on the slaves, but will keep the logos.",
                        lgService.clearKml,
                      ),
                ),

                /// Refresh Timer Activation Tool
                /// Enables periodic refresh of KML content on slave nodes
                /// Useful for dynamic content that needs regular updates
                ToolTile(
                  toolName: "Set Slave Refresh",
                  iconData: Icons.timer_outlined,
                  onTap:
                      () => _showConfirmationDialog(
                        context,
                        "Are you sure you want to set slave refresh?",
                        "This will enable periodic refresh for KML files on the slaves.",
                        lgService.setRefresh,
                      ),
                ),

                /// Refresh Timer Deactivation Tool
                /// Disables periodic refresh to reduce system load
                /// Recommended for static content or performance optimization
                ToolTile(
                  toolName: "Reset Slave Refresh",
                  iconData: Icons.timer_off_outlined,
                  onTap:
                      () => _showConfirmationDialog(
                        context,
                        "Are you sure you want to reset slave refresh?",
                        "This will disable periodic refresh for KML files on the slaves.",
                        lgService.resetRefresh,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A reusable tile widget for displaying individual system administration tools.
///
/// Provides consistent styling and interaction patterns for all tools in the
/// administration interface. Each tile includes an icon, descriptive text,
/// and tap handling for the associated operation.
///
/// Features:
/// - Consistent Material Design ListTile styling
/// - Icon-based visual identification of tool functions
/// - Touch-friendly interaction area
/// - Accessible text and icon combination
///
/// The tile follows Material Design principles with appropriate touch targets
/// and visual feedback for user interactions.
class ToolTile extends StatelessWidget {
  /// The display name of the administrative tool.
  ///
  /// Should be concise and clearly describe the tool's function.
  /// Examples: "Relaunch LG", "Clear KMLs", "Power Off"
  final String toolName;

  /// The icon representing the tool's function.
  ///
  /// Should be visually descriptive and consistent with Material Design
  /// icon guidelines. Icons help users quickly identify tool purposes.
  final IconData iconData;

  /// Callback function executed when the tool tile is tapped.
  ///
  /// Typically triggers the confirmation dialog and subsequent tool operation.
  /// Should handle all necessary error conditions and user feedback.
  final VoidCallback onTap;

  /// Creates a tool tile with the specified name, icon, and action.
  ///
  /// Parameters:
  /// - [toolName]: Display text for the tool
  /// - [iconData]: Icon representing the tool's function
  /// - [onTap]: Callback executed when tile is tapped
  ///
  /// Example:
  /// ```dart
  /// ToolTile(
  ///   toolName: "Reboot System",
  ///   iconData: Icons.refresh,
  ///   onTap: () => performReboot(),
  /// );
  /// ```
  const ToolTile({
    super.key,
    required this.toolName,
    required this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      /// Leading icon for visual tool identification
      leading: Icon(iconData),

      /// Tool name as primary text content
      title: Text(toolName),

      /// Tap handler for tool activation
      onTap: onTap,
    );
  }
}
