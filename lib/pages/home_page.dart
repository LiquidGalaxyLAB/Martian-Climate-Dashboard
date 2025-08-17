import 'dart:convert';
import 'dart:math';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
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
import 'package:martian_climate_dashboard/utils/quickly_visualize_data.dart';
import 'package:martian_climate_dashboard/widgets/button.dart';
import 'package:martian_climate_dashboard/widgets/check_box.dart';
import 'package:martian_climate_dashboard/widgets/date_picker.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
import 'package:martian_climate_dashboard/widgets/parameter_picker.dart';
import 'package:martian_climate_dashboard/widgets/visualization_card.dart';
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
  String selectedParameter = 't';
  String selectedAtmosScenario = 'Martian Year 35';
  final random = Random();
  CancelableOperation<void>? _operation;
  List<SavedSession> recentlyVisualized = [];
  bool _isRecentItemsLoaded = false;

  int _progress = 0;
  String? _loadingFact;

  void _setProgress(int value) {
    if (!mounted) return;
    setState(() {
      _progress = value.clamp(0, 100).toInt();
    });
  }

  @override
  void initState() {
    super.initState();
    _loadRecentSessions();
  }

  Future<void> _loadRecentSessions() async {
    if (_isRecentItemsLoaded) return;

    final sessions = await SavedSession.loadSessions();
    print(sessions[0].apiEntity.variable);
    // SharedPreferences prefs = await SharedPreferences.getInstance();
    // await prefs.remove('saved_sessions');

    if (mounted) {
      setState(() {
        recentlyVisualized = sessions;
        _isRecentItemsLoaded = true;
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
            _loadingFact = null;
          });
        }
      },
    );
  }

  void stopTask() async {
    await _operation?.cancel();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadingFact = null;
      });
    }
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
      _progress = 0;
      _loadingFact = facts[random.nextInt(facts.length)];
    });
    _setProgress(5);
    print("lag debug: process start");

    try {
      ApiService apiService = ApiService();

      _setProgress(10);
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

      _setProgress(25);
      String data = await apiService.fetchData(apiEntity);
      _setProgress(60);

      String imageBase64 = apiService.imageBase64;
      await visualizeData(apiEntity, imageBase64, data: data);
      _setProgress(100);
    } catch (e) {
      if (e is ClientException) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Network error: Could not connect to server'),
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadingFact = null;
        });
      }
    }
  }

  Future<void> visualizeData(
    ApiEntity apiEntity,
    String imageBase64, {
    String? data,
  }) async {
    try {
      print("lag debug: visualizeData function start");
      LgService lgService = Provider.of<LgService>(context, listen: false);
      await lgService.checkConnection();
      if (!lgService.connected) {
        throw Exception('Not connected to the LG server');
      }
      _setProgress(65);

      ColorMap colorMap;
      if (apiEntity.variable == 't') {
        colorMap = ColorMap.bluegreenyellowred;
      } else if (apiEntity.variable == 'p') {
        colorMap = ColorMap.redyellowgreenblue;
      } else {
        colorMap = ColorMap.yelloworangered;
      }

      final service = KmlGenerationService(
        input: data ?? await ApiService().fetchData(apiEntity),
        interpFactor: 4,
        skipFactor: 2,
        colorMap: colorMap,
      );

      _setProgress(70);
      String kml = (await service.generateKml())["kml"];
      _setProgress(80);

      await lgService.sendFile('/var/www/html/heatmap.kml', utf8.encode(kml));
      _setProgress(85);

      await lgService.changeToMars();
      _setProgress(90);

      await lgService.execCommand(
        'echo "http://lg1:81/heatmap.kml" > /var/www/html/kmls.txt',
      );
      _setProgress(92);

      if (apiEntity.isGridEnabled) {
        String content = await rootBundle.loadString(
          'assets/kml/grid_overlay.kml',
        );
        await lgService.sendFile(
          '/var/www/html/grid.kml',
          utf8.encode(content),
        );
        _setProgress(94);

        await lgService.execCommand(
          'echo "http://lg1:81/grid.kml" >> /var/www/html/kmls.txt',
        );
        _setProgress(96);

        await lgService.execCommand(
          'echo "flytoview=<LookAt><longitude>${0.0}</longitude><latitude>${0.0}</latitude><range>${3529400.3297285}</range><tilt>${0}</tilt><heading>${0}</heading><gx:altitudeMode>relativeToGround</gx:altitudeMode></LookAt>" > /tmp/query.txt',
        );
        _setProgress(98);
      }

      if (mounted) {
        _setProgress(99);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) => VisualizationPage(
                  base64Image: imageBase64,
                  apiEntity: apiEntity,
                  colorMap: colorMap,
                ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Visualization error: ${e.toString()}')),
        );
      }
      rethrow;
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
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            children: [
                              Expanded(
                                child: DatePicker(
                                  enabled: true,
                                  onDateSelected:
                                      (d) => setState(() {
                                        date = d.toIso8601String();
                                      }),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: DatePicker(
                                  enabled: isDateRangeEnabled,
                                  onDateSelected:
                                      (d) => setState(() {
                                        toDate = d.toIso8601String();
                                      }),
                                ),
                              ),
                            ],
                          ),
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
                        const Text(
                          "Quick Visualizations",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: quicklyVisualizeData.length,
                          itemBuilder: (context, index) {
                            final item = quicklyVisualizeData[index];
                            return RecentVisualizationCard(
                              item: item,
                              onTap: () async {
                                setState(() {
                                  _isLoading = true;
                                  _progress = 0;
                                  _loadingFact =
                                      facts[random.nextInt(facts.length)];
                                });

                                try {
                                  await visualizeData(
                                    item.apiEntity,
                                    item.imageBase64,
                                  );
                                  _setProgress(100);
                                } catch (e) {
                                  print(e.toString());
                                } finally {
                                  setState(() {
                                    _isLoading = false;
                                    _loadingFact = null;
                                  });
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 20),

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
                            itemCount: min(recentlyVisualized.length, 5),
                            itemBuilder: (context, index) {
                              final item = recentlyVisualized[index];
                              return RecentVisualizationCard(
                                item: item,
                                onTap: () async {
                                  setState(() {
                                    _isLoading = true;
                                    _progress = 0;
                                    _loadingFact =
                                        facts[random.nextInt(facts.length)];
                                  });

                                  try {
                                    await visualizeData(
                                      item.apiEntity,
                                      item.imageBase64,
                                    );
                                    _setProgress(100);
                                  } catch (e) {
                                    print(e.toString());
                                  } finally {
                                    setState(() {
                                      _isLoading = false;
                                      _loadingFact = null;
                                    });
                                  }
                                },
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
                            const SizedBox(height: 20),
                            Text(
                              'Generating Visualization...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$_progress% done',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _loadingFact ?? '',
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
