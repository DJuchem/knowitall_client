import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AvatarSelector extends StatefulWidget {
  final Function(String) onSelect;
  final String initialAvatar;

  const AvatarSelector({
    Key? key,
    required this.onSelect,
    this.initialAvatar = "assets/avatars/avatar1.webp",
  }) : super(key: key);

  @override
  _AvatarSelectorState createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  late String _selected;
  List<String> _avatars = [];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialAvatar;
    _scanAvatars();
  }

  Future<void> _scanAvatars() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      final found = manifest.listAssets().where((k) => k.contains('assets/avatars/')).toList();
      setState(() {
        _avatars = found;
        _isLoading = false;

        if (!_selected.startsWith("data:image") && !_avatars.contains(_selected) && _avatars.isNotEmpty) {
          _selected = _avatars.first;
        }
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 40);
    if (image != null) {
      final bytes = await image.readAsBytes();
      final base64Image = "data:image/png;base64,${base64Encode(bytes)}";
      setState(() => _selected = base64Image);
      widget.onSelect(base64Image);
    }
  }

  ImageProvider _getImage(String path) {
    if (path.startsWith("data:image")) {
      return MemoryImage(base64Decode(path.split(',').last));
    }
    return AssetImage(path);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);

    // Build a “display list” where uploaded image (if any) is first
    final items = <String>[
      if (_selected.startsWith("data:image")) _selected,
      ..._avatars.where((a) => !_selected.startsWith("data:image") || a != _selected),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "SELECT IDENTITY",
              style: theme.textTheme.bodyLarge?.copyWith(fontSize: 14, letterSpacing: 1.5),
            ),
            TextButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text("UPLOAD"),
              onPressed: _pickImage,
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 160, // enough room for 2 rows
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: GridView.builder(
            scrollDirection: Axis.horizontal, // <- horizontal scroll
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // <- TWO ROWS
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (ctx, i) {
              final path = items[i];
              final isSelected = path == _selected;

              return GestureDetector(
                onTap: () {
                  setState(() => _selected = path);
                  widget.onSelect(path);
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(backgroundImage: _getImage(path)),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
