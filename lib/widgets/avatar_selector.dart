import 'package:flutter/material.dart';

class AvatarSelector extends StatefulWidget {
  final Function(String) onSelect;
  final String initialAvatar;

  const AvatarSelector({Key? key, required this.onSelect, this.initialAvatar = "assets/avatars/avatar1.webp"}) : super(key: key);

  @override
  _AvatarSelectorState createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  late String _selected;

  // Define your available avatars here
  final List<String> _avatars = [
    "assets/avatars/avatar1.webp",
    "assets/avatars/avatar2.webp",
    "assets/avatars/avatar3.webp",
    "assets/avatars/avatar4.webp",
    "assets/avatars/avatar5.webp",
    "assets/avatars/avatar6.webp",
  ];

  @override
  void initState() {
    super.initState();
    _selected = widget.initialAvatar;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Choose Avatar", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 70,
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
                child: Container(
                  padding: const EdgeInsets.all(2), // border width
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.blueAccent : Colors.transparent, 
                      width: 3
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: AssetImage(path),
                    onBackgroundImageError: (_, __) {}, // Handle missing assets gracefully
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