import 'dart:convert';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/avatar_selection_sheet.dart';
import '../services/auth_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen>
    with SingleTickerProviderStateMixin {
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
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        game.getMyStats(),
        _api.getLeaderboard(),
      ]);

      if (!mounted) return;
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _leaderboard = results[1] as List<dynamic>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
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
          final finalPath = path.startsWith("assets/") ? path : "assets/$path";
          game.setPlayerInfo(game.myName, finalPath);
          if (game.isLoggedIn) await game.updateAvatarOnServer(finalPath);
          if (mounted) _fetchData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return BaseScaffold(
      appBar: AppBar(
        title: const Text(
          "ACCOUNT",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelStyle: const TextStyle(fontWeight: FontWeight.w900),
          tabs: const [
            Tab(text: "PROFILE"),
            Tab(text: "LEADERBOARD"),
          ],
        ),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : SafeArea(
              child: TabBarView(
                controller: _tabController,
                children: [_buildProfile(theme), _buildLeaderboard(theme)],
              ),
            ),
    );
  }

  Widget _buildProfile(ThemeData theme) {
    final game = Provider.of<GameProvider>(context);
    final cs = theme.colorScheme;

    final gamesPlayed =
        int.tryParse(_stats?['gamesPlayed']?.toString() ?? "0") ?? 0;
    final wins = int.tryParse(_stats?['wins']?.toString() ?? "0") ?? 0;
    final points = int.tryParse(_stats?['totalPoints']?.toString() ?? "0") ?? 0;

    final correct =
        int.tryParse(_stats?['correctCount']?.toString() ?? "0") ?? 0;
    final total = int.tryParse(_stats?['answerCount']?.toString() ?? "0") ?? 0;
    final acc = total > 0 ? (correct / max(total, 1)) : 0.0;

    final badges = (_stats?['badges'] ?? []) as List;
    final bestCategories = (_stats?["bestCategories"] ?? []) as List;

    final ImageProvider avatarImg = game.myAvatar.startsWith("data:")
        ? MemoryImage(base64Decode(game.myAvatar.split(',')[1]))
        : AssetImage(
            game.myAvatar.startsWith("assets/")
                ? game.myAvatar
                : "assets/${game.myAvatar}",
          );

    return RefreshIndicator(
      onRefresh: _fetchData,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        children: [
          _HeroHeader(
            name: game.myName,
            subtitle: game.isLoggedIn ? "Signed in" : "Guest",
            avatar: avatarImg,
            onEditAvatar: () => _changeAvatar(game),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: "GAMES",
                  value: "$gamesPlayed",
                  icon: Icons.videogame_asset_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: "WINS",
                  value: "$wins",
                  icon: Icons.emoji_events_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KpiCard(
                  label: "POINTS",
                  value: "$points",
                  icon: Icons.bolt_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _KpiCard(
                  label: "ACCURACY",
                  value: "${(acc * 100).toStringAsFixed(1)}%",
                  icon: Icons.center_focus_strong_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _SectionCard(
            title: "Best Categories",
            child: bestCategories.isEmpty
                ? Text(
                    "Play more games in different categories to build your Trivial-Pursuit style profile.",
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant.withOpacity(0.85),
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...bestCategories.map((c) {
                        final String name = (c["category"] ?? "").toString();
                        final int games =
                            int.tryParse(c["games"]?.toString() ?? "0") ?? 0;
                        final int total =
                            int.tryParse(c["total"]?.toString() ?? "0") ?? 0;
                        final int correct =
                            int.tryParse(c["correct"]?.toString() ?? "0") ?? 0;
                        final int points =
                            int.tryParse(c["points"]?.toString() ?? "0") ?? 0;

                        final double acc = total <= 0
                            ? 0.0
                            : (correct / total * 100.0);

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _CategoryRow({
                            "category": name,
                            "games": games,
                            "total": total,
                            "correct": correct,
                            "points": points,
                          }),
                        );
                      }).toList(),
                    ],
                  ),
          ),

          const SizedBox(height: 14),

          _SectionCard(
            title: "Badges",
            child: badges.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      "No badges yet. Win games and keep streaks to earn them.",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 0.85,
                        ),
                    itemCount: badges.length,
                    itemBuilder: (_, i) => _BadgeTile(badge: badges[i]),
                  ),
          ),

          const SizedBox(height: 14),

          if (!game.isLoggedIn)
            _HintCard(
              title: "Stats won’t persist as Guest",
              subtitle:
                  "Login to permanently track games, wins, accuracy and badges across devices.",
              icon: Icons.lock_outline,
            ),
        ],
      ),
    );
  }

  Widget _buildLeaderboard(ThemeData theme) {
    final game = Provider.of<GameProvider>(context, listen: false);

    if (_leaderboard.isEmpty) {
      return Center(
        child: Text(
          "No leaderboard data yet.",
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.white70),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
      itemCount: _leaderboard.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final u = _leaderboard[i];
        final isMe = (u['username']?.toString() ?? "") == game.myName;

        return _GlassCard(
          isMeAccent: isMe,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            leading: _RankPill(rank: i + 1),
            title: Text(
              u['username']?.toString() ?? "Unknown",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.cyanAccent.withOpacity(0.12),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.30)),
              ),
              child: Text(
                "${u['points'] ?? 0} PTS",
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static int _toInt(dynamic v) => int.tryParse(v?.toString() ?? "0") ?? 0;
  static double _toDouble(dynamic v) =>
      double.tryParse(v?.toString() ?? "0") ?? 0.0;
}

///
/// ONE TRUE CARD MATERIAL (matches HeroHeader)
/// - Stronger base fill (fixes “background art bleeding through”)
/// - Frosted blur (fixes “cheap transparency”)
/// - Same radius/shadow/border everywhere (fixes “margins/edges feel off”)
///
class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool isMeAccent;
  final double radius;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.isMeAccent = false,
    this.radius = 22,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final Color base = const Color(0xFF1E1E2C).withOpacity(0.94);
    final Color a = (isMeAccent ? cs.primary : cs.primary).withOpacity(0.20);
    final Color b = (isMeAccent ? cs.secondary : cs.secondary).withOpacity(
      0.16,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [a, b, base],
            ),
            border: Border.all(color: Colors.white10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.34),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final ImageProvider avatar;
  final VoidCallback onEditAvatar;

  const _HeroHeader({
    required this.name,
    required this.subtitle,
    required this.avatar,
    required this.onEditAvatar,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          GestureDetector(
            onTap: onEditAvatar,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 38,
                    backgroundImage: avatar,
                    backgroundColor: Colors.black26,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.cyanAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit, size: 16, color: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.toUpperCase(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Tap the avatar to change it",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 20,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 78),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white10),
              ),
              child: Icon(icon, color: Colors.cyanAccent.withOpacity(0.95)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                      letterSpacing: 0.6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final List<String> lines;
  final IconData icon;

  const _MiniStatCard({
    required this.title,
    required this.lines,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.cyanAccent.withOpacity(0.95)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lines.map(
            (t) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                t,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant.withOpacity(0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RankPill extends StatelessWidget {
  final int rank;
  const _RankPill({required this.rank});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bool top3 = rank <= 3;

    return Container(
      width: 54,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: top3
              ? [
                  Colors.amber.withOpacity(0.95),
                  Colors.orange.withOpacity(0.85),
                  Colors.black.withOpacity(0.15),
                ]
              : [
                  cs.primary.withOpacity(0.18),
                  cs.secondary.withOpacity(0.14),
                  Colors.white.withOpacity(0.04),
                ],
        ),
        border: Border.all(color: Colors.white10),
      ),
      alignment: Alignment.center,
      child: Text(
        "#$rank",
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: top3 ? Colors.black : Colors.white,
        ),
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final dynamic badge;
  const _BadgeTile({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final name = badge['name']?.toString() ?? "Badge";
    final desc = badge['description']?.toString() ?? "";
    final path = badge['imagePath']?.toString();

    IconData fallback = Icons.shield;
    if (name == 'Sharpshooter') fallback = Icons.my_location;

    return Tooltip(
      message: "$name\n$desc",
      triggerMode: TooltipTriggerMode.tap,
      child: Column(
        children: [
          Expanded(
            child: _GlassCard(
              padding: const EdgeInsets.all(10),
              radius: 18,
              child: Center(
                child: (path != null && path.isNotEmpty)
                    ? Image.asset(
                        path,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            Icon(fallback, color: Colors.amber),
                      )
                    : Icon(fallback, color: Colors.amber, size: 30),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            name,
            style: theme.textTheme.labelSmall?.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _HintCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _HintCard({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return _GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: Colors.cyanAccent.withOpacity(0.95)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final dynamic data;
  const _CategoryRow(this.data);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final String name = (data["category"] ?? "").toString();
    final int games = int.tryParse(data["games"]?.toString() ?? "0") ?? 0;
    final int total = int.tryParse(data["total"]?.toString() ?? "0") ?? 0;
    final int correct = int.tryParse(data["correct"]?.toString() ?? "0") ?? 0;
    final int points = int.tryParse(data["points"]?.toString() ?? "0") ?? 0;

    final double acc = total <= 0 ? 0.0 : (correct / total * 100.0);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: _GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        radius: 18,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? "(Unspecified)" : name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "$games games • $correct/$total correct • ${acc.toStringAsFixed(1)}%",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.cyanAccent.withOpacity(0.30)),
              ),
              child: Text(
                "+$points",
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.cyanAccent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
