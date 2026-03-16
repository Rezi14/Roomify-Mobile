import 'package:flutter/material.dart';
import '../../services/booking_service.dart';
import '../../services/auth_service.dart';
import '../../models/kamar_model.dart';
import '../../models/fasilitas_model.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'payment_screen.dart';

class BookingScreen extends StatefulWidget {
  final int kamarId;
  final String? initialCheckIn;
  final String? initialCheckOut;

  const BookingScreen({
    super.key,
    required this.kamarId,
    this.initialCheckIn,
    this.initialCheckOut,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _bookingService = BookingService();
  final _authService = AuthService();
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isResending = false;
  bool _isEmailVerified = false; // State baru untuk menyimpan status verifikasi

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
    if (widget.initialCheckIn != null) _checkIn = DateTime.tryParse(widget.initialCheckIn!);
    if (widget.initialCheckOut != null) _checkOut = DateTime.tryParse(widget.initialCheckOut!);
    _loadForm();
  }

  Future<void> _loadForm() async {
    try {
      // Tarik data kamar & data profil user terbaru secara bersamaan
      final result = await _bookingService.getBookingForm(widget.kamarId);
      final currentUser = await _authService.getUser(); 

      if (result['success'] == true) {
        setState(() {
          _kamar = result['kamar'];
          _maxTamu = result['max_tamu'];
          _fasilitasTersedia = result['fasilitas_tersedia'];
          _isEmailVerified = currentUser?.isEmailVerified ?? false; // Update status verifikasi
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

  // Fungsi untuk menarik ulang data verifikasi (jika tamu sudah klik link di browser)
  Future<void> _checkVerification() async {
    setState(() => _isLoading = true);
    final currentUser = await _authService.getUser();
    setState(() {
      _isEmailVerified = currentUser?.isEmailVerified ?? false;
      _isLoading = false;
    });
    
    if (mounted) {
      if (_isEmailVerified) {
        Helpers.showSnackBar(context, 'Akun berhasil diverifikasi! Silakan lanjutkan pesanan.');
      } else {
        Helpers.showSnackBar(context, 'Akun masih belum diverifikasi.', isError: true);
      }
    }
  }

  // Fungsi untuk mengirim ulang email
  Future<void> _resendEmail() async {
    setState(() => _isResending = true);
    final result = await _authService.resendVerification();
    setState(() => _isResending = false);
    
    if (mounted) {
      Helpers.showSnackBar(context, result['message'], isError: !result['success']);
    }
  }

  double get _totalHarga {
    if (_kamar == null || _checkIn == null || _checkOut == null) return 0;
    final durasi = _checkOut!.difference(_checkIn!).inDays;
    final malam = durasi > 0 ? durasi : 1;

    double total = (_kamar!.tipeKamar?.hargaPerMalam ?? 0) * malam;

    for (final id in _selectedFasilitas) {
      final f = _fasilitasTersedia.firstWhere(
        (f) => f.idFasilitas == id,
        orElse: () => FasilitasModel(idFasilitas: 0, namaFasilitas: ''),
      );
      total += (f.biayaTambahan * malam); 
    }

    return total;
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _submit() async {
    if (!_isEmailVerified) return; // Keamanan ganda

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
      Helpers.showSnackBar(context, result['message'] ?? 'Gagal membuat pesanan.', isError: true);
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
            if (tipe?.fullFotoUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(tipe!.fullFotoUrl!, height: 200, width: double.infinity, fit: BoxFit.cover),
              ),
            const SizedBox(height: 16),

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
                    Text('${Helpers.formatRupiah(tipe?.hargaPerMalam ?? 0)} /malam',
                        style: AppTextStyles.heading.copyWith(color: AppColors.primary, fontSize: 18)),
                    Text('Maks $_maxTamu tamu', style: AppTextStyles.body),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text('Tanggal Check-in', style: AppTextStyles.label),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final d = await showDatePicker(
                    context: context, 
                    initialDate: _checkIn ?? DateTime.now(),
                    firstDate: DateTime.now(), 
                    lastDate: DateTime.now().add(const Duration(days: 180))); 
                if (d != null) {
                  setState(() {
                    _checkIn = d;
                    if (_checkOut != null) {
                       final diff = _checkOut!.difference(d).inDays;
                       if (diff <= 0 || diff > 30) {
                         _checkOut = d.add(const Duration(days: 1));
                       }
                    }
                  });
                }
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
                if (_checkIn == null) {
                   Helpers.showSnackBar(context, 'Pilih tanggal check-in terlebih dahulu.', isError: true);
                   return;
                }
                final d = await showDatePicker(
                    context: context, 
                    initialDate: _checkOut ?? _checkIn!.add(const Duration(days: 1)),
                    firstDate: _checkIn!.add(const Duration(days: 1)),
                    lastDate: _checkIn!.add(const Duration(days: 30))); 
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

            Text('Jumlah Tamu (Maks: $_maxTamu)', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _jumlahTamu > 1 ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _jumlahTamu > 1 ? () => setState(() => _jumlahTamu--) : null,
                    icon: Icon(Icons.remove, color: _jumlahTamu > 1 ? AppColors.primary : Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Text('$_jumlahTamu', style: AppTextStyles.heading.copyWith(fontSize: 20)),
                const SizedBox(width: 16),
                Container(
                  decoration: BoxDecoration(
                    color: _jumlahTamu < _maxTamu ? AppColors.primary.withOpacity(0.1) : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    onPressed: _jumlahTamu < _maxTamu ? () => setState(() => _jumlahTamu++) : null,
                    icon: Icon(Icons.add, color: _jumlahTamu < _maxTamu ? AppColors.primary : Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_fasilitasTersedia.isNotEmpty) ...[
              Text('Fasilitas Tambahan (Opsional)', style: AppTextStyles.label),
              const SizedBox(height: 8),
              ...List.generate(_fasilitasTersedia.length, (i) {
                final f = _fasilitasTersedia[i];
                final isSelected = _selectedFasilitas.contains(f.idFasilitas);
                return CheckboxListTile(
                  title: Text(f.namaFasilitas),
                  subtitle: Text('${Helpers.formatRupiah(f.biayaTambahan)} /malam'),
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
                  contentPadding: EdgeInsets.zero,
                );
              }),
              const SizedBox(height: 16),
            ],

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

            // --- TAMBAHAN: Box Peringatan jika belum verifikasi ---
            if (!_isEmailVerified) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  border: Border.all(color: AppColors.warning),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 36),
                    const SizedBox(height: 8),
                    Text(
                      'Akun Belum Diverifikasi',
                      style: AppTextStyles.label.copyWith(color: Colors.orange[800], fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Silakan cek kotak masuk atau spam email Anda untuk melakukan verifikasi agar dapat memesan kamar.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.warning,
                            foregroundColor: Colors.white,
                            elevation: 0,
                          ),
                          onPressed: _isResending ? null : _resendEmail,
                          icon: _isResending 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.send, size: 18),
                          label: const Text('Kirim Ulang Email'),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          tooltip: 'Muat ulang status verifikasi',
                          icon: const Icon(Icons.refresh, color: AppColors.warning),
                          onPressed: _checkVerification,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            // -----------------------------------------------------

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  // Jika belum diverifikasi, tombol menjadi abu-abu
                  backgroundColor: _isEmailVerified ? AppColors.primary : Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                // Tombol tidak bisa diklik jika isEmailVerified == false
                onPressed: (_isSubmitting || !_isEmailVerified) ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24, width: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : const Text('PESAN SEKARANG', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}