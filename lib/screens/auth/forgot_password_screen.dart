import 'package:flutter/material.dart';
import 'package:roomify_mobile/services/auth_service.dart';
// import 'package:roomify_mobile/utils/constants.dart';
import 'package:roomify_mobile/utils/helpers.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isSubmitting = false;
  final _authService = AuthService();

  Future<void> _submit() async {
    if (_emailCtrl.text.trim().isEmpty) return;

    setState(() => _isSubmitting = true);

    final result = await _authService.forgotPassword(_emailCtrl.text.trim());

    setState(() => _isSubmitting = false);

    if (mounted) {
      Helpers.showSnackBar(context, result['message'], isError: result['success'] != true);
      if (result['success'] == true) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lupa Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Masukkan email Anda untuk menerima link reset password.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Kirim Link Reset'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}