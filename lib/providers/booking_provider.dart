import 'package:flutter/material.dart';
import '../models/kamar_model.dart';
import '../models/pemesanan_model.dart';
import '../models/tipe_kamar_model.dart';
import '../models/fasilitas_model.dart';
import '../services/kamar_service.dart';
// import '../services/booking_service.dart';
import '../services/profile_service.dart';

class BookingProvider extends ChangeNotifier {
  final KamarService _kamarService = KamarService();
  // final BookingService _bookingService = BookingService();
  final ProfileService _profileService = ProfileService();

  // State
  List<KamarModel> _kamars = [];
  List<TipeKamarModel> _tipeKamars = [];
  List<FasilitasModel> _fasilitas = [];
  List<PemesananModel> _orders = [];
  bool _isLoading = false;

  // Getters
  List<KamarModel> get kamars => _kamars;
  List<TipeKamarModel> get tipeKamars => _tipeKamars;
  List<FasilitasModel> get fasilitas => _fasilitas;
  List<PemesananModel> get orders => _orders;
  bool get isLoading => _isLoading;

  /// Fetch kamar dengan filter (sesuai DashboardController@index)
  Future<void> fetchKamars({
    String? checkIn,
    String? checkOut,
    int? tipeKamar,
    double? hargaMin,
    double? hargaMax,
    List<int>? fasilitasIds,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _kamars = await _kamarService.getKamars(
        checkIn: checkIn,
        checkOut: checkOut,
        tipeKamar: tipeKamar,
        hargaMin: hargaMin,
        hargaMax: hargaMax,
        fasilitasIds: fasilitasIds,
      );
    } catch (e) {
      _kamars = [];
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Fetch data filter (tipe kamar + fasilitas)
  Future<void> fetchFilterData() async {
    try {
      _tipeKamars = await _kamarService.getTipeKamars();
      _fasilitas = await _kamarService.getFasilitas();
      notifyListeners();
    } catch (_) {}
  }

  /// Fetch riwayat pesanan user
  Future<void> fetchOrders() async {
    _isLoading = true;
    notifyListeners();

    try {
      _orders = await _profileService.getOrders();
    } catch (_) {
      _orders = [];
    }

    _isLoading = false;
    notifyListeners();
  }
}