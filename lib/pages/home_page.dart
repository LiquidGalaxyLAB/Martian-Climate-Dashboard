import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
import 'package:martian_climate_dashboard/widgets/picker.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mars Vision')),
      drawer: MCDDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              "Visualize Mars Conditions",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13.0),
              child: ParameterPicker(
                hintText: 'Select Parameter',
                selectedParameter: 'temperature',
              ),
            ),
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(13.0),
              child: ParameterPicker(
                hintText: 'Mars Atmospheric Scenario',
                selectedParameter: 'Martian Year 35',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
