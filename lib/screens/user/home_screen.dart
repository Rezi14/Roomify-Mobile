import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/booking_provider.dart';
import '../../utils/constants.dart';
import '../../widgets/kamar_card.dart';
import '../../widgets/filter_bottom_sheet.dart';
import 'booking_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // 1. Inisialisasi default tanggal: Hari Ini & Besok
  late String activeCheckIn;
  late String activeCheckOut;

  @override
  void initState() {
    super.initState();
    
    // Format tanggal ke YYYY-MM-DD
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    activeCheckIn = now.toString().substring(0, 10);
    activeCheckOut = tomorrow.toString().substring(0, 10);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = Provider.of<BookingProvider>(context, listen: false);
      // 2. Kirim parameter tanggal default saat load awal
      bp.fetchKamars(checkIn: activeCheckIn, checkOut: activeCheckOut);
      bp.fetchFilterData();
    });
  }

  void _showFilter() {
    final bp = Provider.of<BookingProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollController) => FilterBottomSheet(
          tipeKamars: bp.tipeKamars,
          fasilitas: bp.fasilitas,
          onApply: (filters) {
            // 3. Update state tanggal aktif jika user memilih tanggal di filter
            setState(() {
              if (filters['check_in'] != null) activeCheckIn = filters['check_in'];
              if (filters['check_out'] != null) activeCheckOut = filters['check_out'];
            });

            bp.fetchKamars(
              checkIn: filters['check_in'],
              checkOut: filters['check_out'],
              tipeKamar: filters['tipe_kamar'],
              hargaMin: filters['harga_min']?.toDouble(),
              hargaMax: filters['harga_max']?.toDouble(),
              fasilitasIds: filters['fasilitas_ids']?.cast<int>(),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final bookingProvider = Provider.of<BookingProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Halo, ${authProvider.user?.name ?? 'User'}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilter,
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          ),
        ],
      ),
      body: Column(
        children: [
          // 4. Banner Informasi Tanggal Aktif
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.primary.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.date_range, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ketersediaan: $activeCheckIn s/d $activeCheckOut',
                    style: AppTextStyles.body.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // List Kamar
          Expanded(
            child: bookingProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : bookingProvider.kamars.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: AppColors.textMuted),
                            SizedBox(height: 16),
                            Text('Tidak ada kamar tersedia.',
                                style: TextStyle(fontSize: 16, color: AppColors.textMuted)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        // Pastikan refresh juga mengirimkan tanggal terakhir yang aktif
                        onRefresh: () => bookingProvider.fetchKamars(
                          checkIn: activeCheckIn,
                          checkOut: activeCheckOut,
                        ),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: bookingProvider.kamars.length,
                          itemBuilder: (_, index) {
                            final kamar = bookingProvider.kamars[index];
                            return KamarCard(
                              kamar: kamar,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  // Opsional: Anda bisa mengirim tanggal aktif ini ke BookingScreen 
                                  // agar otomatis terisi di form booking-nya nanti.
                                  builder: (_) => BookingScreen(
                                    kamarId: kamar.idKamar,
                                    initialCheckIn: activeCheckIn,
                                    initialCheckOut: activeCheckOut,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}