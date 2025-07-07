import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';

class VisualizationPage extends StatelessWidget {
  const VisualizationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MCDDrawer(),
      appBar: AppBar(
        title: const Text('Mars Vision'),
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const <Widget>[
            Text('Visualization Page', style: TextStyle(fontSize: 24)),
            SizedBox(height: 20),
            Text(
              'This page will present a summary of the KML data and enable answering questions using AI.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
