import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/entities/state_entity.dart';
import 'package:martian_climate_dashboard/pages/visualization_page.dart';
import 'package:martian_climate_dashboard/services/api_service.dart';
import 'package:martian_climate_dashboard/services/kml_generatation_service.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/utils/atmos_map.dart';
import 'package:martian_climate_dashboard/utils/mars_facts.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';
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
  bool _isLoading = false;
  String? date;
  String? toDate;
  String? selectedParameter;
  final random = Random();
  CancelableOperation<void>? _operation;

  void startCancelableTask() {
    _operation = CancelableOperation.fromFuture(
      onSubmit(),
      onCancel: () {
        setState(() {
          _isLoading = false;
        });
      },
    );
  }

  void stopTask() async {
    await _operation?.cancel();
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> onSubmit() async {
    try {
      print('Visualize Data Pressed');
      if (date == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a date.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      if (isDateRangeEnabled && toDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a to date.'),
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      ApiService apiService = ApiService();
      final apiEntity =
          ApiEntity()
            ..variable = selectedParameter
            ..datekeyhtml = 1
            ..ls = 99.5
            ..localtime =
                DateTime.parse(date!).hour +
                DateTime.parse(date!).minute / 60 +
                DateTime.parse(date!).second / 3600
            ..year = DateTime.parse(date!).year
            ..month = DateTime.parse(date!).month
            ..day = DateTime.parse(date!).day
            ..hours = DateTime.parse(date!).hour
            ..minutes = DateTime.parse(date!).minute
            ..seconds = DateTime.parse(date!).second
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
            ..plat = null
            ..atomsScenario = 'Martian Year 35'
            ..date = DateTime.parse(date!)
            ..isGridEnabled = isGridEnabled
            ..dateRangeEnabled = isDateRangeEnabled
            ..toDate = isDateRangeEnabled ? DateTime.parse(toDate!) : null;
      print(apiEntity.toJson());
      String data = "";
      data = await apiService.fetchData(apiEntity);
      print(apiService.imageBase64);
      LgService lgService = Provider.of<LgService>(context, listen: false);
      await lgService.checkConnection();

      final service = KmlGenerationService(
        input: data,
        interpFactor: 4,
        skipFactor: 2,
      );
      print("test");
      String kml = await service.generateKml();
      print(kml);
      await lgService.sendFile('/var/www/html/heatmap.kml', (utf8.encode(kml)));

      await lgService.changeToMars();

      await lgService.execCommand(
        'echo "http://lg1:81/heatmap.kml" > /var/www/html/kmls.txt',
      );
      if (isGridEnabled) {
        String content = await rootBundle.loadString(
          'assets/kml/grid_overlay.kml',
        );
        await lgService.sendFile(
          '/var/www/html/grid.kml',
          utf8.encode(content),
        );

        await lgService.execCommand(
          'echo "http://lg1:81/grid.kml" >> /var/www/html/kmls.txt',
        );

        await lgService.execCommand(
          'echo "flytoview=<LookAt><longitude>${73.0}</longitude><latitude>${-13.0}</latitude><range>${3529400.3297285}</range><tilt>${0}</tilt><heading>${0}</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>" > /tmp/query.txt',
        );
      }

      print(kml);
      _isLoading = false;
      setState(() {});

      Navigator.of(context).push(
        MaterialPageRoute(
          builder:
              (context) => VisualizationPage(
                base64Image: apiService.imageBase64,
                apiEntity: apiEntity,
              ),
        ),
      );
      // return null;
    } catch (e) {
      print(e.toString());
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mars Vision')),
      drawer: MCDDrawer(),
      body: Stack(
        children: [
          Padding(
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
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13.0),
                      child: ParameterPicker(
                        hintText: 'Select Parameter',
                        selectedParameter: 't',
                        parameters: parameterMap,
                        onChanged: (value) {
                          setState(() {
                            selectedParameter = value ?? 'temperature';
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.all(13.0),
                      child: ParameterPicker(
                        hintText: 'Mars Atmospheric Scenario',
                        selectedParameter: 'Martian Year 35',
                        parameters: atmosMap,
                        onChanged: (value) {},
                      ),
                    ),
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 13.0),
                      child: Text(
                        'Date',
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
                            onDateSelected:
                                (p0) => setState(() {
                                  date = p0.toIso8601String();
                                }),
                            enabled: true,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 16),
                          child: DatePicker(
                            onDateSelected:
                                (p0) => setState(() {
                                  toDate = p0.toIso8601String();
                                }),
                            enabled: isDateRangeEnabled,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    CheckBox(
                      onChange: (value) {
                        setState(() {
                          isDateRangeEnabled = value ?? false;
                        });
                      },
                      isChecked: isDateRangeEnabled,
                      text: "Visualize data over a date range",
                      isEnabled: true,
                    ),
                    SizedBox(height: 7),
                    CheckBox(
                      onChange:
                          (value) => setState(() {
                            isGridEnabled = value ?? false;
                          }),
                      isChecked: isGridEnabled,
                      text: "Show grid lines",
                      isEnabled: true,
                    ),
                  ],
                ),
                MCDButton(
                  onPressed: () {
                    startCancelableTask();
                  },
                  text: 'Visualize Data',
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: FractionallySizedBox(
                  widthFactor: 0.7,
                  child: Card(
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 32.0,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 50,
                            height: 50,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).primaryColor,
                              ),
                              strokeWidth: 5,
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Generating Visualization...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            facts[random.nextInt(facts.length)],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
