import 'package:flutter/material.dart';
import '../utils/helpers.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({super.key, required this.status});

  String get _label {
    switch (status) {
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
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Helpers.getStatusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 12,
          fontFamily: 'Poppins',
        ),
      ),
    );
  }
}