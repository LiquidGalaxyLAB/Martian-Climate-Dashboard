import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:provider/provider.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    LgService lgService = Provider.of<LgService>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: const Text("Mars Vision")),
      // backgroundColor: ThemeColors.backgroundColor,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Text(
              "Liquid Galaxy Tools",
              style: TextStyle(
                // color: ThemeColors.primaryTextColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ToolTile(
            toolName: "Relaunch LG",
            iconData: Icons.autorenew,
            onTap: () {
              lgService.relaunch();
            },
          ),
          ToolTile(
            toolName: "Reboot LG",
            iconData: Icons.refresh_outlined,
            onTap: () {
              lgService.reboot();
            },
          ),
          ToolTile(
            toolName: "Power Off",
            iconData: Icons.power_settings_new,
            onTap: () {
              lgService.shutdown();
            },
          ),
          ToolTile(
            toolName: "Clean KMLs",
            iconData: Icons.cleaning_services,
            onTap: () {
              lgService.clearKml();
            },
          ),
          ToolTile(
            toolName: "Set Slave Refresh",
            iconData: Icons.timer_outlined,
            onTap: () {
              lgService.setRefresh();
            },
          ),
          ToolTile(
            toolName: "Reset Slave Refresh",
            iconData: Icons.timer_off_outlined,
            onTap: () {
              lgService.resetRefresh();
            },
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
