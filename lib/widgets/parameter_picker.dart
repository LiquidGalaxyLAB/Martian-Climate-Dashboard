/// A stateless widget that displays a labeled dropdown for selecting a parameter.
///
/// The [ParameterPicker] widget shows a label (provided by [hintText]) and a
///
/// Parameters:
/// - [selectedParameter]: The value of the currently selected parameter.
/// - [hintText]: The label displayed above the dropdown.
///
library;

import 'package:flutter/material.dart';

class ParameterPicker extends StatelessWidget {
  final String selectedParameter;
  final String hintText;
  final ValueChanged<String?>? onChanged;

  const ParameterPicker({
    super.key,
    required this.selectedParameter,
    required this.hintText,
    this.onChanged,
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
          icon: const Icon(Icons.keyboard_arrow_down_sharp),
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
            DropdownMenuItem(value: 'density', child: Text('Density')),
            DropdownMenuItem(
              value: 'Martian Year 35',
              child: Text('Martian Year 35'),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}
