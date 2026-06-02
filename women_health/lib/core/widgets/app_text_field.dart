import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final bool obscureText;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final TextInputType? keyboardType;
  final String? errorText;
  final int maxLines;
  final int? maxLength;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.validator,
    this.onChanged,
    this.keyboardType,
    this.errorText,
    this.maxLines = 1,
    this.maxLength,
    this.suffixIcon,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscured,
      validator: widget.validator,
      onChanged: widget.onChanged,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      maxLength: widget.maxLength,
      decoration: InputDecoration(
        labelText: widget.label,
        hintText: widget.hint,
        errorText: widget.errorText,
        suffixIcon: widget.suffixIcon ?? (widget.obscureText
            ? IconButton(
                icon: Icon(_obscured ? Icons.visibility : Icons.visibility_off),
                onPressed: () {
                  setState(() {
                    _obscured = !_obscured;
                  });
                },
              )
            : null),
      ),
    );
  }
}
