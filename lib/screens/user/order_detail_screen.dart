import 'dart:async'; // WAJIB DITAMBAHKAN
import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../services/booking_service.dart';
import '../../models/pemesanan_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/order_status_badge.dart';
import 'payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _profileService = ProfileService();
  final _bookingService = BookingService();
  PemesananModel? _order;
  bool _isLoading = true;
  Timer? _timer; // WAJIB DITAMBAHKAN

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel(); // Pastikan timer dimatikan agar tidak memory leak
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    await _fetchDataSilent(); // Ambil data pertama kali
    setState(() => _isLoading = false);

    // Jika statusnya pending, mulai fungsi Real-Time (Polling)
    if (_order?.statusPemesanan.toLowerCase() == 'pending') {
      _startRealTimeUpdate();
    }
  }

  // Fungsi untuk menarik data tanpa memunculkan loading screen (Diam-diam)
  Future<void> _fetchDataSilent() async {
    try {
      final data = await _profileService.getOrderDetail(widget.orderId);
      if (mounted) {
        setState(() {
          _order = data;
        });
      }
    } catch (_) {}
  }

  // Fungsi Timer Real-Time
  void _startRealTimeUpdate() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _fetchDataSilent();
      
      // Jika pesanan tiba-tiba dibatalkan dari server, matikan timer!
      if (_order != null && _order!.statusPemesanan.toLowerCase() != 'pending') {
        timer.cancel();
      }
    });
  }

  Future<void> _cancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger),
            SizedBox(width: 8),
            Text('Batalkan Pesanan?'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dikembalikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak, Kembali', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      final result = await _bookingService.cancelBooking(widget.orderId);
      
      if (mounted) {
        Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
        _load(); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pesanan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? const Center(child: Text('Data tidak ditemukan.'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Pesanan #${_order!.idPemesanan}',
                                      style: AppTextStyles.heading.copyWith(fontSize: 18)),
                                  OrderStatusBadge(status: _order!.statusPemesanan),
                                ],
                              ),
                              const Divider(height: 24),
                              _row('Kamar', _order!.kamar?.tipeKamar?.namaTipeKamar ?? '-'),
                              _row('No. Kamar', _order!.kamar?.nomorKamar ?? '-'),
                              _row('Check-in', Helpers.formatTanggal(_order!.checkInDate)),
                              _row('Check-out', Helpers.formatTanggal(_order!.checkOutDate)),
                              _row('Tamu', '${_order!.jumlahTamu} orang'),
                              if (_order!.fasilitas.isNotEmpty) ...[
                                const Divider(height: 24),
                                Text('Fasilitas Tambahan:', style: AppTextStyles.label),
                                const SizedBox(height: 8),
                                ..._order!.fasilitas.map((f) => Padding(
                                      padding: const EdgeInsets.only(bottom: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('• ${f.namaFasilitas}', style: AppTextStyles.body),
                                          Text(Helpers.formatRupiah(f.pivotTotalHargaFasilitas ?? f.biayaTambahan),
                                              style: AppTextStyles.body),
                                        ],
                                      ),
                                    )),
                              ],
                              const Divider(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                                  Text(Helpers.formatRupiah(_order!.totalHarga),
                                      style: AppTextStyles.heading.copyWith(fontSize: 20, color: AppColors.primary)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 24),

                      // TOMBOL OTOMATIS HILANG JIKA BUKAN PENDING
                      if (_order!.statusPemesanan.toLowerCase() == 'pending') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentScreen(pemesananId: _order!.idPemesanan),
                                ),
                              ).then((_) => _load());
                            },
                            child: const Text(
                              'LANJUTKAN PEMBAYARAN',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 12),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.danger,
                              side: const BorderSide(color: AppColors.danger),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _cancelOrder,
                            child: const Text(
                              'BATALKAN PESANAN',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value, style: AppTextStyles.label.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}