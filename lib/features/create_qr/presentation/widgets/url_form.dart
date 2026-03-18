import 'package:flutter/material.dart';

class UrlQrForm extends StatelessWidget {
  const UrlQrForm({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: const InputDecoration(
        labelText: 'Website URL *',
        hintText: 'https://example.com',
        suffixIcon: Icon(Icons.link),
      ),
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.done,
      validator: (value) {
        final v = value?.trim() ?? '';
        if (v.isEmpty) return 'Введите URL';
        if (!v.startsWith('http://') && !v.startsWith('https://')) {
          return 'URL должен начинаться с http:// или https://';
        }
        return null;
      },
    );
  }
}

