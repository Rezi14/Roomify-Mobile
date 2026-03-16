import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  /// Headers dengan token
  Future<Map<String, String>> _authHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Simpan token
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Ambil token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Hapus token
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Cek apakah sudah login
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// POST /api/login
  /// Sesuai AuthApiController@login: email_or_name + password
  Future<Map<String, dynamic>> login(String emailOrName, String password) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/login'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'email_or_name': emailOrName,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200) {
      await saveToken(data['token']);
      return {
        'success': true,
        'message': data['message'],
        'user': UserModel.fromJson(data['user']),
        'token': data['token'],
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Login gagal.',
      'errors': data['errors'],
    };
  }

  /// POST /api/register
  /// Sesuai AuthApiController@register: name, email, password, password_confirmation
  Future<Map<String, dynamic>> register(
      String name, String email, String password, String passwordConfirmation) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/register'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201) {
      await saveToken(data['token']);
      return {
        'success': true,
        'message': data['message'],
        'user': UserModel.fromJson(data['user']),
        'token': data['token'],
      };
    }

    return {
      'success': false,
      'message': data['message'] ?? 'Registrasi gagal.',
      'errors': data['errors'],
    };
  }

  /// POST /api/logout
  Future<Map<String, dynamic>> logout() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/logout'),
      headers: await _authHeaders(),
    );

    await deleteToken();

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {'success': true, 'message': data['message']};
    }

    return {'success': true, 'message': 'Logged out.'};
  }

  /// GET /api/user
  Future<UserModel?> getUser() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/user'),
      headers: await _authHeaders(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return UserModel.fromJson(data['user']);
    }

    return null;
  }

  /// POST /api/forgot-password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/forgot-password'),
      headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    final data = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': data['message'],
    };
  }
  Future<Map<String, dynamic>> resendVerification() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/email/verification-notification'),
      headers: await _authHeaders(),
    );

    final data = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200 || response.statusCode == 201,
      'message': data['message'] ?? 'Berhasil mengirim ulang email verifikasi.',
    };
  }
}