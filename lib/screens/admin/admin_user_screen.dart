import 'package:flutter/material.dart';
import '../../services/admin_service.dart';
import '../../models/user_model.dart';
import '../../utils/helpers.dart';
import '../../utils/constants.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});
  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final _adminService = AdminService();
  List<UserModel> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      _items = await _adminService.getUsers();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _showForm([UserModel? user]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AdminUserForm(user: user)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showForm(),
        child: const Icon(Icons.person_add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                itemCount: _items.length,
                itemBuilder: (_, i) {
                  final u = _items[i];
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: u.isAdmin ? AppColors.info : AppColors.primary,
                        child: Text(u.name.substring(0, 1).toUpperCase(), style: const TextStyle(color: Colors.white)),
                      ),
                      title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${u.email} | Role: ${u.role?.namaRole ?? '-'}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _showForm(u)),
                          if (!u.isAdmin) // Lindungi agar admin tidak menghapus sesama admin dengan mudah
                            IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Hapus Pengguna?'),
                                      content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                                        ElevatedButton(onPressed: () => Navigator.pop(c, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red), child: const Text('Hapus')),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    final r = await _adminService.deleteUser(u.id);
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

class AdminUserForm extends StatefulWidget {
  final UserModel? user;
  const AdminUserForm({super.key, this.user});

  @override
  State<AdminUserForm> createState() => _AdminUserFormState();
}

class _AdminUserFormState extends State<AdminUserForm> {
  final _formKey = GlobalKey<FormState>();
  final _adminService = AdminService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  int _selectedRole = 2; // Default: pelanggan
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _nameCtrl.text = widget.user!.name;
      _emailCtrl.text = widget.user!.email;
      _selectedRole = widget.user!.idRole;
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    Map<String, dynamic> result;

    if (widget.user == null) {
      result = await _adminService.createUser(
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text,
        passwordConfirmation: _passwordConfirmCtrl.text,
        idRole: _selectedRole,
      );
    } else {
      result = await _adminService.updateUser(
        widget.user!.id,
        name: _nameCtrl.text,
        email: _emailCtrl.text,
        password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
        passwordConfirmation: _passwordConfirmCtrl.text.isNotEmpty ? _passwordConfirmCtrl.text : null,
        idRole: _selectedRole,
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
      appBar: AppBar(title: Text(widget.user == null ? 'Tambah Pengguna' : 'Edit Pengguna')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                value: _selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Admin')),
                  DropdownMenuItem(value: 2, child: Text('Pelanggan')),
                ],
                onChanged: (val) => setState(() => _selectedRole = val!),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(widget.user == null ? 'Set Password' : 'Ubah Password (kosongkan jika tidak diubah)',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: (v) {
                  if (widget.user == null && v!.isEmpty) return 'Wajib diisi untuk user baru';
                  if (v!.isNotEmpty && v.length < 8) return 'Minimal 8 karakter';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordConfirmCtrl,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Konfirmasi Password'),
                validator: (v) {
                  if (_passwordCtrl.text.isNotEmpty && v != _passwordCtrl.text) {
                    return 'Password tidak cocok';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Simpan Pengguna'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}