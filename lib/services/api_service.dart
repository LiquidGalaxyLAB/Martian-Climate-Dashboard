/// A service class responsible for fetching data from a remote API.
///
/// The [ApiService] uses an [http.Client] to perform HTTP requests.
/// It provides a method to fetch data based on an [ApiEntity], which
/// constructs the appropriate URI for the request.
///
/// Example usage:
/// ```dart
/// final apiService = ApiService();
/// final data = await apiService.fetchData(apiEntity);
/// ```
///
/// Methods:
/// - [fetchData]: Fetches data from the API using the provided [ApiEntity].
///   It first retrieves a response, extracts a filename from the response body,
///   constructs a new URI, and fetches the corresponding text file.
/// - [_fetchTextFile]: Helper method to fetch the contents of a text file
///   from a given URI.
///
/// Throws:
/// - [Exception] if the HTTP request fails or if the expected data is not found
///   in the response.
library;

import 'package:http/http.dart' as http;
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'dart:convert';

class ApiService {
  http.Client client;
  late String imageBase64;
  ApiService({http.Client? client}) : client = client ?? http.Client();

  Future<String> fetchData(ApiEntity apiEntity) async {
    final uri = apiEntity.uri();
    try {
      final response = await client.get(uri);
      if (response.statusCode != 200) {
        throw Exception(
          "Failed to fetch data, status code: ${response.statusCode}",
        );
      }
      final textMatch =
          RegExp(r'\.\./txt/([\w\-]+\.txt)').firstMatch(response.body)!;

      final imageMatch =
          RegExp(r'\.\./img/([\w\-]+\.png)').firstMatch(response.body)!;

      final imgName = imageMatch.group(1);
      final imageUri = uri.replace(path: '/mcd_python/img/$imgName', query: '');
      final imageResponse = await client.get(imageUri);
      if (imageResponse.statusCode != 200) {
        throw Exception("Failed to fetch image");
      }

      imageBase64 = base64Encode(imageResponse.bodyBytes);

      final fileName = textMatch.group(1);
      final dataUri = uri.replace(path: '/mcd_python/txt/$fileName', query: '');
      return await _fetchTextFile(dataUri);
    } catch (e) {
      throw Exception("Failed to fetch data: $e");
    }
  }

  Future<String> _fetchTextFile(Uri uri) async {
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw Exception("Failed to fetch data");
    }
    return response.body;
  }
}
