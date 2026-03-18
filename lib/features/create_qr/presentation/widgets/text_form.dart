import 'package:flutter/material.dart';

class TextQrForm extends StatefulWidget {
  const TextQrForm({super.key, required this.controller});

  final TextEditingController controller;

  @override
  State<TextQrForm> createState() => _TextQrFormState();
}

class _TextQrFormState extends State<TextQrForm> {
  int _length = 0;

  @override
  void initState() {
    super.initState();
    _length = widget.controller.text.length;
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    setState(() {
      _length = widget.controller.text.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          decoration: const InputDecoration(
            labelText: 'Text Content *',
            hintText: 'Enter your text here...',
            counterText: '',
          ),
          keyboardType: TextInputType.multiline,
          textInputAction: TextInputAction.newline,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return 'Введите текст';
            }
            return null;
          },
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            '$_length/500',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ),
      ],
    );
  }
}

