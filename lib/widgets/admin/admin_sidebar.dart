import 'package:flutter/material.dart';
import 'package:roomify_mobile/utils/constants.dart';
import 'package:roomify_mobile/screens/admin/admin_dashboard_screen.dart';
import 'package:roomify_mobile/screens/admin/admin_kamar_screen.dart';
import 'package:roomify_mobile/screens/admin/admin_tipe_kamar_screen.dart';
import 'package:roomify_mobile/screens/admin/admin_fasilitas_screen.dart';
import 'package:roomify_mobile/screens/admin/admin_pemesanan_screen.dart';
import 'package:roomify_mobile/screens/admin/admin_user_screen.dart';

class AdminSidebar extends StatelessWidget {
  final String currentRoute;

  const AdminSidebar({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          // Header / Logo
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                const SizedBox(width: 12),
                Text(
                  'Roomify\nAdmin',
                  style: AppTextStyles.heading.copyWith(color: Colors.white, fontSize: 20),
                ),
              ],
            ),
          ),
          
          // Daftar Menu
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _buildMenuItem(
                  context: context,
                  title: 'Dashboard',
                  icon: Icons.dashboard,
                  routeName: 'dashboard',
                  targetScreen: const AdminDashboardScreen(),
                ),

                _buildSectionHeader('DATA MASTER'),
                _buildMenuItem(
                  context: context,
                  title: 'Kamar',
                  icon: Icons.bed,
                  routeName: 'kamar',
                  targetScreen: const AdminKamarScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  title: 'Tipe Kamar',
                  icon: Icons.category,
                  routeName: 'tipe_kamar',
                  targetScreen: const AdminTipeKamarScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  title: 'Fasilitas',
                  icon: Icons.star,
                  routeName: 'fasilitas',
                  targetScreen: const AdminFasilitasScreen(),
                ),

                _buildSectionHeader('TRANSAKSI'),
                _buildMenuItem(
                  context: context,
                  title: 'Pemesanan',
                  icon: Icons.book_online,
                  routeName: 'pemesanan',
                  targetScreen: const AdminPemesananScreen(),
                ),
                _buildMenuItem(
                  context: context,
                  title: 'Riwayat Transaksi',
                  icon: Icons.history,
                  routeName: 'riwayat_pemesanan',
                  targetScreen: const AdminRiwayatPemesananScreen(), 
                ),

                _buildSectionHeader('PENGATURAN'),
                _buildMenuItem(
                  context: context,
                  title: 'Pengguna',
                  icon: Icons.people,
                  routeName: 'pengguna',
                  targetScreen: const AdminUserScreen(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper untuk membuat Header Seksi (seperti di Blade)
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 24, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade600,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  // Helper untuk membuat Item Menu
  Widget _buildMenuItem({
    required BuildContext context,
    required String title,
    required IconData icon,
    required String routeName,
    required Widget targetScreen,
  }) {
    final isSelected = currentRoute == routeName;

    return ListTile(
      leading: Icon(icon, color: isSelected ? AppColors.primary : Colors.grey.shade700),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        if (!isSelected) {
          Navigator.pop(context); // Tutup drawer
          Navigator.pushReplacement(
            context,
            PageRouteBuilder(
              pageBuilder: (_, __, ___) => targetScreen,
              transitionDuration: Duration.zero, // Transisi instan agar terasa seperti web
            ),
          );
        } else {
          Navigator.pop(context);
        }
      },
    );
  }
}