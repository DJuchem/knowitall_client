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

  String _normalizePath(String path) {
    String p = path;
    while (p.startsWith("assets/") || p.startsWith("/assets/")) {
      p = p.replaceFirst("assets/", "").replaceFirst("/assets/", "");
    }
    return p;
  }

  Future<void> _loadAvatars() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
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

      if (mounted) setState(() { _avatars = paths; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _avatars = []; _isLoading = false; });
    }
  }

  void _uploadAvatar() {
    // Placeholder for FilePicker logic
    // In a real app: FilePicker.platform.pickFiles()...
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Upload functionality coming soon!"))
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4, 
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      // Add +1 for the Upload Button
      itemCount: _avatars.length + 1,
      itemBuilder: (ctx, i) {
        // --- UPLOAD BUTTON (Index 0) ---
        if (i == 0) {
          return GestureDetector(
            onTap: _uploadAvatar,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Theme.of(context).colorScheme.primary, width: 2),
              ),
              child: Icon(Icons.camera_alt, color: Theme.of(context).colorScheme.primary),
            ),
          );
        }

        // --- AVATAR LIST (Index 1+) ---
        final path = _avatars[i - 1];
        final cleanPath = _normalizePath(path);
        final cleanInitial = _normalizePath(widget.initialAvatar);
        final isSelected = cleanPath == cleanInitial;

        return GestureDetector(
          onTap: () => widget.onSelect("assets/$path"),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, 
                width: 4
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                "assets/$path",
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.person),
              ),
            ),
          ),
        );
      },
    );
  }
}