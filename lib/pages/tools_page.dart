import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:provider/provider.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            alignment: Alignment.bottomCenter,
            insetPadding: const EdgeInsets.only(
              bottom: 0.0,
              left: 20.0,
              right: 20.0,
            ),
            title: Text(title, textAlign: TextAlign.center),
            actions: null,
            actionsPadding: EdgeInsets.zero,
            buttonPadding: EdgeInsets.zero,
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            actionsAlignment: MainAxisAlignment.center,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(description, textAlign: TextAlign.center),
                const SizedBox(height: 20),
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
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: Colors.white,
                      side: BorderSide(color: Colors.black, width: 2.0),
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

    if (confirmed == true) {
      await onConfirm();
    }
  }

  @override
  Widget build(BuildContext context) {
    LgService lgService = Provider.of<LgService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text("Mars Vision")),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Text(
              "Liquid Galaxy Tools",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              children: [
                ToolTile(
                  toolName: "Relaunch LG",
                  iconData: Icons.autorenew,
                  onTap: () async {
                    await _showConfirmationDialog(
                      context,
                      "Are you sure you want to relaunch?",
                      "This will relaunch the system and may interupt any running visualizations.",
                      () async {
                        await lgService.relaunch();
                        await lgService.checkConnection();
                      },
                    );
                  },
                ),
                ToolTile(
                  toolName: "Reboot LG",
                  iconData: Icons.refresh_outlined,
                  onTap:
                      () => _showConfirmationDialog(
                        context,
                        "Are you sure you want to reboot?",
                        "This will reboot the system and may interupt any running visualizations.",
                        lgService.reboot,
                      ),
                ),
                ToolTile(
                  toolName: "Power Off",
                  iconData: Icons.power_settings_new,
                  onTap:
                      () => _showConfirmationDialog(
                        context,
                        "Are you sure you want to power off?",
                        "This will power off the system and may interupt any running visualizations.",
                        lgService.shutdown,
                      ),
                ),
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

class ToolTile extends StatelessWidget {
  final String toolName;
  final IconData iconData;
  final VoidCallback onTap;
  const ToolTile({
    super.key,
    required this.toolName,
    required this.iconData,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(iconData),
      title: Text(toolName),
      onTap: onTap,
    );
  }
}
