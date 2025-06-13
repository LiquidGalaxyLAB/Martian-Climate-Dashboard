import 'package:flutter/material.dart';

class InputBar extends StatelessWidget {
  final bool showIcon;
  final String? hintText;
  final TextEditingController? controller;
  final Function(String)? onChanged;
  final Function()? onIconPressed;
  final IconData? icon;
  final TextInputType? textInputType;
  const InputBar({
    super.key,
    required this.showIcon,
    this.hintText,
    this.controller,
    this.onChanged,
    this.onIconPressed,
    this.icon,
    this.textInputType,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 0),
      child: TextField(
        autofocus: false,
        onTapOutside: (event) {
          if (!FocusScope.of(context).hasPrimaryFocus) {
            FocusScope.of(context).unfocus();
          }
        },
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        keyboardType: textInputType,
        controller: controller,
        style: TextStyle(
          fontSize: 14.0,
          // color: ThemeColors.primaryTextColor,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          // fillColor: ThemeColors.primaryColor,
          // focusColor: ThemeColors.primaryColor,
          filled: true,
          hintText: hintText,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide.none,
          ),
          suffixIcon:
              showIcon
                  ? IconButton(
                    icon: Icon(icon, size: 23),
                    onPressed: onIconPressed,
                  )
                  : null,
        ),
      ),
    );
  }
}
