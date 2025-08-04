import 'dart:convert';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SphereProjectionImage extends StatefulWidget {
  final String base64Image;
  final Size size;
  final Rect? crop; // Add crop parameter

  const SphereProjectionImage({
    super.key,
    required this.base64Image,
    required this.size,
    this.crop, // Optional crop parameter
  });

  @override
  SphereProjectionImageState createState() => SphereProjectionImageState();
}

class SphereProjectionImageState extends State<SphereProjectionImage> {
  ui.Image? _image;
  ui.Image? _croppedImage;

  @override
  void initState() {
    super.initState();
    _loadImageFromBase64(widget.base64Image);
  }

  Future<void> _loadImageFromBase64(String base64String) async {
    try {
      final list = base64Decode(base64String);
      final image = await decodeImageFromList(list);

      ui.Image? finalImage = image;

      // Apply cropping if specified
      if (widget.crop != null) {
        finalImage = await _cropImage(image, widget.crop!);
      }

      setState(() {
        _image = finalImage;
      });
    } catch (e) {
      print('Error loading image from base64: $e');
    }
  }

  Future<ui.Image> _cropImage(ui.Image originalImage, Rect cropRect) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Calculate the center crop area
    final double originalWidth = originalImage.width.toDouble();
    final double originalHeight = originalImage.height.toDouble();

    // Calculate the cropped dimensions (what remains after cropping)
    final double croppedWidth = originalWidth - cropRect.left - cropRect.right;
    final double croppedHeight =
        originalHeight - cropRect.top - cropRect.bottom;

    // Define source rectangle (the center part we want to keep)
    final srcRect = Rect.fromLTWH(
      cropRect.left,
      cropRect.top,
      croppedWidth,
      croppedHeight,
    );

    // Define destination rectangle (full canvas)
    final destRect = Rect.fromLTWH(0, 0, croppedWidth, croppedHeight);

    // Draw the cropped portion
    canvas.drawImageRect(
      originalImage,
      srcRect,
      destRect,
      Paint()..filterQuality = FilterQuality.high,
    );

    final picture = recorder.endRecording();
    return await picture.toImage(croppedWidth.toInt(), croppedHeight.toInt());
  }

  @override
  Widget build(BuildContext context) {
    return _image == null
        ? Container(
          width: widget.size.width,
          height: widget.size.height,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.grey.shade200,
          ),
          child: CircularProgressIndicator(),
        )
        : CustomPaint(painter: SpherePainter(_image!), size: widget.size);
  }
}

class SpherePainter extends CustomPainter {
  final ui.Image image;

  SpherePainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.high;

    final radius = size.width / 2;
    final center = Offset(radius, radius);

    // Create a circular clipping path
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius)),
    );

    final imageWidth = image.width.toDouble();
    final imageHeight = image.height.toDouble();

    // Use pixel-based approach for better quality
    const int resolution = 200; // Resolution of the sphere projection

    for (int y = 0; y < resolution; y++) {
      for (int x = 0; x < resolution; x++) {
        // Convert pixel coordinates to normalized coordinates (-1 to 1)
        final double nx = (x / (resolution - 1)) * 2 - 1;
        final double ny = (y / (resolution - 1)) * 2 - 1;

        // Check if point is within unit circle
        final double distanceFromCenter = sqrt(nx * nx + ny * ny);
        if (distanceFromCenter <= 1.0) {
          // Calculate 3D coordinates on sphere
          final double z = sqrt(1 - nx * nx - ny * ny);

          // Convert 3D point to spherical coordinates
          final double longitude = atan2(nx, z);
          final double latitude = asin(ny);

          // Map spherical coordinates to texture coordinates
          final double u = (longitude + pi) / (2 * pi);
          final double v = (latitude + pi / 2) / pi;

          // Get source pixel from image
          final int srcX = (u * (imageWidth - 1)).round().clamp(
            0,
            imageWidth.toInt() - 1,
          );
          final int srcY = (v * (imageHeight - 1)).round().clamp(
            0,
            imageHeight.toInt() - 1,
          );

          // Calculate destination pixel position
          final double destX = center.dx + nx * radius;
          final double destY = center.dy + ny * radius;

          // Draw a small rectangle for this pixel
          final srcRect = Rect.fromLTWH(srcX.toDouble(), srcY.toDouble(), 1, 1);
          final destRect = Rect.fromLTWH(destX - 1, destY - 1, 2, 2);

          canvas.drawImageRect(image, srcRect, destRect, paint);
        }
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
