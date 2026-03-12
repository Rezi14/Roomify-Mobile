import 'user_model.dart';
import 'kamar_model.dart';
import 'fasilitas_model.dart';

class PemesananModel {
  final int idPemesanan;
  final int userId;
  final int kamarId;
  final String checkInDate;
  final String checkOutDate;
  final int jumlahTamu;
  final double totalHarga;
  final String statusPemesanan; // pending, confirmed, checked_in, checked_out, cancelled, paid
  final String? createdAt;
  final String? updatedAt;
  final UserModel? user;
  final KamarModel? kamar;
  final List<FasilitasModel> fasilitas;

  PemesananModel({
    required this.idPemesanan,
    required this.userId,
    required this.kamarId,
    required this.checkInDate,
    required this.checkOutDate,
    required this.jumlahTamu,
    required this.totalHarga,
    required this.statusPemesanan,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.kamar,
    this.fasilitas = const [],
  });

  factory PemesananModel.fromJson(Map<String, dynamic> json) {
    return PemesananModel(
      idPemesanan: json['id_pemesanan'] is int
          ? json['id_pemesanan']
          : int.parse(json['id_pemesanan'].toString()),
      userId: json['user_id'] is int
          ? json['user_id']
          : int.parse(json['user_id'].toString()),
      kamarId: json['kamar_id'] is int
          ? json['kamar_id']
          : int.parse(json['kamar_id'].toString()),
      checkInDate: json['check_in_date'] ?? '',
      checkOutDate: json['check_out_date'] ?? '',
      jumlahTamu: json['jumlah_tamu'] is int
          ? json['jumlah_tamu']
          : int.parse(json['jumlah_tamu'].toString()),
      totalHarga: _parseDouble(json['total_harga']),
      statusPemesanan: json['status_pemesanan'] ?? 'pending',
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      kamar: json['kamar'] != null ? KamarModel.fromJson(json['kamar']) : null,
      fasilitas: json['fasilitas'] != null
          ? (json['fasilitas'] as List)
              .map((e) => FasilitasModel.fromJson(e))
              .toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_pemesanan': idPemesanan,
      'user_id': userId,
      'kamar_id': kamarId,
      'check_in_date': checkInDate,
      'check_out_date': checkOutDate,
      'jumlah_tamu': jumlahTamu,
      'total_harga': totalHarga,
      'status_pemesanan': statusPemesanan,
    };
  }

  // Helper status
  bool get isPending => statusPemesanan == 'pending';
  bool get isConfirmed => statusPemesanan == 'confirmed';
  bool get isCheckedIn => statusPemesanan == 'checked_in';
  bool get isCheckedOut => statusPemesanan == 'checked_out';
  bool get isCancelled => statusPemesanan == 'cancelled';
  bool get isPaid => statusPemesanan == 'paid';

  String get statusLabel {
    switch (statusPemesanan) {
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'confirmed':
        return 'Dikonfirmasi';
      case 'checked_in':
        return 'Checked In';
      case 'checked_out':
        return 'Checked Out';
      case 'cancelled':
        return 'Dibatalkan';
      case 'paid':
        return 'Lunas';
      default:
        return statusPemesanan;
    }
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}