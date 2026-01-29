import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_theme.dart';

class ChatSheet extends StatefulWidget {
  @override
  _ChatSheetState createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _controller = TextEditingController();
  
  // State
  bool _isOpen = false;
  int _lastViewedCount = 0;

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final messages = game.lobby?.chat ?? [];
    
    // Unread Logic
    if (_isOpen) _lastViewedCount = messages.length;
    int unread = messages.length - _lastViewedCount;
    if (unread < 0) unread = 0;

    // Height Calculations
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final double closedHeight = 60.0 + MediaQuery.of(context).padding.bottom; 
    // Open height: Header + Keyboard + Some space for messages
    final double openHeight = 400.0 + keyboardHeight;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      height: _isOpen ? openHeight : closedHeight,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5))
        ],
      ),
      child: Column(
        children: [
          // --- HEADER (Tap to Toggle) ---
          GestureDetector(
            onTap: () {
              setState(() {
                _isOpen = !_isOpen;
                if (!_isOpen) FocusScope.of(context).unfocus();
              });
            },
            child: Container(
              height: 60,
              color: Colors.transparent, // Hitbox
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Lobby Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    if (unread > 0 && !_isOpen)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                        child: Text("$unread NEW", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    Icon(_isOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up, color: Colors.white54),
                  ],
                ),
              ),
            ),
          ),

          // --- CHAT BODY ---
          if (_isOpen)
            Expanded(
              child: Column(
                children: [
                  // Messages List
                  Expanded(
                    child: Container(
                      color: const Color(0xFF252538),
                      child: messages.isEmpty
                          ? const Center(child: Text("No messages yet.", style: TextStyle(color: Colors.white30)))
                          : ListView.builder(
                              reverse: true,
                              itemCount: messages.length,
                              padding: const EdgeInsets.all(16),
                              itemBuilder: (ctx, i) {
                                final msg = messages[messages.length - 1 - i];
                                final isMe = msg.from == game.myName;
                                
                                // Default avatar if missing in JSON
                                final avatarPath = msg.avatar ?? "assets/avatars/avatar1.webp"; 
                                
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      // Opponent Avatar
                                      if (!isMe) ...[
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: AssetImage(avatarPath), 
                                          backgroundColor: Colors.grey,
                                          onBackgroundImageError: (_,__) => {}, // Prevent crash on bad asset
                                        ),
                                        const SizedBox(width: 8),
                                      ],

                                      // Bubble
                                      Flexible(
                                        child: Column(
                                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                                          children: [
                                            // Name Label (only for others)
                                            if (!isMe)
                                              Padding(
                                                padding: const EdgeInsets.only(left: 4, bottom: 2),
                                                child: Text(msg.from, style: const TextStyle(fontSize: 10, color: Colors.white54)),
                                              ),
                                            
                                            // Message Box
                                            Container(
                                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                              decoration: BoxDecoration(
                                                color: isMe ? Colors.blueAccent : const Color(0xFF3A3A50),
                                                borderRadius: BorderRadius.only(
                                                  topLeft: const Radius.circular(16),
                                                  topRight: const Radius.circular(16),
                                                  bottomLeft: isMe ? const Radius.circular(16) : Radius.zero,
                                                  bottomRight: isMe ? Radius.zero : const Radius.circular(16),
                                                ),
                                              ),
                                              child: Text(msg.text, style: const TextStyle(color: Colors.white, fontSize: 15)),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // My Avatar
                                      if (isMe) ...[
                                        const SizedBox(width: 8),
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundImage: AssetImage(avatarPath),
                                          backgroundColor: Colors.blue[900],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // Input Field
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppTheme.primaryColor),
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 45,
                            child: TextField(
                              controller: _controller,
                              style: const TextStyle(color: Colors.white),
                              
                              // --- FEATURES: Enter to Send + Emojis ---
                              textInputAction: TextInputAction.send,
                              keyboardType: TextInputType.text, 
                              
                              onSubmitted: (val) {
                                if (val.trim().isNotEmpty) {
                                   game.sendChat(val.trim());
                                   _controller.clear();
                                   // Keep focus or unfocus based on preference:
                                   // FocusScope.of(context).requestFocus(_focusNode); 
                                 }
                              },
                              
                              decoration: InputDecoration(
                                hintText: "Type a message...",
                                hintStyle: const TextStyle(color: Colors.white30),
                                filled: true,
                                fillColor: const Color(0xFF1E1E2C),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            if (_controller.text.trim().isNotEmpty) {
                              game.sendChat(_controller.text.trim());
                              _controller.clear();
                            }
                          },
                          child: const CircleAvatar(
                            backgroundColor: Colors.blueAccent,
                            radius: 20,
                            child: Icon(Icons.send, color: Colors.white, size: 18),
                          ),
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
}