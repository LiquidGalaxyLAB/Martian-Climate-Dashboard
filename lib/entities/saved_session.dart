import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Represents a saved user session for Mars climate data visualization and analysis.
///
/// This class encapsulates a complete user session including the visualization data,
/// conversation context with the AI assistant, and the underlying API data. Sessions
/// are persisted locally using SharedPreferences to allow users to resume their
/// analysis work across app restarts.
///
/// Sessions include:
/// - Base64-encoded visualization images for quick preview
/// - Complete conversation history with AI responses
/// - Original API entity data for regenerating visualizations
///
/// The system maintains up to 5 recent sessions, automatically removing older
/// sessions when the limit is exceeded.
///
/// Example usage:
/// ```dart
/// // Create and save a new session
/// final session = SavedSession(
///   imageBase64: visualizationImageData,
///   apiEntity: currentApiData,
///   context: conversationHistory,
/// );
/// await SavedSession.saveSessions(session);
///
/// // Load previous sessions
/// final sessions = await SavedSession.loadSessions();
/// ```
class SavedSession {
  /// Base64-encoded string representation of the visualization image.
  ///
  /// Contains the Mars climate data visualization as a compressed base64 string,
  /// enabling quick preview generation without needing to regenerate the
  /// visualization from raw data. This is particularly useful for session
  /// thumbnails and rapid session switching.
  final String imageBase64;

  /// Conversation context history with the AI assistant.
  ///
  /// Stores the complete conversation thread including user questions and
  /// AI responses about the Mars climate data. Each entry is a map containing
  /// role ("user" or "assistant") and message content, maintaining the full
  /// context for continued analysis when sessions are resumed.
  ///
  /// Structure: List of maps with keys like:
  /// - "role": "user" | "assistant"
  /// - "content": message text
  /// - "timestamp": optional timestamp
  final List<Map<String, dynamic>> context;

  /// The original API entity containing Mars climate data parameters.
  ///
  /// Stores the complete API request configuration including variable type,
  /// date range, geographic bounds, and other parameters. This enables
  /// exact recreation of the visualization and supports modification of
  /// parameters when resuming a session.
  final ApiEntity apiEntity;

  /// Creates a new saved session with the specified data.
  ///
  /// Parameters:
  /// - [imageBase64]: Base64-encoded visualization image data
  /// - [apiEntity]: Original API entity with climate data parameters
  /// - [context]: Conversation history with AI assistant
  ///
  /// Example:
  /// ```dart
  /// final session = SavedSession(
  ///   imageBase64: encodedImageData,
  ///   apiEntity: ApiEntity(
  ///     variable: 'temp',
  ///     date: '2024-01-15',
  ///     // ... other parameters
  ///   ),
  ///   context: [
  ///     {"role": "user", "content": "What's the temperature pattern?"},
  ///     {"role": "assistant", "content": "The temperature shows..."},
  ///   ],
  /// );
  /// ```
  SavedSession({
    required this.imageBase64,
    required this.apiEntity,
    required this.context,
  });

  /// Converts the saved session to a JSON-serializable map.
  ///
  /// Transforms all session data into a format suitable for storage
  /// in SharedPreferences or other JSON-based persistence systems.
  ///
  /// Returns: Map containing all session data with string keys
  ///
  /// Example output:
  /// ```json
  /// {
  ///   "imageBase64": "iVBORw0KGgoAAAANSUhEUgAA...",
  ///   "context": [{"role": "user", "content": "..."}],
  ///   "apiEntity": {"variable": "temp", "date": "2024-01-15", ...}
  /// }
  /// ```
  Map<String, dynamic> toJson() {
    return {
      'imageBase64': imageBase64,
      'context': context,
      'apiEntity': apiEntity.toJson(),
    };
  }

