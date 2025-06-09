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
      ApiEntity apiEntity = ApiEntity(
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
      ).thenAnswer((_) async => http.Response('{"message": "Success"}', 200));

      expect((await api.fetchData(apiEntity))['message'], equals("Success"));
    });

    test('throws an exception if the http call fails', () {
      final client = MockClient();
      ApiEntity apiEntity = ApiEntity(
        variable: 'temperature',
        year: 2023,
        month: 10,
        day: 1,
        hours: 12,
        minutes: 0,
        seconds: 0,
      );
      final api = ApiService(client: client);

      when(
        client.get(apiEntity.uri()),
      ).thenAnswer((_) async => http.Response('Not Found', 404));

      expect(api.fetchData(apiEntity), throwsException);
    });
  });
}
