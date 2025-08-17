/// A custom [Drawer] widget for the Mars Vision app.
///
/// This drawer provides navigation options for the application, including:
/// - A header displaying the app name.
/// - A "Connection" option that navigates to the '/connect' route.
/// - A "Tools" option that navigates to the '/tools' route.
///
/// The drawer uses a simple [Column] layout and applies theming to the header text.
library;

import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:provider/provider.dart';

class MCDDrawer extends StatelessWidget {
  const MCDDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    LgService lgService = Provider.of<LgService>(context);
    return Drawer(
      shape: const RoundedRectangleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            child: DrawerHeader(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    "Mars Vision",
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 12.0),
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: lgService.connected ? Colors.green : Colors.red,
                      // color: Colors.red,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            textColor: Colors.black,
            leading: const Icon(Icons.settings_outlined),
            title: Text('Connection'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/connect');
            },
          ),
          ListTile(
            textColor: Colors.black,
            leading: const Icon(Icons.build_outlined),
            title: Text('Tools'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/tools');
            },
          ),
          ListTile(
            textColor: Colors.black,
            leading: const Icon(Icons.code_outlined),
            title: Text('API Key'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/apiKey');
            },
          ),
          ListTile(
            textColor: Colors.black,
            leading: const Icon(Icons.info_outline),
            title: Text('About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/about');
            },
          ),
        ],
      ),
    );
  }
}
