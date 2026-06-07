import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final TextCapitalization textCapitalization;
  final IconData? prefixIcon;
  final String? Function(String?)? validator;
  final VoidCallback? onTap;
  final bool readOnly;

  const CustomTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.textCapitalization = TextCapitalization.none,
    this.prefixIcon,
    this.validator,
    this.onTap,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          style: const TextStyle(color: AppTheme.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: AppTheme.textSecondary) : null,
          ),
        ),
      ],
    );
  }
}
