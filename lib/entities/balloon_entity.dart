import 'package:martian_climate_dashboard/entities/api_entity.dart';
import 'package:martian_climate_dashboard/enums/ballon_type.dart';
import 'package:martian_climate_dashboard/enums/colomap.dart';
import 'package:martian_climate_dashboard/utils/parameter_map.dart';

/// Represents a KML balloon entity for displaying information overlays in Liquid Galaxy.
///
/// This class generates KML balloon content for Mars climate visualizations,
/// supporting both location-based balloons and visualization summaries with
/// color-coded gradient bars.
class BalloonEntity {
  /// The type of balloon (e.g., visualization, location)
  final BalloonType type;

  /// The color mapping scheme used for data visualization gradients
  final ColorMap colorMap;

  /// The API entity containing Mars climate data to be displayed
  final ApiEntity apiEntity;

  /// Creates a new balloon entity with the specified configuration.
  ///
  /// Parameters:
  /// - [type]: The balloon type determining display style and content
  /// - [colorMap]: Color scheme for gradient visualization bars
  /// - [apiEntity]: Source data entity containing Mars climate information
  BalloonEntity({
    required this.type,
    required this.colorMap,
    required this.apiEntity,
  });

  @override
  String toString() {
    return 'BalloonEntity(type: $type, colorMap: $colorMap, apiEntity: $apiEntity)';
  }

  /// Generates a static KML balloon for displaying location-based information.
  ///
  /// Creates a simple balloon with title and content, positioned at the
  /// specified coordinates. Used for displaying general information about
  /// Mars locations or features.
  ///
  /// Parameters:
  /// - [content]: HTML content to display in the balloon body
  /// - [title]: Bold title text displayed at the top
  /// - [coordinates]: [longitude, latitude] array for balloon positioning
  ///
  /// Returns: Complete KML string with embedded balloon styling
  ///
  /// Example:
  /// ```dart
  /// final kml = BalloonEntity.generateLocationBalloon(
  ///   "Temperature data for Olympus Mons region",
  ///   "Mars Climate Data",
  ///   [-18.65, 226.2]
  /// );
  /// ```
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

  /// Generates a rich visualization balloon with gradient color bar and data summary.
  ///
  /// Creates a sophisticated balloon displaying Mars climate data with:
  /// - Color-coded gradient bar representing data value range
  /// - Parameter name and measurement date
  /// - AI-generated summary of the visualization
  /// - Professional styling optimized for Liquid Galaxy display
  ///
  /// The gradient bar uses either provided custom color stops or defaults
  /// to the entity's color map configuration.
  ///
  /// Parameters:
  /// - [colorMap]: Color scheme for the gradient (can override entity's colorMap)
  /// - [summary]: AI-generated text summary of the climate data
  /// - [gradientStops]: Optional custom color stops as Map`<`position, [R,G,B]`>`
  ///   where position is 0.0-1.0 and RGB values are 0-255
  /// - [minValue]: Minimum data value for the range display (default: -22.7)
  /// - [maxValue]: Maximum data value for the range display (default: 73.3)
  ///
  /// Returns: Complete KML string with embedded balloon and styling
  ///
  /// Example:
  /// ```dart
  /// final customStops = {
  ///   0.0: [255, 255, 0],   // Yellow (cold)
  ///   0.5: [255, 128, 0],   // Orange (medium)
  ///   1.0: [255, 0, 0],     // Red (hot)
  /// };
  ///
  /// final kml = balloonEntity.generateVisualizationBalloon(
  ///   ColorMap.temperature,
  ///   "Temperature varies significantly across the polar regions...",
  ///   gradientStops: customStops,
  ///   minValue: -80.0,
  ///   maxValue: 20.0,
  /// );
  /// ```
  String generateVisualizationBalloon(
    ColorMap colorMap,
    String summary, {
    Map<double, List<int>>? gradientStops,
    double? minValue = -22.7,
    double? maxValue = 73.3,
  }) {
    // Use provided gradient stops or fall back to color map defaults
    final stops = gradientStops ?? colorMapData[colorMap]!;
    final minLabel = (minValue ?? -22.7).toString();
    final maxLabel = (maxValue ?? 73.3).toString();

    /// Generates CSS linear-gradient string from color stop data.
    ///
    /// Converts the Map<double, List<int>> gradient stops into a CSS
    /// linear-gradient that can be used in HTML styling. Sorts stops
    /// by position and formats RGB values as hex colors.
    ///
    /// Returns: CSS linear-gradient string (e.g., "linear-gradient(90deg, #ffff00 0.0%, #ff0000 100.0%)")
    String genGrad() {
      /// Converts RGB array [R,G,B] to hex color string #RRGGBB
      String rgbToHex(List<int> rgb) {
        return '#${rgb.map((c) => c.toRadixString(16).padLeft(2, '0')).join()}';
      }

      // Sort color stops by position (0.0 to 1.0)
      var sortedStops =
          stops.entries.toList()..sort((a, b) => a.key.compareTo(b.key));

      // Build CSS gradient string with color and percentage positions
      String gradient =
          'linear-gradient(90deg, ${sortedStops.map((entry) => '${rgbToHex(entry.value)} ${(entry.key * 100).toStringAsFixed(1)}%').join(', ')})';
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
