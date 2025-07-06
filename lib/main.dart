//    await sshConnection.sendCommand('echo \'planet=$planet\' > /tmp/query.txt');

import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/utils/routes.dart';
import 'package:martian_climate_dashboard/utils/themedata.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [Provider<LgService>(create: (_) => LgService())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mars Vision',
      routes: routes(context),
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}
