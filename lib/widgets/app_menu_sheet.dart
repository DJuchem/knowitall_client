import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../navigation/app_nav_rules.dart';
import '../providers/game_provider.dart';
import '../screens/account_screen.dart';
// Login/Register intentionally NOT in the app menu. Those entry points live on the Welcome screen.
import 'client_settings_sheet.dart';
import 'tv_connect_sheet.dart';

class AppMenuSheet extends StatelessWidget {
  final BuildContext parentContext;

  const AppMenuSheet({super.key, required this.parentContext});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.70,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 40)],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: Navigator(
            onGenerateRoute: (_) => MaterialPageRoute(
              builder: (_) => _MenuRootPage(parentContext: parentContext),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuRootPage extends StatelessWidget {
  final BuildContext parentContext;
  const _MenuRootPage({required this.parentContext});

  // Close the bottom-sheet route (not the internal Navigator inside the sheet).
  void _closeSheet() => Navigator.of(parentContext, rootNavigator: true).pop();

  void _pushSubPage(BuildContext context, Widget child, String title) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _MenuSubPage(title: title, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final game = Provider.of<GameProvider>(context);
    final canConnectTv = AppNavRules.canConnectTv(game.appState);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        centerTitle: false,
        title: Text(
          "MENU",
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        actions: [
          IconButton(
            tooltip: "Close",
            icon: const Icon(Icons.close),
            onPressed: _closeSheet,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (game.isLoggedIn)
              _MenuTile(
                icon: Icons.person,
                title: "Account",
                subtitle: "Profile, stats, badges",
                showChevron: false,
                onTap: () {
                  _closeSheet();
                  Navigator.push(
                    parentContext,
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  );
                },
              ),

            _MenuTile(
              icon: Icons.tv,
              title: "Connect TV",
              subtitle: canConnectTv ? "Pair with spectator screen" : "Available before lobby creation",
              enabled: canConnectTv,
              onTap: () {
                _pushSubPage(context, const TvConnectSheet(), "Connect TV");
              },
            ),

            _MenuTile(
              icon: Icons.settings,
              title: "App settings",
              subtitle: "Theme, wallpaper, music",
              onTap: () {
                _pushSubPage(context, const ClientSettingsSheet(), "App settings");
              },
            ),

            const Spacer(),

            if (game.isLoggedIn)
              FilledButton.icon(
                onPressed: () {
                  game.logout();
                  _closeSheet();
                },
                icon: const Icon(Icons.logout),
                label: const Text("Logout"),
              ),
          ],
        ),
      ),
    );
  }
}

class _MenuSubPage extends StatelessWidget {
  final String title;
  final Widget child;
  const _MenuSubPage({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      ),
      body: child,
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final bool showChevron;

  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
    this.showChevron = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Opacity(
      opacity: enabled ? 1.0 : 0.45,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 10),
        child: ListTile(
          enabled: enabled,
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
          trailing: showChevron ? const Icon(Icons.chevron_right) : null,
          onTap: enabled ? onTap : null,
        ),
      ),
    );
  }
}
