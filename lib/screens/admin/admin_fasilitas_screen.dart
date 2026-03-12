import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/fasilitas_model.dart';
import '../../utils/helpers.dart';

class AdminFasilitasScreen extends StatefulWidget {
  const AdminFasilitasScreen({super.key});
  @override
  State<AdminFasilitasScreen> createState() => _AdminFasilitasScreenState();
}

class _AdminFasilitasScreenState extends State<AdminFasilitasScreen> {
  final _adminService = AdminService();
  List<FasilitasModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _items = await _adminService.getFasilitas();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showForm([FasilitasModel? fasilitas]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminFasilitasForm(fasilitas: fasilitas)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Fasilitas')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final f = _items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.star, color: Colors.white)),
                      title: Text(f.namaFasilitas, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(f.isBerbayar ? 'Berbayar: ${Helpers.formatRupiah(f.biayaTambahan)}' : 'Gratis'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(f)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Hapus Fasilitas?'),
                                    content: const Text('Yakin ingin menghapus fasilitas ini?'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final r = await _adminService.deleteFasilitas(f.idFasilitas);
                                  if (mounted) {
                                    Helpers.showSnackBar(context, r['message'], isError: r['success'] != true);
                                    _load();
                                  }
                                }
                              }),
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

class AdminFasilitasForm extends StatefulWidget {
  final FasilitasModel? fasilitas;
  const AdminFasilitasForm({super.key, this.fasilitas});

  @override
  State<AdminFasilitasForm> createState() => _AdminFasilitasFormState();
}

class _AdminFasilitasFormState extends State<AdminFasilitasForm> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _namaCtrl = TextEditingController();
  final _biayaCtrl = TextEditingController(text: '0');
  final _deskripsiCtrl = TextEditingController();
  final _iconCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.fasilitas != null) {
      _namaCtrl.text = widget.fasilitas!.namaFasilitas;
      _biayaCtrl.text = widget.fasilitas!.biayaTambahan.toStringAsFixed(0);
      _deskripsiCtrl.text = widget.fasilitas!.deskripsi ?? '';
      _iconCtrl.text = widget.fasilitas!.icon ?? '';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    Map<String, dynamic> result;

    if (widget.fasilitas == null) {
      result = await _adminService.createFasilitas(
        namaFasilitas: _namaCtrl.text,
        biayaTambahan: double.tryParse(_biayaCtrl.text),
        deskripsi: _deskripsiCtrl.text,
        icon: _iconCtrl.text,
      );
    } else {
      result = await _adminService.updateFasilitas(
        widget.fasilitas!.idFasilitas,
        namaFasilitas: _namaCtrl.text,
        biayaTambahan: double.tryParse(_biayaCtrl.text),
        deskripsi: _deskripsiCtrl.text,
        icon: _iconCtrl.text,
      );
    }

    setState(() => _isSubmitting = false);
    if (mounted) {
      Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
      if (result['success'] == true) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fasilitas == null ? 'Tambah Fasilitas' : 'Edit Fasilitas')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Fasilitas'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _biayaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Biaya Tambahan (Isi 0 jika gratis)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _iconCtrl,
                decoration: const InputDecoration(labelText: 'Icon (Optional/Class Name)'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi', alignLabelWithHint: true),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Fasilitas'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}