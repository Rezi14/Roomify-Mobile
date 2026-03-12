import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/pemesanan_model.dart';
import 'auth_service.dart';

class ProfileService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/profile
  Future<UserModel> getProfile() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/profile'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    }

    throw Exception('Gagal memuat profil');
  }

  /// PUT /api/profile
  Future<Map<String, dynamic>> updateProfile(String name, String email) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/profile'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'email': email}),
    );

    final data = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': data['message'],
      'user': response.statusCode == 200 ? UserModel.fromJson(data['user']) : null,
      'errors': data['errors'],
    };
  }

  /// PUT /api/profile/password
  Future<Map<String, dynamic>> updatePassword(
      String currentPassword, String password, String passwordConfirmation) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/profile/password'),
      headers: await _headers(),
      body: jsonEncode({
        'current_password': currentPassword,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final data = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': data['message'],
      'errors': data['errors'],
    };
  }

  /// GET /api/profile/orders
  Future<List<PemesananModel>> getOrders() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/profile/orders'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['orders'] as List)
          .map((e) => PemesananModel.fromJson(e))
          .toList();
    }

    throw Exception('Gagal memuat riwayat pesanan');
  }

  /// GET /api/profile/orders/{id}
  Future<PemesananModel> getOrderDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/profile/orders/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PemesananModel.fromJson(data['order']);
    }

    throw Exception('Gagal memuat detail pesanan');
  }
}