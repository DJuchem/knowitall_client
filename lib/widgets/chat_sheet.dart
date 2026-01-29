import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'package:animate_do/animate_do.dart';

class ChatSheet extends StatefulWidget {
  @override
  _ChatSheetState createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _msgController = TextEditingController();
  bool _isExpanded = false;
  final List<String> _quickEmojis = ["😂", "❤️", "👍", "🔥", "🤔", "😮", "👋", "🎉"];

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final chat = game.lobby?.chat ?? [];
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isExpanded && game.unreadCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => game.resetUnreadCount());
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      // FIX: Increased collapsed height slightly to prevent overflow
      height: _isExpanded ? 500 : 70, 
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withValues(alpha: 0.9) : Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // HEADER
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 68, // FIX: Matches container height constraint minus borders
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Icon(_isExpanded ? Icons.expand_more : Icons.chat_bubble, color: Theme.of(context).colorScheme.primary, size: 28),
                    const SizedBox(width: 12),
                    Text("CHAT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Theme.of(context).textTheme.bodyLarge?.color)),
                    
                    if (!_isExpanded && game.unreadCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Bounce(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(20)),
                            child: Text("${game.unreadCount}", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ),
                        ),
                      ),

                    const Spacer(),
                    
                    if (!_isExpanded && chat.isNotEmpty)
                      Flexible(
                        child: Text(
                          "${chat.last.from}: ${chat.last.text}",
                          style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 16),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // EXPANDED BODY
          if (_isExpanded)
            Expanded(
              child: Column(
                children: [
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: chat.length,
                      itemBuilder: (ctx, i) {
                        final msg = chat[i];
                        final isMe = msg.from == game.myName;
                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            constraints: const BoxConstraints(maxWidth: 300),
                            decoration: BoxDecoration(
                              color: isMe ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2) : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(msg.from, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(msg.text, style: TextStyle(fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  // EMOJI BAR
                  Container(
                    height: 50,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: _quickEmojis.length,
                      separatorBuilder: (_,__) => const SizedBox(width: 20),
                      itemBuilder: (ctx, i) {
                        return GestureDetector(
                          onTap: () {
                            final text = _msgController.text;
                            final selection = _msgController.selection;
                            final newText = text.replaceRange(selection.start >= 0 ? selection.start : text.length, selection.end >= 0 ? selection.end : text.length, _quickEmojis[i]);
                            _msgController.value = TextEditingValue(
                              text: newText,
                              selection: TextSelection.collapsed(offset: (selection.start >= 0 ? selection.start : text.length) + _quickEmojis[i].length),
                            );
                          },
                          child: Center(child: Text(_quickEmojis[i], style: const TextStyle(fontSize: 32))),
                        );
                      },
                    ),
                  ),

                  // INPUT
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _msgController,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 18),
                            decoration: const InputDecoration(
                              hintText: "Type a message...",
                              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            onSubmitted: (_) => _send(game),
                          ),
                        ),
                        const SizedBox(width: 10),
                        FloatingActionButton(
                          child: const Icon(Icons.send),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          onPressed: () => _send(game),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _send(GameProvider game) {
    if (_msgController.text.trim().isEmpty) return;
    game.sendChat(_msgController.text.trim());
    _msgController.clear();
  }
}