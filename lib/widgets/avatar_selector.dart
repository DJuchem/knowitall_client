import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class AvatarSelector extends StatefulWidget {
  final Function(String) onSelect;
  final String initialAvatar;

  const AvatarSelector({Key? key, required this.onSelect, this.initialAvatar = "assets/avatars/avatar1.webp"}) : super(key: key);

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
    } catch (_) { setState(() => _isLoading = false); }
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
    if (_isLoading) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("SELECT IDENTITY", style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: 14, letterSpacing: 1.5)),
            TextButton.icon(
              icon: const Icon(Icons.cloud_upload),
              label: const Text("UPLOAD"),
              onPressed: _pickImage,
            )
          ],
        ),
        const SizedBox(height: 10),
        Container(
          height: 110,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(16)
          ),
          child: GridView.builder(
            scrollDirection: Axis.vertical,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 5, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: _avatars.length + (_selected.startsWith("data:image") ? 1 : 0),
            itemBuilder: (ctx, i) {
              // Show uploaded image first if it exists
              String path;
              if (_selected.startsWith("data:image")) {
                if (i == 0) path = _selected;
                else path = _avatars[i - 1];
              } else {
                path = _avatars[i];
              }

              final isSelected = path == _selected;
              return GestureDetector(
                onTap: () { setState(() => _selected = path); widget.onSelect(path); },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent, 
                      width: 3
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