import 'package:flutter/material.dart';

class ProfileCover extends StatelessWidget {
  final Widget child;
  const ProfileCover({super.key, required this.child});
  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: child);
}
