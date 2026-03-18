import 'package:flutter/material.dart';

class SuccessBadge extends StatelessWidget {
  const SuccessBadge();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 4),
        _GlowCircle(),
        SizedBox(height: 12),
        Text(
          'Scan Successful',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
        ),
        SizedBox(height: 4),
        Text(
          'QR code decoded successfully',
          style: TextStyle(fontSize: 13, color: Color(0xFF757575)),
        ),
      ],
    );
  }
}

class _GlowCircle extends StatelessWidget {
  const _GlowCircle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
        color: Color(0xFF4CAF50),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x664CAF50),
            blurRadius: 16,
            spreadRadius: 4,
          ),
          BoxShadow(
            color: Color(0x334CAF50),
            blurRadius: 32,
            spreadRadius: 8,
          ),
        ],
      ),
      child: const Center(
        child: Icon(Icons.check, color: Colors.white, size: 36),
      ),
    );
  }
}