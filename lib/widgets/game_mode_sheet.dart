import 'package:flutter/material.dart';

class GameModeSheet extends StatelessWidget {
  final String currentMode;
  final Function(String) onModeSelected;

  const GameModeSheet({
    Key? key, 
    required this.currentMode, 
    required this.onModeSelected
  }) : super(key: key);

  // ✅ CONFIG: Map your mode keys to Display Names, Asset Images, and Fallback Icons
  static final List<Map<String, dynamic>> modes = [
    {
      "id": "general-knowledge",
      "label": "General Knowledge",
      "asset": "assets/modes/general.png",
      "icon": Icons.school_rounded,
      "color": Colors.blueAccent
    },
    {
      "id": "music",
      "label": "Music Quiz",
      "asset": "assets/modes/music.png",
      "icon": Icons.music_note_rounded,
      "color": Colors.pinkAccent
    },
    {
      "id": "calculations",
      "label": "Math Chaos",
      "asset": "assets/modes/math.png",
      "icon": Icons.calculate_rounded,
      "color": Colors.orangeAccent
    },
    {
      "id": "flags",
      "label": "Guess the Flag",
      "asset": "assets/modes/flags.png",
      "icon": Icons.flag_rounded,
      "color": Colors.redAccent
    },
    {
      "id": "capitals",
      "label": "Capitals",
      "asset": "assets/modes/capitals.png",
      "icon": Icons.location_city_rounded,
      "color": Colors.purpleAccent
    },
    {
      "id": "odd_one_out",
      "label": "Odd One Out",
      "asset": "assets/modes/odd.png",
      "icon": Icons.rule_rounded,
      "color": Colors.greenAccent
    },
    {
      "id": "fill_in_the_blank",
      "label": "Fill The Blank",
      "asset": "assets/modes/fill.png",
      "icon": Icons.text_fields_rounded,
      "color": Colors.tealAccent
    },
    {
      "id": "true_false",
      "label": "True / False",
      "asset": "assets/modes/tf.png",
      "icon": Icons.check_circle_outline,
      "color": Colors.cyanAccent
    },
    {
      "id": "population",
      "label": "Population",
      "asset": "assets/modes/pop.png",
      "icon": Icons.groups_rounded,
      "color": Colors.indigoAccent
    },
  ];

  static Map<String, dynamic> getModeDetails(String id) {
    return modes.firstWhere((m) => m["id"] == id, orElse: () => modes.first);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C), // Dark modal bg
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(color: Colors.grey[700], borderRadius: BorderRadius.circular(2)),
          ),
          
          const Text("SELECT GAME MODE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              itemCount: modes.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3, // Rectangular cards
              ),
              itemBuilder: (ctx, i) {
                final mode = modes[i];
                final isSelected = mode["id"] == currentMode;
                
                return GestureDetector(
                  onTap: () {
                    onModeSelected(mode["id"]);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? (mode["color"] as Color).withOpacity(0.2) 
                          : Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(16),
                      border: isSelected 
                          ? Border.all(color: mode["color"], width: 2) 
                          : Border.all(color: Colors.white12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Image or Fallback Icon
                        _buildModeIcon(mode["asset"], mode["icon"], mode["color"]),
                        const SizedBox(height: 12),
                        Text(
                          mode["label"].toUpperCase(),
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeIcon(String assetPath, IconData icon, Color color) {
    return Image.asset(
      assetPath,
      width: 48,
      height: 48,
      errorBuilder: (context, error, stackTrace) {
        // Fallback if image doesn't exist
        return Icon(icon, size: 48, color: color);
      },
    );
  }
}