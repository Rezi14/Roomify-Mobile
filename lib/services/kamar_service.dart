import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/kamar_model.dart';
import '../models/tipe_kamar_model.dart';
import '../models/fasilitas_model.dart';
import 'auth_service.dart';

class KamarService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// GET /api/kamars?check_in=...&check_out=...&tipe_kamar=...&harga_min=...&harga_max=...&fasilitas[]=...
  /// Sesuai KamarApiController@index
  Future<List<KamarModel>> getKamars({
    String? checkIn,
    String? checkOut,
    int? tipeKamar,
    double? hargaMin,
    double? hargaMax,
    List<int>? fasilitasIds,
  }) async {
    final queryParams = <String, String>{};

    if (checkIn != null) queryParams['check_in'] = checkIn;
    if (checkOut != null) queryParams['check_out'] = checkOut;
    if (tipeKamar != null) queryParams['tipe_kamar'] = tipeKamar.toString();
    if (hargaMin != null) queryParams['harga_min'] = hargaMin.toString();
    if (hargaMax != null) queryParams['harga_max'] = hargaMax.toString();

    // Fasilitas multi-value: fasilitas[]=1&fasilitas[]=2
    String fasilitasQuery = '';
    if (fasilitasIds != null && fasilitasIds.isNotEmpty) {
      fasilitasQuery = fasilitasIds.map((id) => 'fasilitas[]=$id').join('&');
    }

    var url = '${ApiConfig.baseUrl}/kamars';
    if (queryParams.isNotEmpty || fasilitasQuery.isNotEmpty) {
      url += '?';
      if (queryParams.isNotEmpty) {
        url += queryParams.entries.map((e) => '${e.key}=${e.value}').join('&');
      }
      if (fasilitasQuery.isNotEmpty) {
        url += (queryParams.isNotEmpty ? '&' : '') + fasilitasQuery;
      }
    }

    final response = await http.get(
      Uri.parse(url),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['kamars'] as List)
          .map((e) => KamarModel.fromJson(e))
          .toList();
    }

    throw Exception('Gagal memuat data kamar');
  }

  /// GET /api/kamars/{id}
  Future<KamarModel> getKamarDetail(int id) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/kamars/$id'),
      headers: await _headers(),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return KamarModel.fromJson(data['kamar']);
    }

    throw Exception('Gagal memuat detail kamar');
  }

  /// GET /api/tipe-kamars
  Future<List<TipeKamarModel>> getTipeKamars() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tipe-kamars'),
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

  /// GET /api/fasilitas
  Future<List<FasilitasModel>> getFasilitas() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/fasilitas'),
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
}