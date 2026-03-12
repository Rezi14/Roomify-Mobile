import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_mobile/providers/auth_provider.dart';
import 'package:roomify_mobile/utils/constants.dart';

class AdminNavbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;

  const AdminNavbar({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return AppBar(
      title: Text(title),
      elevation: 2,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        // Dropdown Profil (Memetakan nav-profile di Blade)
        PopupMenuButton<String>(
          offset: const Offset(0, 50),
          tooltip: 'Profil Admin',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      auth.user?.name ?? 'Admin',
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      'Administrator',
                      style: TextStyle(fontSize: 11, color: Colors.white70),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: AppColors.primary, size: 20),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
              ],
            ),
          ),
          onSelected: (value) async {
            if (value == 'logout') {
              await auth.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'profile',
              enabled: false,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey, size: 20),
                  SizedBox(width: 8),
                  Text('Info Akun'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: AppColors.danger, size: 20),
                  SizedBox(width: 8),
                  Text('Logout', style: TextStyle(color: AppColors.danger)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}