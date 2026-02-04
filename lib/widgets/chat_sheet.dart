import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

class ChatSheet extends StatefulWidget {
  const ChatSheet({super.key});

  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _msgController = TextEditingController();
  final _focusNode = FocusNode();

  bool _isExpanded = false;
  bool _showEmojiPicker = false;
  final List<String> _quickEmojis = ["😂", "❤️", "👍", "🔥", "🤔", "😮", "👋", "🎉"];
  final List<String> _recent = [];

  @override
  void dispose() {
    _msgController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _insertText(String insert) {
    final text = _msgController.text;
    final sel = _msgController.selection;
    final start = sel.start >= 0 ? sel.start : text.length;
    final end = sel.end >= 0 ? sel.end : text.length;
    final newText = text.replaceRange(start, end, insert);
    _msgController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: start + insert.length));
  }

  void _onEmojiPicked(String emoji) {
    _insertText(emoji);
    setState(() {
      _recent.remove(emoji);
      _recent.insert(0, emoji);
      if (_recent.length > 24) _recent.removeRange(24, _recent.length);
    });
  }

  void _toggleExpanded(GameProvider game) {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) _showEmojiPicker = false;
    });
    if (_isExpanded) game.markChatAsRead();
  }

  void _send(GameProvider game) {
    final msg = _msgController.text.trim();
    if (msg.isEmpty) return;
    game.sendChat(msg);
    _msgController.clear();
    setState(() => _showEmojiPicker = false);
    _focusNode.requestFocus();
  }

  // ✅ Helper to find player avatar safely
  String _getAvatarForPlayer(GameProvider game, String playerName) {
    if (playerName == game.myName) return game.myAvatar;
    try {
      final p = game.lobby?.players.firstWhere((pl) => pl.name == playerName);
      return p?.avatar ?? "avatars/avatar_0.png";
    } catch (_) {
      return "avatars/avatar_0.png";
    }
  }

  // ✅ Robust Path Cleaner
  String _cleanPath(String path) {
    if (path.isEmpty) return "avatars/avatar_0.png";
    String p = path;
    // Strip all assets/ prefixes
    while (p.startsWith("assets/") || p.startsWith("/assets/")) {
      p = p.replaceFirst("assets/", "").replaceFirst("/assets/", "");
    }
    return p;
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final chat = game.lobby?.chat ?? [];

    if (_isExpanded && game.unreadCount > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => game.markChatAsRead());
    }

    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final screenSize = MediaQuery.of(context).size;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final sheetBg = cs.surface.withOpacity(isDark ? 0.95 : 1.0);
    final myBubble = cs.primary.withOpacity(0.3);
    final otherBubble = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);

    // ✅ FIX: Base height
    double targetH = 80; 
    if (_isExpanded) {
      targetH = screenSize.height * 0.5;
      if (_showEmojiPicker) targetH += 250;
      if (targetH > screenSize.height * 0.85) targetH = screenSize.height * 0.85;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      height: targetH,
      margin: EdgeInsets.fromLTRB(12, 0, 12, 12 + bottomInset),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: sheetBg,
        border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        children: [
          // --- HEADER ---
          InkWell(
            onTap: () => _toggleExpanded(game),
            child: SizedBox(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Icon(_isExpanded ? Icons.expand_more : Icons.chat_bubble,
                        color: cs.primary),
                    const SizedBox(width: 12),
                    Text("CHAT",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: cs.onSurface)),
                    if (!_isExpanded && game.unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(left: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text("${game.unreadCount}",
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ),
                    const Spacer(),
                    if (!_isExpanded && chat.isNotEmpty)
                      Flexible(
                        child: Text(
                          "${chat.last.from}: ${chat.last.text}",
                          style: TextStyle(color: cs.onSurface.withOpacity(0.6)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          
          // --- EXPANDED CONTENT ---
          if (_isExpanded)
            Expanded(
              // ✅ FIX: LayoutBuilder prevents crash if container is too small during animation
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxHeight < 100) return const SizedBox();
                  
                  return Column(
                    children: [
                      Divider(height: 1, color: cs.onSurface.withOpacity(0.1)),
                      
                      // MESSAGES
                      Expanded(
                        child: ListView.builder(
                          reverse: true,
                          padding: const EdgeInsets.all(16),
                          itemCount: chat.length,
                          itemBuilder: (ctx, i) {
                            final msg = chat[chat.length - 1 - i];
                            final isMe = msg.from == game.myName;
                            final avatarPath = _getAvatarForPlayer(game, msg.from);

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Row(
                                mainAxisAlignment: isMe
                                    ? MainAxisAlignment.end
                                    : MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (!isMe) ...[
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: Colors.black26,
                                      backgroundImage: AssetImage("assets/${_cleanPath(avatarPath)}"),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Flexible(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isMe ? myBubble : otherBubble,
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          if (!isMe)
                                            Text(msg.from,
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    color: cs.primary,
                                                    fontWeight: FontWeight.bold)),
                                          Text(msg.text,
                                              style: TextStyle(
                                                  fontSize: 16, color: cs.onSurface)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // INPUT
                      Container(
                        padding: const EdgeInsets.all(12),
                        color: cs.surface.withOpacity(0.5),
                        child: Column(
                          children: [
                            if (_quickEmojis.isNotEmpty)
                              SizedBox(
                                height: 40,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _quickEmojis.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 15),
                                  itemBuilder: (_, i) => GestureDetector(
                                    onTap: () => _onEmojiPicked(_quickEmojis[i]),
                                    child: Center(
                                        child: Text(_quickEmojis[i],
                                            style: const TextStyle(fontSize: 24))),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton(
                                  icon: Icon(
                                      _showEmojiPicker
                                          ? Icons.keyboard
                                          : Icons.emoji_emotions_outlined,
                                      color: cs.onSurface.withOpacity(0.7)),
                                  onPressed: () {
                                    setState(() =>
                                        _showEmojiPicker = !_showEmojiPicker);
                                    if (_showEmojiPicker)
                                      _focusNode.unfocus();
                                    else
                                      _focusNode.requestFocus();
                                  },
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _msgController,
                                    focusNode: _focusNode,
                                    style: TextStyle(color: cs.onSurface),
                                    decoration: InputDecoration(
                                      hintText: "Type a message...",
                                      hintStyle: TextStyle(
                                          color: cs.onSurface.withOpacity(0.4)),
                                      filled: true,
                                      fillColor: cs.onSurface.withOpacity(0.1),
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(20),
                                          borderSide: BorderSide.none),
                                    ),
                                    onSubmitted: (_) => _send(game),
                                    onTap: () =>
                                        setState(() => _showEmojiPicker = false),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(Icons.send, color: cs.secondary),
                                  onPressed: () => _send(game),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      // EMOJI PICKER
                      if (_showEmojiPicker)
                        SizedBox(
                          height: 250,
                          child: _FancyEmojiPicker(
                            primary: cs.primary,
                            isDark: isDark,
                            recent: _recent,
                            onPick: _onEmojiPicked,
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FancyEmojiPicker extends StatelessWidget {
  final Color primary;
  final bool isDark;
  final List<String> recent;
  final Function(String) onPick;

  const _FancyEmojiPicker(
      {required this.primary,
      required this.isDark,
      required this.recent,
      required this.onPick});

  @override
  Widget build(BuildContext context) {
    final emojis = [
      "😀", "😃", "😄", "😁", "😆", "😅", "😂", "🤣", "😊", "😇", "🙂", "🙃", "😉", "😌", "😍", "🥰",
      "😘", "😗", "😙", "😚", "😋", "😛", "😜", "🤪", "😝", "🤑", "🤗", "🤭", "🤫", "🤔", "🤐", "🤨",
      "😐", "😑", "😶", "😏", "😒", "🙄", "😬", "🤥", "😌", "😔", "😪", "🤤", "😴", "😷", "🤒", "🤕",
      "🤢", "🤮", "🤧", "🥵", "🥶", "🥴", "😵", "🤯", "🤠", "🥳", "😎", "🤓", "🧐", "😕", "😟", "🙁",
      "☹️", "😮", "😯", "😲", "😳", "🥺", "😦", "😧", "😨", "😰", "😥", "😢", "😭", "😱", "😖", "😣",
      "😞", "😓", "😩", "😫", "🥱", "😤", "😡", "😠", "🤬", "😈", "👿", "💀", "☠️", "💩", "🤡", "👹",
      "👺", "👻", "👽", "👾", "🤖", "😺", "😸", "😹", "😻", "😼", "😼", "😽", "🙀", "😿", "😾", "🙈",
      "🙉", "🙊", "👋", "🤚", "🖐️", "✋", "🖖", "👌", "🤌", "🤏", "✌️", "🤞", "🤟", "🤘", "🤙", "👈",
      "👉", "👆", "🖕", "👇", "☝️", "👍", "👎", "✊", "👊", "🤛", "🤜", "👏", "🙌", "👐", "🤲", "🤝", "🙏"
    ];
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8, crossAxisSpacing: 5, mainAxisSpacing: 5),
      itemCount: emojis.length,
      itemBuilder: (_, i) => GestureDetector(
        onTap: () => onPick(emojis[i]),
        child: Center(
            child: Text(emojis[i], style: const TextStyle(fontSize: 24))),
      ),
    );
  }
}