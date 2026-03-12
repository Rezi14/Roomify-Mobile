import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/kamar_model.dart';
import '../../models/tipe_kamar_model.dart';
import '../../utils/helpers.dart';

class AdminKamarScreen extends StatefulWidget {
  const AdminKamarScreen({super.key});
  @override
  State<AdminKamarScreen> createState() => _AdminKamarScreenState();
}

class _AdminKamarScreenState extends State<AdminKamarScreen> {
  final _adminService = AdminService();
  List<KamarModel> _kamars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _kamars = await _adminService.getKamars();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showForm([KamarModel? kamar]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminKamarForm(kamar: kamar)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Kamar')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: _kamars.length,
                itemBuilder: (_, i) {
                  final k = _kamars[i];
                  return Card(
                    child: ListTile(
                      title: Text('Kamar ${k.nomorKamar}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(k.tipeKamar?.namaTipeKamar ?? '-'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: k.statusKamar ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(k.statusKamar ? 'Tersedia' : 'Terisi',
                                style: TextStyle(color: k.statusKamar ? Colors.green : Colors.red, fontSize: 12)),
                          ),
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(k)),
                          IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (c) => AlertDialog(
                                    title: const Text('Hapus Kamar?'),
                                    content: const Text('Tindakan ini tidak dapat dibatalkan.'),
                                    actions: [
                                      TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                      ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  final r = await _adminService.deleteKamar(k.idKamar);
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

class AdminKamarForm extends StatefulWidget {
  final KamarModel? kamar;
  const AdminKamarForm({super.key, this.kamar});

  @override
  State<AdminKamarForm> createState() => _AdminKamarFormState();
}

class _AdminKamarFormState extends State<AdminKamarForm> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _nomorCtrl = TextEditingController();
  int? _selectedTipe;
  bool _statusKamar = true;
  List<TipeKamarModel> _tipeKamars = [];
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.kamar != null) {
      _nomorCtrl.text = widget.kamar!.nomorKamar;
      _selectedTipe = widget.kamar!.idTipeKamar;
      _statusKamar = widget.kamar!.statusKamar;
    }
    _loadTipeKamars();
  }

  Future<void> _loadTipeKamars() async {
    try {
      final list = await _adminService.getTipeKamars();
      setState(() => _tipeKamars = list);
    } catch (_) {}
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedTipe == null) {
      Helpers.showSnackBar(context, 'Harap lengkapi semua data', isError: true);
      return;
    }

    setState(() => _isSubmitting = true);
    Map<String, dynamic> result;

    if (widget.kamar == null) {
      result = await _adminService.createKamar(
        nomorKamar: _nomorCtrl.text,
        idTipeKamar: _selectedTipe!,
        statusKamar: _statusKamar,
      );
    } else {
      result = await _adminService.updateKamar(
        widget.kamar!.idKamar,
        nomorKamar: _nomorCtrl.text,
        idTipeKamar: _selectedTipe!,
        statusKamar: _statusKamar,
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
      appBar: AppBar(title: Text(widget.kamar == null ? 'Tambah Kamar' : 'Edit Kamar')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nomorCtrl,
                decoration: const InputDecoration(labelText: 'Nomor Kamar'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedTipe,
                decoration: const InputDecoration(labelText: 'Tipe Kamar'),
                items: _tipeKamars
                    .map((t) => DropdownMenuItem(value: t.idTipeKamar, child: Text(t.namaTipeKamar)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedTipe = val),
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Status Kamar'),
                subtitle: Text(_statusKamar ? 'Tersedia' : 'Terisi'),
                value: _statusKamar,
                onChanged: (val) => setState(() => _statusKamar = val),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}