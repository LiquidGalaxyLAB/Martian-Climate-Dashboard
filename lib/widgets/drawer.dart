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

class MCDDrawer extends StatelessWidget {
  const MCDDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: const RoundedRectangleBorder(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 100,
            child: DrawerHeader(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              // padding: EdgeInsets.symmetric(horizontal: .0, vertical: 10.0),
              child: Text(
                "Mars Vision",
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          ListTile(
            textColor: Colors.black,
            leading: const Icon(Icons.settings_outlined),
            title: Text('Connection'),
            onTap: () {
              Navigator.pushNamed(context, '/connect');
            },
          ),
          ListTile(
            textColor: Colors.black,
            leading: const Icon(Icons.build_outlined),
            title: Text('Tools'),
            onTap: () {
              Navigator.pushNamed(context, '/tools');
            },
          ),
        ],
      ),
    );
  }
}
