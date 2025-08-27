/// Represents an interpolated grid of Mars climate data with longitude, latitude, and parameter values.
///
/// This class stores a 2D grid of climate data that has been interpolated to provide
/// smooth transitions between data points. It's commonly used for creating continuous
/// visualizations of Mars climate parameters across geographic regions.
///
/// The grid structure allows for efficient storage and retrieval of climate data
/// at specific coordinate locations, enabling high-quality visualizations and
/// analysis of Mars atmospheric conditions.
///
/// Example usage:
/// ```dart
/// // Create interpolated temperature grid for Mars polar region
/// final temperatureGrid = InterpolatedGrid(
///   [-180.0, -170.0, -160.0], // longitude values
///   [80.0, 85.0, 90.0],       // latitude values
///   [                          // temperature matrix (Kelvin)
///     [150.2, 148.7, 147.1],
///     [152.1, 149.8, 148.3],
///     [154.0, 151.2, 149.7],
///   ],
/// );
/// ```
class InterpolatedGrid {
  /// Array of longitude values in degrees.
  ///
  /// Represents the X-axis coordinates of the grid, typically ranging
  /// from -180° to +180° for global Mars coverage. Values should be
  /// sorted in ascending order for proper grid functionality.
  ///
  /// Each longitude value corresponds to a column in the parameter matrix.
  final List<double> lon;

  /// Array of latitude values in degrees.
  ///
  /// Represents the Y-axis coordinates of the grid, typically ranging
  /// from -90° to +90° for global Mars coverage. Values should be
  /// sorted in ascending order for proper grid functionality.
  ///
  /// Each latitude value corresponds to a row in the parameter matrix.
  final List<double> lat;

  /// 2D matrix of interpolated parameter values.
  ///
  /// Contains the climate data values organized as parameter[lat_index][lon_index].
  /// Each row corresponds to a latitude band, and each column corresponds to
  /// a longitude band. The values represent the interpolated climate parameter
  /// (e.g., temperature, pressure, wind speed) at each grid intersection.
  ///
  /// Matrix dimensions should match:
  /// - Rows: parameter.length == lat.length
  /// - Columns: parameter[i].length == lon.length for all i
  final List<List<double>> parameter;

  /// Creates a new interpolated grid with the specified coordinate arrays and parameter matrix.
  ///
  /// Parameters:
  /// - [lon]: Array of longitude values in degrees (ascending order recommended)
  /// - [lat]: Array of latitude values in degrees (ascending order recommended)
  /// - [parameter]: 2D matrix of interpolated values where parameter[lat_index][lon_index]
  ///   represents the climate data at the corresponding coordinates
  ///
  /// Example:
  /// ```dart
  /// final grid = InterpolatedGrid(
  ///   [-10.0, 0.0, 10.0],           // 3 longitude points
  ///   [0.0, 5.0],                   // 2 latitude points
  ///   [                             // 2x3 parameter matrix
  ///     [250.1, 251.3, 252.0],      // values at lat=0.0
  ///     [248.7, 249.9, 250.5],      // values at lat=5.0
  ///   ],
  /// );
  /// ```
  InterpolatedGrid(this.lon, this.lat, this.parameter);

  /// Finds the minimum parameter value across the entire grid.
  ///
  /// Iterates through all values in the parameter matrix to determine
  /// the smallest climate data value. Useful for setting visualization
  /// scales and determining data ranges for color mapping.
  ///
  /// Returns: The minimum parameter value found in the grid
  ///
  /// Example:
  /// ```dart
  /// final tempGrid = InterpolatedGrid(/*...*/);
  /// final minTemp = tempGrid.minParameter; // e.g., 145.2 Kelvin
  /// print('Coldest temperature: ${minTemp}K');
  /// ```
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

  /// Finds the maximum parameter value across the entire grid.
  ///
  /// Iterates through all values in the parameter matrix to determine
  /// the largest climate data value. Useful for setting visualization
  /// scales and determining data ranges for color mapping.
  ///
  /// Returns: The maximum parameter value found in the grid
  ///
  /// Example:
  /// ```dart
  /// final tempGrid = InterpolatedGrid(/*...*/);
  /// final maxTemp = tempGrid.maxParameter; // e.g., 295.7 Kelvin
  /// print('Warmest temperature: ${maxTemp}K');
  /// ```
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

  /// Gets the parameter value at specific grid indices.
  ///
  /// Parameters:
  /// - [latIndex]: Row index in the parameter matrix (0 to lat.length-1)
  /// - [lonIndex]: Column index in the parameter matrix (0 to lon.length-1)
  ///
  /// Returns: The parameter value at the specified grid location
  ///
  /// Throws: [RangeError] if indices are out of bounds
  ///
  /// Example:
  /// ```dart
  /// final value = grid.getValueAt(1, 2); // Get value at lat[1], lon[2]
  /// ```
  double getValueAt(int latIndex, int lonIndex) {
    return parameter[latIndex][lonIndex];
  }

  /// Gets the geographic coordinates for specific grid indices.
  ///
  /// Parameters:
  /// - [latIndex]: Row index (0 to lat.length-1)
  /// - [lonIndex]: Column index (0 to lon.length-1)
  ///
  /// Returns: A list [longitude, latitude] in degrees
  ///
  /// Example:
  /// ```dart
  /// final coords = grid.getCoordinatesAt(1, 2); // [lon[2], lat[1]]
  /// ```
  List<double> getCoordinatesAt(int latIndex, int lonIndex) {
    return [lon[lonIndex], lat[latIndex]];
  }

  /// Gets the parameter value range (min and max) for the entire grid.
  ///
  /// Returns: A list [minValue, maxValue] representing the data range
  ///
  /// Example:
  /// ```dart
  /// final range = grid.parameterRange; // [145.2, 295.7]
  /// final span = range[1] - range[0];  // Total range span
  /// ```
  List<double> get parameterRange {
    return [minParameter, maxParameter];
  }

  /// Returns grid dimensions as [longitude_count, latitude_count].
  ///
  /// Useful for understanding the resolution and structure of the grid.
  ///
  /// Returns: A list [lon.length, lat.length] representing grid size
  ///
  /// Example:
  /// ```dart
  /// final dimensions = grid.dimensions; // [360, 180] for 1° resolution global grid
  /// print('Grid resolution: ${dimensions[0]} x ${dimensions[1]}');
  /// ```
  List<int> get dimensions {
    return [lon.length, lat.length];
  }

  /// Provides a string representation of the interpolated grid.
  ///
  /// Includes grid dimensions and parameter value range for debugging.
  ///
  /// Returns: Formatted string with grid information
  @override
  String toString() {
    return 'InterpolatedGrid(${lon.length}x${lat.length}, '
        'range: ${minParameter.toStringAsFixed(2)} to ${maxParameter.toStringAsFixed(2)})';
  }
}
