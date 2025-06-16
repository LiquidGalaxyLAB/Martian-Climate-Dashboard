import 'package:flutter/material.dart';

class InputBar extends StatelessWidget {
  final bool showIcon;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onIconPressed;
  final IconData? icon;
  final TextInputType? textInputType;
  final bool obscureText;
  final int? maxLines;
  final EdgeInsetsGeometry padding;

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
