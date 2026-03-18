import 'package:flutter/material.dart';

class WifiQrForm extends StatefulWidget {
  const WifiQrForm({
    super.key,
    required this.ssidController,
    required this.passwordController,
    required this.securityValue,
    required this.onSecurityChanged,
  });

  final TextEditingController ssidController;
  final TextEditingController passwordController;
  final String securityValue;
  final ValueChanged<String> onSecurityChanged;

  @override
  State<WifiQrForm> createState() => _WifiQrFormState();
}

class _WifiQrFormState extends State<WifiQrForm> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final showPassword = widget.securityValue != 'None';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.ssidController,
          decoration: const InputDecoration(
            labelText: 'Network Name (SSID) *',
          ),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: 12),
        if (showPassword) ...[
          TextFormField(
            controller: widget.passwordController,
            decoration: InputDecoration(
              labelText: 'Password',
              suffixIcon: IconButton(
                icon: Icon(
                  _obscure ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _obscure = !_obscure;
                  });
                },
              ),
            ),
            obscureText: _obscure,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
        ],
        DropdownButtonFormField<String>(
          value: widget.securityValue,
          decoration: const InputDecoration(
            labelText: 'Security Type',
          ),
          items: const [
            DropdownMenuItem(
              value: 'WPA/WPA2',
              child: Text('WPA/WPA2'),
            ),
            DropdownMenuItem(
              value: 'WEP',
              child: Text('WEP'),
            ),
            DropdownMenuItem(
              value: 'None',
              child: Text('None'),
            ),
          ],
          onChanged: (v) {
            if (v == null) return;
            widget.onSecurityChanged(v);
          },
        ),
      ],
    );
  }
}

