import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart'; 

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
  final ScrollController _scrollController = ScrollController();

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

      if (mounted) {
        setState(() {
          _avatars = paths;
          _isLoading = false;
        });
        _scrollToSelected();
      }
    } catch (e) {
      if (mounted) setState(() { _avatars = []; _isLoading = false; });
    }
  }

  void _scrollToSelected() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_avatars.isEmpty || !_scrollController.hasClients) return;
      final initialClean = _normalizePath(widget.initialAvatar);
      // Only scroll for standard assets
      if (!initialClean.startsWith("data:")) {
        final index = _avatars.indexOf(initialClean);
        if (index != -1) {
          final row = index ~/ 4;
          final offset = row * 80.0; 
          _scrollController.animateTo(offset, duration: const Duration(milliseconds: 500), curve: Curves.easeOut);
        }
      }
    });
  }

  Future<void> _uploadCustom() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery, 
        maxWidth: 200, 
        maxHeight: 200,
        imageQuality: 70
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64String = "data:image/png;base64,${base64Encode(bytes)}";
        widget.onSelect(base64String); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error picking image."), backgroundColor: Colors.red)
      );
    }
  }

  @override
Widget build(BuildContext context) {
  if (_isLoading) {
    return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
  }

  final theme = Theme.of(context);
  final isCustom = widget.initialAvatar.startsWith("data:");

  const double avatarSize = 56; // ✅ fixed size (no scaling)
  const double tileExtent = 76; // ✅ fixed tile size (includes padding/border)

  return Column(
    children: [
      Expanded(
        child: GridView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: tileExtent, // ✅ prevents giant tiles on large screens
            mainAxisExtent: tileExtent,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _avatars.length,
          itemBuilder: (ctx, i) {
            final path = _avatars[i];
            final isSelected = !isCustom && _normalizePath(path) == _normalizePath(widget.initialAvatar);

            return Center(
              child: GestureDetector(
                onTap: () => widget.onSelect("assets/$path"),
                child: SizedBox(
                  width: avatarSize,
                  height: avatarSize,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.5), blurRadius: 8)]
                          : const [],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        "assets/$path",
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.person, color: Colors.white30),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),

      if (isCustom)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("Custom Avatar Selected", style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(width: 8),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.primary),
                ),
                child: ClipOval(
                  child: Image.memory(
                    base64Decode(widget.initialAvatar.split(',')[1]),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            ],
          ),
        ),

      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.upload_file),
            label: const Text("UPLOAD PHOTO"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondary,
              foregroundColor: Colors.white,
              elevation: 0,
            ),
            onPressed: _uploadCustom,
          ),
        ),
      ),
    ],
  );
}
}