import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/enums/ballon_type.dart';
import 'package:martian_climate_dashboard/enums/colomap.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';

class BalloonEntity {
  final BalloonType type;
  final ColorMap colorMap;
  final ApiEntity apiEntity;
  // final String content;

  BalloonEntity({
    required this.type,
    required this.colorMap,
    required this.apiEntity,
    // required this.content,
  });

  @override
  String toString() {
    return 'BalloonEntity(type: $type, colorMap: $colorMap, apiEntity: $apiEntity)';
  }

  String generateXml(String content) {
    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>MCD-balloon</name>
    <open>1</open>
    <Folder>
          <Style id="balloon-SCHX-0895-2361-9925-0309">
      <BalloonStyle>
        <bgColor>ffffffff</bgColor>
        <text><![CDATA[
            <div style="text-align: center;">
              <b><font size="+2">${parameterMap[apiEntity.variable]} Visualization</font></b>
            </div>
            <div style="text-align: left; margin-top: 10px;">
              $content
            </div>
        ]]></text>
      </BalloonStyle>
      <LabelStyle>
        <scale>0</scale>
      </LabelStyle>
      <IconStyle>
        <scale>0</scale>
      </IconStyle>
    </Style>
    <Placemark>
      <name>TRANSIT 5B-5 (ALIVE)-Balloon</name>
      <styleUrl>#balloon-SCHX-0895-2361-9925-0309</styleUrl>
            <Point>
        <gx:drawOrder>1</gx:drawOrder>
        <gx:altitudeMode>relativeToGround</gx:altitudeMode>
        <coordinates>-79.1829904714479,24.144372395491576,58938.817715522695</coordinates>
      </Point>

      <gx:balloonVisibility>1</gx:balloonVisibility>
    </Placemark>


    </Folder>
  </Document>
</kml>
''';
  }
}
