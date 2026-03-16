import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await Provider.of<AuthProvider>(context, listen: false)
        .register(_nameCtrl.text.trim(), _emailCtrl.text.trim(),
            _passwordCtrl.text, _passwordConfirmCtrl.text);

    setState(() => _isSubmitting = false);

    if (result['success'] == true) {
      if (mounted) {
        // PERBAIKAN: Tampilkan Pop-Up instruksi verifikasi email
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.mark_email_unread, color: AppColors.primary),
                const SizedBox(width: 8),
                const Text('Cek Email Anda'),
              ],
            ),
            content: const Text(
              'Registrasi berhasil! Kami telah mengirimkan tautan verifikasi ke email Anda. '
              'Silakan verifikasi email Anda terlebih dahulu agar dapat melakukan pemesanan kamar.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: () {
                  Navigator.pop(ctx); // Tutup dialog
                  Navigator.of(context).popUntil((route) => route.isFirst); // Kembali ke Home/Login
                },
                child: const Text('Mengerti', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      }
    } else {
      if (mounted) Helpers.showSnackBar(context, result['message'] ?? 'Gagal.', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person)),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi.';
                      if (!v.contains('@')) return 'Format email salah.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Wajib diisi.';
                      if (v.length < 8) return 'Minimal 8 karakter.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordConfirmCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                        labelText: 'Konfirmasi Password', prefixIcon: Icon(Icons.lock_outline)),
                    validator: (v) {
                      if (v != _passwordCtrl.text) return 'Password tidak cocok.';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _register,
                      child: _isSubmitting
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Daftar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}