import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRPage extends StatefulWidget {
  const QRPage({super.key});

  @override
  State<QRPage> createState() => _QRPageState();
}

class _QRPageState extends State<QRPage> {
  String? qrCode;
  bool connecting = false;
  Future<void> setPrefs(LgService lgService) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('host', lgService.host);
    await prefs.setInt('port', lgService.port);
    await prefs.setString('username', lgService.username);
    await prefs.setString('password', lgService.password);
    await prefs.setInt('rigs', lgService.rigs);
  }

  void _onDetect(BarcodeCapture capture) async {
    final String? code = capture.barcodes.first.rawValue;
    if (code != null && code != qrCode && connecting == false) {
      setState(() {
        connecting = true;
      });
      try {
        final Map<String, dynamic> jsonData = jsonDecode(code);
        print(jsonData['username']);
        qrCode = jsonData.toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connecting to ${jsonData['ip']}')),
        );
        LgService lgService = Provider.of<LgService>(context, listen: false);
        lgService.host = jsonData['ip'];
        lgService.port = jsonData['port'] ?? 22;
        lgService.username = jsonData['username'] ?? 'lg';
        lgService.password = jsonData['password'] ?? 'lqgalaxy';
        lgService.rigs = jsonData['screens'] ?? 5;

        await setPrefs(lgService);
        if (await lgService.checkConnection()) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Connected to ${lgService.host}')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to connect to ${lgService.host}')),
          );
        }
      } catch (e) {
        print('Failed to parse QR code: $e');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to connect: $e')));
        qrCode = code;
      } finally {
        setState(() {
          connecting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: Stack(
        children: [
          MobileScanner(onDetect: _onDetect),
          CustomPaint(
            size: Size(
              MediaQuery.of(context).size.width,
              MediaQuery.of(context).size.height,
            ),
            painter: CutoutPainter(),
          ),
          // if (qrCode != null)
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black54,
              padding: const EdgeInsets.all(16),
              child: Text(
                "Scan LG QR code to connect",
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          if (connecting)
            Align(
              alignment: Alignment.center,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                height: MediaQuery.of(context).size.width * 0.3,
                width: MediaQuery.of(context).size.width * 0.3,
                // color: Colors.white,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Center(child: CircularProgressIndicator()),
                    const Text('Connecting...'),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class CutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outerRect = Rect.fromLTWH(0, 0, size.width, size.height);

    final cutoutSize = size.width * 0.75;
    final left = (size.width - cutoutSize) / 2;
    final top = (size.height - cutoutSize) / 2;
    final cutoutRect = Rect.fromLTWH(left, top, cutoutSize, cutoutSize);
    final borderRadius = 20.0;

    final cutoutPath =
        Path()..addRRect(
          RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)),
        );

    // final borderPaint =
    //     Paint()
    //       ..color = Colors.black38
    //       ..style = PaintingStyle.stroke
    //       ..strokeWidth = 2.0;
    // canvas.drawRRect(
    //   RRect.fromRectAndRadius(cutoutRect, Radius.circular(borderRadius)),
    //   borderPaint,
    // );

    final outerPath = Path()..addRect(outerRect);

    final combinedPath = Path.combine(PathOperation.xor, outerPath, cutoutPath);

    final paint =
        Paint()
          ..color = Colors.black45
          ..style = PaintingStyle.fill;

    canvas.drawPath(combinedPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
