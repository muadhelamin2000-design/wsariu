import 'package:flutter/material.dart';

class CustomSearchField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final Function(String) onChanged;
  final Duration? debounceDuration;
  final VoidCallback? onClear;

  const CustomSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.debounceDuration,
    this.onClear,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: onClear != null ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear) : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
