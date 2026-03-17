import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../services/profile_service.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/order_status_badge.dart';
import 'order_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _profileService = ProfileService();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Ambil data pertama kali saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BookingProvider>(context, listen: false).fetchOrders();
    });

    // Jalankan timer untuk polling (tarik data diam-diam) setiap 5 detik
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        Provider.of<BookingProvider>(context, listen: false).fetchOrders();
      }
    });
  }

  @override
  void dispose() {
    // WAJIB dimatikan agar tidak bocor di memori saat pindah menu
    _timer?.cancel();
    super.dispose();
  }

  void _showEditProfileDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: auth.user?.name);
    final emailCtrl = TextEditingController(text: auth.user?.email);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nama')),
            const SizedBox(height: 12),
            TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final result = await _profileService.updateProfile(nameCtrl.text, emailCtrl.text);
              if (mounted) {
                Navigator.pop(context);
                Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
                if (result['success'] == true) auth.refreshUser();
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog() {
    final curCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ubah Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: curCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Lama')),
            const SizedBox(height: 12),
            TextField(controller: newCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'Password Baru')),
            const SizedBox(height: 12),
            TextField(controller: confCtrl, obscureText: true,
                decoration: const InputDecoration(labelText: 'Konfirmasi Password Baru')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final result = await _profileService.updatePassword(
                  curCtrl.text, newCtrl.text, confCtrl.text);
              if (mounted) {
                Navigator.pop(context);
                Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
              }
            },
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
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
        content: const Text('Apakah Anda yakin ingin keluar dari akun Anda?'),
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
      
      // Tampilkan loading sebentar agar transisi lebih halus
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      await Provider.of<AuthProvider>(context, listen: false).logout();
      
      if (!mounted) return;
      // Hapus semua rute dan kembali ke layar awal
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }
  // --------------------------------

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final booking = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil Saya'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            // Panggil fungsi konfirmasi yang baru saja dibuat
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- INFO USER ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                        radius: 40, 
                        backgroundColor: AppColors.primary,
                        child: Text(auth.user?.name.substring(0, 1).toUpperCase() ?? '?',
                            style: const TextStyle(fontSize: 32, color: Colors.white))),
                    const SizedBox(height: 12),
                    Text(auth.user?.name ?? '', style: AppTextStyles.heading.copyWith(fontSize: 20)),
                    Text(auth.user?.email ?? '', style: AppTextStyles.body),
                    Text(auth.user?.role?.namaRole ?? '', style: AppTextStyles.body.copyWith(color: AppColors.primary)),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(onPressed: _showEditProfileDialog, child: const Text('Edit Profil')),
                        const SizedBox(width: 12),
                        OutlinedButton(onPressed: _showChangePasswordDialog, child: const Text('Ubah Password')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // --- RIWAYAT PESANAN ---
            Text('Riwayat Pesanan', style: AppTextStyles.heading.copyWith(fontSize: 18)),
            const SizedBox(height: 8),

            // Kondisi ini mencegah layar berkedip saat polling Real-Time berjalan
            if (booking.isLoading && booking.orders.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (booking.orders.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(32),
                  child: Text('Belum ada pesanan.', style: TextStyle(color: AppColors.textMuted))))
            else
              ...booking.orders.map((order) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.idPemesanan)),
                      ).then((_) {
                        // Tarik data ulang saat user menekan kembali (Back) dari Order Detail
                        Provider.of<BookingProvider>(context, listen: false).fetchOrders();
                      }),
                      title: Text(order.kamar?.tipeKamar?.namaTipeKamar ?? 'Kamar ${order.kamarId}'),
                      subtitle: Text(
                          '${Helpers.formatTanggalPendek(order.checkInDate)} - ${Helpers.formatTanggalPendek(order.checkOutDate)}'),
                      trailing: OrderStatusBadge(status: order.statusPemesanan),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}