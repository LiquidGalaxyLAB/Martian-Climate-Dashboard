import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:martian_climate_dashboard/entities/api_entity.dart';

class ApiService {
  http.Client client;
  ApiService({http.Client? client}) : client = client ?? http.Client();

  Future<Map<String, dynamic>> fetchData(ApiEntity apiEntity) async {
    final uri = apiEntity.uri();
    final response = await client.get(uri);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Erro fetching data: ${response.statusCode}');
    }
  }
}
