import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/avatar_selection_sheet.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    final game = Provider.of<GameProvider>(context, listen: false);
    try {
      final data = await game.getMyStats(); 
      if (mounted) setState(() { _stats = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeAvatar(GameProvider game) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AvatarSelectionSheet(
        currentAvatar: game.myAvatar,
        onAvatarSelected: (path) async {
          String finalPath = path.startsWith("assets/") ? path : "assets/$path";
          game.setPlayerInfo(game.myName, finalPath);
          if (game.isLoggedIn) {
             await game.updateAvatarOnServer(finalPath);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    
    final gamesPlayed = _stats?['gamesPlayed'] ?? 0;
    final wins = _stats?['wins'] ?? 0;
    final points = _stats?['totalPoints'] ?? 0;
    final List topics = _stats?['bestTopics'] ?? [];

    ImageProvider avatarImg;
    if (game.myAvatar.startsWith("data:")) {
       avatarImg = MemoryImage(base64Decode(game.myAvatar.split(',')[1]));
    } else {
       // Ensure path is clean for asset loading
       String assetPath = game.myAvatar.startsWith("assets/") ? game.myAvatar : "assets/${game.myAvatar}";
       avatarImg = AssetImage(assetPath);
    }

    return BaseScaffold(
      // 🟢 Fix: Ensure Safe Area for notches
      body: SafeArea(
        child: Column(
          children: [
            // Custom AppBar inside Body to allow seamless scrolling or separate
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      "MY PROFILE", 
                      textAlign: TextAlign.center,
                      style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 18, color: Colors.white)
                    ),
                  ),
                  const SizedBox(width: 48), // Balance spacing
                ],
              ),
            ),
            
            Expanded(
              child: _loading 
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // 1. HEADER
                      FadeInDown(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2C),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white12),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.6), blurRadius: 20, offset: const Offset(0, 10))
                            ],
                          ),
                          child: Column(
                            children: [
                              GestureDetector(
                                onTap: () => _changeAvatar(game),
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.cyanAccent, width: 3),
                                        boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 25)],
                                      ),
                                      child: CircleAvatar(radius: 60, backgroundImage: avatarImg, backgroundColor: Colors.black26),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                                      child: const Icon(Icons.edit, size: 20, color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(game.myName.toUpperCase(), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
                              Text("Joined 2026", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5), fontStyle: FontStyle.italic)),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 2. STATS ROW
                      FadeInUp(
                        delay: const Duration(milliseconds: 200),
                        child: Row(
                          children: [
                            _buildStatCard("GAMES", "$gamesPlayed", Icons.videogame_asset, Colors.purpleAccent),
                            const SizedBox(width: 12),
                            _buildStatCard("WINS", "$wins", Icons.emoji_events, Colors.amber),
                            const SizedBox(width: 12),
                            _buildStatCard("POINTS", _formatPoints(points), Icons.bolt, Colors.cyanAccent),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // 3. TOPIC MASTERY
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: const Color(0xFF252535),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 15)],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: const [
                                    Icon(Icons.bar_chart, color: Colors.white70),
                                    SizedBox(width: 10),
                                    Text("TOPIC MASTERY", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Colors.white10),
                              
                              if (topics.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(child: Text("Play games to unlock stats!", style: TextStyle(color: Colors.white30))),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  itemCount: topics.length,
                                  separatorBuilder: (_,__) => const Divider(color: Colors.white10, height: 1),
                                  itemBuilder: (ctx, i) => _buildTopicRow(topics[i], i + 1),
                                ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // 4. LOGOUT BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          label: const Text("LOGOUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 5,
                          ),
                          onPressed: () {
                            game.logout();
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      
                      // 🟢 Fix: Extra padding at bottom to prevent cutoff
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: const Color(0xFF252535),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicRow(dynamic topic, int rank) {
    String mode = (topic['mode'] ?? "Unknown").toString().toUpperCase().replaceAll("-", " ");
    int pts = topic['points'] ?? 0;
    
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: rank == 1 ? Colors.amber : (rank == 2 ? Colors.grey : Colors.brown),
          shape: BoxShape.circle,
        ),
        child: Text("#$rank", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      title: Text(mode, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      trailing: Text("$pts pts", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 15)),
    );
  }

  String _formatPoints(int points) {
    if (points > 1000) return "${(points / 1000).toStringAsFixed(1)}k";
    return "$points";
  }
}