import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/avatar_selection_sheet.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _stats;
  List<dynamic> _leaderboard = [];
  bool _loading = true;
  final AuthService _api = AuthService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    final game = Provider.of<GameProvider>(context, listen: false);
    try {
      final results = await Future.wait([
        game.getMyStats(),
        _api.getLeaderboard()
      ]);
      
      if (mounted) setState(() { 
        _stats = results[0] as Map<String, dynamic>; 
        _leaderboard = results[1] as List<dynamic>;
        _loading = false; 
      });
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
          if (game.isLoggedIn) await game.updateAvatarOnServer(finalPath);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);

    return BaseScaffold(
      // 🟢 FIX: No 'extendBodyBehindAppBar' to prevent layout issues
      appBar: AppBar(
        title: const Text("RANKINGS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900),
          tabs: const [Tab(text: "MY PROFILE"), Tab(text: "LEADERBOARD")],
        ),
      ),
      body: _loading 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
        : SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMyProfile(game),
                      _buildLeaderboard(),
                    ],
                  ),
                ),
                
                // 🟢 PINNED FOOTER (Solid)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E1E2C), 
                    border: Border(top: BorderSide(color: Colors.white10)),
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout, color: Colors.white),
                      label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent.shade700,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () { 
                        game.logout(); 
                        Navigator.pop(context); 
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildMyProfile(GameProvider game) {
    final gamesPlayed = _stats?['gamesPlayed']?.toString() ?? "0";
    final wins = _stats?['wins']?.toString() ?? "0";
    final points = _stats?['totalPoints']?.toString() ?? "0";
    
    final int correct = int.tryParse(_stats?['correctCount']?.toString() ?? "0") ?? 0;
    final int total = int.tryParse(_stats?['answerCount']?.toString() ?? "0") ?? 0;
    final double acc = total > 0 ? (correct / total * 100) : 0.0;
    final String accString = "${acc.toStringAsFixed(1)}%";

    final List badges = _stats?['badges'] ?? [];

    ImageProvider avatarImg;
    if (game.myAvatar.startsWith("data:")) {
       avatarImg = MemoryImage(base64Decode(game.myAvatar.split(',')[1]));
    } else {
       String p = game.myAvatar.startsWith("assets/") ? game.myAvatar : "assets/${game.myAvatar}";
       avatarImg = AssetImage(p);
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // 1. HEADER (Solid)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C), 
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10)],
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
                const SizedBox(height: 16),
                Text(game.myName.toUpperCase(), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white)),
                Text("Member since 2026", style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.5))),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 2. STATS
          Row(
            children: [
              _buildStatBox("GAMES", gamesPlayed, Colors.purpleAccent),
              const SizedBox(width: 10),
              _buildStatBox("WINS", wins, Colors.amber),
              const SizedBox(width: 10),
              _buildStatBox("POINTS", points, Colors.cyanAccent),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatBox("CORRECT", "$correct", Colors.green),
              const SizedBox(width: 10),
              _buildStatBox("ACCURACY", accString, acc > 80 ? Colors.greenAccent : Colors.orange),
            ],
          ),

          const SizedBox(height: 24),

          // 3. BADGES
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2C),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("BADGES", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                const Divider(height: 20, color: Colors.white10),
                if (badges.isEmpty)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text("Play more to earn badges!", style: TextStyle(color: Colors.white30)),
                  ))
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4, 
                      crossAxisSpacing: 10, 
                      mainAxisSpacing: 10,
                    ),
                    itemCount: badges.length,
                    itemBuilder: (ctx, i) => _buildBadgeItem(badges[i]),
                  ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(dynamic badge) {
    String? path = badge['imagePath'];
    IconData fallback = Icons.shield;
    if (badge['name'] == 'Sharpshooter') fallback = Icons.my_location;

    return Tooltip(
      message: "${badge['name']}\n${badge['description']}",
      triggerMode: TooltipTriggerMode.tap,
      child: Column(
        children: [
          Expanded(
            child: (path != null && path.isNotEmpty)
              ? Image.asset(path, fit: BoxFit.contain, errorBuilder: (_,__,___) => Icon(fallback, color: Colors.amber))
              : Icon(fallback, color: Colors.amber, size: 30),
          ),
          const SizedBox(height: 4),
          Text(badge['name'], style: const TextStyle(color: Colors.white70, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildLeaderboard() {
    if (_leaderboard.isEmpty) return const Center(child: Text("No data yet.", style: TextStyle(color: Colors.white54)));
    
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _leaderboard.length,
      separatorBuilder: (_,__) => const Divider(color: Colors.white10),
      itemBuilder: (ctx, i) {
        final u = _leaderboard[i];
        final isMe = u['username'] == Provider.of<GameProvider>(context, listen: false).myName;
        
        return Container(
          decoration: BoxDecoration(
            color: isMe ? Colors.white.withOpacity(0.1) : const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white10),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: i < 3 ? Colors.amber : Colors.grey[800],
              child: Text("#${i+1}", style: TextStyle(color: i < 3 ? Colors.black : Colors.white, fontWeight: FontWeight.bold)),
            ),
            title: Text(u['username'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            trailing: Text("${u['points']} PTS", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildStatBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(16), 
          border: Border.all(color: color.withOpacity(0.5))
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}