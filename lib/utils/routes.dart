// Defines the application's named routes and their corresponding widget builders.

import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/pages/about_page.dart';
import 'package:martian_climate_dashboard/pages/api_key.dart';
import 'package:martian_climate_dashboard/pages/connection_page.dart';
import 'package:martian_climate_dashboard/pages/home_page.dart';
import 'package:martian_climate_dashboard/pages/qr_page.dart';
import 'package:martian_climate_dashboard/pages/splash_screen.dart';
import 'package:martian_climate_dashboard/pages/tools_page.dart';
import 'package:martian_climate_dashboard/pages/visualization_page.dart';

Map<String, WidgetBuilder> routes(context) => {
  '/': (context) => SplashScreen(),
  '/home': (context) => HomePage(),
  '/connect': (context) => ConnectPage(),
  '/tools': (context) => ToolsPage(),
  '/scan': (context) => QRPage(),
  // '/visualization': (context) => Visualizat  ionPage(),
  '/about': (context) => const AboutPage(),
  '/apiKey': (context) => const ApiKeyPage(),
};
