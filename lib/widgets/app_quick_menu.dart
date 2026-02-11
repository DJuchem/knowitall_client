import 'package:flutter/material.dart';
import 'app_menu_sheet.dart';

class AppQuickMenuButton extends StatelessWidget {
  final Color? iconColor;
  const AppQuickMenuButton({super.key, this.iconColor});

  void _openMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      showDragHandle: true,
      builder: (_) => AppMenuSheet(parentContext: context),
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
