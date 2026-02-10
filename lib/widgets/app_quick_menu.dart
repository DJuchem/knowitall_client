import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../screens/account_screen.dart';
import 'client_settings_sheet.dart';
import 'tv_connect_sheet.dart';

class AppQuickMenuButton extends StatelessWidget {
  final Color? iconColor;
  final bool showLabel;

  const AppQuickMenuButton({super.key, this.iconColor, this.showLabel = false});

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AppQuickMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: "Menu",
      icon: Icon(Icons.grid_view_rounded, color: iconColor),
      onPressed: () => _openMenu(context),
    );
  }
}

class _AppQuickMenuSheet extends StatelessWidget {
  const _AppQuickMenuSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = Provider.of<GameProvider>(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text("MENU", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1)),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 10),

          _MenuTile(
            icon: Icons.person,
            title: "Account",
            subtitle: game.isLoggedIn ? "Profile, stats, badges" : "Login to save stats",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountScreen()));
            },
          ),
          _MenuTile(
            icon: Icons.tv,
            title: "Connect TV",
            subtitle: "Pair with spectator screen",
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const TvConnectSheet(),
              );
            },
          ),
          _MenuTile(
            icon: Icons.settings,
            title: "App settings",
            subtitle: "Theme, wallpaper, music",
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const ClientSettingsSheet(),
              );
            },
          ),

          const Spacer(),
          if (game.isLoggedIn)
            FilledButton.icon(
              onPressed: () {
                game.logout();
                Navigator.pop(context);
              },
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
            ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: theme.colorScheme.primary.withOpacity(0.12),
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
