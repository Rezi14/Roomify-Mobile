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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            SizedBox(width: 8),
            Text('Batalkan Pesanan?', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin membatalkan pesanan ini? Tindakan ini tidak dapat dikembalikan.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tidak, Kembali', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    // Gunakan background yang sedikit abu-abu agar Card putih lebih menonjol
    return Scaffold(
      backgroundColor: Colors.grey[50], 
      appBar: AppBar(
        title: const Text('Detail Pesanan', style: TextStyle(fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _order == null
              ? _buildEmptyState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeaderCard(),
                      const SizedBox(height: 16),
                      _buildRoomInfoCard(),
                      const SizedBox(height: 16),
                      if (_order!.fasilitas.isNotEmpty) ...[
                        _buildFacilitiesCard(),
                        const SizedBox(height: 16),
                      ],
                      _buildPaymentSummaryCard(),
                    ],
                  ),
                ),
      // Sticky Bottom Buttons
      bottomNavigationBar: (_order != null && _order!.statusPemesanan.toLowerCase() == 'pending') 
          ? _buildBottomActions() 
          : null,
    );
  }

  // --- WIDGET BUILDERS UNTUK UI YANG LEBIH RAPI ---

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('Data pesanan tidak ditemukan.', style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ID Pesanan', style: TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text('#${_order!.idPemesanan}', style: AppTextStyles.heading.copyWith(fontSize: 18)),
            ],
          ),
          OrderStatusBadge(status: _order!.statusPemesanan),
        ],
      ),
    );
  }

  Widget _buildRoomInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Informasi Menginap', style: AppTextStyles.heading.copyWith(fontSize: 16)),
          const Divider(height: 32, color: Colors.black12),
          _iconRow(Icons.king_bed_rounded, 'Tipe Kamar', _order!.kamar?.tipeKamar?.namaTipeKamar ?? '-'),
          const SizedBox(height: 16),
          _iconRow(Icons.meeting_room_rounded, 'No. Kamar', _order!.kamar?.nomorKamar ?? '-'),
          const SizedBox(height: 16),
          _iconRow(Icons.login_rounded, 'Check-in', Helpers.formatTanggal(_order!.checkInDate)),
          const SizedBox(height: 16),
          _iconRow(Icons.logout_rounded, 'Check-out', Helpers.formatTanggal(_order!.checkOutDate)),
          const SizedBox(height: 16),
          _iconRow(Icons.people_alt_rounded, 'Jumlah Tamu', '${_order!.jumlahTamu} orang'),
        ],
      ),
    );
  }

  Widget _buildFacilitiesCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Fasilitas Tambahan', style: AppTextStyles.heading.copyWith(fontSize: 16)),
          const SizedBox(height: 16),
          ..._order!.fasilitas.map((f) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.star_rounded, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(f.namaFasilitas, style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w500)),
                ),
                Text(
                  Helpers.formatRupiah(f.pivotTotalHargaFasilitas ?? f.biayaTambahan),
                  style: AppTextStyles.body.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildPaymentSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Total Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 14)),
              const SizedBox(height: 4),
              Text(
                Helpers.formatRupiah(_order!.totalHarga),
                style: AppTextStyles.heading.copyWith(fontSize: 22, color: AppColors.primary),
              ),
            ],
          ),
          Icon(Icons.account_balance_wallet_rounded, color: AppColors.primary.withOpacity(0.2), size: 40),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 0.5),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _cancelOrder,
                child: const Text(
                  'BATALKAN PESANAN',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget untuk baris berikon
  Widget _iconRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[500]),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const Spacer(),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}