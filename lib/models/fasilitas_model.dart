class FasilitasModel {
  final int idFasilitas;
  final String namaFasilitas;
  final String? deskripsi;
  final String? icon;
  final double biayaTambahan;
  // Pivot data (dari pemesanan_fasilitas)
  final int? pivotJumlah;
  final double? pivotTotalHargaFasilitas;

  FasilitasModel({
    required this.idFasilitas,
    required this.namaFasilitas,
    this.deskripsi,
    this.icon,
    this.biayaTambahan = 0,
    this.pivotJumlah,
    this.pivotTotalHargaFasilitas,
  });

  factory FasilitasModel.fromJson(Map<String, dynamic> json) {
    // Parse pivot data jika ada
    final pivot = json['pivot'];

    return FasilitasModel(
      idFasilitas: json['id_fasilitas'] is int
          ? json['id_fasilitas']
          : int.parse(json['id_fasilitas'].toString()),
      namaFasilitas: json['nama_fasilitas'] ?? '',
      deskripsi: json['deskripsi'],
      icon: json['icon'],
      biayaTambahan: _parseDouble(json['biaya_tambahan']),
      pivotJumlah: pivot != null ? _parseInt(pivot['jumlah']) : null,
      pivotTotalHargaFasilitas:
          pivot != null ? _parseDoubleNullable(pivot['total_harga_fasilitas']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_fasilitas': idFasilitas,
      'nama_fasilitas': namaFasilitas,
      'deskripsi': deskripsi,
      'icon': icon,
      'biaya_tambahan': biayaTambahan,
    };
  }

  bool get isBerbayar => biayaTambahan > 0;

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  static double? _parseDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}