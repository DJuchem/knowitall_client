import 'dart:convert'; // 🟢 Added
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../providers/game_provider.dart';
import '../widgets/base_scaffold.dart';
import '../widgets/avatar_selection_sheet.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  final _secretCodeCtrl = TextEditingController();
  
  String _selectedAvatar = "avatars/avatar10.webp"; 
  bool _isLoading = false;

  void _openAvatarSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return AvatarSelectionSheet(
              currentAvatar: _selectedAvatar,
              onAvatarSelected: (path) {
                String cleanPath = path.startsWith("assets/") ? path.substring(7) : path;
                setState(() => _selectedAvatar = cleanPath);
              },
            );
          },
        );
      },
    );
  }

  bool _isValidEmail(String email) {
    if (email.isEmpty) return true; 
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    final game = Provider.of<GameProvider>(context);
    final theme = Theme.of(context);

    ImageProvider displayImage;
    if (_selectedAvatar.startsWith("data:")) {
      displayImage = MemoryImage(base64Decode(_selectedAvatar.split(',')[1]));
    } else {
      String assetPath = _selectedAvatar.startsWith("assets/") ? _selectedAvatar : "assets/$_selectedAvatar";
      displayImage = AssetImage(assetPath);
    }

    return BaseScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text("CREATE ACCOUNT", style: theme.textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    const SizedBox(height: 30),

                    GestureDetector(
                      onTap: _openAvatarSheet,
                      child: Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          CircleAvatar(radius: 50, backgroundColor: Colors.white10, backgroundImage: displayImage),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(color: Color(0xFF2979FF), shape: BoxShape.circle),
                            child: const Icon(Icons.edit, size: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    _buildInput("USERNAME *", _userCtrl, false),
                    const SizedBox(height: 16),
                    _buildInput("EMAIL (OPTIONAL)", _emailCtrl, false),
                    const SizedBox(height: 16),
                    _buildInput("PASSWORD *", _passCtrl, true),
                    const SizedBox(height: 16),
                    _buildInput("CONFIRM PASSWORD *", _passConfirmCtrl, true),
                    const SizedBox(height: 16),
                    _buildInput("REGISTRATION CODE *", _secretCodeCtrl, true),
                    
                    const SizedBox(height: 30),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8E24AA),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        onPressed: _isLoading ? null : () async {
                          if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Username and Password are required!"), backgroundColor: Colors.red));
                             return;
                          }
                          if (!_isValidEmail(_emailCtrl.text.trim())) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Email Address"), backgroundColor: Colors.red));
                             return;
                          }
                          if (_passCtrl.text != _passConfirmCtrl.text) {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Passwords do not match!"), backgroundColor: Colors.red));
                             return;
                          }
                          if (_secretCodeCtrl.text != "BANGKOK@2026!") {
                             ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Invalid Registration Code!"), backgroundColor: Colors.red));
                             return;
                          }

                          setState(() => _isLoading = true);
                          try {
                            String finalAvatar = _selectedAvatar.startsWith("assets/") ? _selectedAvatar : "assets/$_selectedAvatar";
                            
                            await game.register(_userCtrl.text.trim(), _emailCtrl.text.trim(), _passCtrl.text.trim(), finalAvatar);
                            
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Account Created! Please Login."), backgroundColor: Colors.green));
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
                          } finally {
                            if (mounted) setState(() => _isLoading = false);
                          }
                        },
                        child: _isLoading 
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("REGISTER", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 FIXED: Opaque Container Style
  Widget _buildInput(String label, TextEditingController ctrl, bool obscure) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        const SizedBox(height: 8),
        Container(
          height: 55,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7), // Darker background
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}