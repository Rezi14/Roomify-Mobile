import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/admin_service.dart';
import '../../models/pemesanan_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
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

  // --- FUNGSI KONFIRMASI LOGOUT ---
  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.power_settings_new_rounded, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Text('Keluar Akun?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari dashboard admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Ya, Keluar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      
      // KITA HAPUS showDialog manual di sini.
      // Biarkan Provider yang mengurus loading dan navigasinya!
      await Provider.of<AuthProvider>(context, listen: false).logout();
      
      if (mounted) {
        // Membersihkan sisa tumpukan rute (jika ada)
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    }
  }
  // --- FUNGSI UNTUK PROSES CHECKOUT ---
  Future<void> _prosesCheckout(int idPemesanan) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Proses Checkout?'),
        content: const Text('Apakah Anda yakin ingin melakukan proses check-out untuk pesanan ini? Pastikan semua tagihan telah diselesaikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal', style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
            child: const Text('Ya, Checkout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await _adminService.checkOutPemesanan(idPemesanan);
      
      if (mounted) Navigator.pop(context);

      if (mounted) {
        Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
        if (result['success'] == true) {
          _loadDashboard(); 
        }
      }
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
            // Memanggil fungsi konfirmasi logout
            onPressed: _confirmLogout,
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const DrawerHeader(
                    decoration: BoxDecoration(color: AppColors.primary),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Icon(Icons.admin_panel_settings, size: 48, color: Colors.white),
                        SizedBox(height: 8),
                        Text('Roomify Admin', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminKamarScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.category),
                    title: const Text('Tipe Kamar'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminTipeKamarScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.star),
                    title: const Text('Fasilitas'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFasilitasScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.book_online),
                    title: const Text('Pemesanan'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPemesananScreen()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Pengguna'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminUserScreen()));
                    },
                  ),
                ],
              ),
            ),
            // Tombol Logout di paling bawah menu Drawer
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.power_settings_new_rounded, color: Colors.red),
              title: const Text('Keluar Akun', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context); // Tutup drawer-nya dulu
                _confirmLogout();       // Baru panggil konfirmasinya
              },
            ),
            const SizedBox(height: 16), // Jarak aman di bawah
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
                        _statCard('Kamar', '$_totalKamar', Icons.hotel, AppColors.primary),
                        const SizedBox(width: 8),
                        _statCard('Pemesanan', '$_totalPemesanan', Icons.book_online, AppColors.accentGreen),
                        const SizedBox(width: 8),
                        _statCard('Pengguna', '$_totalPengguna', Icons.people, AppColors.info),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Pelanggan Check-in Section
                    Text('Pelanggan Sedang Check-in', style: AppTextStyles.heading.copyWith(fontSize: 18)),
                    const SizedBox(height: 12),
                    
                    if (_pelangganCheckin.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('Tidak ada tamu yang sedang check-in.', style: TextStyle(color: AppColors.textMuted)),
                          ),
                        ),
                      )
                    else
                      ..._pelangganCheckin.map((p) => Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      p.user?.name ?? 'Tamu', 
                                      style: AppTextStyles.heading.copyWith(fontSize: 16),
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    Helpers.formatRupiah(p.totalHarga),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 16),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${p.kamar?.tipeKamar?.namaTipeKamar ?? '-'} | Kamar No. ${p.kamar?.nomorKamar ?? '-'}',
                                      style: const TextStyle(color: AppColors.textMedium, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.people, size: 14, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Text('${p.jumlahTamu} Tamu', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: 16),

                              Row(
                                children: [
                                  const Icon(Icons.login, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('In: ${Helpers.formatTanggalPendek(p.checkInDate)}', style: const TextStyle(fontSize: 13)),
                                  const SizedBox(width: 16),
                                  const Icon(Icons.logout, size: 16, color: Colors.grey),
                                  const SizedBox(width: 6),
                                  Text('Out: ${Helpers.formatTanggalPendek(p.checkOutDate)}', style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                              const SizedBox(height: 12),

                              const Text('Fasilitas Tambahan:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              if (p.fasilitas.isEmpty)
                                const Text('- Tidak ada', style: TextStyle(fontSize: 13, color: Colors.grey))
                              else
                                ...p.fasilitas.map((f) => Text('• ${f.namaFasilitas}', style: const TextStyle(fontSize: 13, color: Colors.grey))),
                              
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final result = await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => AdminPemesananForm(pemesanan: p)),
                                      );
                                      if (result == true) {
                                        _loadDashboard();
                                      }
                                    },
                                    icon: const Icon(Icons.add_circle_outline, size: 18),
                                    label: const Text('Fasilitas', style: TextStyle(fontSize: 13)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton.icon(
                                    onPressed: () => _prosesCheckout(p.idPemesanan),
                                    icon: const Icon(Icons.logout, size: 18),
                                    label: const Text('Checkout', style: TextStyle(fontSize: 13)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.accentGreen,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      minimumSize: Size.zero,
                                      elevation: 0,
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      )),
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
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, color: color, size: 36),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
              ),
              const SizedBox(height: 4),
              Text(title, style: AppTextStyles.body.copyWith(fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}