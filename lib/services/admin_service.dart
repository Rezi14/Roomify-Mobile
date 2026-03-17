import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/kamar_model.dart';
import '../models/tipe_kamar_model.dart';
import '../models/fasilitas_model.dart';
import '../models/pemesanan_model.dart';
import '../models/user_model.dart';
import 'auth_service.dart';

class AdminService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ================================================================
  // DASHBOARD
  // ================================================================

  /// GET /api/admin/dashboard
  Future<Map<String, dynamic>> getDashboard() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/dashboard'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'total_kamar': data['total_kamar'],
        'total_pemesanan': data['total_pemesanan'],
        'total_pengguna': data['total_pengguna'],
        'pelanggan_checkin': (data['pelanggan_checkin'] as List)
            .map((e) => PemesananModel.fromJson(e))
            .toList(),
      };
    }

    throw Exception('Gagal memuat dashboard');
  }

  // ================================================================
  // CRUD KAMAR - Mapping ke KamarAdminApiController
  // ================================================================

  Future<List<KamarModel>> getKamars() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/kamars'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['kamars'] as List)
          .map((e) => KamarModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat kamar');
  }

  Future<Map<String, dynamic>> createKamar({
    required String nomorKamar,
    required int idTipeKamar,
    required bool statusKamar,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/kamars'),
      headers: await _headers(),
      body: jsonEncode({
        'nomor_kamar': nomorKamar,
        'id_tipe_kamar': idTipeKamar,
        'status_kamar': statusKamar ? 1 : 0,
      }),
    );
    final data = jsonDecode(response.body);
    return {
      'success': response.statusCode == 201,
      'message': data['message'],
      'data': data,
    };
  }

  Future<Map<String, dynamic>> updateKamar(
    int id, {
    required String nomorKamar,
    required int idTipeKamar,
    bool? statusKamar,
  }) async {
    final body = <String, dynamic>{
      'nomor_kamar': nomorKamar,
      'id_tipe_kamar': idTipeKamar,
    };
    if (statusKamar != null) body['status_kamar'] = statusKamar ? 1 : 0;

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/kamars/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  Future<Map<String, dynamic>> deleteKamar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/kamars/$id'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  // ================================================================
  // CRUD TIPE KAMAR - Mapping ke TipeKamarAdminApiController
  // ================================================================

  Future<List<TipeKamarModel>> getTipeKamars() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/tipe-kamars'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['tipe_kamars'] as List)
          .map((e) => TipeKamarModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat tipe kamar');
  }

  /// Dengan upload foto (multipart)
  Future<Map<String, dynamic>> createTipeKamar({
    required String namaTipeKamar,
    required double hargaPerMalam,
    required int kapasitas,
    String? deskripsi,
    File? foto,
    List<int>? fasilitasIds,
  }) async {
    final token = await _authService.getToken();
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/admin/tipe-kamars'),
    );

    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['nama_tipe_kamar'] = namaTipeKamar;
    request.fields['harga_per_malam'] = hargaPerMalam.toString();
    request.fields['kapasitas'] = kapasitas.toString();
    if (deskripsi != null) request.fields['deskripsi'] = deskripsi;

    if (fasilitasIds != null) {
      for (int i = 0; i < fasilitasIds.length; i++) {
        request.fields['fasilitas_ids[$i]'] = fasilitasIds[i].toString();
      }
    }

    if (foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    return {
      'success': response.statusCode == 201,
      'message': data['message'],
      'data': data,
    };
  }

  Future<Map<String, dynamic>> updateTipeKamar(
    int id, {
    required String namaTipeKamar,
    required double hargaPerMalam,
    required int kapasitas,
    String? deskripsi,
    File? foto,
    List<int>? fasilitasIds,
  }) async {
    final token = await _authService.getToken();

    // Laravel membutuhkan POST + _method=PUT untuk multipart
    var request = http.MultipartRequest(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/admin/tipe-kamars/$id'),
    );

    request.headers['Accept'] = 'application/json';
    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.fields['_method'] = 'PUT';
    request.fields['nama_tipe_kamar'] = namaTipeKamar;
    request.fields['harga_per_malam'] = hargaPerMalam.toString();
    request.fields['kapasitas'] = kapasitas.toString();
    if (deskripsi != null) request.fields['deskripsi'] = deskripsi;

    if (fasilitasIds != null) {
      for (int i = 0; i < fasilitasIds.length; i++) {
        request.fields['fasilitas_ids[$i]'] = fasilitasIds[i].toString();
      }
    }

    if (foto != null) {
      request.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    }

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  Future<Map<String, dynamic>> deleteTipeKamar(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/tipe-kamars/$id'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  // ================================================================
  // CRUD FASILITAS - Mapping ke FasilitasAdminApiController
  // ================================================================

  Future<List<FasilitasModel>> getFasilitas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/fasilitas'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['fasilitas'] as List)
          .map((e) => FasilitasModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat fasilitas');
  }

  Future<Map<String, dynamic>> createFasilitas({
    required String namaFasilitas,
    String? deskripsi,
    double? biayaTambahan,
    String? icon,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/fasilitas'),
      headers: await _headers(),
      body: jsonEncode({
        'nama_fasilitas': namaFasilitas,
        'deskripsi': deskripsi,
        'biaya_tambahan': biayaTambahan ?? 0,
        'icon': icon,
      }),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 201, 'message': data['message']};
  }

  Future<Map<String, dynamic>> updateFasilitas(
    int id, {
    required String namaFasilitas,
    String? deskripsi,
    double? biayaTambahan,
    String? icon,
  }) async {
    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/fasilitas/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'nama_fasilitas': namaFasilitas,
        'deskripsi': deskripsi,
        'biaya_tambahan': biayaTambahan ?? 0,
        'icon': icon,
      }),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  Future<Map<String, dynamic>> deleteFasilitas(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/fasilitas/$id'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  // ================================================================
  // CRUD USER - Mapping ke UserAdminApiController
  // ================================================================

  Future<List<UserModel>> getUsers() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/users'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['users'] as List).map((e) => UserModel.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat users');
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String email,
    required String password,
    required String passwordConfirmation,
    required int idRole,
  }) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/users'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': passwordConfirmation,
        'id_role': idRole,
      }),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 201, 'message': data['message']};
  }

  Future<Map<String, dynamic>> updateUser(
    int id, {
    required String name,
    required String email,
    required int idRole,
    String? password,
    String? passwordConfirmation,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'email': email,
      'id_role': idRole,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
      body['password_confirmation'] = passwordConfirmation;
    }

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  Future<Map<String, dynamic>> deleteUser(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/users/$id'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  // ================================================================
  // CRUD PEMESANAN - Mapping ke PemesananAdminApiController
  // ================================================================

  Future<List<PemesananModel>> getPemesanans() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/pemesanans'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['pemesanans'] as List)
          .map((e) => PemesananModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat pemesanan');
  }

  /// FUNGSI BARU: CREATE PEMESANAN MANUAL
  Future<Map<String, dynamic>> createPemesanan({
    int? userId,
    required int kamarId,
    required String checkInDate,
    required String checkOutDate,
    required int jumlahTamu,
    required double totalHarga,
    required String statusPemesanan,
    required List<int> fasilitasIds,
    required String customerType,
    String? newUserName, // Untuk tamu baru
    String? newUserEmail,
  }) async {
    
    // 1. Pastikan Map dideklarasikan sebagai <String, dynamic>
    final body = <String, dynamic>{
      'kamar_id': kamarId,
      'check_in_date': checkInDate,
      'check_out_date': checkOutDate,
      'jumlah_tamu': jumlahTamu,
      'total_harga': totalHarga,
      'status_pemesanan': statusPemesanan,
      'fasilitas_ids': fasilitasIds,
      'customer_type': customerType, // <--- 2. INI SANGAT PENTING AGAR LARAVEL TIDAK ERROR
    };

    // 3. Masukkan data dinamis sesuai customer_type
    if (customerType == 'new') {
      body['new_user_name'] = newUserName;
      body['new_user_email'] = newUserEmail;
    } else {
      body['user_id'] = userId;
    }

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin/pemesanans'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    return {
      'success': response.statusCode == 201 || response.statusCode == 200,
      'message': data['message'] ?? 'Gagal membuat pesanan.',
    };
  }

  /// FUNGSI: MENGAMBIL DETAIL PEMESANAN (Untuk Edit)
  Future<PemesananModel> getPemesananDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/pemesanans/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return PemesananModel.fromJson(data['pemesanan']);
    }
    throw Exception('Gagal memuat detail pesanan');
  }

  /// FUNGSI: UPDATE PEMESANAN (Untuk Edit)
  Future<Map<String, dynamic>> updatePemesanan(
    int id, {
    required int userId,
    required int kamarId,
    required String checkInDate,
    required String checkOutDate,
    required int jumlahTamu,
    required List<int> fasilitasIds,
    required String statusPemesanan,
  }) async {
    final body = {
      'user_id': userId,
      'kamar_id': kamarId,
      'check_in_date': checkInDate,
      'check_out_date': checkOutDate,
      'jumlah_tamu': jumlahTamu,
      'fasilitas_ids': fasilitasIds,
      'status_pemesanan': statusPemesanan,
    };

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/admin/pemesanans/$id'),
      headers: await _headers(),
      body: jsonEncode(body),
    );

    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  Future<Map<String, dynamic>> confirmPemesanan(int id) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/admin/pemesanans/$id/confirm'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  Future<Map<String, dynamic>> checkInPemesanan(int id) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/admin/pemesanans/$id/checkin'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  Future<Map<String, dynamic>> checkOutPemesanan(int id) async {
    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/admin/pemesanans/$id/checkout'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  Future<Map<String, dynamic>> deletePemesanan(int id) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/admin/pemesanans/$id'),
      headers: await _headers(),
    );
    final data = jsonDecode(response.body);
    return {'success': response.statusCode == 200, 'message': data['message']};
  }

  /// GET /api/admin/riwayat/pemesanan
  Future<List<PemesananModel>> getRiwayatPemesanan() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/admin/riwayat/pemesanan'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['riwayat'] as List)
          .map((e) => PemesananModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat riwayat');
  }
}
