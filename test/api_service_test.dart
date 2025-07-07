import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/services/api_service.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'api_service_test.mocks.dart';

@GenerateMocks([http.Client])
void main() {
  group('ApiService', () {
    test('returns data if the http call completes successfully', () async {
      final client = MockClient();
      final api = ApiService(client: client);

      final apiEntity = ApiEntity(
        variable: 'temperature',
        year: 2023,
        month: 10,
        day: 1,
        hours: 12,
        minutes: 0,
        seconds: 0,
      );

      when(client.get(apiEntity.uri())).thenAnswer(
        (_) async => http.Response('... ../txt/data-003.txt ...', 200),
      );

      final fileUri = Uri.parse(
        'https://www-mars.lmd.jussieu.fr/mcd_python/txt/data-003.txt?',
      );
      when(
        client.get(fileUri),
      ).thenAnswer((_) async => http.Response('{"message":"Success"}', 200));

      final resultString = await api.fetchData(apiEntity);
      final jsonResult = jsonDecode(resultString);
      expect(jsonResult['message'], 'Success');
    });

    test('throws an exception if the http call fails', () {
      final client = MockClient();
      final api = ApiService(client: client);
      final apiEntity = ApiEntity(
        variable: 'temperature',
        year: 2023,
        month: 10,
        day: 1,
        hours: 12,
        minutes: 0,
        seconds: 0,
      );

      when(
        client.get(apiEntity.uri()),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(api.fetchData(apiEntity), throwsException);
    });

    test('throws an exception if no match found in response body', () {
      final client = MockClient();
      final api = ApiService(client: client);
      final apiEntity = ApiEntity(
        variable: 'temperature',
        year: 2023,
        month: 10,
        day: 1,
        hours: 12,
        minutes: 0,
        seconds: 0,
      );

      when(
        client.get(apiEntity.uri()),
      ).thenAnswer((_) async => http.Response('No matching pattern here', 200));

      expect(api.fetchData(apiEntity), throwsException);
    });
  });
}
