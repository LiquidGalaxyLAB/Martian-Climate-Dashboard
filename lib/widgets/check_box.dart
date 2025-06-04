import 'package:flutter/material.dart';

class CheckBox extends StatelessWidget {
  final ValueChanged<bool?> onChange;
  final bool isChecked;
  final String text;
  const CheckBox({
    super.key,
    required this.onChange,
    required this.text,
    required this.isChecked,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [Checkbox(value: isChecked, onChanged: onChange), Text(text)],
    );
  }
}
