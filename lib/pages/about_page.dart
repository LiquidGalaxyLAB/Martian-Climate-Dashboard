import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Image.asset(
                  'assets/Martian Climate Dashboard-nobg.png',
                  height: 200,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Martian Climate Dashboard',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Author:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const Text(
                      'Mohit Sharma',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Mentors:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                    const Text(
                      'Víctor Pérez, Victor Carreras',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                'The project aims to provide real-time and historical climate data visualization from Mars on Liquid Galaxy through an engaging and interactive experience. A Flutter-based mobile app will retrieve and process atmospheric data from the Mars Climate Database (MCD), presenting it with compelling visualizations on Liquid Galaxy.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              // const SizedBox(height: 24),
              // Logos.png further below
              Center(child: Image.asset('assets/Logos.png', height: 400)),
            ],
          ),
        ),
      ),
    );
  }
}
