import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class CustomTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool obscureText;
  final TextInputType keyboardType;
  final IconData? prefixIcon;
  final String? hintText;
  final int maxLines;

  const CustomTextField({
    super.key,
    required this.controller,
    required this.label,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.prefixIcon,
    this.hintText,
    this.maxLines = 1,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _isObscured;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (focused) {
        setState(() => _isFocused = focused);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: _isFocused
              ? [
                  BoxShadow(
                    color: AppColors.accentOrange.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: TextField(
          controller: widget.controller,
          obscureText: _isObscured,
          keyboardType: widget.keyboardType,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(
                    widget.prefixIcon,
                    color: _isFocused ? AppColors.accentOrange : AppColors.textSecondary,
                    size: 20,
                  )
                : null,
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _isObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _isObscured = !_isObscured;
                      });
                    },
                  )
                : null,
          ),
        ),
      ),
    );
  }
}
