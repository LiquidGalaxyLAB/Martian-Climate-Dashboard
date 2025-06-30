/// A service for generating KML (Keyhole Markup Language) files from ASCII grid data.
///
/// This service parses input ASCII data containing latitude, longitude, and parameter values,
/// interpolates the grid to a higher resolution, and generates a KML file with colored polygons
/// representing the parameter values.
///
/// The color of each polygon is determined by mapping the parameter value to a color gradient.
/// The interpolation is performed using bilinear interpolation.
///
/// Parameters:
/// - [input]: The ASCII grid data as a string.
/// - [interpFactor]: The interpolation factor to increase grid resolution.
/// - [skipFactor]: The factor to skip grid cells when generating polygons (controls density).
///
/// Example usage:
/// ```dart
/// final service = KmlGenerationService(
///   input: await File("ASCII.txt").readAsString(),
///   interpFactor: 4,
///   skipFactor: 2,
/// );
/// final kmlString = await service.generateKml();
/// ```
///
/// Throws:
/// - [Exception] if the input data cannot be parsed or if there is a mismatch in grid dimensions.
///
/// Methods:
/// - [generateKml]: Parses the input, interpolates the grid, and generates the KML string.
/// - [interpolateGrid]: Performs bilinear interpolation on the grid data.
/// - [bilinearInterpolate]: Computes the interpolated value at a given point.
/// - [parameterToKmlColor]: Maps a parameter value to a KML color string.
library;

import 'dart:math';

import 'package:martian_climate_dashboard/entities/grid_point.dart';
import 'package:martian_climate_dashboard/entities/interpolated_grid.dart';

class KmlGenerationService {
  final String input;
  final int interpFactor;
  final int skipFactor;

  KmlGenerationService({
    required this.input,
    required this.interpFactor,
    required this.skipFactor,
  });

  Future<String> generateKml() async {
    final lines = input.split('\n');
    final lats = <double>[];
    final lons = <double>[];
    final parameterData = <List<double>>[];

    bool readingLatHeader = false;

    double? tryFloat(String s) => double.tryParse(s);

    for (final line in lines) {
      final lineStrip = line.trim();
      if (lineStrip.isEmpty || lineStrip.startsWith('#')) {
        continue;
      }

      if (lineStrip.startsWith("---- ||")) {
        readingLatHeader = true;
        final parts = lineStrip.split("||");

        if (parts.length < 2) {
          continue;
        }

        final latValsStr = parts[1].split(RegExp(r"\s+"));
        for (var val in latValsStr) {
          final valFloat = tryFloat(val);
          if (valFloat != null) {
            lats.add(valFloat);
          }
        }
        continue;
      }

      if (readingLatHeader && lineStrip.contains("||")) {
        final parts = lineStrip.split("||");
        if (parts.length < 2) {
          continue;
        }
        final lonStr = parts[0].trim();
        final lonVal = tryFloat(lonStr);
        if (lonVal == null) {
          continue;
        }
        lons.add(lonVal);

        final presStrList = parts[1].split(RegExp(r"\s+"));
        final rowParameters = <double>[];
        for (var val in presStrList) {
          final p = tryFloat(val);
          if (p != null) {
            rowParameters.add(p);
          }
        }
        parameterData.add(rowParameters);
      }
    }

    if (lons.isEmpty || lats.isEmpty || parameterData.isEmpty) {
      throw Exception("Parsing failed, data empty");
    }

    final numLats = lats.length;

    for (var row in parameterData) {
      if (row.length != numLats) {
        throw Exception("Mismatch in lat columns vs data row length.");
      }
    }

    final grid = await interpolateGrid(lons, lats, parameterData, interpFactor);

    final minP = grid.minParameter;
    final maxP = grid.maxParameter;
    final deltaP = (maxP - minP).abs() < 1e-12 ? 1e-12 : (maxP - minP);

    final buffer =
        StringBuffer()
          ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
          ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
          ..writeln('<Document>');

    for (var row = 0; row < grid.parameter.length - 1; row += skipFactor) {
      for (
        var col = 0;
        col < grid.parameter[row].length - 1;
        col += skipFactor
      ) {
        final p00 = grid.parameter[row][col];
        final left = grid.lon[col];
        final right =
            grid.lon[(col + skipFactor < grid.lon.length)
                ? col + skipFactor
                : grid.lon.length - 1];
        final bottom = grid.lat[row];
        final top =
            grid.lat[(row + skipFactor < grid.lat.length)
                ? row + skipFactor
                : grid.lat.length - 1];

        final color = parameterToKmlColor(p00, minP, deltaP);

        buffer
          ..writeln('<Placemark>')
          ..writeln(
            '<Style><PolyStyle><color>$color</color><outline>0</outline></PolyStyle></Style>',
          )
          ..writeln('<Polygon><outerBoundaryIs><LinearRing><coordinates>')
          ..writeln('$left,$bottom,0')
          ..writeln('$right,$bottom,0')
          ..writeln('$right,$top,0')
          ..writeln('$left,$top,0')
          ..writeln('$left,$bottom,0')
          ..writeln('</coordinates></LinearRing></outerBoundaryIs></Polygon>')
          ..writeln('</Placemark>');
      }
    }

    buffer
      ..writeln('</Document>')
      ..writeln('</kml>');

    return buffer.toString();
  }

