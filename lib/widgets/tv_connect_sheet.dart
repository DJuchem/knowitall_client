import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class TvConnectSheet extends StatefulWidget {
  const TvConnectSheet({super.key});

  @override
  State<TvConnectSheet> createState() => _TvConnectSheetState();
}

class _TvConnectSheetState extends State<TvConnectSheet> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _msg;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final game = Provider.of<GameProvider>(context, listen: false);
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() { _busy = true; _msg = null; });

    try {
      await game.linkTv(code);
      setState(() => _msg = "TV pairing requested. If the TV is online, it should attach now.");
    } catch (e) {
      setState(() => _msg = "Pairing failed: $e");
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.55,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 40)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 44, height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Row(
            children: [
              const Icon(Icons.tv),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "CONNECT TO TV",
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            "Enter the TV code shown on the spectator screen.",
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _ctrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              labelText: "TV CODE",
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _busy ? null : _pair,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.link),
              label: Text(_busy ? "PAIRING..." : "PAIR"),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),

          if (_msg != null) ...[
            const SizedBox(height: 12),
            Text(_msg!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}
