import 'package:flutter/material.dart';

class MedRhythmsAppBar extends StatelessWidget implements PreferredSizeWidget {
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.green,
      title: Center(
        child: _buildLogo(),
      ),
    );
  }

  Widget _buildLogo() {
    try {
      return Image.asset(
        'assets/images/logo.jpg',
        height: kToolbarHeight - 8, // Adjust as needed
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Text(
            'Logo Not Found',
            style: TextStyle(color: Colors.white, fontSize: 18),
          );
        },
      );
    } catch (e) {
      return const Text(
        'Error Loading Image',
        style: TextStyle(color: Colors.white, fontSize: 18),
      );
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
