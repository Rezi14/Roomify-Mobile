import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailOrNameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isSubmitting = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final result = await Provider.of<AuthProvider>(
      context,
      listen: false,
    ).login(_emailOrNameCtrl.text.trim(), _passwordCtrl.text);

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
    }

    if (result['success'] == true) {
      // Navigation handled by SplashDecider (Consumer)
    } else {
      if (mounted) {
        Helpers.showSnackBar(
          context,
          result['message'] ?? 'Login gagal.',
          isError: true,
        );
      }
    }
  }

  // --- TAMBAHKAN DISPOSE DI SINI ---
  @override
  void dispose() {
    // Bersihkan controller dari memori saat layar login ditutup
    _emailOrNameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
  // ---------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo / Title
                      Icon(Icons.hotel, size: 64, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(
                        'Roomify',
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 28,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Selamat Datang Kembali', style: AppTextStyles.body),
                      const SizedBox(height: 32),

                      // Email atau Username (sesuai LoginController: email_or_name)
                      TextFormField(
                        controller: _emailOrNameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email atau Username',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Wajib diisi.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      TextFormField(
                        controller: _passwordCtrl,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                          ),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) return 'Wajib diisi.';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),

                      // Lupa Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordScreen(),
                            ),
                          ),
                          child: const Text('Lupa Password?'),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Tombol Login
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _login,
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Masuk',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Link Register
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Belum punya akun? '),
                          TextButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            ),
                            child: const Text('Daftar Sekarang'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}