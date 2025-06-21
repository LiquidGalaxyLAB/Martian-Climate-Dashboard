import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/services/api_service.dart';
import 'package:martian_climate_dashboard/services/kml_generatation_service.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/widgets/button.dart';
import 'package:martian_climate_dashboard/widgets/check_box.dart';
import 'package:martian_climate_dashboard/widgets/date_picker.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
import 'package:martian_climate_dashboard/widgets/parameter_picker.dart';
import 'package:provider/provider.dart';

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
              onPressed: () async {
                print('Visualize Data Pressed');
                ApiService apiService = ApiService();
                final apiEntity =
                    ApiEntity()
                      ..variable = "t"
                      ..datekeyhtml = 1
                      ..ls = 99.5
                      ..localtime = 0.0
                      ..year = 2025
                      ..month = 6
                      ..day = 20
                      ..hours = 13
                      ..minutes = 42
                      ..seconds = 57
                      ..julian = 2460847.0714930557
                      ..martianyear = 38
                      ..sol = 215
                      ..latitude = "all"
                      ..longitude = "all"
                      ..altitude = 10.0
                      ..zkey = 3
                      ..spacecraft = "none"
                      ..isfixedlt = "off"
                      ..dust = "1"
                      ..hrkey = 1
                      ..averaging = "off"
                      ..dpi = 80
                      ..islog = "off"
                      ..colorm = "jet"
                      ..minval = ""
                      ..maxval = ""
                      ..proj = "cyl"
                      ..palt = null
                      ..plon = null
                      ..plat = null;
                String data = "";
                data = await apiService.fetchData(apiEntity);

                final service = KmlGenerationService(
                  input: data,
                  interpFactor: 4,
                  skipFactor: 2,
                );
                LgService lgService = Provider.of<LgService>(
                  context,
                  listen: false,
                );

                String kml = await service.generateKml();
                await lgService.sendFile(
                  '/var/www/html/heatmap.kml',
                  (utf8.encode(kml)),
                );

                await lgService.execCommand(
                  'echo "http://lg1:81/heatmap.kml" > /var/www/html/kmls.txt',
                );

                print(kml);
              },
              text: 'Visualize Data',
            ),
          ],
        ),
      ),
    );
  }
}
