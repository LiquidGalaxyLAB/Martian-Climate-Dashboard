/// Button widget for the Martian Climate Dashboard.
///
/// [MCDButton] displays a Material Design elevated button with configurable
/// text and an optional callback for when the button is pressed. The button
/// stretches to fill the available width and includes padding for visual
/// separation.
///
/// Parameters:
/// - [onPressed]: The callback that is called when the button is tapped or pressed.
///   If null, the button will be disabled.
/// - [text]: The text label displayed on the button. This parameter is required.
library;

import 'package:flutter/material.dart';

class MCDButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final Color? color;
  const MCDButton({super.key, this.onPressed, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 14),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              horizontal: 30.0,
              vertical: 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            backgroundColor:
                color ?? Theme.of(context).buttonTheme.colorScheme?.primary,
          ),
          child: Text(text),
        ),
      ),
    );
  }
}
