import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/pemesanan_model.dart';
import '../models/kamar_model.dart';
import '../models/fasilitas_model.dart';
import 'auth_service.dart';

class BookingService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/booking/form/{kamarId}
  /// Sesuai BookingApiController@showBookingForm
  Future<Map<String, dynamic>> getBookingForm(int kamarId) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/booking/form/$kamarId'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'kamar': KamarModel.fromJson(data['kamar']),
        'max_tamu': data['max_tamu'],
        'fasilitas_tersedia': (data['fasilitas_tersedia'] as List)
            .map((e) => FasilitasModel.fromJson(e))
            .toList(),
      };
    }

    // 409 = ada pending booking
    return {
      'success': false,
      'message': data['message'],
      'pending_pemesanan_id': data['pending_pemesanan_id'],
    };
  }

  /// POST /api/booking
  /// Sesuai BookingApiController@store (menggunakan StoreBookingRequest)
  Future<Map<String, dynamic>> createBooking({
    required int kamarId,
    required String checkInDate,
    required String checkOutDate,
    required int jumlahTamu,
    List<int>? fasilitasIds,
  }) async {
    final body = {
      'kamar_id': kamarId,
      'check_in_date': checkInDate,
      'check_out_date': checkOutDate,
      'jumlah_tamu': jumlahTamu,
      if (fasilitasIds != null && fasilitasIds.isNotEmpty)
        'fasilitas_ids': fasilitasIds,
    };

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/booking'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      return {
        'success': true,
        'message': data['message'],
        'pemesanan': PemesananModel.fromJson(data['pemesanan']),
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Gagal membuat pesanan.',
      'errors': data['errors'],
    };
  }

  /// GET /api/booking/{id}/detail
  Future<PemesananModel> getBookingDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/booking/$id/detail'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PemesananModel.fromJson(data['pemesanan']);
    }

    throw Exception('Gagal memuat detail pesanan');
  }

  /// GET /api/booking/{id}/payment
  /// Sesuai BookingApiController@showPayment
  Future<Map<String, dynamic>> getPaymentData(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/booking/$id/payment'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'pemesanan': PemesananModel.fromJson(data['pemesanan']),
        'batas_waktu': data['batas_waktu'],
        'sisa_detik': data['sisa_detik'],
      };
    }

    // 410 = expired
    return {
      'success': false,
      'message': data['message'],
      'status': data['status'],
    };
  }

  /// GET /api/booking/{id}/payment/check
  /// Sesuai BookingApiController@checkPaymentStatus
  Future<String> checkPaymentStatus(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/booking/$id/payment/check'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['status']; // 'success', 'expired', 'pending'
    }

    return 'error';
  }

  /// POST /api/booking/{id}/cancel
  Future<Map<String, dynamic>> cancelBooking(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/booking/$id/cancel'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': data['message'],
    };
  }
  Future<Map<String, dynamic>> simulateQRPayment(int id) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/booking/$id/simulate-pay'),
      headers: await _headers(),
    );

    final data = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': data['message'],
    };
  }
}