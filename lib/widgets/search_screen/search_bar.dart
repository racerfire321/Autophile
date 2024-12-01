import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final VoidCallback onMicPressed;

  const SearchBarWidget({required this.onMicPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(40),
      child: TextField(
        decoration: InputDecoration(
          hintText: "Search Car",
          filled: true,
          fillColor: Colors.white70,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: IconButton(
            icon: Icon(Icons.mic, color: Colors.grey),
            onPressed: onMicPressed,
          ),
          border: InputBorder.none,
        ),
      ),
    );
  }
}