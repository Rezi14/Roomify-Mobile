import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/admin_service.dart';
import '../../models/tipe_kamar_model.dart';
import '../../models/fasilitas_model.dart';
import '../../utils/helpers.dart';

class AdminTipeKamarScreen extends StatefulWidget {
  const AdminTipeKamarScreen({super.key});
  @override
  State<AdminTipeKamarScreen> createState() => _AdminTipeKamarScreenState();
}

class _AdminTipeKamarScreenState extends State<AdminTipeKamarScreen> {
  final _adminService = AdminService();
  List<TipeKamarModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _items = await _adminService.getTipeKamars();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showForm([TipeKamarModel? tipe]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminTipeKamarForm(tipe: tipe)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Tipe Kamar')),
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
                  final t = _items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: t.fullFotoUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(t.fullFotoUrl!, width: 60, height: 60, fit: BoxFit.cover))
                          : const Icon(Icons.image, size: 50),
                      title: Text(t.namaTipeKamar, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${Helpers.formatRupiah(t.hargaPerMalam)} | Maks ${t.kapasitas} tamu'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(t)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Hapus Tipe Kamar?'),
                                    content: const Text('Pastikan tidak ada kamar yang menggunakan tipe ini.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final r = await _adminService.deleteTipeKamar(t.idTipeKamar);
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

class AdminTipeKamarForm extends StatefulWidget {
  final TipeKamarModel? tipe;
  const AdminTipeKamarForm({super.key, this.tipe});

  @override
  State<AdminTipeKamarForm> createState() => _AdminTipeKamarFormState();
}

class _AdminTipeKamarFormState extends State<AdminTipeKamarForm> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _namaCtrl = TextEditingController();
  final _hargaCtrl = TextEditingController();
  final _kapasitasCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();
  
  List<FasilitasModel> _semuaFasilitas = [];
  final List<int> _selectedFasilitas = [];
  File? _imageFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.tipe != null) {
      _namaCtrl.text = widget.tipe!.namaTipeKamar;
      _hargaCtrl.text = widget.tipe!.hargaPerMalam.toStringAsFixed(0);
      _kapasitasCtrl.text = widget.tipe!.kapasitas.toString();
      _deskripsiCtrl.text = widget.tipe!.deskripsi ?? '';
      _selectedFasilitas.addAll(widget.tipe!.fasilitas.map((f) => f.idFasilitas));
    }
    _loadFasilitas();
  }

  Future<void> _loadFasilitas() async {
    try {
      final list = await _adminService.getFasilitas();
      setState(() => _semuaFasilitas = list);
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery,
        maxWidth: 1024, maxHeight: 1024, imageQuality: 80 // Kompresi gambar
    );
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    Map<String, dynamic> result;

    if (widget.tipe == null) {
      result = await _adminService.createTipeKamar(
        namaTipeKamar: _namaCtrl.text,
        hargaPerMalam: double.parse(_hargaCtrl.text),
        kapasitas: int.parse(_kapasitasCtrl.text),
        deskripsi: _deskripsiCtrl.text,
        foto: _imageFile,
        fasilitasIds: _selectedFasilitas,
      );
    } else {
      result = await _adminService.updateTipeKamar(
        widget.tipe!.idTipeKamar,
        namaTipeKamar: _namaCtrl.text,
        hargaPerMalam: double.parse(_hargaCtrl.text),
        kapasitas: int.parse(_kapasitasCtrl.text),
        deskripsi: _deskripsiCtrl.text,
        foto: _imageFile,
        fasilitasIds: _selectedFasilitas,
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
      appBar: AppBar(title: Text(widget.tipe == null ? 'Tambah Tipe' : 'Edit Tipe')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama Tipe Kamar'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _hargaCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Harga / Malam'),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _kapasitasCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Kapasitas (Orang)'),
                      validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _deskripsiCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Deskripsi', alignLabelWithHint: true),
              ),
              const SizedBox(height: 16),
              const Text('Fasilitas', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _semuaFasilitas.map((f) {
                  final isSelected = _selectedFasilitas.contains(f.idFasilitas);
                  return FilterChip(
                    label: Text(f.namaFasilitas),
                    selected: isSelected,
                    onSelected: (val) {
                      setState(() {
                        if (val) _selectedFasilitas.add(f.idFasilitas);
                        else _selectedFasilitas.remove(f.idFasilitas);
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Foto Kamar', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _imageFile != null
                      ? Image.file(_imageFile!, fit: BoxFit.cover)
                      : widget.tipe?.fullFotoUrl != null
                          ? Image.network(widget.tipe!.fullFotoUrl!, fit: BoxFit.cover)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                                Text('Pilih Foto'),
                              ],
                            ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Tipe Kamar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}