import 'dart:convert';
import 'package:flutter/material.dart';

class GameAvatar extends StatelessWidget {
  final String path;
  final double radius;
  final Color? borderColor;

  const GameAvatar({
    Key? key,
    required this.path,
    this.radius = 20,
    this.borderColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (path.startsWith("data:image")) {
      // Handle Uploaded Base64 Image
      try {
        final base64String = path.split(',').last; // Remove "data:image/png;base64," header
        imageProvider = MemoryImage(base64Decode(base64String));
      } catch (e) {
        imageProvider = const AssetImage("assets/avatars/avatar1.webp");
      }
    } else {
      // Handle Asset Path
      imageProvider = AssetImage(path);
    }

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: borderColor != null ? Border.all(color: borderColor!, width: 2) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 5)],
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey[800],
        backgroundImage: imageProvider,
        onBackgroundImageError: (_, __) {}, // Suppress asset loading errors
      ),
    );
  }
}