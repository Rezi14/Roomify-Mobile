import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../models/pemesanan_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class PaymentScreen extends StatefulWidget {
  final int pemesananId;

  const PaymentScreen({super.key, required this.pemesananId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _bookingService = BookingService();
  PemesananModel? _pemesanan;
  bool _isLoading = true;
  bool _isSimulating = false; // State untuk loading tombol simulasi
  int _sisaDetik = 0;
  Timer? _countdownTimer;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _loadPayment();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPayment() async {
    final result = await _bookingService.getPaymentData(widget.pemesananId);

    if (result['success'] == true) {
      setState(() {
        _pemesanan = result['pemesanan'];
        _sisaDetik = int.tryParse(result['sisa_detik'].toString()) ?? 0;
        _isLoading = false;
      });
      _startCountdown();
      _startPolling();
    } else {
      if (mounted) {
        Helpers.showSnackBar(context, result['message'] ?? 'Expired.', isError: true);
        Navigator.pop(context);
      }
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (_sisaDetik > 0) {
        setState(() => _sisaDetik--);
      } else {
        _countdownTimer?.cancel();
        _pollTimer?.cancel();
        
        await _bookingService.cancelBooking(widget.pemesananId);

        if (mounted) {
          Helpers.showSnackBar(context, 'Waktu habis! Pesanan otomatis dibatalkan.', isError: true);
          Navigator.pop(context);
        }
      }
    });
  }

  void _startPolling() {
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final status = await _bookingService.checkPaymentStatus(widget.pemesananId);
      if (status == 'success' && mounted) {
        _countdownTimer?.cancel();
        _pollTimer?.cancel();
        Helpers.showSnackBar(context, 'Pembayaran berhasil!');
        Navigator.pop(context);
      } else if (status == 'expired' && mounted) {
        _countdownTimer?.cancel();
        _pollTimer?.cancel();
        Helpers.showSnackBar(context, 'Pesanan kedaluwarsa.', isError: true);
        Navigator.pop(context);
      }
    });
  }

  Future<void> _cancelBooking() async {
    final result = await _bookingService.cancelBooking(widget.pemesananId);
    if (mounted) {
      Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
      if (result['success'] == true) Navigator.pop(context);
    }
  }

  // --- FUNGSI SIMULASI QR CODE ---
  Future<void> _simulateQRPayment() async {
    setState(() => _isSimulating = true);
    final result = await _bookingService.simulateQRPayment(widget.pemesananId);
    setState(() => _isSimulating = false);

    if (result['success'] == true && mounted) {
      _countdownTimer?.cancel();
      _pollTimer?.cancel();
      Helpers.showSnackBar(context, 'Pembayaran Diterima! Pesanan dikonfirmasi.', isError: false);
      Navigator.pop(context);
    } else if (mounted) {
      Helpers.showSnackBar(context, result['message'] ?? 'Simulasi Gagal', isError: true);
    }
  }

  String get _timerText {
    final m = (_sisaDetik ~/ 60).toString().padLeft(2, '0');
    final s = (_sisaDetik % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Timer Hitung Mundur
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _sisaDetik < 60 ? AppColors.danger.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Text('Sisa Waktu Pembayaran', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Text(_timerText,
                      style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: _sisaDetik < 60 ? AppColors.danger : AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // --- BOX DUMMY QR CODE ---
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text('Scan QRIS untuk Membayar', style: AppTextStyles.heading.copyWith(fontSize: 16)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.borderColor, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.qr_code_2, size: 160, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSimulating 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.check_circle_outline),
                        label: Text(_isSimulating ? 'Memproses...' : 'Simulasikan Pembayaran'),
                        onPressed: _isSimulating ? null : _simulateQRPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // ---------------------------

            // Detail Pesanan
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow('Kamar', _pemesanan?.kamar?.tipeKamar?.namaTipeKamar ?? '-'),
                    _detailRow('No. Kamar', _pemesanan?.kamar?.nomorKamar ?? '-'),
                    _detailRow('Check-in', Helpers.formatTanggal(_pemesanan?.checkInDate)),
                    _detailRow('Check-out', Helpers.formatTanggal(_pemesanan?.checkOutDate)),
                    _detailRow('Tamu', '${_pemesanan?.jumlahTamu ?? 0} orang'),
                    const Divider(),
                    _detailRow('Total', Helpers.formatRupiah(_pemesanan?.totalHarga ?? 0), isBold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Batalkan
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.danger,
                  side: const BorderSide(color: AppColors.danger),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: _cancelBooking,
                child: const Text('Batalkan Pesanan', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles.body),
          Text(value,
              style: isBold
                  ? AppTextStyles.heading.copyWith(fontSize: 16, color: AppColors.primary)
                  : AppTextStyles.label.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}