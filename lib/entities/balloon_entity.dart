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

  static String generateLocationBalloon(
    String content,
    String title,
    List<dynamic> coordinates,
  ) {
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
              <b><font size="+2">$title</font></b>
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
        <coordinates>${coordinates[0]}, ${coordinates[1]},58938.817715522695</coordinates>
      </Point>

      <gx:balloonVisibility>1</gx:balloonVisibility>
    </Placemark>


    </Folder>
  </Document>
</kml>
''';
  }

  String generateVisualizationBalloon(
    ColorMap colorMap,
    String summary, {
    Map<double, List<int>>? gradientStops,
    double? minValue = -22.7,
    double? maxValue = 73.3,
  }) {
    final stops = gradientStops ?? colorMapData[colorMap]!;
    final minLabel = (minValue ?? -22.7).toString();
    final maxLabel = (maxValue ?? 73.3).toString();

    String genGrad() {
      String rgbToHex(List<int> rgb) {
        return '#${rgb.map((c) => c.toRadixString(16).padLeft(2, '0')).join()}';
      }

      // Sort stops by key (position)
      var sortedStops =
          stops.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      String gradient =
          'linear-gradient(90deg, ' +
          sortedStops
              .map(
                (entry) =>
                    '${rgbToHex(entry.value)} ${(entry.key * 100).toStringAsFixed(1)}%',
              )
              .join(', ') +
          ')';
      return gradient;
    }

    return '''
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
  <Document>
    <name>MCD-balloon</name>
    <open>1</open>
    <Folder>
      <Style id="balloon-SCHX-0895-2361-9925-0309">
        <BalloonStyle>
          <bgColor>00000000</bgColor>
          <text><![CDATA[
            <div style="font-family:Arial,Helvetica,sans-serif;border-radius:16px;box-shadow:0 4px 12px rgba(0,0,0,0.15);background:#fff;padding:16px;max-width:320px;border:1px solid #e0e0e0;">
              <div style="font-size:18px;font-weight:700;margin-bottom:4px;color:#222;">
                ${parameterMap[apiEntity.variable]} Visualization
              </div>
              <div style="font-size:13px;color:#555;margin-bottom:10px;">
                ${apiEntity.date}
              </div>
              <div style="margin-bottom:10px;">
                <div style="font-size:12px;color:#333;margin-bottom:4px;">
                  Value Range
                </div>
                <div style="display:flex;align-items:center;">
                  <span style="font-size:11px;color:#555;margin-right:6px;">$minLabel</span>
                  <div style="flex:1;height:10px;border-radius:5px;position:relative;">
                    <!-- Use both methods for maximum compatibility -->
                    <div style="position:absolute;top:0;left:0;right:0;bottom:0;border-radius:5px;background:${genGrad()}"></div>
                  </div>
                  <span style="font-size:11px;color:#555;margin-left:6px;">$maxLabel</span>
                </div>
              </div>
              <div style="font-size:12px;color:#222;line-height:1.4;">
                <b>Summary:</b> ${summary.split("**Summary:**").last.trim()}
              </div>
            </div>
          ]]></text>
        </BalloonStyle>
        <LabelStyle><scale>0</scale></LabelStyle>
        <IconStyle><scale>0</scale></IconStyle>
      </Style>
      <Placemark>
        <name>Summary Balloon</name>
        <styleUrl>#balloon-SCHX-0895-2361-9925-0309</styleUrl>
        <gx:balloonVisibility>1</gx:balloonVisibility>
      </Placemark>
    </Folder>
  </Document>
</kml>
''';
  }
}
