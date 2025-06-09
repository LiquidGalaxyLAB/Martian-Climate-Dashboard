class GridPoint {
  final double x;
  final double y;
  const GridPoint(this.x, this.y);

  @override
  bool operator ==(other) =>
      (other is GridPoint && other.x == x && other.y == y);
  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}
