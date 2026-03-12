import 'package:flutter/material.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';

class ContactScreen extends StatelessWidget {
  const ContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hubungi Kami')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ada pertanyaan?', style: AppTextStyles.heading.copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            const Text('Kirim pesan kepada kami dan tim kami akan segera menghubungi Anda.'),
            const SizedBox(height: 24),
            const TextField(decoration: InputDecoration(labelText: 'Nama', prefixIcon: Icon(Icons.person))),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email))),
            const SizedBox(height: 12),
            const TextField(decoration: InputDecoration(labelText: 'Subjek', prefixIcon: Icon(Icons.subject))),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(labelText: 'Pesan', alignLabelWithHint: true),
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Helpers.showSnackBar(context, 'Pesan terkirim! Terima kasih.'),
                child: const Text('Kirim Pesan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}