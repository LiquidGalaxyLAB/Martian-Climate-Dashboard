import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/widgets/button.dart';
import 'package:martian_climate_dashboard/widgets/input.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConnectPage extends StatefulWidget {
  const ConnectPage({super.key});

  @override
  State<ConnectPage> createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> {
  TextEditingController hostController = TextEditingController();
  TextEditingController portController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController screenCountController = TextEditingController();

  Future<void> _loadSavedData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      hostController.text = prefs.getString('host') ?? '';
      portController.text = prefs.getInt('port')?.toString() ?? '';
      usernameController.text = prefs.getString('username') ?? '';
      passwordController.text = prefs.getString('password') ?? '';
      screenCountController.text = prefs.getInt('rigs')?.toString() ?? '';
    });
  }

  @override
  void initState() {
    _loadSavedData();
    super.initState();
  }

  @override
  void dispose() {
    hostController.dispose();
    portController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    screenCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lgService = Provider.of<LgService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Connect')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MCDButton(
                textColor: Colors.black,
                onPressed: () {
                  if (kDebugMode) {
                    print("Scan QR Code");
                  }
                  Navigator.of(context).pushNamed('/scan');
                },
                text: "Scan Using QR",
                color: Theme.of(context).primaryColor,
              ),
            ),
            ChoiceDivider(),
            FormInput(
              hintText: "192.168.56.121",
              labelText: "Host",
              controller: hostController,
            ),
            FormInput(
              hintText: "22",
              labelText: "Port",
              textInputType: TextInputType.number,
              controller: portController,
            ),
            FormInput(
              hintText: "lg",
              labelText: "Username",
              controller: usernameController,
            ),
            FormInput(
              hintText: "lg",
              labelText: "Password",
              controller: passwordController,
            ),
            FormInput(
              hintText: "3",
              labelText: "Number of Screens",
              textInputType: TextInputType.number,
              controller: screenCountController,
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MCDButton(
                text: "CONNECT",
                onPressed: () async {
                  if (kDebugMode) {
                    print(hostController.text);
                  }
                  final SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  try {
                    lgService.host = hostController.text;
                    lgService.port =
                        portController.text.isNotEmpty
                            ? int.parse(portController.text)
                            : 22;
                    lgService.username = usernameController.text;
                    lgService.password = passwordController.text;
                    lgService.rigs =
                        int.tryParse(screenCountController.text) ?? 0;

                    prefs.setString('host', lgService.host);
                    prefs.setInt('port', lgService.port);
                    prefs.setString('username', lgService.username);
                    prefs.setString('password', lgService.password);
                    prefs.setInt('rigs', lgService.rigs);

                    bool res = await lgService.checkConnection();
                    if (kDebugMode) {
                      print(res);
                    }
                    if (!res) {
                      lgService.connected = false;
                    } else {
                      lgService.connected = true;
                    }
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(res ? 'Connected' : 'Failed to connect'),
                      ),
                    );
                    String logo = await rootBundle.loadString(
                      'assets/kml/logos.kml',
                    );
                    await lgService.execCommand(
                      "echo '$logo' > /var/www/html/kml/slave_${lgService.logoScreen}.kml",
                    );
                  } catch (e) {
                    if (kDebugMode) {
                      print(e.toString());
                    }
                    if (!mounted) return;
                    // ignore: use_build_context_synchronously
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FormInput extends StatelessWidget {
  final String? hintText;
  final String labelText;
  final TextEditingController? controller;
  final TextInputType? textInputType;
  const FormInput({
    super.key,
    this.hintText,
    required this.labelText,
    this.controller,
    this.textInputType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 5),
          child: Text(labelText, style: TextStyle(color: Colors.black)),
        ),
        InputBar(
          controller: controller,
          hintText: hintText,
          showIcon: false,
          textInputType: textInputType,
        ),
        SizedBox(height: 3),
      ],
    );
  }
}

class ChoiceDivider extends StatelessWidget {
  const ChoiceDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 28),
      child: Row(
        children: [
          Expanded(child: Divider(color: Colors.black, thickness: 1)),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Text("or", style: TextStyle(color: Colors.black)),
          ),
          Expanded(child: Divider(color: Colors.black, thickness: 1)),
        ],
      ),
    );
  }
}
