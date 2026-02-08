import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

// ✅ The Slide-In Sheet Wrapper
class AvatarSelectionSheet extends StatelessWidget {
  final String currentAvatar;
  final ValueChanged<String> onAvatarSelected;

  const AvatarSelectionSheet({
    super.key,
    required this.currentAvatar,
    required this.onAvatarSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75, // 75% Height
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 50)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag Handle
          Center(
            child: Container(
              width: 40, height: 4, 
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("SELECT AVATAR", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),

          // Grid Content
          Expanded(
            child: _AvatarGrid(
              initialAvatar: currentAvatar,
              onSelect: (path) {
                onAvatarSelected(path);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ The Internal Grid Widget with Local State
class _AvatarGrid extends StatefulWidget {
  final String initialAvatar;
  final ValueChanged<String> onSelect;

  const _AvatarGrid({required this.initialAvatar, required this.onSelect});

  @override
  State<_AvatarGrid> createState() => _AvatarGridState();
}

class _AvatarGridState extends State<_AvatarGrid> {
  List<String> _avatars = [];
  bool _isLoading = true;
  String? _selectedPath; 
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _selectedPath = widget.initialAvatar; 
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
      final paths = allAssets.where((String key) {
        final k = key.toLowerCase();
        return k.contains('avatars/') && (k.endsWith('.png') || k.endsWith('.jpg') || k.endsWith('.webp'));
      }).map((path) => _normalizePath(path)).toList();
      
      paths.sort(); 

      if (mounted) {
        setState(() { _avatars = paths; _isLoading = false; });
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
      if (!initialClean.startsWith("data:")) {
        final index = _avatars.indexOf(initialClean);
        if (index != -1) {
          // +1 because index 0 is now the Upload button
          final row = (index + 1) ~/ 4; 
          _scrollController.jumpTo(row * 80.0);
        }
      }
    });
  }

  Future<void> _uploadCustom() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery, maxWidth: 200, maxHeight: 200, imageQuality: 70);
      if (image != null) {
        final bytes = await image.readAsBytes();
        final b64 = "data:image/png;base64,${base64Encode(bytes)}";
        setState(() => _selectedPath = b64); 
        widget.onSelect(b64); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error picking image"), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final theme = Theme.of(context);
    final currentClean = _normalizePath(_selectedPath ?? "");
    final isCustom = currentClean.startsWith("data:");

    return Column(
      children: [
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, 
              crossAxisSpacing: 16, 
              mainAxisSpacing: 16,
              childAspectRatio: 1.0, 
            ),
            // ✅ +1 for the Upload Button
            itemCount: _avatars.length + 1,
            itemBuilder: (ctx, i) {
              // --- TILE 1: UPLOAD BUTTON / SELECTED CUSTOM AVATAR ---
              if (i == 0) {
                return GestureDetector(
                  onTap: _uploadCustom,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      // If custom is selected, make border THICK and PRIMARY color
                      border: Border.all(
                        color: isCustom ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.2),
                        width: isCustom ? 4 : 2,
                      ),
                    ),
                    child: ClipOval(
                      child: isCustom
                          ? Image.memory(
                              base64Decode(currentClean.split(',')[1]),
                              fit: BoxFit.cover,
                            )
                          : Icon(Icons.add_a_photo, color: theme.colorScheme.primary),
                    ),
                  ),
                );
              }

              // --- TILE 2+: STANDARD AVATARS ---
              final path = _avatars[i - 1];
              final isSelected = !isCustom && path == currentClean;

              return GestureDetector(
                onTap: () {
                  setState(() => _selectedPath = "assets/$path"); 
                  widget.onSelect("assets/$path");
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      width: 4,
                    ),
                    boxShadow: isSelected ? [BoxShadow(color: theme.colorScheme.primary.withOpacity(0.5), blurRadius: 10)] : [],
                  ),
                  child: ClipOval(
                    child: Image.asset("assets/$path", fit: BoxFit.cover),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}