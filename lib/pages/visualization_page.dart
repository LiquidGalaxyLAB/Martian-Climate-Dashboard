import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/entities/balloon_entity.dart';
import 'package:martian_climate_dashboard/entities/saved_session.dart';
import 'package:martian_climate_dashboard/enums/ballon_type.dart';
import 'package:martian_climate_dashboard/enums/colomap.dart';
import 'package:martian_climate_dashboard/services/api_service.dart';
import 'package:martian_climate_dashboard/services/balloon_service.dart';
import 'package:martian_climate_dashboard/services/gemini_service.dart';
import 'package:martian_climate_dashboard/services/kml_generatation_service.dart';
import 'package:martian_climate_dashboard/services/kml_service.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/utils/mars_facts.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';
import 'package:martian_climate_dashboard/widgets/dots_indicator.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VisualizationPage extends StatefulWidget {
  final String base64Image;
  final ApiEntity apiEntity;
  const VisualizationPage({
    super.key,
    required this.base64Image,
    required this.apiEntity,
  });

  @override
  State<VisualizationPage> createState() => _VisualizationPageState();
}

class _VisualizationPageState extends State<VisualizationPage> {
  late GeminiService geminiService;
  TextEditingController msgController = TextEditingController();
  bool _isLoading = false;
  bool _isWaitingForResponse = false;
  final random = Random();
  late DateTime? currentDate;
  late BalloonService balloonService;

  @override
  void initState() {
    super.initState();
    currentDate = widget.apiEntity.date;
    initialize();
  }

  @override
  void dispose() {
    if (apiKey != null) {
      print(geminiService.context);
      SavedSession.saveSessions(
        SavedSession(
          imageBase64: widget.base64Image,
          apiEntity: widget.apiEntity,
          context: geminiService.context,
        ),
      );
      geminiService.dispose();
    }
    msgController.dispose();
    super.dispose();
  }

