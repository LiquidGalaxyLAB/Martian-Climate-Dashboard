import 'package:flutter/material.dart';

/// A reusable text input widget with optional trailing icon button.
///
/// InputBar wraps a Material TextField and exposes common customizations:
/// - Placeholder/hint text
/// - Text controller and change callbacks
/// - Password/secret input (obscureText)
/// - Multi-line input (maxLines)
/// - Optional suffix icon with press handler
/// - Custom keyboard type and horizontal padding
///
/// Notes:
/// - When using obscureText = true (password fields), prefer maxLines = 1.
/// - Tapping outside the field dismisses focus (hides keyboard).
///
/// Example (search input with clear button):
/// ```dart
/// final controller = TextEditingController();
/// InputBar(
///   hintText: 'Search locations on Mars',
///   controller: controller,
///   textInputType: TextInputType.text,
///   showIcon: true,
///   icon: Icons.clear,
///   onIconPressed: () {
///     controller.clear();
///   },
///   onChanged: (value) {
///     // trigger filtering
///   },
/// )
/// ```
///
/// Example (password input):
/// ```dart
/// InputBar(
///   hintText: 'Password',
///   obscureText: true,
///   maxLines: 1,
///   textInputType: TextInputType.visiblePassword,
/// )
/// ```
class InputBar extends StatelessWidget {
  /// Whether to show a suffix icon button at the end of the field.
  ///
  /// If true, [icon] must be provided to render the button.
  final bool showIcon;

  /// Text shown when the field is empty.
  final String? hintText;

  /// External controller to read/write the field value.
  ///
  /// Pass a controller to manage text or to clear the field from parent widgets.
  final TextEditingController? controller;

  /// Callback invoked whenever the text changes.
  final ValueChanged<String>? onChanged;

  /// Callback invoked when the suffix icon button is pressed.
  ///
  /// Only used when [showIcon] is true and [icon] is not null.
  final VoidCallback? onIconPressed;

  /// Icon to display as the suffix button when [showIcon] is true.
  final IconData? icon;

  /// Keyboard configuration for the input (e.g., text, number, email).
  final TextInputType? textInputType;

  /// If true, hides the entered text (useful for passwords/secrets).
  ///
  /// Tip: use [maxLines] = 1 when obscuring text.
  final bool obscureText;

  /// Maximum number of lines the field can span.
  ///
  /// Set to > 1 for multi-line input. Defaults to 1 (single-line).
  final int? maxLines;

  /// Horizontal padding applied around the TextField.
  ///
  /// Defaults to symmetric padding of 28.0 on left and right.
  final EdgeInsetsGeometry padding;

  /// Creates an InputBar.
  ///
  /// Parameters:
  /// - [showIcon]: toggles visibility of the suffix icon button.
  /// - [hintText]: placeholder text when the field is empty.
  /// - [controller]: optional TextEditingController for external control.
  /// - [onChanged]: text change callback.
  /// - [onIconPressed]: suffix icon press handler (used if [showIcon] and [icon] are set).
  /// - [icon]: suffix icon to display.
  /// - [textInputType]: keyboard type (e.g., TextInputType.number).
  /// - [obscureText]: hides text for secure inputs.
  /// - [maxLines]: number of visible lines (use 1 for password fields).
  /// - [padding]: outer padding around the field.
  const InputBar({
    super.key,
    this.showIcon = false,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onIconPressed,
    this.icon,
    this.textInputType,
    this.obscureText = false,
    this.maxLines = 1,
    this.padding = const EdgeInsets.symmetric(horizontal: 28.0),
  });

  /// Builds the Material TextField with the configured decoration and behavior.
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        keyboardType: textInputType,
        obscureText: obscureText,
        maxLines: maxLines,
        style: theme.textTheme.bodyLarge?.copyWith(
          // fontSize: 14.0,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          filled: true,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          suffixIcon:
              showIcon && icon != null
                  ? IconButton(
                    icon: Icon(icon, size: 23),
                    onPressed: onIconPressed,
                  )
                  : null,
        ),
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
      ),
    );
  }
}
