import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import 'package:animate_do/animate_do.dart';

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
  bool _clearedUnreadThisOpen = false;

  // quick bar (kept from your version)
  final List<String> _quickEmojis = ["😂", "❤️", "👍", "🔥", "🤔", "😮", "👋", "🎉"];

  // recent emojis (simple local session list)
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
      selection: TextSelection.collapsed(offset: start + insert.length),
    );
  }

  void _onEmojiPicked(String emoji) {
    _insertText(emoji);
    // update recent (unique, capped)
    setState(() {
      _recent.remove(emoji);
      _recent.insert(0, emoji);
      if (_recent.length > 24) _recent.removeRange(24, _recent.length);
    });
  }

  void _toggleExpanded(GameProvider game) {
    setState(() {
      _isExpanded = !_isExpanded;
      if (!_isExpanded) {
        _showEmojiPicker = false;
        _clearedUnreadThisOpen = false;
      }
    });

    if (_isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (game.unreadCount > 0 && !_clearedUnreadThisOpen) {
          _clearedUnreadThisOpen = true;
          game.resetUnreadCount();
        }
      });
    }
  }

  void _toggleEmojiPicker() {
    setState(() => _showEmojiPicker = !_showEmojiPicker);

    if (_showEmojiPicker) {
      _focusNode.unfocus(); // hide keyboard
    } else {
      _focusNode.requestFocus();
    }
  }

  void _send(GameProvider game) {
    final msg = _msgController.text.trim();
    if (msg.isEmpty) return;

    game.sendChat(msg);
    _msgController.clear();

    // keep UX snappy
    setState(() => _showEmojiPicker = false);
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final chat = game.lobby?.chat ?? [];
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Clear unread once while expanded
    if (_isExpanded && game.unreadCount > 0 && !_clearedUnreadThisOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (_isExpanded && game.unreadCount > 0 && !_clearedUnreadThisOpen) {
          _clearedUnreadThisOpen = true;
          game.resetUnreadCount();
        }
      });
    }

    // styling
    final sheetBg = cs.surface.withOpacity(isDark ? 0.55 : 0.70);
    final sheetBorder =
        (isDark ? Colors.white : Colors.black).withOpacity(isDark ? 0.16 : 0.10);

    final headerTextColor = cs.onSurface.withOpacity(0.92);
    final previewTextColor = cs.onSurface.withOpacity(0.55);

    final myBubble = cs.primary.withOpacity(isDark ? 0.22 : 0.18);
    final otherBubble =
        cs.surfaceContainerHighest.withOpacity(isDark ? 0.45 : 0.60);
    final bubbleBorder =
        (isDark ? Colors.white : Colors.black).withOpacity(0.10);

    final inputFill =
        cs.surfaceContainerHighest.withOpacity(isDark ? 0.45 : 0.65);
    final inputBorder =
        (isDark ? Colors.white : Colors.black).withOpacity(0.12);

    // height logic (avoid overflow)
    final baseExpanded = 500.0;
    final emojiH = 300.0;
    final maxH = MediaQuery.of(context).size.height * 0.82;
    final targetH = _isExpanded
        ? (baseExpanded + (_showEmojiPicker ? emojiH : 0)).clamp(220.0, maxH)
        : 70.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      height: targetH,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: sheetBorder),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -5))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // glass blur
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: const SizedBox(),
            ),
          ),

          // tint
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    sheetBg,
                    sheetBg.withOpacity(sheetBg.opacity * 0.85),
                  ],
                ),
              ),
            ),
          ),

          Column(
            children: [
              // HEADER
              LayoutBuilder(
                builder: (context, constraints) {
                  final w = constraints.maxWidth;
                  final tiny = w < 180;
                  final small = w < 260;

                  final horizontalPad = tiny ? 10.0 : (small ? 14.0 : 24.0);
                  final titleSize = tiny ? 14.0 : 18.0;
                  final iconSize = tiny ? 22.0 : 28.0;

                  return InkWell(
                    onTap: () => _toggleExpanded(game),
                    borderRadius: BorderRadius.circular(24),
                    child: SizedBox(
                      height: 68,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPad),
                        child: Row(
                          children: [
                            Icon(
                              _isExpanded
                                  ? Icons.expand_more
                                  : Icons.chat_bubble,
                              color: cs.primary.withOpacity(0.95),
                              size: iconSize,
                            ),
                            SizedBox(width: tiny ? 6 : 12),
                            Flexible(
                              child: Text(
                                "CHAT",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: titleSize,
                                  color: headerTextColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ),
                            if (!tiny && !_isExpanded && game.unreadCount > 0)
                              Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Bounce(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent.withOpacity(0.95),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "${game.unreadCount}",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const Spacer(),
                            if (!small && !_isExpanded && chat.isNotEmpty)
                              Flexible(
                                child: Text(
                                  "${chat.last.from}: ${chat.last.text}",
                                  style: TextStyle(
                                    color: previewTextColor,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),

              // EXPANDED BODY
              if (_isExpanded)
                Expanded(
                  child: Column(
                    children: [
                      Divider(height: 1, color: sheetBorder),

                      // messages
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: chat.length,
                          itemBuilder: (ctx, i) {
                            final msg = chat[i];
                            final isMe = msg.from == game.myName;

                            return Align(
                              alignment: isMe
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                constraints:
                                    const BoxConstraints(maxWidth: 320),
                                decoration: BoxDecoration(
                                  color: isMe ? myBubble : otherBubble,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: bubbleBorder),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      msg.from,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: cs.secondary.withOpacity(0.95),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      msg.text,
                                      style: TextStyle(
                                        fontSize: 18,
                                        color: cs.onSurface.withOpacity(0.95),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // quick emoji bar
                      SizedBox(
                        height: 50,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _quickEmojis.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 18),
                          itemBuilder: (ctx, i) {
                            final e = _quickEmojis[i];
                            return GestureDetector(
                              onTap: () => _onEmojiPicked(e),
                              child: Center(
                                child: Text(e,
                                    style: const TextStyle(fontSize: 30)),
                              ),
                            );
                          },
                        ),
                      ),

                      // input row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Row(
                          children: [
                            SizedBox(
                              height: 52,
                              width: 52,
                              child: Material(
                                color: cs.surfaceContainerHighest
                                    .withOpacity(isDark ? 0.35 : 0.55),
                                borderRadius: BorderRadius.circular(16),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: _toggleEmojiPicker,
                                  child: Icon(
                                    _showEmojiPicker
                                        ? Icons.keyboard
                                        : Icons.emoji_emotions_outlined,
                                    color: cs.onSurface.withOpacity(0.85),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _msgController,
                                focusNode: _focusNode,
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.95),
                                  fontSize: 18,
                                ),
                                decoration: InputDecoration(
                                  hintText: "Type a message...",
                                  hintStyle: TextStyle(
                                      color: cs.onSurface.withOpacity(0.55)),
                                  filled: true,
                                  fillColor: inputFill,
                                  contentPadding:
                                      const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 14),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: inputBorder),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: cs.primary.withOpacity(0.7),
                                      width: 1.5,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  if (_showEmojiPicker) {
                                    setState(() => _showEmojiPicker = false);
                                  }
                                },
                                onSubmitted: (_) => _send(game),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              height: 52,
                              width: 52,
                              child: FloatingActionButton(
                                heroTag: "chat_send_btn",
                                elevation: 0,
                                backgroundColor: cs.primary,
                                onPressed: () => _send(game),
                                child: Icon(Icons.send, color: cs.onPrimary),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // premium picker
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: _FancyEmojiPicker(
                          primary: cs.primary,
                          isDark: isDark,
                          recent: _recent,
                          onPick: _onEmojiPicked,
                        ),
                        crossFadeState: _showEmojiPicker
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 160),
                        sizeCurve: Curves.easeOut,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FancyEmojiPicker extends StatefulWidget {
  final Color primary;
  final bool isDark;
  final List<String> recent;
  final void Function(String) onPick;

  const _FancyEmojiPicker({
    required this.primary,
    required this.isDark,
    required this.recent,
    required this.onPick,
  });

  @override
  State<_FancyEmojiPicker> createState() => _FancyEmojiPickerState();
}

class _FancyEmojiPickerState extends State<_FancyEmojiPicker>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    _search.dispose();
    super.dispose();
  }

  static const _cats = <String, List<String>>{
    "Smileys": ["😀","😃","😄","😁","😆","😅","😂","🤣","🥲","😊","😇","🙂","🙃","😉","😌","😍","🥰","😘","😗","😙","😚","😋","😛","😜","🤪","😝","🤗","🤭","🤫","🤔","😐","😑","😶","🫠","😏","😒","🙄","😬","😮‍💨","😴","🤤","😪","😵","🤐","🥴","😷","🤒","🤕","🤧","🥵","🥶","😱","😳","🥺","😢","😭","😤","😡","🤬","😎","🤓","🧐"
    ],
    "People": ["👋","🤚","🖐️","✋","🖖","👌","🤌","🤏","✌️","🤞","🤟","🤘","👍","👎","👏","🙌","🫶","🙏","💪","🦾","🧠","🫀","🫁","🧑","👨","👩","🧔","👶","👦","👧","🧓","👴","👵"
    ],
    "Hearts": ["❤️","🧡","💛","💚","💙","💜","🖤","🤍","🤎","💖","💗","💓","💞","💕","💘","💝","💟","❣️","❤️‍🔥","❤️‍🩹"
    ],
    "Food": ["🍕","🍔","🍟","🌭","🍿","🧀","🥨","🥐","🍞","🥖","🥗","🍝","🍜","🍣","🍤","🍩","🍪","🎂","🍰","🍫","🍬","🍭","☕","🧋","🥤","🍺","🍷"
    ],
    "Activities": ["🎉","🎊","🎁","🎈","🏆","🥇","🥈","🥉","🎮","🎲","🎯","🏁","⚽","🏀","🏈","🎾","🏐","🏓","🏸","🥊","🛹","🎸","🥁","🎤"
    ],
    "Symbols": ["🔥","✨","⚡","💥","💫","⭐","🌟","✅","❌","⚠️","❓","❗","💯","🔁","🔄","🔊","🔇","📣","📌","🔒","🔓","🧩","🛰️","🚀"
    ],
  };

  List<String> _filtered(List<String> base) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return base;
    // ultra-simple search: match by "emoji name" isn't possible without metadata,
    // so we match by exact emoji typing (works for paste) and show everything otherwise.
    return base.where((e) => e.contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final border = Colors.white.withOpacity(widget.isDark ? 0.10 : 0.14);
    final text = (widget.isDark ? Colors.white : Colors.black).withOpacity(0.85);

    final tabs = [
      const Tab(text: "🙂"),
      const Tab(text: "👋"),
      const Tab(text: "❤️"),
      const Tab(text: "🍕"),
      const Tab(text: "🎮"),
      const Tab(text: "✨"),
    ];

    final pages = [
      _grid("Smileys", _cats["Smileys"]!, widget.recent),
      _grid("People", _cats["People"]!, widget.recent),
      _grid("Hearts", _cats["Hearts"]!, widget.recent),
      _grid("Food", _cats["Food"]!, widget.recent),
      _grid("Activities", _cats["Activities"]!, widget.recent),
      _grid("Symbols", _cats["Symbols"]!, widget.recent),
    ];

    return SizedBox(
      height: 300,
      child: Column(
        children: [
          // search + recent row
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: text),
                    decoration: InputDecoration(
                      hintText: "Search (paste emoji)…",
                      hintStyle: TextStyle(
                        color: (widget.isDark ? Colors.white : Colors.black)
                            .withOpacity(0.45),
                      ),
                      isDense: true,
                      filled: true,
                      fillColor: Colors.white.withOpacity(widget.isDark ? 0.06 : 0.10),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: widget.primary.withOpacity(0.70), width: 1.4),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: widget.primary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border),
                  ),
                  child: Icon(Icons.history,
                      color: widget.primary.withOpacity(0.95)),
                ),
              ],
            ),
          ),

          // recent strip
          if (widget.recent.isNotEmpty)
            SizedBox(
              height: 38,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: widget.recent.length.clamp(0, 14),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, i) {
                  final e = widget.recent[i];
                  return InkWell(
                    onTap: () => widget.onPick(e),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(widget.isDark ? 0.06 : 0.10),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: border),
                      ),
                      child: Text(e, style: const TextStyle(fontSize: 22)),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 6),

          // tabs
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(widget.isDark ? 0.05 : 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: border),
            ),
            child: TabBar(
              controller: _tabs,
              tabs: tabs,
              indicator: BoxDecoration(
                color: widget.primary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              labelColor: widget.primary.withOpacity(0.95),
              unselectedLabelColor:
                  (widget.isDark ? Colors.white : Colors.black).withOpacity(0.60),
              dividerColor: Colors.transparent,
            ),
          ),

          const SizedBox(height: 8),

          // pages
          Expanded(
            child: TabBarView(
              controller: _tabs,
              children: pages,
            ),
          ),
        ],
      ),
    );
  }

  Widget _grid(String name, List<String> emojis, List<String> recent) {
    final border = Colors.white.withOpacity(widget.isDark ? 0.10 : 0.14);

    final filtered = _filtered(emojis);

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 9,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final e = filtered[i];
        return InkWell(
          onTap: () => widget.onPick(e),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(widget.isDark ? 0.06 : 0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: border),
            ),
            child: Text(e, style: const TextStyle(fontSize: 22)),
          ),
        );
      },
    );
  }
}
