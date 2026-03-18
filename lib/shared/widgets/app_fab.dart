import 'package:flutter/material.dart';

class AppFab extends StatelessWidget {
  const AppFab({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Color(0x884CAF50),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: onPressed,
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        child: const Icon(
          Icons.add,
          size: 28,
          color: Colors.white,
        ),
      ),
    );
  }
}