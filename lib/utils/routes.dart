import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/pages/connection_page.dart';
import 'package:martian_climate_dashboard/pages/home_page.dart';
import 'package:martian_climate_dashboard/pages/tools_page.dart';

Map<String, WidgetBuilder> routes(context) => {
  '/': (context) => HomePage(),
  '/connect': (context) => ConnectPage(),
  '/tools': (context) => ToolsPage(),
};
