import 'package:flutter/material.dart';
import 'package:martian_climate_dashboard/services/lg_service.dart';
import 'package:martian_climate_dashboard/widgets/button.dart';
import 'package:martian_climate_dashboard/widgets/drawer.dart';
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
      // backgroundColor: ThemeColors.backgroundColor,
      appBar: AppBar(title: const Text('Connect')),
      // drawer: MCDDrawer(),
      // appBar: AppBarPilot(title: "Connect"),
      // drawer: DrawerPilot(  ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: MCDButton(
                textColor: Colors.black,
                onPressed: () {
                  //   Navigator.of(
                  //     context,
                  //   ).push(MaterialPageRoute(builder: (context) => QRPage()));
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
                  print(hostController.text);
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
                    print(res);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        // backgroundColor: ThemeColors.primaryColor,
                        content: Text(
                          res ? 'Connected' : 'Failed to connect',
                          // style: TextStyle(color: ThemeColors.primaryTextColor),
                        ),
                      ),
                    );
                  } catch (e) {
                    print(e.toString());
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString()}')),
                    );
                  }
                },
                // fillColor: ThemeColors.inverseBackgroundColor,
                // textColor: ThemeColors.inverseTextColor,
                // textDecoration: TextStyle(
                //   fontSize: 20.0,
                //   color: ThemeColors.inverseTextColor,
                //   fontWeight: FontWeight.bold,
                // ),
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
