import 'fasilitas_model.dart';

class TipeKamarModel {
  final int idTipeKamar;
  final String namaTipeKamar;
  final double hargaPerMalam;
  final int kapasitas;
  final String? deskripsi;
  final String? fotoUrl;
  final List<FasilitasModel> fasilitas;

  TipeKamarModel({
    required this.idTipeKamar,
    required this.namaTipeKamar,
    required this.hargaPerMalam,
    required this.kapasitas,
    this.deskripsi,
    this.fotoUrl,
    this.fasilitas = const [],
  });

  factory TipeKamarModel.fromJson(Map<String, dynamic> json) {
    return TipeKamarModel(
      idTipeKamar: json['id_tipe_kamar'] is int
          ? json['id_tipe_kamar']
          : int.parse(json['id_tipe_kamar'].toString()),
      namaTipeKamar: json['nama_tipe_kamar'] ?? '',
      hargaPerMalam: _parseDouble(json['harga_per_malam']),
      kapasitas: json['kapasitas'] is int
          ? json['kapasitas']
          : int.parse(json['kapasitas'].toString()),
      deskripsi: json['deskripsi'],
      fotoUrl: json['foto_url'],
      fasilitas: json['fasilitas'] != null
          ? (json['fasilitas'] as List)
              .map((e) => FasilitasModel.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_tipe_kamar': idTipeKamar,
      'nama_tipe_kamar': namaTipeKamar,
      'harga_per_malam': hargaPerMalam,
      'kapasitas': kapasitas,
      'deskripsi': deskripsi,
      'foto_url': fotoUrl,
    };
  }

  /// Full URL foto untuk Image.network()
  String? get fullFotoUrl {
    if (fotoUrl == null || fotoUrl!.isEmpty) return null;
    if (fotoUrl!.startsWith('http')) return fotoUrl;
    // Base URL tanpa /api
    const serverBase = 'http://192.168.0.104:8000';
    return '$serverBase$fotoUrl';
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}