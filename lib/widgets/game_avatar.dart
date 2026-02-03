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

  /// Standardizes the path to prevent "assets/assets/" 404 errors on Web
  String _getCleanPath(String rawPath) {
    if (rawPath.isEmpty) return "assets/avatars/avatar_0.png";
    
    String p = rawPath;
    // Remove all redundant "assets/" or "/assets/" prefixes
    while (p.startsWith("assets/") || p.startsWith("/assets/")) {
      p = p.replaceFirst("assets/", "").replaceFirst("/assets/", "");
    }
    
    // Always return with exactly one "assets/" for the AssetImage/Image.asset constructor
    return "assets/$p";
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;

    if (path.startsWith("data:image")) {
      // Handle Uploaded Base64 Image
      try {
        final base64String = path.split(',').last; 
        imageProvider = MemoryImage(base64Decode(base64String));
      } catch (e) {
        // Fallback to a safe default if decoding fails
        imageProvider = const AssetImage("assets/avatars/avatar_0.png");
      }
    } else {
      // Handle Asset Path with the new cleaning logic
      imageProvider = AssetImage(_getCleanPath(path));
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
        // Suppress errors visually, the fallback or cleanPath handles the logic
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint("Avatar Load Error: $exception");
        }, 
      ),
    );
  }
}