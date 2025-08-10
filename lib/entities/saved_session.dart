import 'dart:convert';

import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SavedSession {
  String imageBase64;
  List<Map<String, dynamic>> context;
  ApiEntity apiEntity;
  SavedSession({
    required this.imageBase64,
    required this.apiEntity,
    required this.context,
  });

  Map<String, dynamic> toJson() {
    return {
      'imageBase64': imageBase64,
      'context': context,
      'apiEntity': apiEntity.toJson(),
    };
  }

  factory SavedSession.fromJson(Map<String, dynamic> json) {
    return SavedSession(
      imageBase64: json['imageBase64'],
      context: List<Map<String, dynamic>>.from(json['context']),
      apiEntity: ApiEntity.fromJson(json['apiEntity']),
    );
  }

  static Future<void> saveSessions(SavedSession session) async {
    final sessions = await loadSessions();
    sessions.insert(0, session);
    if (sessions.length > 5) {
      sessions.removeRange(5, sessions.length);
    }
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString('saved_sessions', jsonEncode(jsonList));
  }

  static Future<List<SavedSession>> loadSessions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('saved_sessions');

    if (jsonString == null) return [];

    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => SavedSession.fromJson(json)).toList();
  }
}
