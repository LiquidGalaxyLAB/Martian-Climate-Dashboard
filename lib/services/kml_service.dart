class KmlService {
  static String generateOrbit(
    double latitude, {
    double altitude = 0,
    double range = 1000000,
    double tilt = 60,
  }) {
    String orbit = '''
<?xml version="1.0" encoding="UTF-8"?>
  <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
    <gx:Tour>
      <name>Orbit</name>
      <gx:Playlist> 
''';

    for (int longitude = -180; longitude <= 180; longitude += 10) {
      orbit += '''
        <gx:FlyTo>
          <gx:duration>1.2</gx:duration>
          <gx:flyToMode>smooth</gx:flyToMode>
          <LookAt>
              <longitude>$longitude</longitude>
              <latitude>$latitude</latitude>
              <heading>90</heading>
              <tilt>$tilt</tilt>
              <range>$range</range>
              <gx:fovy>60</gx:fovy>
              <altitude>$altitude</altitude>
              <gx:altitudeMode>relativeToGround</gx:altitudeMode>
          </LookAt>
        </gx:FlyTo>
''';
    }
    orbit += '''
    </gx:Playlist>
  </gx:Tour>
</kml>
''';
    return orbit;
  }

  static String generateEquatorialOrbit({
    double altitude = 0,
    double range = 1000000,
    double tilt = 60,
    double duration = 1.2,
    int steps = 36,
  }) {
    String orbit = '''
<?xml version="1.0" encoding="UTF-8"?>
  <kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
    <gx:Tour>
      <name>Equatorial Orbit</name>
      <gx:Playlist> 
''';

    for (int i = 0; i <= steps; i++) {
      double longitude = -180 + (360.0 * i / steps);

      orbit += '''
        <gx:FlyTo>
          <gx:duration>$duration</gx:duration>
          <gx:flyToMode>smooth</gx:flyToMode>
          <LookAt>
              <longitude>$longitude</longitude>
              <latitude>0</latitude>
              <heading>90</heading>
              <tilt>$tilt</tilt>
              <range>$range</range>
              <gx:fovy>60</gx:fovy>
              <altitude>$altitude</altitude>
              <gx:altitudeMode>relativeToGround</gx:altitudeMode>
          </LookAt>
        </gx:FlyTo>
''';
    }

    orbit += '''
    </gx:Playlist>
  </gx:Tour>
</kml>
''';
    return orbit;
  }

  static String generatePrimeMeridianOrbit({
    double longitude = 0,
    double latitude = 0,
    double altitude = 0,
    double range = 10000000,
    double tilt = 45,
    int stepDegrees = 5,
    double durationPerStep = 0.8,
  }) {
    final sb = StringBuffer();
    sb.writeln('''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2">
  <gx:Tour>
    <name>Orbit</name>
    <gx:Playlist>''');

    for (int heading = 0; heading <= 360; heading += stepDegrees) {
      sb.writeln('''
      <gx:FlyTo>
        <gx:duration>${durationPerStep.toStringAsFixed(2)}</gx:duration>
        <gx:flyToMode>smooth</gx:flyToMode>
        <LookAt>
          <longitude>${longitude.toStringAsFixed(4)}</longitude>
          <latitude>${latitude.toStringAsFixed(4)}</latitude>
          <altitude>$altitude</altitude>
          <heading>$heading</heading>
          <tilt>${tilt.toStringAsFixed(2)}</tilt>
          <range>${range.toStringAsFixed(0)}</range>
          <gx:altitudeMode>relativeToGround</gx:altitudeMode>
        </LookAt>
      </gx:FlyTo>''');
    }

    sb.writeln('''
    </gx:Playlist>
  </gx:Tour>
</kml>''');
    return sb.toString();
  }
}
