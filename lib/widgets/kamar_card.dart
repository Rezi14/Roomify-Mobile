import 'package:flutter/material.dart';
import '../models/kamar_model.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

class KamarCard extends StatelessWidget {
  final KamarModel kamar;
  final VoidCallback onTap;

  const KamarCard({super.key, required this.kamar, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tipe = kamar.tipeKamar;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Foto
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(15)),
              child: tipe?.fullFotoUrl != null
                  ? Image.network(
                      tipe!.fullFotoUrl!,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 180,
                        color: AppColors.background,
                        child: const Icon(Icons.hotel, size: 60, color: AppColors.textMuted),
                      ),
                    )
                  : Container(
                      height: 180,
                      color: AppColors.background,
                      child: const Center(
                        child: Icon(Icons.hotel, size: 60, color: AppColors.textMuted),
                      ),
                    ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nama Tipe + Nomor Kamar
                  Text(
                    tipe?.namaTipeKamar ?? 'Kamar',
                    style: AppTextStyles.heading.copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Kamar No. ${kamar.nomorKamar}',
                    style: AppTextStyles.body.copyWith(fontSize: 14),
                  ),
                  const SizedBox(height: 8),

                  // Kapasitas & Fasilitas count
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: AppColors.textMuted),
                      const SizedBox(width: 4),
                      Text('Maks ${tipe?.kapasitas ?? '-'} tamu',
                          style: AppTextStyles.body.copyWith(fontSize: 13)),
                      const SizedBox(width: 16),
                      if (tipe != null && tipe.fasilitas.isNotEmpty) ...[
                        Icon(Icons.wifi, size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text('${tipe.fasilitas.length} fasilitas',
                            style: AppTextStyles.body.copyWith(fontSize: 13)),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Harga
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Helpers.formatRupiah(tipe?.hargaPerMalam ?? 0),
                        style: AppTextStyles.heading.copyWith(
                          fontSize: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      Text('/malam',
                          style: AppTextStyles.body.copyWith(fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}