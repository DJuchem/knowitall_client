import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/services.dart'; // Ensure this is imported

class AvatarSelector extends StatefulWidget {
  final String initialAvatar;
  final ValueChanged<String> onSelect;

  const AvatarSelector({
    super.key,
    required this.initialAvatar,
    required this.onSelect,
  });

  @override
  State<AvatarSelector> createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  List<String> _avatars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvatars();
  }

  String _normalizePath(String path) {
    String p = path;
    while (p.startsWith("assets/") || p.startsWith("/assets/")) {
      p = p.replaceFirst("assets/", "").replaceFirst("/assets/", "");
    }
    return p;
  }

  Future<void> _loadAvatars() async {
  try {
    // ✅ NEW WAY: Use the built-in AssetManifest class
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    
    // Get all asset keys
    final allAssets = manifest.listAssets();

    final paths = allAssets
        .where((String key) {
          final k = key.toLowerCase();
          return k.contains('avatars/') && 
                 (k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.webp'));
        })
        .map((path) => _normalizePath(path)) 
        .toList();
    
    paths.sort(); 

    if (mounted) {
      setState(() {
        _avatars = paths;
        _isLoading = false;
      });
    }
  } catch (e) {
    debugPrint("Error loading avatars: $e");
    if (mounted) {
      setState(() {
        _avatars = []; 
        _isLoading = false;
      });
    }
  }
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
    }

    if (_avatars.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No avatars found. Check AssetManifest.json", style: TextStyle(color: Colors.white70)),
      );
    }

    return SizedBox(
      height: 300, 
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, 
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _avatars.length,
        itemBuilder: (ctx, i) {
          final path = _avatars[i];
          final isSelected = _normalizePath(path) == _normalizePath(widget.initialAvatar);

          return GestureDetector(
            onTap: () => widget.onSelect("assets/$path"),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isSelected ? Colors.amber : Colors.transparent, width: 4),
              ),
              child: ClipOval(
                child: Image.asset(
                  path, // Image.asset prepends 'assets/' on Web automatically
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white30),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}