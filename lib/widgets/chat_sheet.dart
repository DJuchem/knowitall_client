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

    final sheetBg = cs.surface.withOpacity(isDark ? 0.95 : 1.0);
    final myBubble = cs.primary.withOpacity(0.3);
    final otherBubble = isDark ? Colors.white10 : Colors.black.withOpacity(0.05);

    // FIX: Set collapsed height to match header (68) + border/padding room to avoid overflow
    double targetH = 70;
    if (_isExpanded) {
      targetH = 500;
      if (_showEmojiPicker) targetH += 250;
      final screenH = MediaQuery.of(context).size.height;
      if (targetH > screenH * 0.85) targetH = screenH * 0.85;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutBack,
      height: targetH,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
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
          // HEADER
          InkWell(
            onTap: () => _toggleExpanded(game),
            child: SizedBox(
              height: 68, // Header height
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
                          // ✅ FIXED: Use .from and .text instead of map syntax []
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
          if (_isExpanded)
            Expanded(
              child: Column(
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
                        // ✅ FIXED: Use .from and .text instead of map syntax []
                        final sender = msg.from;
                        final text = msg.text;
                        final isMe = sender == game.myName;

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
                                    radius: 14,
                                    backgroundColor: cs.onSurface.withOpacity(0.1),
                                    child: Text(sender.isNotEmpty ? sender[0] : "?",
                                        style: TextStyle(
                                            fontSize: 10, color: cs.onSurface))),
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
                                        Text(sender,
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: cs.primary,
                                                fontWeight: FontWeight.bold)),
                                      Text(text,
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
                  // INPUT AREA
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: cs.surface.withOpacity(0.5),
                    child: Column(
                      children: [
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