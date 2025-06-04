import 'package:flutter/material.dart';

class ParameterPicker extends StatelessWidget {
  final String selectedParameter;
  final String hintText;

  const ParameterPicker({
    super.key,
    required this.selectedParameter,
    required this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          hintText,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        ),
        SizedBox(height: 3),
        DropdownButtonFormField<String>(
          value: selectedParameter,
          isDense: true,
          decoration: const InputDecoration(
            contentPadding: EdgeInsets.symmetric(
              vertical: 0.0,
              horizontal: 12.0,
            ),
          ),
          style: const TextStyle(
            fontSize: 17,
            color: Colors.black,
            fontWeight: FontWeight.w700,
          ),
          items: const [
            DropdownMenuItem(value: 'temperature', child: Text('Temperature')),
            DropdownMenuItem(value: 'pressure', child: Text('Pressure')),
            DropdownMenuItem(value: 'wind_speed', child: Text('Wind Speed')),
            DropdownMenuItem(
              value: 'Martian Year 35',
              child: Text('Martian Year 35'),
            ),
          ],
          onChanged: (value) {
            // Handle parameter selection
          },
        ),
      ],
    );
  }
}
