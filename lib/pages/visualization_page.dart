import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/entities/state_entity.dart';
import 'package:martian_climate_dashboard/services/gemini_service.dart';
import 'package:martian_climate_dashboard/services/kml_service.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
import 'package:provider/provider.dart';

class VisualizationPage extends StatefulWidget {
  const VisualizationPage({super.key});

  @override
  State<VisualizationPage> createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage> {
  late GeminiService? geminiService;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadData() async {}

  @override
  Widget build(BuildContext context) {
    StateEntity stateEntity = Provider.of<StateEntity>(context, listen: false);
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: "orbit",
        onPressed: () async {
          LgService lgService = Provider.of<LgService>(context, listen: false);
          String kmlData = KmlService.generateOrbit(3000);
          await lgService.sendFile(
            '/var/www/html/orbit.kml',
            (utf8.encode(kmlData)),
          );
          print(kmlData);
          await lgService.execCommand(
            'echo "http://lg1:81/Orbit.kml" >> /var/www/html/kmls.txt',
          );
          await lgService.execCommand('echo "playtour=Orbit" > /tmp/query.txt');
        },
        child: const Icon(Icons.track_changes),
      ),
      drawer: MCDDrawer(),
      appBar: AppBar(
        title: const Text('Mars Vision'),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              '${parameterMap[stateEntity.param]} Visualization',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            // SizedBox(height: 20),
            Text(
              (() {
                final monthNames = [
                  'January',
                  'February',
                  'March',
                  'April',
                  'May',
                  'June',
                  'July',
                  'August',
                  'September',
                  'October',
                  'November',
                  'December',
                ];
                return '${monthNames[stateEntity.date!.month - 1]} ${stateEntity.date!.day}, ${stateEntity.date!.year}';
              })(),
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
