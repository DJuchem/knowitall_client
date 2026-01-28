import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AvatarSelector extends StatefulWidget {
  final Function(String) onSelect;
  const AvatarSelector({Key? key, required this.onSelect}) : super(key: key);

  @override
  _AvatarSelectorState createState() => _AvatarSelectorState();
}

class _AvatarSelectorState extends State<AvatarSelector> {
  final List<String> _avatars = [
    "assets/avatars/avatar1.webp", 
    "assets/avatars/avatar2.webp",
    "assets/avatars/avatar3.webp",
    "assets/avatars/avatar4.webp",
  ];
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.onSelect(_avatars[0]); 
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Choose your Character", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        SizedBox(
          height: 80, // Slightly taller for the glow
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _avatars.length,
            itemBuilder: (ctx, i) {
              final isSelected = i == _selectedIndex;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedIndex = i);
                  widget.onSelect(_avatars[i]);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 16),
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Use AppTheme colors
                    border: isSelected ? Border.all(color: AppTheme.accentPink, width: 3) : null,
                    boxShadow: isSelected ? [BoxShadow(color: AppTheme.accentPink.withOpacity(0.6), blurRadius: 15)] : [],
                  ),
                  child: CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Text("${i+1}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    // backgroundImage: AssetImage(_avatars[i]), // Uncomment when assets exist
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