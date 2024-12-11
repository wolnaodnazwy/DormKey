import 'package:flutter/material.dart';

class AutoUnfocus extends StatelessWidget {
  final Widget child;

  const AutoUnfocus({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: child,
    );
  }
}