  /// Creates a SavedSession instance from a JSON map.
  ///
  /// Reconstructs a saved session from previously serialized JSON data,
  /// typically loaded from SharedPreferences storage.
  ///
  /// Parameters:
  /// - [json]: Map containing serialized session data
  ///
  /// Returns: New SavedSession instance with restored data
  ///
  /// Throws: [FormatException] if JSON structure is invalid
  ///
  /// Example:
  /// ```dart
  /// final jsonData = jsonDecode(storedSessionString);
  /// final session = SavedSession.fromJson(jsonData);
  /// ```
  factory SavedSession.fromJson(Map<String, dynamic> json) {
    return SavedSession(
      imageBase64: json['imageBase64'],
      context: List<Map<String, dynamic>>.from(json['context']),
      apiEntity: ApiEntity.fromJson(json['apiEntity']),
    );
  }

  /// Saves a new session to local storage, maintaining a maximum of 5 sessions.
  ///
  /// Adds the new session to the beginning of the session list (most recent first)
  /// and automatically removes the oldest sessions if more than 5 exist. This
  /// ensures efficient storage usage while preserving recent user activity.
  ///
  /// Parameters:
  /// - [session]: The SavedSession instance to persist
  ///
  /// Throws: [Exception] if storage operation fails
  ///
  /// Example:
  /// ```dart
  /// final currentSession = SavedSession(
  ///   imageBase64: visualizationData,
  ///   apiEntity: currentParams,
  ///   context: chatHistory,
  /// );
  ///
  /// try {
  ///   await SavedSession.saveSessions(currentSession);
  ///   print('Session saved successfully');
  /// } catch (e) {
  ///   print('Failed to save session: $e');
  /// }
  /// ```
  static Future<void> saveSessions(SavedSession session) async {
    // Load existing sessions and prepend the new one
    final sessions = await loadSessions();
    sessions.insert(0, session);

    // Maintain maximum of 5 sessions (remove oldest if exceeded)
    if (sessions.length > 5) {
      sessions.removeRange(5, sessions.length);
    }

    // Serialize and save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final jsonList = sessions.map((s) => s.toJson()).toList();
    await prefs.setString('saved_sessions', jsonEncode(jsonList));
  }

  /// Loads all saved sessions from local storage.
  ///
  /// Retrieves the complete list of saved sessions from SharedPreferences,
  /// ordered by most recent first. Returns an empty list if no sessions
  /// have been saved or if storage access fails.
  ///
  /// Returns: List of SavedSession instances, ordered by recency (newest first)
  ///
  /// Example:
  /// ```dart
  /// final sessions = await SavedSession.loadSessions();
  ///
  /// if (sessions.isNotEmpty) {
  ///   print('Found ${sessions.length} saved sessions');
  ///   final mostRecent = sessions.first;
  ///   print('Most recent: ${mostRecent.apiEntity.date}');
  /// } else {
  ///   print('No saved sessions found');
  /// }
  /// ```
  static Future<List<SavedSession>> loadSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString('saved_sessions');

      // Return empty list if no sessions stored
      if (jsonString == null) return [];

      // Parse JSON and reconstruct SavedSession objects
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList.map((json) => SavedSession.fromJson(json)).toList();
    } catch (e) {
      // Handle parsing errors gracefully
      if (kDebugMode) {
        print('Error loading sessions: $e');
      }
      return [];
    }
  }

  /// Clears all saved sessions from local storage.
  ///
  /// Removes all persisted session data, useful for privacy concerns
  /// or storage cleanup operations.
  ///
  /// Example:
  /// ```dart
  /// await SavedSession.clearAllSessions();
  /// print('All sessions cleared');
  /// ```
  static Future<void> clearAllSessions() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_sessions');
  }

  /// Returns a brief description of the session for UI display.
  ///
  /// Generates a user-friendly string describing the session's content,
  /// useful for session list displays and selection interfaces.
  ///
  /// Returns: String description including date and climate variable
  ///
  /// Example:
  /// ```dart
  /// final session = SavedSession(/*...*/);
  /// print(session.description); // "Temperature data for 2024-01-15"
  /// ```
  String get description {
    return '${apiEntity.variable} data for ${apiEntity.date}';
  }

  @override
  String toString() {
    return 'SavedSession(variable: ${apiEntity.variable}, '
        'date: ${apiEntity.date}, '
        'contextLength: ${context.length})';
  }
}
