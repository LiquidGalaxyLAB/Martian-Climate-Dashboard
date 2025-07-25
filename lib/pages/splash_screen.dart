import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 5), () {
      Navigator.pushReplacementNamed(context, '/home');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      LgService lgService = Provider.of<LgService>(context, listen: false);
      lgService.checkConnection();
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(child: Image(image: AssetImage('assets/Logos.png'))),
    );
  }
}