  Future<InterpolatedGrid> interpolateGrid(
    List<double> lons,
    List<double> lats,
    List<List<double>> parameterData,
    int interpFactor,
  ) async {
    final lonMin = lons.reduce(min);
    final lonMax = lons.reduce(max);
    final latMin = lats.reduce(min);
    final latMax = lats.reduce(max);

    final newLonCount = (lons.length - 1) * interpFactor + 1;
    final newLatCount = (lats.length - 1) * interpFactor + 1;

    final lonNew = <double>[];
    final latNew = <double>[];
    for (var i = 0; i < newLonCount; i++) {
      lonNew.add(lonMin + (lonMax - lonMin) * i / (newLonCount - 1));
    }
    for (var j = 0; j < newLatCount; j++) {
      latNew.add(latMin + (latMax - latMin) * j / (newLatCount - 1));
    }

    final oldMap = <GridPoint, double>{};
    for (var i = 0; i < lons.length; i++) {
      for (var j = 0; j < lats.length; j++) {
        oldMap[GridPoint(lons[i], lats[j])] = parameterData[i][j];
      }
    }

    final newParameter = List.generate(
      newLatCount,
      (_) => List<double>.filled(newLonCount, 0.0),
    );

    for (var j = 0; j < newLatCount; j++) {
      for (var i = 0; i < newLonCount; i++) {
        final x = lonNew[i];
        final y = latNew[j];
        newParameter[j][i] = bilinearInterpolate(x, y, oldMap, lons, lats);
      }
    }

    return InterpolatedGrid(lonNew, latNew, newParameter);
  }

  double bilinearInterpolate(
    double x,
    double y,
    Map<GridPoint, double> dataMap,
    List<double> lons,
    List<double> lats,
  ) {
    var i1 = 0;
    while (i1 < lons.length - 1 && lons[i1 + 1] <= x) {
      i1++;
    }
    final i2 = (i1 < lons.length - 1) ? i1 + 1 : i1;

    var j1 = 0;
    while (j1 < lats.length - 1 && lats[j1 + 1] <= y) {
      j1++;
    }
    final j2 = (j1 < lats.length - 1) ? j1 + 1 : j1;

    final x1 = lons[i1];
    final x2 = lons[i2];
    final y1 = lats[j1];
    final y2 = lats[j2];

    final fQ11 = dataMap[GridPoint(x1, y1)] ?? 0.0;
    final fQ21 = dataMap[GridPoint(x2, y1)] ?? 0.0;
    final fQ12 = dataMap[GridPoint(x1, y2)] ?? 0.0;
    final fQ22 = dataMap[GridPoint(x2, y2)] ?? 0.0;

    final denom = (x2 - x1) * (y2 - y1);
    if (denom.abs() < 1e-12) {
      return (fQ11 + fQ21 + fQ12 + fQ22) / 4.0;
    }

    final val =
        fQ11 * (x2 - x) * (y2 - y) +
        fQ21 * (x - x1) * (y2 - y) +
        fQ12 * (x2 - x) * (y - y1) +
        fQ22 * (x - x1) * (y - y1);

    return val / denom;
  }

  String parameterToKmlColor(
    double parameterValue,
    double minP,
    double deltaP,
  ) {
    final ratio = (parameterValue - minP) / deltaP;

    final stops = <double, List<int>>{
      // 0.2: [0, 0, 0],
      0.2: [255, 200, 0],
      0.5: [255, 150, 0],
      0.8: [255, 50, 0],
      1.0: [255, 0, 0],
      0.0: [255, 255, 0],
    };

    double leftStop = 0.0;
    List<int> leftColor = [0, 0, 0];
    double rightStop = 1.0;
    List<int> rightColor = [255, 0, 0];
    final sorted = stops.keys.toList()..sort();

    var found = false;
    for (var i = 0; i < sorted.length - 1; i++) {
      final start = sorted[i];
      final end = sorted[i + 1];
      if (ratio >= start && ratio <= end) {
        leftStop = start;
        leftColor = stops[start]!;
        rightStop = end;
        rightColor = stops[end]!;
        found = true;
        break;
      }
    }
    if (!found) {
      if (ratio < 0.0) {
        leftStop = 0.0;
        rightStop = 0.0;
        leftColor = stops[0.0]!;
        rightColor = stops[0.0]!;
      } else {
        leftStop = 1.0;
        rightStop = 1.0;
        leftColor = stops[1.0]!;
        rightColor = stops[1.0]!;
      }
    }

    final segRange =
        (rightStop - leftStop).abs() < 1e-12 ? 1e-12 : (rightStop - leftStop);
    final t = (ratio - leftStop) / segRange;
    final r = (leftColor[0] + (rightColor[0] - leftColor[0]) * t).round().clamp(
      0,
      255,
    );
    final g = (leftColor[1] + (rightColor[1] - leftColor[1]) * t).round().clamp(
      0,
      255,
    );
    final b = (leftColor[2] + (rightColor[2] - leftColor[2]) * t).round().clamp(
      0,
      255,
    );

    String twoHex(int v) => v.toRadixString(16).padLeft(2, '0').toUpperCase();
    return "FF${twoHex(b)}${twoHex(g)}${twoHex(r)}";
  }
}

// Future<void> main() async {
//   final service = KmlGenerationService(
//     input: await File("ASCII.txt").readAsString(),
//     interpFactor: 4,
//     skipFactor: 2,
//   );
//   await service.generateKml();
// }
