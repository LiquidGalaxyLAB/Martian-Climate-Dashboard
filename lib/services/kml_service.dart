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
}
