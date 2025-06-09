import 'package:flutter_test/flutter_test.dart';
import 'package:martian_climate_dashboard/services/kml_generatation_service.dart';

void main() {
  group('KmlGenerationService', () {
    test('generateKml returns valid KML for minimal input', () async {
      // Minimal valid ASCII input with 2 lats and 2 lons
      final input = '''
---- || 10 20
30 || 1 2
40 || 3 4
''';

      final service = KmlGenerationService(
        input: input,
        interpFactor: 1,
        skipFactor: 1,
      );

      final kml = await service.generateKml();

      expect(kml, contains('<?xml version="1.0" encoding="UTF-8"?>'));
      expect(kml, contains('<kml xmlns="http://www.opengis.net/kml/2.2">'));
      expect(kml, contains('<Placemark>'));
      expect(kml, contains('<Polygon>'));
      expect(kml, contains('</kml>'));
    });

    test('throws exception on empty input', () async {
      final service = KmlGenerationService(
        input: '',
        interpFactor: 1,
        skipFactor: 1,
      );
      expect(() async => await service.generateKml(), throwsException);
    });

    test('throws exception on mismatched row length', () async {
      final input = '''
---- || 10 20
30 || 1
40 || 3 4
''';
      final service = KmlGenerationService(
        input: input,
        interpFactor: 1,
        skipFactor: 1,
      );
      expect(() async => await service.generateKml(), throwsException);
    });

    test('parameterToKmlColor returns correct color format', () {
      final service = KmlGenerationService(
        input: '',
        interpFactor: 1,
        skipFactor: 1,
      );
      final color = service.parameterToKmlColor(0.5, 0.0, 1.0);
      expect(color, startsWith('FF')); // KML color starts with alpha
      expect(color.length, 8); // FF + 6 hex digits
    });
  });
}
