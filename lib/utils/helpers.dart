import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'constants.dart';

class Helpers {
  /// Format Rupiah: Rp 500.000
  static String formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  /// Format tanggal: 15 Maret 2026
  static String formatTanggal(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateString;
    }
  }

  /// Format tanggal pendek: 15 Mar 2026
  static String formatTanggalPendek(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMM yyyy', 'id_ID').format(date);
    } catch (_) {
      return dateString;
    }
  }

  /// Color badge berdasarkan status pemesanan
  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.info;
      case 'checked_in':
        return AppColors.primary;
      case 'checked_out':
        return AppColors.textMuted;
      case 'cancelled':
        return AppColors.danger;
      case 'paid':
        return AppColors.accentGreen;
      default:
        return AppColors.textMuted;
    }
  }

  /// Snackbar helper
  static void showSnackBar(BuildContext context, String message,
      {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.accentGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}