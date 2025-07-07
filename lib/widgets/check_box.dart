/// A custom checkbox widget that displays a [Checkbox] alongside a [Text] label.
///
/// The [CheckBox] widget is a stateless widget that takes a [ValueChanged<bool?>] callback,
/// a boolean value to indicate whether the checkbox is checked, and a string label to display
/// next to the checkbox.
///
/// - [onChange]: Called when the user toggles the checkbox.
/// - [isChecked]: Whether the checkbox is checked.
/// - [text]: The label displayed next to the checkbox.
library;

import 'package:flutter/material.dart';

class CheckBox extends StatelessWidget {
  final ValueChanged<bool?> onChange;
  final bool isChecked;
  final String text;
  final bool isEnabled;
  const CheckBox({
    super.key,
    required this.onChange,
    required this.text,
    required this.isChecked,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Checkbox(value: isEnabled ? isChecked : false, onChanged: onChange),
        Text(text),
      ],
    );
  }
}
