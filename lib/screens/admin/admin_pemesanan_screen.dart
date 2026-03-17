import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/pemesanan_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';
import '../../widgets/order_status_badge.dart';
import '../../models/kamar_model.dart';
import '../../models/fasilitas_model.dart';
import '../../models/user_model.dart';

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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminPemesananCreateForm()),
          );
          if (result == true) {
            _load(); // Refresh jika berhasil buat pesanan
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat Pesanan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Future<void> _loadDetail() async {
    try {
      final updatedPemesanan = await _adminService.getPemesananDetail(_p.idPemesanan);
      setState(() {
        _p = updatedPemesanan;
      });
    } catch (_) {}
  }

  void _goToEdit() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminPemesananForm(pemesanan: _p)),
    );

    if (result == true) {
      _loadDetail();
    }
  }

  // --- FUNGSI POPUP KONFIRMASI CHECK-IN ---
  Future<void> _confirmCheckIn() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.login, color: AppColors.info),
            SizedBox(width: 8),
            Text('Proses Check-In?'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin memproses check-in untuk pesanan ini? Pastikan tamu telah tiba.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.info),
            child: const Text('Ya, Check-In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _updateStatus('checkin');
    }
  }
  // ----------------------------------------

  // --- FUNGSI POPUP KONFIRMASI CHECK-OUT ---
  Future<void> _confirmCheckout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.accentGreen),
            SizedBox(width: 8),
            Text('Proses Checkout?'),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin melakukan proses check-out untuk pesanan ini? Pastikan semua tagihan telah diselesaikan.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false), 
            child: const Text('Batal', style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
            child: const Text('Ya, Checkout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      _updateStatus('checkout');
    }
  }
  // ----------------------------------------

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
          Navigator.pop(context, true); 
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
        content: const Text('Apakah Anda yakin ingin menghapus pemesanan ini? Tindakan ini tidak dapat dibatalkan.'),
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
      appBar: AppBar(
        title: Text('Detail Pesanan #${_p.idPemesanan}'),
        actions: [
          if (_p.isPending || _p.isConfirmed || _p.isCheckedIn)
            IconButton(
              icon: const Icon(Icons.edit_note_rounded),
              tooltip: 'Edit Pesanan',
              onPressed: _goToEdit,
            ),
        ],
      ),
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
                    if (_p.fasilitas.isNotEmpty) ...[
                      const Divider(height: 24),
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Fasilitas Tambahan:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      ..._p.fasilitas.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('• ${f.namaFasilitas}', style: const TextStyle(color: Colors.grey)),
                            Text(Helpers.formatRupiah(f.pivotTotalHargaFasilitas ?? f.biayaTambahan)),
                          ],
                        ),
                      )),
                    ],
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
                    // --- MENGGUNAKAN FUNGSI KONFIRMASI CHECK-IN ---
                    onPressed: _confirmCheckIn,
                  ),
                ),
              
              if (_p.isCheckedIn)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGreen),
                    icon: const Icon(Icons.logout),
                    label: const Text('Proses Check-Out (Selesai)'),
                    onPressed: _confirmCheckout,
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

  void _goToDetail(PemesananModel p) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminPemesananDetailScreen(pemesanan: p)),
    ).then((_) => _load());
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
                      onTap: () => _goToDetail(p),
                      title: Text(p.user?.name ?? '-', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Kamar ${p.kamar?.nomorKamar ?? '-'} | Tgl: ${Helpers.formatTanggalPendek(p.checkInDate)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          OrderStatusBadge(status: p.statusPemesanan),
                          const SizedBox(height: 4),
                          Text(
                            Helpers.formatRupiah(p.totalHarga), 
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)
                          ),
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
// Halaman Form Edit Pemesanan
// ========================================================
class AdminPemesananForm extends StatefulWidget {
  final PemesananModel pemesanan;
  const AdminPemesananForm({super.key, required this.pemesanan});

  @override
  State<AdminPemesananForm> createState() => _AdminPemesananFormState();
}

class _AdminPemesananFormState extends State<AdminPemesananForm> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  
  bool _isLoading = true;
  bool _isSubmitting = false;

  List<KamarModel> _kamars = [];
  List<FasilitasModel> _fasilitasTersedia = [];

  int? _selectedKamarId;
  DateTime? _checkIn;
  DateTime? _checkOut;
  final _tamuCtrl = TextEditingController();
  List<int> _selectedFasilitasIds = [];

  @override
  void initState() {
    super.initState();
    _selectedKamarId = widget.pemesanan.kamarId;
    _checkIn = DateTime.tryParse(widget.pemesanan.checkInDate);
    _checkOut = DateTime.tryParse(widget.pemesanan.checkOutDate);
    _tamuCtrl.text = widget.pemesanan.jumlahTamu.toString();
    _selectedFasilitasIds = widget.pemesanan.fasilitas.map((f) => f.idFasilitas).toList();

    _loadDataMaster();
  }

  Future<void> _loadDataMaster() async {
    try {
      final k = await _adminService.getKamars();
      final f = await _adminService.getFasilitas();
      setState(() {
        _kamars = k;
        _fasilitasTersedia = f;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  KamarModel? get _selectedKamar {
    try {
      return _kamars.firstWhere((k) => k.idKamar == _selectedKamarId);
    } catch (_) {
      return null;
    }
  }

  double get _kalkulasiTotalHarga {
    final kamar = _selectedKamar;
    if (kamar == null || _checkIn == null || _checkOut == null) return 0;

    final durasi = _checkOut!.difference(_checkIn!).inDays;
    final malam = durasi > 0 ? durasi : 1; 

    double total = (kamar.tipeKamar?.hargaPerMalam ?? 0) * malam;

    for (final id in _selectedFasilitasIds) {
      final f = _fasilitasTersedia.firstWhere(
        (f) => f.idFasilitas == id,
        orElse: () => FasilitasModel(idFasilitas: 0, namaFasilitas: ''),
      );
      total += (f.biayaTambahan * malam);
    }

    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedKamarId == null || _checkIn == null || _checkOut == null) {
      Helpers.showSnackBar(context, 'Harap lengkapi semua data wajib.', isError: true);
      return;
    }

    if (_checkOut!.isBefore(_checkIn!) || _checkOut!.isAtSameMomentAs(_checkIn!)) {
      Helpers.showSnackBar(context, 'Tanggal check-out harus setelah check-in.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await _adminService.updatePemesanan(
      widget.pemesanan.idPemesanan,
      userId: widget.pemesanan.userId,
      kamarId: _selectedKamarId!,
      checkInDate: _formatDate(_checkIn!),
      checkOutDate: _formatDate(_checkOut!),
      jumlahTamu: int.parse(_tamuCtrl.text),
      fasilitasIds: _selectedFasilitasIds,
      statusPemesanan: widget.pemesanan.statusPemesanan,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
      if (result['success'] == true) {
        Navigator.pop(context, true); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fasilitasBerbayar = _fasilitasTersedia.where((f) => f.biayaTambahan > 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Pesanan')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Pilih Kamar', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedKamarId,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: _kamars.map((k) {
                    return DropdownMenuItem(
                      value: k.idKamar,
                      child: Text('Kamar ${k.nomorKamar} (${k.tipeKamar?.namaTipeKamar ?? ''})'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedKamarId = val),
                  validator: (v) => v == null ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context, 
                                  initialDate: _checkIn ?? DateTime.now(),
                                  firstDate: DateTime(2020), 
                                  lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (d != null) setState(() => _checkIn = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                              child: Text(_checkIn != null ? Helpers.formatTanggalPendek(_checkIn.toString()) : 'Pilih'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Check-out', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context, 
                                  initialDate: _checkOut ?? (_checkIn ?? DateTime.now()),
                                  firstDate: DateTime(2020), 
                                  lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (d != null) setState(() => _checkOut = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                              child: Text(_checkOut != null ? Helpers.formatTanggalPendek(_checkOut.toString()) : 'Pilih'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Jumlah Tamu', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tamuCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 24),

                const Text('Tambah / Kurangi Fasilitas Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                if (fasilitasBerbayar.isEmpty)
                  const Text('Tidak ada data fasilitas tambahan berbayar.', style: TextStyle(color: Colors.grey))
                else
                  ...fasilitasBerbayar.map((f) {
                    final isSelected = _selectedFasilitasIds.contains(f.idFasilitas);
                    return CheckboxListTile(
                      title: Text(f.namaFasilitas),
                      subtitle: Text('+ ${Helpers.formatRupiah(f.biayaTambahan)} / malam'),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedFasilitasIds.add(f.idFasilitas);
                          } else {
                            _selectedFasilitasIds.remove(f.idFasilitas);
                          }
                        });
                      },
                    );
                  }),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Harga Baru:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        Helpers.formatRupiah(_kalkulasiTotalHarga),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Perubahan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
      ),
    );
  }
}
/// ========================================================
// Halaman Form CREATE Pemesanan Manual (Walk-in)
// ========================================================
class AdminPemesananCreateForm extends StatefulWidget {
  const AdminPemesananCreateForm({super.key});

  @override
  State<AdminPemesananCreateForm> createState() => _AdminPemesananCreateFormState();
}

class _AdminPemesananCreateFormState extends State<AdminPemesananCreateForm> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  
  bool _isLoading = true;
  bool _isSubmitting = false;

  // State untuk mode tamu
  bool _isNewUser = false;

  List<UserModel> _users = [];
  List<KamarModel> _kamars = [];
  List<FasilitasModel> _fasilitasTersedia = [];

  // Controller HANYA untuk Nama Tamu Offline
  final _newNameCtrl = TextEditingController();

  int? _selectedUserId;
  int? _selectedKamarId;
  DateTime? _checkIn;
  DateTime? _checkOut;
  final _tamuCtrl = TextEditingController(text: '1');
  List<int> _selectedFasilitasIds = [];

  @override
  void initState() {
    super.initState();
    _loadDataMaster();
  }

  @override
  void dispose() {
    _newNameCtrl.dispose();
    _tamuCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDataMaster() async {
    try {
      final u = await _adminService.getUsers();
      final k = await _adminService.getKamars();
      final f = await _adminService.getFasilitas();
      setState(() {
        _users = u;
        _kamars = k.where((kamar) => kamar.statusKamar == 1 || kamar.statusKamar == true).toList(); 
        _fasilitasTersedia = f;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  String _formatDate(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  KamarModel? get _selectedKamar {
    try {
      return _kamars.firstWhere((k) => k.idKamar == _selectedKamarId);
    } catch (_) {
      return null;
    }
  }

  int get _maxKapasitas => _selectedKamar?.tipeKamar?.kapasitas ?? 0;

  double get _kalkulasiTotalHarga {
    final kamar = _selectedKamar;
    if (kamar == null || _checkIn == null || _checkOut == null) return 0;

    final durasi = _checkOut!.difference(_checkIn!).inDays;
    final malam = durasi > 0 ? durasi : 1; 

    double total = (kamar.tipeKamar?.hargaPerMalam ?? 0) * malam;

    for (final id in _selectedFasilitasIds) {
      final f = _fasilitasTersedia.firstWhere(
        (f) => f.idFasilitas == id,
        orElse: () => FasilitasModel(idFasilitas: 0, namaFasilitas: ''),
      );
      total += (f.biayaTambahan * malam);
    }

    return total;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_isNewUser && _selectedUserId == null) {
      Helpers.showSnackBar(context, 'Harap pilih pelanggan.', isError: true);
      return;
    }

    if (_selectedKamarId == null || _checkIn == null || _checkOut == null) {
      Helpers.showSnackBar(context, 'Harap lengkapi data kamar dan tanggal.', isError: true);
      return;
    }

    if (_checkOut!.isBefore(_checkIn!) || _checkOut!.isAtSameMomentAs(_checkIn!)) {
      Helpers.showSnackBar(context, 'Tanggal check-out harus setelah check-in.', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);

    String? newName;
    String? newEmail;
    int? finalUserId;

    // Siapkan data berdasarkan pilihan admin
    if (_isNewUser) {
      newName = _newNameCtrl.text.trim();
      // Bikin email dummy unik langsung di Flutter untuk dikirim ke backend
      // Sehingga admin tidak perlu repot mengisi email
      newEmail = 'guest_${DateTime.now().millisecondsSinceEpoch}@walkin.local'; 
    } else {
      finalUserId = _selectedUserId;
    }

    // --- PROSES PEMBUATAN PESANAN (Backend akan urus pembuatan akun otomatis) ---
    final result = await _adminService.createPemesanan(
      userId: finalUserId,
      kamarId: _selectedKamarId!,
      checkInDate: _formatDate(_checkIn!),
      checkOutDate: _formatDate(_checkOut!),
      jumlahTamu: int.parse(_tamuCtrl.text),
      totalHarga: _kalkulasiTotalHarga,
      statusPemesanan: 'checked_in',
      fasilitasIds: _selectedFasilitasIds,
      customerType: _isNewUser ? 'new' : 'existing', 
      newUserName: newName,
      newUserEmail: newEmail,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
      if (result['success'] == true) {
        Navigator.pop(context, true); 
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final fasilitasBerbayar = _fasilitasTersedia.where((f) => f.biayaTambahan > 0).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Pesanan Manual')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                // --- BAGIAN PILIHAN JENIS PELANGGAN ---
                const Text('Tipe Pelanggan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                Container(
                  margin: const EdgeInsets.only(top: 8, bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!)
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Punya Akun', style: TextStyle(fontSize: 14)),
                          value: false,
                          groupValue: _isNewUser,
                          onChanged: (val) => setState(() => _isNewUser = val!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<bool>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Tamu Walk-in', style: TextStyle(fontSize: 14)),
                          value: true,
                          groupValue: _isNewUser,
                          onChanged: (val) => setState(() => _isNewUser = val!),
                        ),
                      ),
                    ],
                  ),
                ),

                // Tampilan Dinamis Berdasarkan Tipe Pelanggan
                if (!_isNewUser) ...[
                  const Text('Pilih Pelanggan Terdaftar', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    value: _selectedUserId,
                    decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Cari & pilih akun'),
                    items: _users.map((u) {
                      return DropdownMenuItem(
                        value: u.id,
                        child: Text('${u.name} (${u.email})'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedUserId = val),
                    validator: (v) => !_isNewUser && v == null ? 'Wajib memilih pelanggan' : null,
                  ),
                ] else ...[
                  // --- FORM TAMU OFFLINE (HANYA NAMA) ---
                  const Text('Data Tamu Walk-in', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _newNameCtrl,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(), 
                      labelText: 'Nama Tamu', 
                      prefixIcon: Icon(Icons.person_outline),
                      hintText: 'Masukkan nama tamu yang menginap',
                    ),
                    validator: (v) => _isNewUser && (v == null || v.isEmpty) ? 'Nama tamu wajib diisi' : null,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '* Sistem akan mencatat tamu ini otomatis ke dalam database.', 
                      style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic)
                    ),
                  )
                ],
                // ----------------------------------------
                
                const Divider(height: 40),

                const Text('Pilih Kamar', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<int>(
                  value: _selectedKamarId,
                  decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Kamar yang tersedia'),
                  items: _kamars.map((k) {
                    return DropdownMenuItem(
                      value: k.idKamar,
                      child: Text('Kamar ${k.nomorKamar} (${k.tipeKamar?.namaTipeKamar ?? ''}) - Maks. ${k.tipeKamar?.kapasitas} org'),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedKamarId = val),
                  validator: (v) => v == null ? 'Wajib memilih kamar' : null,
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context, 
                                  initialDate: _checkIn ?? DateTime.now(),
                                  firstDate: DateTime(2020), 
                                  lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (d != null) setState(() => _checkIn = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                              child: Text(_checkIn != null ? Helpers.formatTanggalPendek(_checkIn.toString()) : 'Pilih Tanggal'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Check-out', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () async {
                              final d = await showDatePicker(
                                  context: context, 
                                  initialDate: _checkOut ?? (_checkIn ?? DateTime.now().add(const Duration(days: 1))),
                                  firstDate: DateTime(2020), 
                                  lastDate: DateTime.now().add(const Duration(days: 365)));
                              if (d != null) setState(() => _checkOut = d);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                              child: Text(_checkOut != null ? Helpers.formatTanggalPendek(_checkOut.toString()) : 'Pilih Tanggal'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                const Text('Jumlah Tamu', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _tamuCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    hintText: _selectedKamarId == null ? 'Pilih kamar terlebih dahulu' : 'Maksimal $_maxKapasitas tamu',
                    prefixIcon: const Icon(Icons.people_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Wajib diisi';
                    final val = int.tryParse(v);
                    if (val == null || val < 1) return 'Minimal 1 tamu';
                    
                    if (_selectedKamarId != null && val > _maxKapasitas) {
                      return 'Kapasitas kamar ini maksimal $_maxKapasitas orang.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                const Text('Fasilitas Tambahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                if (fasilitasBerbayar.isEmpty)
                  const Text('Tidak ada data fasilitas tambahan berbayar.', style: TextStyle(color: Colors.grey))
                else
                  ...fasilitasBerbayar.map((f) {
                    final isSelected = _selectedFasilitasIds.contains(f.idFasilitas);
                    return CheckboxListTile(
                      title: Text(f.namaFasilitas),
                      subtitle: Text('+ ${Helpers.formatRupiah(f.biayaTambahan)} / malam'),
                      value: isSelected,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _selectedFasilitasIds.add(f.idFasilitas);
                          } else {
                            _selectedFasilitasIds.remove(f.idFasilitas);
                          }
                        });
                      },
                    );
                  }),
                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimasi Total:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        Helpers.formatRupiah(_kalkulasiTotalHarga),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Buat Pesanan Sekarang', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
      ),
    );
  }
}