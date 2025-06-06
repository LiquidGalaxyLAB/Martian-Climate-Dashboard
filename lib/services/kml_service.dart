import 'dart:io';
import 'dart:math';

class InterpolatedGrid {
  final List<double> lon;
  final List<double> lat;
  final List<List<double>> pressure;

  InterpolatedGrid(this.lon, this.lat, this.pressure);

  double get minPressure {
    var minVal = double.infinity;
    for (final row in pressure) {
      for (final val in row) {
        if (val < minVal) {
          minVal = val;
        }
      }
    }
    return minVal;
  }

  double get maxPressure {
    var maxVal = double.negativeInfinity;
    for (final row in pressure) {
      for (final val in row) {
        if (val > maxVal) {
          maxVal = val;
        }
      }
    }
    return maxVal;
  }
}

Future<void> generateSmootherKmlOptimized({
  required String inputFile,
  String outputKml = "mars_smoother_heatmap.kml",
  int interpFactor = 4,
  int skipFactor = 2,
}) async {
  final lines = await File(inputFile).readAsLines();
  print(lines);
  final lats = <double>[];
  final lons = <double>[];
  final pressureData = <List<double>>[];

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
      final rowPressures = <double>[];
      for (var val in presStrList) {
        final p = tryFloat(val);
        if (p != null) {
          rowPressures.add(p);
        }
      }
      pressureData.add(rowPressures);
    }
  }

  if (lons.isEmpty || lats.isEmpty || pressureData.isEmpty) {
    throw Exception(
      "Parsing failed or no valid data found. Check your file format.",
    );
  }
  final numLons = lons.length;
  final numLats = lats.length;
  for (var row in pressureData) {
    if (row.length != numLats) {
      throw Exception("Mismatch in lat columns vs data row length.");
    }
  }

  final grid = await interpolateGrid(lons, lats, pressureData, interpFactor);

  final minP = grid.minPressure;
  final maxP = grid.maxPressure;
  final deltaP = (maxP - minP).abs() < 1e-12 ? 1e-12 : (maxP - minP);

  final buffer =
      StringBuffer()
        ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
        ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
        ..writeln('<Document>');

  for (var row = 0; row < grid.pressure.length - 1; row += skipFactor) {
    for (var col = 0; col < grid.pressure[row].length - 1; col += skipFactor) {
      final p00 = grid.pressure[row][col];
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

      final color = pressureToKmlColor(p00, minP, deltaP);

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

  await File(outputKml).writeAsString(buffer.toString());
  print("KML file '$outputKml' created successfully!");
}

Future<InterpolatedGrid> interpolateGrid(
  List<double> lons,
  List<double> lats,
  List<List<double>> pressureData,
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

  final oldMap = <_Point, double>{};
  for (var i = 0; i < lons.length; i++) {
    for (var j = 0; j < lats.length; j++) {
      oldMap[_Point(lons[i], lats[j])] = pressureData[i][j];
    }
  }

  final newPressure = List.generate(
    newLatCount,
    (_) => List<double>.filled(newLonCount, 0.0),
  );

  for (var j = 0; j < newLatCount; j++) {
    for (var i = 0; i < newLonCount; i++) {
      final x = lonNew[i];
      final y = latNew[j];
      newPressure[j][i] = bilinearInterpolate(x, y, oldMap, lons, lats);
    }
  }

  return InterpolatedGrid(lonNew, latNew, newPressure);
}

double bilinearInterpolate(
  double x,
  double y,
  Map<_Point, double> dataMap,
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

  final fQ11 = dataMap[_Point(x1, y1)] ?? 0.0;
  final fQ21 = dataMap[_Point(x2, y1)] ?? 0.0;
  final fQ12 = dataMap[_Point(x1, y2)] ?? 0.0;
  final fQ22 = dataMap[_Point(x2, y2)] ?? 0.0;

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

class _Point {
  final double x;
  final double y;
  const _Point(this.x, this.y);

  @override
  bool operator ==(other) => (other is _Point && other.x == x && other.y == y);
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

String pressureToKmlColor(double pressureValue, double minP, double deltaP) {
  final ratio = (pressureValue - minP) / deltaP;

  final stops = <double, List<int>>{
    0.2: [0, 0, 0],
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

Future<void> main() async {
  await generateSmootherKmlOptimized(
    inputFile: "ASCII.txt",
    outputKml: "mars_smoother_heatmap.kml",
    interpFactor: 6,
    skipFactor: 2,
  );
}
