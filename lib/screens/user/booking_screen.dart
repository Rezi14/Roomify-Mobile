import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../models/kamar_model.dart';
import '../../models/fasilitas_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final int kamarId;

  const BookingScreen({super.key, required this.kamarId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _bookingService = BookingService();
  bool _isLoading = true;
  bool _isSubmitting = false;
  KamarModel? _kamar;
  int _maxTamu = 1;
  List<FasilitasModel> _fasilitasTersedia = [];
  final List<int> _selectedFasilitas = [];

  DateTime? _checkIn;
  DateTime? _checkOut;
  int _jumlahTamu = 1;

  @override
  void initState() {
    super.initState();
    _loadForm();
  }

  Future<void> _loadForm() async {
    try {
      final result = await _bookingService.getBookingForm(widget.kamarId);
      if (result['success'] == true) {
        setState(() {
          _kamar = result['kamar'];
          _maxTamu = result['max_tamu'];
          _fasilitasTersedia = result['fasilitas_tersedia'];
          _isLoading = false;
        });
      } else {
        if (mounted) {
          Helpers.showSnackBar(context, result['message'], isError: true);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        Helpers.showSnackBar(context, 'Gagal memuat data.', isError: true);
        Navigator.pop(context);
      }
    }
  }

  double get _totalHarga {
    if (_kamar == null || _checkIn == null || _checkOut == null) return 0;
    final durasi = _checkOut!.difference(_checkIn!).inDays;
    if (durasi <= 0) return 0;

    double total = (_kamar!.tipeKamar?.hargaPerMalam ?? 0) * durasi;

    for (final id in _selectedFasilitas) {
      final f = _fasilitasTersedia.firstWhere(
        (f) => f.idFasilitas == id,
        orElse: () => FasilitasModel(idFasilitas: 0, namaFasilitas: ''),
      );
      total += f.biayaTambahan;
    }

    return total;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (_checkIn == null || _checkOut == null) {
      Helpers.showSnackBar(context, 'Pilih tanggal check-in dan check-out.', isError: true);
      return;
    }
    if (_checkOut!.isBefore(_checkIn!) || _checkOut!.isAtSameMomentAs(_checkIn!)) {
      Helpers.showSnackBar(context, 'Tanggal check-out harus setelah check-in.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _bookingService.createBooking(
      kamarId: widget.kamarId,
      checkInDate: _formatDate(_checkIn!),
      checkOutDate: _formatDate(_checkOut!),
      jumlahTamu: _jumlahTamu,
      fasilitasIds: _selectedFasilitas.isNotEmpty ? _selectedFasilitas : null,
    );

    setState(() => _isSubmitting = false);

    if (result['success'] == true && mounted) {
      final pemesanan = result['pemesanan'];
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentScreen(pemesananId: pemesanan.idPemesanan),
        ),
      );
    } else if (mounted) {
      Helpers.showSnackBar(context, result['message'] ?? 'Gagal.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tipe = _kamar?.tipeKamar;

    return Scaffold(
      appBar: AppBar(title: const Text('Pemesanan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto Kamar
            if (tipe?.fullFotoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(tipe!.fullFotoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),

            // Detail Kamar
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(tipe?.namaTipeKamar ?? '', style: AppTextStyles.heading.copyWith(fontSize: 20)),
                    Text('Kamar No. ${_kamar?.nomorKamar ?? '-'}', style: AppTextStyles.body),
                    const SizedBox(height: 8),
                    Text(Helpers.formatRupiah(tipe?.hargaPerMalam ?? 0) + ' /malam',
                        style: AppTextStyles.heading.copyWith(color: AppColors.primary, fontSize: 18)),
                    Text('Maks $_maxTamu tamu', style: AppTextStyles.body),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Form Booking
            Text('Tanggal Check-in', style: AppTextStyles.label),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                    context: context, initialDate: DateTime.now(),
                    firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setState(() => _checkIn = d);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor), borderRadius: BorderRadius.circular(10)),
                child: Text(_checkIn != null ? _formatDate(_checkIn!) : 'Pilih tanggal'),
              ),
            ),
            const SizedBox(height: 12),

            Text('Tanggal Check-out', style: AppTextStyles.label),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                    context: context, initialDate: _checkIn?.add(const Duration(days: 1)) ?? DateTime.now(),
                    firstDate: _checkIn?.add(const Duration(days: 1)) ?? DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)));
                if (d != null) setState(() => _checkOut = d);
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    border: Border.all(color: AppColors.borderColor), borderRadius: BorderRadius.circular(10)),
                child: Text(_checkOut != null ? _formatDate(_checkOut!) : 'Pilih tanggal'),
              ),
            ),
            const SizedBox(height: 12),

            // Jumlah Tamu
            Text('Jumlah Tamu (Maks: $_maxTamu)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _jumlahTamu > 1 ? () => setState(() => _jumlahTamu--) : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text('$_jumlahTamu', style: AppTextStyles.heading.copyWith(fontSize: 20)),
                IconButton(
                  onPressed: _jumlahTamu < _maxTamu ? () => setState(() => _jumlahTamu++) : null,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Fasilitas Tambahan
            if (_fasilitasTersedia.isNotEmpty) ...[
              Text('Fasilitas Tambahan (Opsional)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              ...List.generate(_fasilitasTersedia.length, (i) {
                final f = _fasilitasTersedia[i];
                final isSelected = _selectedFasilitas.contains(f.idFasilitas);
                return CheckboxListTile(
                  title: Text(f.namaFasilitas),
                  subtitle: Text(Helpers.formatRupiah(f.biayaTambahan)),
                  value: isSelected,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedFasilitas.add(f.idFasilitas);
                      } else {
                        _selectedFasilitas.remove(f.idFasilitas);
                      }
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                );
              }),
              const SizedBox(height: 16),
            ],

            // Total Harga
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Harga:', style: AppTextStyles.label.copyWith(fontSize: 16)),
                  Text(Helpers.formatRupiah(_totalHarga),
                      style: AppTextStyles.heading.copyWith(fontSize: 22, color: AppColors.primary)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Tombol Submit
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('PESAN SEKARANG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}