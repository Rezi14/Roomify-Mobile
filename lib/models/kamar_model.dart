import 'tipe_kamar_model.dart';

class KamarModel {
  final int idKamar;
  final String nomorKamar;
  final int idTipeKamar;
  final bool statusKamar;
  final TipeKamarModel? tipeKamar;

  KamarModel({
    required this.idKamar,
    required this.nomorKamar,
    required this.idTipeKamar,
    required this.statusKamar,
    this.tipeKamar,
  });

  factory KamarModel.fromJson(Map<String, dynamic> json) {
    return KamarModel(
      idKamar: json['id_kamar'] is int
          ? json['id_kamar']
          : int.parse(json['id_kamar'].toString()),
      nomorKamar: json['nomor_kamar'] ?? '',
      idTipeKamar: json['id_tipe_kamar'] is int
          ? json['id_tipe_kamar']
          : int.parse(json['id_tipe_kamar'].toString()),
      statusKamar: json['status_kamar'] == true ||
          json['status_kamar'] == 1 ||
          json['status_kamar'] == '1',
      tipeKamar: json['tipe_kamar'] != null
          ? TipeKamarModel.fromJson(json['tipe_kamar'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_kamar': idKamar,
      'nomor_kamar': nomorKamar,
      'id_tipe_kamar': idTipeKamar,
      'status_kamar': statusKamar ? 1 : 0,
    };
  }
}