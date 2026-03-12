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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bp = Provider.of<BookingProvider>(context, listen: false);
      bp.fetchKamars();
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
      body: bookingProvider.isLoading
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
                  onRefresh: () => bookingProvider.fetchKamars(),
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
                            builder: (_) => BookingScreen(kamarId: kamar.idKamar),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}