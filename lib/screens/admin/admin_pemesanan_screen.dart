import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/pemesanan_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/order_status_badge.dart';

class AdminPemesananScreen extends StatefulWidget {
  const AdminPemesananScreen({super.key});
  @override
  State<AdminPemesananScreen> createState() => _AdminPemesananScreenState();
}

class _AdminPemesananScreenState extends State<AdminPemesananScreen> {
  final _adminService = AdminService();
  List<PemesananModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _items = await _adminService.getPemesanans();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _goToDetail(PemesananModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminPemesananDetailScreen(pemesanan: p)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Pemesanan'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Riwayat Lunas/Batal',
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminRiwayatPemesananScreen()));
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final p = _items[i];
                  return Card(
                    child: ListTile(
                      onTap: () => _goToDetail(p),
                      title: Text(p.user?.name ?? 'User #${p.userId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        'Kamar ${p.kamar?.nomorKamar ?? '-'} | ${Helpers.formatTanggalPendek(p.checkInDate)} - ${Helpers.formatTanggalPendek(p.checkOutDate)}',
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          OrderStatusBadge(status: p.statusPemesanan),
                          const SizedBox(height: 4),
                          Text(Helpers.formatRupiah(p.totalHarga), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

// ========================================================
// Halaman Detail & Aksi
// ========================================================
class AdminPemesananDetailScreen extends StatefulWidget {
  final PemesananModel pemesanan;
  const AdminPemesananDetailScreen({super.key, required this.pemesanan});

  @override
  State<AdminPemesananDetailScreen> createState() => _AdminPemesananDetailScreenState();
}

class _AdminPemesananDetailScreenState extends State<AdminPemesananDetailScreen> {
  final _adminService = AdminService();
  late PemesananModel _p;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _p = widget.pemesanan;
  }

  Future<void> _updateStatus(String action) async {
    setState(() => _isProcessing = true);
    Map<String, dynamic> result;
    
    try {
      if (action == 'confirm') {
        result = await _adminService.confirmPemesanan(_p.idPemesanan);
      } else if (action == 'checkin') {
        result = await _adminService.checkInPemesanan(_p.idPemesanan);
      } else if (action == 'checkout') {
        result = await _adminService.checkOutPemesanan(_p.idPemesanan);
      } else {
        throw Exception('Aksi tidak valid');
      }

      if (mounted) {
        Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
        if (result['success'] == true) {
          Navigator.pop(context, true); // Refresh list
        }
      }
    } catch (e) {
      if (mounted) Helpers.showSnackBar(context, 'Terjadi kesalahan', isError: true);
    }
    setState(() => _isProcessing = false);
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Pemesanan?'),
        content: const Text('Tindakan ini tidak bisa dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
        ],
      ),
    );
    if (confirm == true) {
      setState(() => _isProcessing = true);
      final r = await _adminService.deletePemesanan(_p.idPemesanan);
      setState(() => _isProcessing = false);
      if (mounted) {
        Helpers.showSnackBar(context, r['message'], isError: r['success'] != true);
        if (r['success'] == true) Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Detail Pesanan #${_p.idPemesanan}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status Saat Ini:', style: TextStyle(fontWeight: FontWeight.bold)),
                        OrderStatusBadge(status: _p.statusPemesanan),
                      ],
                    ),
                    const Divider(height: 24),
                    _row('Nama Pemesan', _p.user?.name ?? '-'),
                    _row('Email', _p.user?.email ?? '-'),
                    const Divider(height: 24),
                    _row('Kamar', _p.kamar?.tipeKamar?.namaTipeKamar ?? '-'),
                    _row('No. Kamar', _p.kamar?.nomorKamar ?? '-'),
                    _row('Tamu', '${_p.jumlahTamu} orang'),
                    _row('Check-In', Helpers.formatTanggal(_p.checkInDate)),
                    _row('Check-Out', Helpers.formatTanggal(_p.checkOutDate)),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(Helpers.formatRupiah(_p.totalHarga),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            if (_isProcessing)
              const Center(child: CircularProgressIndicator())
            else ...[
              if (_p.isPending)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Konfirmasi Pembayaran'),
                    onPressed: () => _updateStatus('confirm'),
                  ),
                ),
              
              if (_p.isConfirmed)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
                    icon: const Icon(Icons.login),
                    label: const Text('Proses Check-In Tamu'),
                    onPressed: () => _updateStatus('checkin'),
                  ),
                ),
              
              if (_p.isCheckedIn)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
                    icon: const Icon(Icons.logout),
                    label: const Text('Proses Check-Out (Selesai)'),
                    onPressed: () => _updateStatus('checkout'),
                  ),
                ),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                  icon: const Icon(Icons.delete),
                  label: const Text('Hapus Data Pesanan'),
                  onPressed: _delete,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ========================================================
// Halaman Riwayat Pemesanan (Selesai/Lunas & Batal)
// ========================================================
class AdminRiwayatPemesananScreen extends StatefulWidget {
  const AdminRiwayatPemesananScreen({super.key});
  @override
  State<AdminRiwayatPemesananScreen> createState() => _AdminRiwayatPemesananScreenState();
}

class _AdminRiwayatPemesananScreenState extends State<AdminRiwayatPemesananScreen> {
  final _adminService = AdminService();
  List<PemesananModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _items = await _adminService.getRiwayatPemesanan();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Transaksi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final p = _items[i];
                  return Card(
                    color: Colors.grey.shade100,
                    child: ListTile(
                      title: Text(p.user?.name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Kamar ${p.kamar?.nomorKamar ?? '-'} | Tgl: ${Helpers.formatTanggalPendek(p.checkInDate)}'),
                      trailing: OrderStatusBadge(status: p.statusPemesanan),
                    ),
                  );
                },
              ),
            ),
    );
  }
}