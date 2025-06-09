class InterpolatedGrid {
  final List<double> lon;
  final List<double> lat;
  final List<List<double>> parameter;

  InterpolatedGrid(this.lon, this.lat, this.parameter);

  double get minParameter {
    var minVal = double.infinity;
    for (final row in parameter) {
      for (final val in row) {
        if (val < minVal) {
          minVal = val;
        }
      }
    }
    return minVal;
  }

  double get maxParameter {
    var maxVal = double.negativeInfinity;
    for (final row in parameter) {
      for (final val in row) {
        if (val > maxVal) {
          maxVal = val;
        }
      }
    }
    return maxVal;
  }
}
