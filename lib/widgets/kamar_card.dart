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

    return Container(
      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 24,
            spreadRadius: 2,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. GAMBAR & FLOATING BADGE ---
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: tipe?.fullFotoUrl != null
                        ? Image.network(
                            tipe!.fullFotoUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholder(),
                          )
                        : _buildPlaceholder(),
                  ),
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.meeting_room, color: Colors.white, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Kamar ${kamar.nomorKamar}',
                            style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // --- 2. INFORMASI TEKS ---
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            tipe?.namaTipeKamar ?? 'Tipe Kamar',
                            style: AppTextStyles.heading.copyWith(fontSize: 20),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              Helpers.formatRupiah(tipe?.hargaPerMalam ?? 0),
                              style: AppTextStyles.heading.copyWith(
                                fontSize: 18,
                                color: AppColors.primary,
                              ),
                            ),
                            Text(
                              '/ malam',
                              style: AppTextStyles.body.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // --- 3. FITUR & FASILITAS (Menampilkan Nama Fasilitas) ---
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      child: Row(
                        children: [
                          // Pill Kapasitas Tamu
                          _buildFeaturePill(Icons.person_outline, 'Maks ${tipe?.kapasitas ?? '-'} Tamu'),
                          
                          // Looping untuk Menampilkan Semua Nama Fasilitas
                          if (tipe != null && tipe.fasilitas.isNotEmpty) ...[
                            const SizedBox(width: 10),
                            ...tipe.fasilitas.map((fasilitas) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: _buildFeaturePill(
                                  Icons.check_circle_outline, // Bisa disesuaikan dengan icon bawaan fasilitas jika ada
                                  fasilitas.namaFasilitas,
                                ),
                              );
                            }).toList(),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper untuk gambar kosong
  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_outlined, size: 48, color: AppColors.textMuted.withOpacity(0.5)),
            const SizedBox(height: 8),
            Text('Foto tidak tersedia', style: AppTextStyles.body.copyWith(fontSize: 12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  // Widget Helper untuk membuat tag/pil modern
  Widget _buildFeaturePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryDark),
          const SizedBox(width: 6),
          Text(
            label,
            style: AppTextStyles.label.copyWith(fontSize: 13, color: AppColors.primaryDark),
          ),
        ],
      ),
    );
  }
}