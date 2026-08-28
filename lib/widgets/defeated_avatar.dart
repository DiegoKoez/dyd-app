import 'dart:convert';
import 'package:flutter/material.dart';

class DefeatedAvatar extends StatelessWidget {
  final String? photoBase64;
  final bool isDefeated;
  final IconData defaultIcon;
  final double radius;
  final String? assetPath;

  const DefeatedAvatar({
    super.key,
    this.photoBase64,
    required this.isDefeated,
    this.defaultIcon = Icons.person,
    this.radius = 24,
    this.assetPath,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatar;
    if (photoBase64 != null && photoBase64!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: MemoryImage(base64Decode(photoBase64!)),
      );
    } else if (assetPath != null) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: AssetImage(assetPath!),
      );
    } else {
      avatar = CircleAvatar(radius: radius, child: Icon(defaultIcon));
    }

    if (!isDefeated) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -4,
          bottom: -4,
          child: Icon(Icons.warning, color: Colors.red, size: radius * 0.75),
        ),
      ],
    );
  }
}
