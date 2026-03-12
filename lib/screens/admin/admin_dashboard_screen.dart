import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../models/pemesanan_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
// import '../../widgets/order_status_badge.dart';
import 'admin_kamar_screen.dart';
import 'admin_tipe_kamar_screen.dart';
import 'admin_pemesanan_screen.dart';
import 'admin_user_screen.dart';
import 'admin_fasilitas_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminService();
  bool _isLoading = true;
  int _totalKamar = 0;
  int _totalPemesanan = 0;
  int _totalPengguna = 0;
  List<PemesananModel> _pelangganCheckin = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await _adminService.getDashboard();
      setState(() {
        _totalKamar = data['total_kamar'];
        _totalPemesanan = data['total_pemesanan'];
        _totalPengguna = data['total_pengguna'];
        _pelangganCheckin = data['pelanggan_checkin'];
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Provider.of<AuthProvider>(context, listen: false).logout();
              if (!context.mounted) return;

              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(
                    Icons.admin_panel_settings,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Roomify Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.hotel),
              title: const Text('Kamar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminKamarScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text('Tipe Kamar'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminTipeKamarScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.star),
              title: const Text('Fasilitas'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminFasilitasScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.book_online),
              title: const Text('Pemesanan'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminPemesananScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Pengguna'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminUserScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat Cards
                    Row(
                      children: [
                        _statCard(
                          'Kamar',
                          '$_totalKamar',
                          Icons.hotel,
                          AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _statCard(
                          'Pemesanan',
                          '$_totalPemesanan',
                          Icons.book_online,
                          AppColors.accentGreen,
                        ),
                        const SizedBox(width: 8),
                        _statCard(
                          'Pengguna',
                          '$_totalPengguna',
                          Icons.people,
                          AppColors.info,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pelanggan Check-in
                    Text(
                      'Pelanggan Sedang Check-in',
                      style: AppTextStyles.heading.copyWith(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    if (_pelangganCheckin.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(
                            child: Text('Tidak ada tamu yang sedang check-in.'),
                          ),
                        ),
                      )
                    else
                      ..._pelangganCheckin.map(
                        (p) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(p.user?.name ?? '-'),
                            subtitle: Text(
                              '${p.kamar?.tipeKamar?.namaTipeKamar ?? '-'} | No. ${p.kamar?.nomorKamar ?? '-'}',
                            ),
                            trailing: Text(
                              Helpers.formatRupiah(p.totalHarga),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(title, style: AppTextStyles.body.copyWith(fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
