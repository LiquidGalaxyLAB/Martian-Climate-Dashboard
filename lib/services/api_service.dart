import 'package:http/http.dart' as http;
import 'package:martian_climate_dashboard/entities/api_entity.dart';

class ApiService {
  http.Client client;
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
      final match = RegExp(
        r'\.\./txt/([\w\-]+\.txt)',
      ).firstMatch(response.body);
      if (match == null) throw Exception("No match found in response body");

      final fileName = match.group(1);
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
