import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Helper to ensure we don't have redundant "assets/" prefixes
  String _normalizePath(String path) {
    String p = path;
    while (p.startsWith("assets/")) {
      p = p.replaceFirst("assets/", "");
    }
    // We return it WITHOUT "assets/" because Image.asset 
    // adds it automatically in many contexts, or we add it once 
    // consistently across the app.
    return p;
  }

  Future<void> _loadAvatars() async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      // Clean the paths immediately upon loading
      final paths = manifestMap.keys
          .where((String key) => key.contains('avatars/') && key.toLowerCase().endsWith('.png'))
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
          // Fallback: Store clean paths
          _avatars = List.generate(10, (i) => "avatars/avatar_$i.png");
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_avatars.isEmpty) {
      return const Text("No avatars found", style: TextStyle(color: Colors.white54));
    }

    return SizedBox(
      height: 300, 
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4, 
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1,
        ),
        itemCount: _avatars.length,
        itemBuilder: (ctx, i) {
          // Both 'path' and 'widget.initialAvatar' should now be clean (e.g. "avatars/avatar_0.png")
          final path = _avatars[i];
          
          // We normalize the initialAvatar just in case SharedPreferences has a dirty "assets/assets" string
          final isSelected = _normalizePath(path) == _normalizePath(widget.initialAvatar);

          return GestureDetector(
            onTap: () => widget.onSelect("assets/$path"), // Pass with assets/ for the parent to save
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.amber : Colors.transparent,
                  width: isSelected ? 4 : 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: ClipOval(
                child: Image.asset(
                  "assets/$path", // Explicitly add exactly one "assets/"
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}