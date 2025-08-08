import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/entities/saved_session.dart';
import 'package:martian_climate_dashboard/enums/colomap.dart';
import 'package:martian_climate_dashboard/pages/visualization_page.dart';
import 'package:martian_climate_dashboard/services/api_service.dart';
import 'package:martian_climate_dashboard/services/kml_generatation_service.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/utils/atmos_map.dart';
import 'package:martian_climate_dashboard/utils/mars_facts.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';
import 'package:martian_climate_dashboard/widgets/button.dart';
import 'package:martian_climate_dashboard/widgets/check_box.dart';
import 'package:martian_climate_dashboard/widgets/circular_globe.dart';
import 'package:martian_climate_dashboard/widgets/date_picker.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
import 'package:martian_climate_dashboard/widgets/parameter_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  String selectedParameter = 't';
  String selectedAtmosScenario = 'Martian Year 35';
  final random = Random();
  CancelableOperation<void>? _operation;
  List<SavedSession> recentlyVisualized = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSessions();
  }

  Future<void> _loadRecentSessions() async {
    final sessions = await SavedSession.loadSessions();
    print(sessions[0].apiEntity.variable);
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.remove('saved_sessions');

    if (mounted) {
      setState(() {
        recentlyVisualized = sessions;
      });
    }
  }

  void startCancelableTask() {
    _operation = CancelableOperation.fromFuture(
      onSubmit(),
      onCancel: () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      },
    );
  }

  void stopTask() async {
    await _operation?.cancel();
  }

  Future<void> onSubmit() async {
    if (date == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a date.')));
      return;
    }
    if (isDateRangeEnabled && toDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a "to" date for the range.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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
            ..atomsScenario = selectedAtmosScenario
            ..date = DateTime.parse(date!)
            ..isGridEnabled = isGridEnabled
            ..dateRangeEnabled = isDateRangeEnabled
            ..toDate = isDateRangeEnabled ? DateTime.parse(toDate!) : null;

      String data = await apiService.fetchData(apiEntity);
      LgService lgService = Provider.of<LgService>(context, listen: false);
      await lgService.checkConnection();

      final service = KmlGenerationService(
        input: data,
        interpFactor: 4,
        skipFactor: 2,
        colorMap:
            apiEntity.variable == 't'
                ? ColorMap.redyellowgreenblue
                : ColorMap.yelloworangered,
      );
      String kml = await service.generateKml();
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

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => VisualizationPage(
                  base64Image: apiService.imageBase64,
                  apiEntity: apiEntity,
                ),
          ),
        );
        // await _loadRecentSessions();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'No date';
    const monthNames = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return '${monthNames[dt.month - 1]} ${dt.day}, ${dt.year}';
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
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
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
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 13.0),
                          child: ParameterPicker(
                            hintText: 'Select Parameter',
                            selectedParameter: selectedParameter,
                            parameters: parameterMap,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedParameter = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.all(13.0),
                          child: ParameterPicker(
                            hintText: 'Mars Atmospheric Scenario',
                            selectedParameter: selectedAtmosScenario,
                            parameters: atmosMap,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  selectedAtmosScenario = value;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(height: 10),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 13.0),
                          child: Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
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
                        const SizedBox(height: 20),
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
                        const SizedBox(height: 7),
                        CheckBox(
                          onChange:
                              (value) => setState(() {
                                isGridEnabled = value ?? false;
                              }),
                          isChecked: isGridEnabled,
                          text: "Show grid lines",
                          isEnabled: true,
                        ),
                        const SizedBox(height: 10),
                        if (recentlyVisualized.isNotEmpty)
                          const Text(
                            "Recently Visualized",
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        if (recentlyVisualized.isNotEmpty)
                          const SizedBox(height: 10),
                        if (recentlyVisualized.isNotEmpty)
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: recentlyVisualized.length,
                            itemBuilder: (context, index) {
                              final item = recentlyVisualized[index];
                              return Card(
                                shadowColor: Colors.transparent,
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                  horizontal: 4.0,
                                ),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(12),
                                  onTap: () {
                                    print(item.context);
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder:
                                            (context) => VisualizationPage(
                                              base64Image: item.imageBase64,
                                              apiEntity: item.apiEntity,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(12.0),
                                    child: Row(
                                      // crossAxisAlignment:
                                      // CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.start,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                parameterMap[item
                                                        .apiEntity
                                                        .variable] ??
                                                    'Unknown',
                                                style: const TextStyle(
                                                  fontSize: 21,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _formatDate(
                                                  item.apiEntity.date,
                                                ),
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                item.apiEntity.atomsScenario ??
                                                    'Default Scenario',
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SphereProjectionImage(
                                          base64Image: item.imageBase64,
                                          crop: const Rect.fromLTRB(
                                            160,
                                            88,
                                            179,
                                            81,
                                          ),
                                          size: const Size(130, 130),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                MCDButton(
                  onPressed: _isLoading ? null : startCancelableTask,
                  text: 'Visualize Data',
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20.0,
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
                            const SizedBox(height: 20),
                            const Text(
                              'Generating Visualization...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              facts[random.nextInt(facts.length)],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            TextButton(
                              onPressed: stopTask,
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
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
