import 'dart:convert';
import 'package:flutter/foundation.dart'; // for compute()
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

class _QRPageState extends State<QRPage> with WidgetsBindingObserver {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    detectionTimeoutMs: 800,
    formats: const [BarcodeFormat.qrCode],
  );

  String? _lastCode;
  bool _connecting = false;
  DateTime _lastScan = DateTime.fromMillisecondsSinceEpoch(0);
  static const _debounce = Duration(milliseconds: 900);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _safeStop();
    } else if (state == AppLifecycleState.resumed) {
      _safeStart();
    }
  }

  Future<void> _safeStop() async {
    if (!_controller.value.isRunning) return;
    try {
      await _controller.stop().timeout(const Duration(milliseconds: 500));
    } catch (_) {}
  }

  Future<void> _safeStart() async {
    if (_controller.value.isRunning) return;
    try {
      await _controller.start().timeout(const Duration(milliseconds: 700));
    } catch (_) {}
  }

  Future<void> _setPrefs(LgService lgService) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('host', lgService.host);
    await prefs.setInt('port', lgService.port);
    await prefs.setString('username', lgService.username);
    await prefs.setString('password', lgService.password);
    await prefs.setInt('rigs', lgService.rigs);
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    final code = capture.barcodes.first.rawValue;
    if (code == null) return;

    final now = DateTime.now();
    if (_connecting ||
        code == _lastCode ||
        now.difference(_lastScan) < _debounce) {
      return;
    }
    _lastScan = now;
    _lastCode = code;

    setState(() => _connecting = true);

    try {
      final data = await compute(_decodeJson, code);

      if (!mounted) return;
      final lgService = context.read<LgService>();
      lgService
        ..host = (data['ip'] as String?) ?? lgService.host
        ..port = (data['port'] as int?) ?? 22
        ..username = (data['username'] as String?) ?? 'lg'
        ..password = (data['password'] as String?) ?? 'lqgalaxy'
        ..rigs = (data['screens'] as int?) ?? 5;

      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(content: Text('Connecting to ${lgService.host}...')),
      );

      await _setPrefs(lgService);

      final ok = await lgService.checkConnection();
      if (!mounted) return;

      messenger.hideCurrentSnackBar();
      if (ok) {
        messenger.showSnackBar(
          SnackBar(content: Text('Connected to ${lgService.host}')),
        );
        Navigator.of(context).pop();
        return;
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to connect to ${lgService.host}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to parse/connect: $e')));
    } finally {
      if (mounted) {
        setState(() => _connecting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR')),
      body: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final cutoutSize = w * 0.75;
          final left = (w - cutoutSize) / 2;
          final top = (h - cutoutSize) / 2;
          final scanWindow = Rect.fromLTWH(left, top, cutoutSize, cutoutSize);

          return Stack(
            children: [
              MobileScanner(
                controller: _controller,
                fit: BoxFit.cover,
                scanWindow: scanWindow,
                onDetect: _onDetect,
              ),
              IgnorePointer(
                child: CustomPaint(size: Size(w, h), painter: CutoutPainter()),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black54,
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    "Scan LG QR code to connect",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              if (_connecting)
                const ModalBarrier(dismissible: false, color: Colors.black38),
              if (_connecting)
                Center(
                  child: Container(
                    constraints: BoxConstraints(
                      minWidth: w * 0.6,
                      minHeight: w * 0.3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 12),
                        Text('Connecting...'),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

Map<String, dynamic> _decodeJson(String s) =>
    jsonDecode(s) as Map<String, dynamic>;

class CutoutPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outer = Path()..addRect(Offset.zero & size);
    final cutoutSize = size.width * 0.75;
    final left = (size.width - cutoutSize) / 2;
    final top = (size.height - cutoutSize) / 2;
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(left, top, cutoutSize, cutoutSize),
      const Radius.circular(20),
    );
    final cut = Path()..addRRect(rrect);
    final shade = Paint()..color = Colors.black45;
    canvas.drawPath(Path.combine(PathOperation.xor, outer, cut), shade);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
