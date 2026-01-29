import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for AssetManifest

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
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialAvatar;
    _scanAvatars();
  }

  // --- DYNAMICALLY SCAN ASSETS ---
  Future<void> _scanAvatars() async {
    try {
      // Use the built-in AssetManifest to find files
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      
      // Filter for files in the avatar directory with image extensions
      final found = manifest.listAssets()
          .where((String key) => key.contains('assets/avatars/'))
          .where((String key) => 
              key.toLowerCase().endsWith('.png') || 
              key.toLowerCase().endsWith('.jpg') || 
              key.toLowerCase().endsWith('.jpeg') || 
              key.toLowerCase().endsWith('.webp'))
          .toList();

      setState(() {
        _avatars = found;
        _isLoading = false;
        if (!_avatars.contains(_selected) && _avatars.isNotEmpty) {
          _selected = _avatars.first;
          widget.onSelect(_selected);
        }
      });
    } catch (e) {
      debugPrint("Error scanning avatars: $e");
      // Fallback to a safe default if scanning fails
      setState(() {
        _avatars = ["assets/avatars/avatar1.webp"]; 
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 80, child: Center(child: CircularProgressIndicator()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Choose Identity", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 10),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _avatars.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (ctx, i) {
              final path = _avatars[i];
              final isSelected = path == _selected;
              return GestureDetector(
                onTap: () {
                  setState(() => _selected = path);
                  widget.onSelect(path);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(isSelected ? 3 : 0),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.cyanAccent : Colors.transparent, 
                      width: 3
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[900],
                    backgroundImage: AssetImage(path),
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