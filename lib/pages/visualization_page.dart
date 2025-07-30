import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/entities/saved_session.dart';
import 'package:martian_climate_dashboard/services/gemini_service.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
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
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadApiKey();
  }

  @override
  void dispose() {
    SavedSession.saveSessions(
      SavedSession(
        imageBase64: widget.base64Image,
        apiEntity: widget.apiEntity,
        context: geminiService.context,
      ),
    );
    geminiService.dispose();
    msgController.dispose();
    super.dispose();
  }

  String? apiKey;

  Future<void> loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('api_key');
    });
    geminiService = GeminiService(
      apiKey: apiKey!,
      imageContent: widget.base64Image,
    );
    await geminiService.generateSummary();
    setState(() {});
    // print(geminiService.context);
  }

  Future<void> _loadData() async {}

  void _sendMessage(String text) async {
    if (apiKey == null) return;

    setState(() {
      msgController.clear();
    });

    try {
      final response = await geminiService.callApi(text);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // floatingActionButton: FloatingActionButton(
      //   tooltip: "orbit",
      //   onPressed: () async {
      //     LgService lgService = Provider.of<LgService>(context, listen: false);
      //     String kmlData = KmlService.generateOrbit(3000);
      //     await lgService.sendFile(
      //       '/var/www/html/orbit.kml',
      //       (utf8.encode(kmlData)),
      //     );
      //     print(kmlData);
      //     await lgService.execCommand(
      //       'echo "http://lg1:81/Orbit.kml" >> /var/www/html/kmls.txt',
      //     );
      //     await lgService.execCommand('echo "playtour=Orbit" > /tmp/query.txt');
      //   },
      //   child: const Icon(Icons.track_changes),
      // ),
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
              '${parameterMap[widget.apiEntity.variable]} Visualization',
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
                return '${monthNames[widget.apiEntity.date!.month - 1]} ${widget.apiEntity.date!.day}, ${widget.apiEntity.date!.year}';
              })(),
              style: const TextStyle(fontSize: 16),
            ),
            SizedBox(height: 20),
            Expanded(
              child:
                  apiKey == null
                      ? const Center(child: CircularProgressIndicator())
                      : geminiService.context.isEmpty
                      ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Generating summary..."),
                          SizedBox(width: 10),
                          CircularProgressIndicator(),
                        ],
                      )
                      : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 20),
                        itemCount: geminiService.context.length,
                        itemBuilder: (context, index) {
                          final message = geminiService.context[index];
                          final isUser = message['role'] == 'user';

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
                              child: MarkdownBody(
                                data:
                                    message['parts'][0]['text'] ??
                                    "Empty message",
                                // style: TextStyle(
                                //   color: isUser ? Colors.black87 : Colors.black,
                                // ),
                              ),
                            ),
                          );
                        },
                      ),
            ),

            if (isLoading)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    vertical: 4,
                    horizontal: 12,
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text("Thinking..."),
                    ],
                  ),
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
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final text = msgController.text;
                      if (text.trim().isEmpty) return;
                      _sendMessage(text);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
