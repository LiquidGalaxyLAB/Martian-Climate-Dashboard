import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class SphereProjectionImage extends StatefulWidget {
  final String base64Image;
  final Size size;
  final Rect? crop;

  /// Optional grid resolution for the mesh (higher = smoother, more triangles).
  /// 64–128 is usually plenty. Default 96.
  final int grid;

  const SphereProjectionImage({
    super.key,
    required this.base64Image,
    required this.size,
    this.crop,
    this.grid = 96,
  });

  @override
  State<SphereProjectionImage> createState() => SphereProjectionImageState();
}

class SphereProjectionImageState extends State<SphereProjectionImage> {
  ui.Image? _image; // final (possibly cropped) image used for drawing
  ui.Shader? _shader; // Image shader bound to _image
  ui.Vertices? _vertices; // Cached sphere mesh for current size/image
  Size? _lastSize; // To detect when to rebuild mesh
  int? _lastGrid;

  @override
  void initState() {
    super.initState();
    _loadAndPrepareImage(widget.base64Image, widget.crop);
  }

  @override
  void didUpdateWidget(covariant SphereProjectionImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final imageChanged = widget.base64Image != oldWidget.base64Image;
    final cropChanged = widget.crop != oldWidget.crop;
    final sizeChanged = widget.size != oldWidget.size;
    final gridChanged = widget.grid != oldWidget.grid;

    if (imageChanged || cropChanged) {
      _disposeResources(); // full reset
      _loadAndPrepareImage(widget.base64Image, widget.crop);
    } else if (sizeChanged || gridChanged) {
      _rebuildMeshIfNeeded(force: true);
    }
  }

  Future<void> _loadAndPrepareImage(String base64String, Rect? crop) async {
    try {
      final bytes = base64Decode(base64String);
      final decoded = await decodeImageFromList(bytes);

      ui.Image finalImage = decoded;
      if (crop != null) {
        finalImage = await _cropImage(decoded, crop);
        // keep a ref to dispose later if desired
      }

      // Build shader & mesh
      _image = finalImage;
      _shader = ui.ImageShader(
        finalImage,
        TileMode.clamp,
        TileMode.clamp,
        Matrix4.identity().storage,
        filterQuality: FilterQuality.high,
      );
      _rebuildMeshIfNeeded(force: true);
      if (mounted) setState(() {});
    } catch (e) {
      // ignore: avoid_print
      print('Error loading image from base64: $e');
    }
  }

  Future<ui.Image> _cropImage(ui.Image original, Rect cropRect) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final double ow = original.width.toDouble();
    final double oh = original.height.toDouble();

    final double cw = (ow - cropRect.left - cropRect.right).clamp(1, ow);
    final double ch = (oh - cropRect.top - cropRect.bottom).clamp(1, oh);

    final src = Rect.fromLTWH(
      cropRect.left.clamp(0.0, ow - 1),
      cropRect.top.clamp(0.0, oh - 1),
      cw,
      ch,
    );
    final dst = Rect.fromLTWH(0, 0, cw, ch);

    canvas.drawImageRect(
      original,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    return await picture.toImage(cw.toInt(), ch.toInt());
  }

  void _rebuildMeshIfNeeded({bool force = false}) {
    if (_image == null || _shader == null) return;

    if (!force &&
        _vertices != null &&
        _lastSize == widget.size &&
        _lastGrid == widget.grid) {
      return;
    }

    _vertices = _buildSphereVertices(
      image: _image!,
      drawSize: widget.size,
      grid: widget.grid,
    );
    _lastSize = widget.size;
    _lastGrid = widget.grid;
  }

  ui.Vertices _buildSphereVertices({
    required ui.Image image,
    required Size drawSize,
    required int grid,
  }) {
    final radius = drawSize.width / 2.0;
    final center = Offset(radius, radius);
    final iw = image.width.toDouble();
    final ih = image.height.toDouble();

    // Positions (screen), texture coordinates (image space), and indices.
    final positions = <Offset>[];
    final texCoords = <Offset>[];
    final indices = <int>[];

    // Build a uniform grid over the square that bounds the circle.
    for (int gy = 0; gy < grid; gy++) {
      final ny = (gy / (grid - 1)) * 2.0 - 1.0; // [-1, 1]
      for (int gx = 0; gx < grid; gx++) {
        final nx = (gx / (grid - 1)) * 2.0 - 1.0; // [-1, 1]
        positions.add(Offset(center.dx + nx * radius, center.dy + ny * radius));

        final r2 = nx * nx + ny * ny;
        double u = 0.0, v = 0.0;

        if (r2 <= 1.0) {
          // Point on unit sphere (upper hemisphere z >= 0 after projection)
          final z = math.sqrt(1.0 - r2);
          final longitude = math.atan2(nx, z);
          final latitude = math.asin(ny);

          // Equirectangular UVs in [0,1]
          final uu = (longitude + math.pi) / (2 * math.pi);
          final vv = (latitude + math.pi / 2) / math.pi;

          // Texture coordinates in image pixel space
          u = uu * (iw - 1);
          v = vv * (ih - 1);
        }

        texCoords.add(Offset(u, v));
      }
    }

    // Quad -> two triangles
    for (int y = 0; y < grid - 1; y++) {
      for (int x = 0; x < grid - 1; x++) {
        final i0 = y * grid + x;
        final i1 = i0 + 1;
        final i2 = i0 + grid;
        final i3 = i2 + 1;
        indices.addAll([i0, i2, i1, i1, i2, i3]);
      }
    }

    return ui.Vertices(
      ui.VertexMode.triangles,
      positions,
      textureCoordinates: texCoords,
      indices: indices,
    );
  }

  void _disposeResources() {
    // Note: ui.Image has dispose() on newer Flutter; call if available in your channel.
    _vertices = null;
    _shader = null;
    _image = null;
  }

  @override
  void dispose() {
    _disposeResources();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    if (_image == null || _shader == null || _vertices == null) {
      return Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade200,
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return RepaintBoundary(
      child: CustomPaint(
        size: size,
        isComplex: true,
        willChange: false,
        painter: _SpherePainter(vertices: _vertices!, shader: _shader!),
      ),
    );
  }
}

class _SpherePainter extends CustomPainter {
  final ui.Vertices vertices;
  final ui.Shader shader;

  _SpherePainter({required this.vertices, required this.shader});

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.width / 2.0;
    final center = Offset(radius, radius);

    // Clip to a circle to hide the square mesh outside the sphere
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    final paint =
        Paint()
          ..isAntiAlias = true
          ..shader = shader
          ..filterQuality = FilterQuality.low; // sampling handled by GPU

    canvas.drawVertices(vertices, BlendMode.srcOver, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SpherePainter oldDelegate) {
    // We rebuild vertices/shader only when inputs change, so painter itself
    // does not need to repaint.
    return false;
  }
}