  String? apiKey;
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('api_key');
    });

    if (apiKey == null) {
      setState(() {
        _isWaitingForResponse = false;
      });
      return;
    }

    geminiService = GeminiService(
      apiKey: apiKey!,
      imageContent: widget.base64Image,
    );

    balloonService = BalloonService(
      BalloonEntity(
        type: BalloonType.info,
        colorMap: ColorMap.redyellowgreenblue,
        apiEntity: widget.apiEntity,
      ),
    );

    setState(() {
      _isWaitingForResponse = true;
    });

    try {
      String response = await geminiService.generateSummary();
      print(response);
      await balloonService.showBalloon(
        Provider.of<LgService>(context, listen: false),
        response,
      );
    } catch (e) {
      print('Error generating summary: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating summary: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isWaitingForResponse = false;
      });
    }
  }

  Future<void> _buildNextDate() async {
    if (!widget.apiEntity.dateRangeEnabled) return;

    try {
      final nextDate = currentDate!.add(Duration(days: 1));
      setState(() {
        _isLoading = true;
      });
      ApiEntity apiEntity = widget.apiEntity.copyWith(date: nextDate);
      ApiService apiService = ApiService();
      String data = await apiService.fetchData(apiEntity);
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
      LgService lgService = Provider.of<LgService>(context, listen: false);

      await lgService.sendFile('/var/www/html/heatmap.kml', (utf8.encode(kml)));

      await lgService.changeToMars();

      await lgService.execCommand(
        'echo "http://lg1:81/heatmap.kml" > /var/www/html/kmls.txt',
      );
      if (widget.apiEntity.isGridEnabled) {
        await lgService.execCommand(
          'echo "http://lg1:81/grid.kml" >> /var/www/html/kmls.txt',
        );
      }

      setState(() {
        _isLoading = false;
        currentDate = nextDate;
      });

      if (apiKey != null) {
        await geminiService.clearContext();
        String newSummary = await geminiService.generateSummary();
        await balloonService.showBalloon(
          Provider.of<LgService>(context, listen: false),
          newSummary,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating date: ${e.toString()}')),
      );
    }
  }

  Future<void> _buildPrevDate() async {
    if (widget.apiEntity.dateRangeEnabled) {
      final prevDate = currentDate!.subtract(Duration(days: 1));
      print(prevDate.toIso8601String());
      setState(() {
        _isLoading = true;
      });
      ApiEntity apiEntity = widget.apiEntity.copyWith(date: prevDate);
      ApiService apiService = ApiService();
      String data = await apiService.fetchData(apiEntity);
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
      LgService lgService = Provider.of<LgService>(context, listen: false);

      await lgService.sendFile('/var/www/html/heatmap.kml', (utf8.encode(kml)));

      await lgService.changeToMars();

      await lgService.execCommand(
        'echo "http://lg1:81/heatmap.kml" > /var/www/html/kmls.txt',
      );
      if (widget.apiEntity.isGridEnabled) {
        await lgService.execCommand(
          'echo "http://lg1:81/grid.kml" >> /var/www/html/kmls.txt',
        );
      }

      setState(() {
        _isLoading = false;
        currentDate = prevDate;
      });
    }
  }

  void _sendMessage(String text) async {
    if (apiKey == null) return;

    setState(() {
      msgController.clear();
      _isWaitingForResponse = true;
    });

    try {
      final response = await geminiService.sendMessage(text);
      print(response);
      setState(() {
        _isWaitingForResponse = false;
      });
    } catch (e) {
      setState(() {
        _isWaitingForResponse = false;
      });
      print(e);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  Future<void> _stopOrbit() async {
    LgService lgService = Provider.of<LgService>(context, listen: false);
    await lgService.execCommand('echo "playtour=None" > /tmp/query.txt');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stop Orbit not implemented yet.')),
    );
  }

  Future<void> _startOrbit() async {
    LgService lgService = Provider.of<LgService>(context, listen: false);
    String kmlData = KmlService.generateOrbit(0, range: 3000000, tilt: 45);
    await lgService.sendFile('/var/www/html/orbit.kml', (utf8.encode(kmlData)));
    print(kmlData);
    await lgService.execCommand(
      'echo "http://lg1:81/Orbit.kml" >> /var/www/html/kmls.txt',
    );
    await lgService.execCommand('echo "playtour=Orbit" > /tmp/query.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: MCDDrawer(),
      appBar: AppBar(
        title: const Text('Mars Vision'),
        // actions: [
        //   IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        // ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${parameterMap[widget.apiEntity.variable] ?? "Temperature"} Visualization',
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
                    return '${monthNames[currentDate!.month - 1]} ${currentDate!.day}, ${currentDate!.year}';
                  })(),
                  style: const TextStyle(fontSize: 16),
                ),
                SizedBox(height: 20),
                Expanded(
                  child:
                      apiKey == null
                          ? const Center(
                            child: Text(
                              "API key required, please configure it.",
                            ),
                          )
                          // : geminiService.context.isEmpty
                          // ? Row(
                          //   mainAxisAlignment: MainAxisAlignment.center,
                          //   children: [
                          //     Text("Generating summary..."),
                          //     SizedBox(width: 10),
                          //     CircularProgressIndicator(),
                          //   ],
                          // )
                          : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 20),
                            itemCount:
                                geminiService.context.length +
                                (_isWaitingForResponse ? 1 : 0),
                            itemBuilder: (context, index) {
                              // Show loading bubble at the end if waiting for response
                              if (index == geminiService.context.length &&
                                  _isWaitingForResponse) {
                                return Align(
                                  alignment: Alignment.centerLeft,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      vertical: 4,
                                      horizontal: 12,
                                    ),
                                    padding: const EdgeInsets.all(12),
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                          0.7,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SizedBox(width: 3),
                                        Text("Thinking "),
                                        JumpingDots(
                                          color: Colors.black54,
                                          radius: 4,
                                          numberOfDots: 3,
                                          animationDuration: Duration(
                                            milliseconds: 200,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              final message = geminiService.context[index];
                              final isUser = message['role'] == 'user';

                              final messageText =
                                  message['parts'] != null &&
                                          message['parts'].isNotEmpty &&
                                          message['parts'][0]['text'] != null
                                      ? message['parts'][0]['text']
                                      : "Empty message";

                              return Align(
                                alignment:
                                    isUser
                                        ? Alignment.centerRight
                                        : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 12,
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color:
                                        isUser
                                            ? Colors.grey[200]
                                            : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: BoxConstraints(
                                    maxWidth:
                                        MediaQuery.of(context).size.width * 0.7,
                                  ),
                                  child: MarkdownBody(data: messageText),
                                ),
                              );
                            },
                          ),
                ),
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: msgController,
                          decoration: InputDecoration(
                            fillColor: Colors.white24,
                            hintText: 'Type your message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                          textInputAction: TextInputAction.send,
                          onSubmitted: (text) {
                            if (text.trim().isEmpty) return;
                            _sendMessage(text);
                          },
                        ),
                      ),
                      IconButton(
                        // onPressed: (_isWaitingForResponse || apiKey == null || msgController.text.trim().isEmpty)
                        //   ? null
                        //   : () {
                        //     final text = msgController.text;
                        //     if (text.trim().isEmpty) return;
                        //     _sendMessage(text);
                        //     FocusScope.of(context).unfocus();
                        // },
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          final text = msgController.text;
                          if (text.trim().isEmpty) return;
                          _sendMessage(text);
                          FocusScope.of(context).unfocus();
                        },
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_horiz),
                        tooltip: "More options",
                        offset: const Offset(0, -120),
                        // onSelected: (String result) {
                        //   switch (result) {
                        //     case 'save_session':
                        //       SavedSession.saveSessions(
                        //         SavedSession(
                        //           imageBase64: widget.base64Image,
                        //           apiEntity: widget.apiEntity,
                        //           context: geminiService.context,
                        //         ),
                        //       );
                        //       ScaffoldMessenger.of(context).showSnackBar(
                        //         const SnackBar(content: Text('Session Saved!')),
                        //       );
                        //       break;
                        //     case 'generate_orbit':
                        //       ScaffoldMessenger.of(context).showSnackBar(
                        //         const SnackBar(
                        //           content: Text(
                        //             'Generate Orbit not implemented yet.',
                        //           ),
                        //         ),
                        //       );
                        //       break;
                        //   }
                        // },
                        itemBuilder:
                            (BuildContext context) => <PopupMenuEntry<String>>[
                              PopupMenuItem<String>(
                                value: 'stop_orbit',
                                onTap: () async => await _stopOrbit(),
                                child: ListTile(
                                  leading: Icon(Icons.stop),
                                  title: Text('Stop Orbit'),
                                ),
                              ),
                              PopupMenuItem<String>(
                                value: 'start_orbit',
                                onTap: () async => await _startOrbit(),
                                child: const ListTile(
                                  leading: Icon(Icons.track_changes),
                                  title: Text('Start Orbit'),
                                ),
                              ),
                              if (widget.apiEntity.dateRangeEnabled)
                                PopupMenuItem<String>(
                                  value: 'next_date',
                                  onTap: () async => await _buildNextDate(),
                                  child: ListTile(
                                    enabled: currentDate!.isBefore(
                                      widget.apiEntity.toDate!,
                                    ),
                                    leading: Icon(Icons.arrow_forward),
                                    title: Text('Next Date'),
                                  ),
                                ),
                              if (widget.apiEntity.dateRangeEnabled)
                                PopupMenuItem<String>(
                                  value: 'prev_date',
                                  onTap: () async => await _buildPrevDate(),
                                  child: ListTile(
                                    // enabled: currentDate!.isBefore(
                                    //   widget.apiEntity.toDate!,
                                    // ),
                                    leading: Icon(Icons.arrow_back),
                                    title: Text('Previous Date'),
                                  ),
                                ),
                            ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.05),
              width: MediaQuery.of(context).size.width,
              height: double.infinity,
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
