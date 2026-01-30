import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../models/lobby_data.dart';
import '../widgets/game_avatar.dart';
import '../widgets/base_scaffold.dart';

class GameOverScreen extends StatefulWidget {
  const GameOverScreen({super.key});

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen> {
  bool _in = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _in = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final lobby = game.lobby;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (lobby == null) {
      return const BaseScaffold(body: Center(child: CircularProgressIndicator()));
    }

    final players = List<Player>.from(lobby.players);
    players.sort((a, b) => b.score.compareTo(a.score));

    final winner = players.isNotEmpty ? players[0] : null;
    final second = players.length > 1 ? players[1] : null;
    final third = players.length > 2 ? players[2] : null;

    final rest = players.length > 3 ? players.sublist(3) : const <Player>[];

    return BaseScaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Title
                AnimatedSlide(
                  offset: _in ? Offset.zero : const Offset(0, -0.05),
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: _in ? 1 : 0,
                    duration: const Duration(milliseconds: 160),
                    child: Text(
                      "GAME OVER",
                      style: theme.textTheme.titleLarge?.copyWith(
                        letterSpacing: 3,
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Podium (Top 3)
                _PodiumTop3(
                  inAnim: _in,
                  winner: winner,
                  second: second,
                  third: third,
                ),

                const SizedBox(height: 14),

                // Rest list (only if >3 players)
                if (rest.isNotEmpty)
                  Expanded(
                    child: _GlassCard(
                      borderRadius: 22,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        itemCount: rest.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Colors.white10),
                        itemBuilder: (ctx, i) {
                          final p = rest[i];
                          final rank = i + 4;

                          return TweenAnimationBuilder<double>(
                            tween: Tween(begin: _in ? 1 : 0, end: 1),
                            duration: Duration(milliseconds: 140 + (i * 28)),
                            curve: Curves.easeOut,
                            builder: (_, t, child) {
                              return Transform.translate(
                                offset: Offset(0, (1 - t) * 10),
                                child: child,
                              );
                            },
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.white.withOpacity(0.10),
                                child: Text(
                                  "#$rank",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              title: Text(
                                p.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                "${p.score} pts",
                                style: const TextStyle(color: Colors.white54),
                              ),
                              trailing: GameAvatar(
                                path: p.avatar ?? "",
                                radius: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  )
                else
                  const Spacer(),

                const SizedBox(height: 12),

                // Actions
                if (game.amIHost) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.refresh, color: Colors.white),
                      label: const Text(
                        "PLAY AGAIN",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      onPressed: () => game.playAgain(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    icon: Icon(Icons.settings, color: cs.onSurface.withOpacity(0.7)),
                    label: Text(
                      "Back to Lobby (Settings)",
                      style: TextStyle(color: cs.onSurface.withOpacity(0.7)),
                    ),
                    onPressed: () => game.resetToLobby(),
                  ),
                ] else ...[
                  TextButton(
                    onPressed: () => game.leaveLobby(),
                    child: const Text(
                      "Leave Lobby",
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PodiumTop3 extends StatelessWidget {
  final bool inAnim;
  final Player? winner;
  final Player? second;
  final Player? third;

  const _PodiumTop3({
    required this.inAnim,
    required this.winner,
    required this.second,
    required this.third,
  });

  @override
  Widget build(BuildContext context) {
    final maxH = MediaQuery.of(context).size.height;
    final podiumHeight = (maxH * 0.40).clamp(260.0, 360.0);

    // layout: second - winner - third
    return SizedBox(
      height: podiumHeight,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // ✅ REPLACED the big glass slab:
          // tight neon stage under the columns only
          Positioned(
            bottom: 0,
            child: _StageGlow(inAnim: inAnim),
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (second != null)
                _PodiumColumn(
                  inAnim: inAnim,
                  delayMs: 40,
                  p: second!,
                  rank: 2,
                  height: 120,
                  colorTop: Colors.white.withOpacity(0.35),
                  colorBottom: Colors.white.withOpacity(0.08),
                ),

              if (winner != null)
                _PodiumColumn(
                  inAnim: inAnim,
                  delayMs: 0,
                  p: winner!,
                  rank: 1,
                  height: 170,
                  colorTop: Colors.amber.withOpacity(0.75),
                  colorBottom: Colors.black.withOpacity(0.10),
                  crown: true,
                ),

              if (third != null)
                _PodiumColumn(
                  inAnim: inAnim,
                  delayMs: 80,
                  p: third!,
                  rank: 3,
                  height: 105,
                  colorTop: Colors.orange.withOpacity(0.40),
                  colorBottom: Colors.white.withOpacity(0.08),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageGlow extends StatelessWidget {
  final bool inAnim;
  const _StageGlow({required this.inAnim});

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final stageW = (w * 0.78).clamp(320.0, 720.0);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: inAnim ? 1 : 0, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (_, t, __) {
        return Opacity(
          opacity: 0.85 * t,
          child: Container(
            width: stageW,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Colors.transparent,
                  Colors.cyanAccent.withOpacity(0.25),
                  Colors.purpleAccent.withOpacity(0.22),
                  Colors.transparent,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withOpacity(0.10 * t),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Colors.purpleAccent.withOpacity(0.10 * t),
                  blurRadius: 26,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(color: Colors.white.withOpacity(0.10 * t)),
            ),
          ),
        );
      },
    );
  }
}

class _PodiumColumn extends StatelessWidget {
  final bool inAnim;
  final int delayMs;
  final Player p;
  final int rank;
  final double height;
  final Color colorTop;
  final Color colorBottom;
  final bool crown;

  const _PodiumColumn({
    required this.inAnim,
    required this.delayMs,
    required this.p,
    required this.rank,
    required this.height,
    required this.colorTop,
    required this.colorBottom,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    final medal = rank == 1 ? "🥇" : (rank == 2 ? "🥈" : "🥉");

    final double width = rank == 1 ? 150 : 125;
    final double avatarR = rank == 1 ? 42 : 36;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: inAnim ? 1 : 0, end: 1),
      duration: Duration(milliseconds: 220 + delayMs),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) {
        final dy = (1 - t) * 16;
        final scale = 0.96 + 0.04 * t;
        return Transform.translate(
          offset: Offset(0, dy),
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // avatar + name + score
            Stack(
              alignment: Alignment.topCenter,
              children: [
                Column(
                  children: [
                    const SizedBox(height: 14),
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (rank == 1 ? Colors.amber : Colors.white).withOpacity(0.25),
                            blurRadius: 22,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: GameAvatar(path: p.avatar ?? "", radius: avatarR),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "$medal ${p.name}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${p.score} pts",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
                if (crown)
                  Positioned(
                    top: 0,
                    child: Text(
                      "👑",
                      style: TextStyle(
                        fontSize: 26,
                        shadows: [
                          Shadow(
                            color: Colors.amber.withOpacity(0.55),
                            blurRadius: 14,
                          )
                        ],
                      ),
                    ),
                  ),
              ],
            ),

            // podium block
            Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Colors.white12),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [colorTop, colorBottom],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.emoji_events,
                          color: Colors.white.withOpacity(0.85),
                          size: rank == 1 ? 30 : 26,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "#$rank",
                          style: TextStyle(
                            color: Colors.black.withOpacity(0.82),
                            fontWeight: FontWeight.w900,
                            fontSize: rank == 1 ? 34 : 28,
                          ),
                        ),
                      ],
                    ),
                  ),

                  Positioned.fill(
                    child: IgnorePointer(
                      child: Opacity(
                        opacity: 0.10,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Colors.white, Colors.transparent],
                            ),
                          ),
                        ),
                      ),
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final double borderRadius;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.white.withOpacity(0.10),
            border: Border.all(color: Colors.white12),
          ),
          child: child,
        ),
      ),
    );
  }
}
