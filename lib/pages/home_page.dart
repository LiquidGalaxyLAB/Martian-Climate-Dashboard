import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/widgets/button.dart';
import 'package:martian_climate_dashboard/widgets/check_box.dart';
import 'package:martian_climate_dashboard/widgets/date_picker.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
import 'package:martian_climate_dashboard/widgets/parameter_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isDateRangeEnabled = false;
  bool isGridEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mars Vision')),
      drawer: MCDDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
                SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 13.0),
                  child: Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ),
                SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: DatePicker(
                        onDateSelected: (p0) => print(p0.toIso8601String()),
                        enabled: true,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(right: 16),
                      child: DatePicker(
                        onDateSelected: (p0) => print(p0.toIso8601String()),
                        enabled: false,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                CheckBox(
                  onChange:
                      (value) => setState(() {
                        isDateRangeEnabled = value ?? false;
                      }),
                  isChecked: isDateRangeEnabled,
                  text: "Visualize data over a date range",
                ),
                SizedBox(height: 7),
                CheckBox(
                  onChange:
                      (value) => setState(() {
                        isGridEnabled = value ?? false;
                      }),
                  isChecked: isGridEnabled,
                  text: "Show grid lines",
                ),
              ],
            ),
            MCDButton(
              onPressed: () {
                print('Visualize Data Pressed');
              },
              text: 'Visualize Data',
            ),
          ],
        ),
      ),
    );
  }
}
