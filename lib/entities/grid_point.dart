import 'dart:math' as math;

/// Represents a 2D coordinate point in a grid system for Mars climate data visualization.
///
/// This immutable class defines a point with X and Y coordinates, typically used
/// for mapping climate data to specific locations on Mars' surface or within
/// visualization grids. The coordinates are stored as double values to support
/// precise positioning.
///
/// Common use cases:
/// - Representing data points in Mars Climate Database (MCD) grid systems
/// - Mapping visualization coordinates to Mars surface locations
/// - Defining positions for climate data interpolation
/// - Grid-based data structure indexing
class GridPoint {
  /// The X coordinate of the grid point
  ///
  /// Typically represents longitude or horizontal position in the grid system.
  /// Range and units depend on the specific grid system being used.
  final double x;

  /// The Y coordinate of the grid point
  ///
  /// Typically represents latitude or vertical position in the grid system.
  /// Range and units depend on the specific grid system being used.
  final double y;

  /// Creates a new grid point with the specified X and Y coordinates.
  ///
  /// Parameters:
  /// - [x]: The horizontal coordinate value
  /// - [y]: The vertical coordinate value
  ///
  /// Example:
  /// ```dart
  /// // Create a grid point for Olympus Mons region
  /// final olympusMons = GridPoint(226.2, 18.65);
  ///
  /// // Create origin point
  /// final origin = GridPoint(0.0, 0.0);
  /// ```
  const GridPoint(this.x, this.y);

  /// Compares this grid point with another object for equality.
  ///
  /// Two grid points are considered equal if they have identical
  /// X and Y coordinate values.
  ///
  /// Parameters:
  /// - [other]: The object to compare with this grid point
  ///
  /// Returns: `true` if the objects are equal, `false` otherwise
  @override
  bool operator ==(other) =>
      (other is GridPoint && other.x == x && other.y == y);

  /// Generates a hash code for this grid point.
  ///
  /// The hash code is computed using the XOR of the hash codes
  /// of the X and Y coordinates, ensuring that equal grid points
  /// produce the same hash code.
  ///
  /// Returns: Integer hash code for this grid point
  @override
  int get hashCode => x.hashCode ^ y.hashCode;

  /// Returns a string representation of this grid point.
  ///
  /// Useful for debugging and logging purposes.
  ///
  /// Returns: String in the format "GridPoint(x, y)"
  ///
  /// Example:
  /// ```dart
  /// final point = GridPoint(10.5, -20.3);
  /// print(point.toString()); // Output: GridPoint(10.5, -20.3)
  /// ```
  @override
  String toString() => 'GridPoint($x, $y)';

  /// Calculates the Euclidean distance between this point and another grid point.
  ///
  /// Uses the standard distance formula: √((x₂-x₁)² + (y₂-y₁)²)
  ///
  /// Parameters:
  /// - [other]: The grid point to calculate distance to
  ///
  /// Returns: The distance as a double value
  ///
  /// Example:
  /// ```dart
  /// final point1 = GridPoint(0.0, 0.0);
  /// final point2 = GridPoint(3.0, 4.0);
  /// final distance = point1.distanceTo(point2); // Returns 5.0
  /// ```
  double distanceTo(GridPoint other) {
    final dx = x - other.x;
    final dy = y - other.y;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Creates a new grid point by adding the coordinates of another point.
  ///
  /// Parameters:
  /// - [other]: The grid point to add to this point
  ///
  /// Returns: A new GridPoint with summed coordinates
  ///
  /// Example:
  /// ```dart
  /// final point1 = GridPoint(1.0, 2.0);
  /// final point2 = GridPoint(3.0, 4.0);
  /// final sum = point1 + point2; // GridPoint(4.0, 6.0)
  /// ```
  GridPoint operator +(GridPoint other) {
    return GridPoint(x + other.x, y + other.y);
  }

  /// Creates a new grid point by subtracting the coordinates of another point.
  ///
  /// Parameters:
  /// - [other]: The grid point to subtract from this point
  ///
  /// Returns: A new GridPoint with the difference in coordinates
  ///
  /// Example:
  /// ```dart
  /// final point1 = GridPoint(5.0, 7.0);
  /// final point2 = GridPoint(2.0, 3.0);
  /// final diff = point1 - point2; // GridPoint(3.0, 4.0)
  /// ```
  GridPoint operator -(GridPoint other) {
    return GridPoint(x - other.x, y - other.y);
  }

  /// Creates a new grid point by scaling this point's coordinates.
  ///
  /// Parameters:
  /// - [scalar]: The value to multiply both coordinates by
  ///
  /// Returns: A new GridPoint with scaled coordinates
  ///
  /// Example:
  /// ```dart
  /// final point = GridPoint(2.0, 3.0);
  /// final scaled = point * 2.5; // GridPoint(5.0, 7.5)
  /// ```
  GridPoint operator *(double scalar) {
    return GridPoint(x * scalar, y * scalar);
  }
}
