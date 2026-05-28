import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AuthField  extends StatelessWidget {
  final TextEditingController    controller;
  final FocusNode                focusNode;
  final String                   label;
  final String                   hint;
  final IconData                 icon;
  final TextInputType            inputType;
  final bool                     obscureText;
  final Widget?                  suffixIcon;
  final TextInputAction          textInputAction;
  final ValueChanged<String>?    onSubmitted;

  const AuthField ({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.icon,
    this.inputType       = TextInputType.text,
    this.obscureText     = false,
    this.suffixIcon,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller:      controller,
      focusNode:       focusNode,
      keyboardType:    inputType,
      obscureText:     obscureText,
      textInputAction: textInputAction,
      onSubmitted:     onSubmitted,
      style: const TextStyle(
        fontSize: 15,
        color: AppColors.text,
        fontWeight: FontWeight.w400,
      ),
      decoration: InputDecoration(
        labelText:      label,
        hintText:       hint,
        prefixIcon:     Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon:     suffixIcon,
        labelStyle: const TextStyle(
            color: AppColors.textMuted, fontSize: 14),
        hintStyle: const TextStyle(
            color: AppColors.textLight, fontSize: 15),
        filled:      true,
        fillColor:   AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.cardBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }
}