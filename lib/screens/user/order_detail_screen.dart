import 'package:flutter/material.dart';
import '../../services/profile_service.dart';
import '../../models/pemesanan_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/order_status_badge.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _profileService = ProfileService();
  PemesananModel? _order;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _order = await _profileService.getOrderDetail(widget.orderId);
    } catch (_) {}
    setState(() => _isLoading = false);
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
                  child: Card(
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