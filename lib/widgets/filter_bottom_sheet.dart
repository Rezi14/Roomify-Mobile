import 'package:flutter/material.dart';
import '../models/tipe_kamar_model.dart';
import '../models/fasilitas_model.dart';
import '../utils/constants.dart';

class FilterBottomSheet extends StatefulWidget {
  final List<TipeKamarModel> tipeKamars;
  final List<FasilitasModel> fasilitas;
  final Function(Map<String, dynamic> filters) onApply;

  const FilterBottomSheet({
    super.key,
    required this.tipeKamars,
    required this.fasilitas,
    required this.onApply,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int? _selectedTipeKamar;
  final TextEditingController _hargaMinCtrl = TextEditingController();
  final TextEditingController _hargaMaxCtrl = TextEditingController();
  final List<int> _selectedFasilitas = [];

  Future<void> _selectDate(BuildContext context, bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Pilih tanggal';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Filter Pencarian', style: AppTextStyles.heading.copyWith(fontSize: 20)),
            const SizedBox(height: 16),

            // Tanggal Check-in
            Text('Check-in', style: AppTextStyles.label),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, true),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(_formatDate(_checkIn)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tanggal Check-out
            Text('Check-out', style: AppTextStyles.label),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _selectDate(context, false),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18),
                    const SizedBox(width: 8),
                    Text(_formatDate(_checkOut)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Tipe Kamar Dropdown
            Text('Tipe Kamar', style: AppTextStyles.label),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              value: _selectedTipeKamar,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              hint: const Text('Semua Tipe'),
              items: [
                const DropdownMenuItem<int>(value: null, child: Text('Semua Tipe')),
                ...widget.tipeKamars.map((t) => DropdownMenuItem(
                      value: t.idTipeKamar,
                      child: Text(t.namaTipeKamar),
                    )),
              ],
              onChanged: (val) => setState(() => _selectedTipeKamar = val),
            ),
            const SizedBox(height: 12),

            // Range Harga
            Text('Range Harga', style: AppTextStyles.label),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _hargaMinCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Min',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text('-'),
                ),
                Expanded(
                  child: TextField(
                    controller: _hargaMaxCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Max',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Fasilitas Checkboxes
            if (widget.fasilitas.isNotEmpty) ...[
              Text('Fasilitas', style: AppTextStyles.label),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: widget.fasilitas.map((f) {
                  final isSelected = _selectedFasilitas.contains(f.idFasilitas);
                  return FilterChip(
                    label: Text(f.namaFasilitas),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedFasilitas.add(f.idFasilitas);
                        } else {
                          _selectedFasilitas.remove(f.idFasilitas);
                        }
                      });
                    },
                    selectedColor: AppColors.primary.withOpacity(0.2),
                    checkmarkColor: AppColors.primary,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // Tombol Apply & Reset
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      widget.onApply({});
                      Navigator.pop(context);
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () {
                      final filters = <String, dynamic>{};
                      if (_checkIn != null) filters['check_in'] = _formatDate(_checkIn);
                      if (_checkOut != null) filters['check_out'] = _formatDate(_checkOut);
                      if (_selectedTipeKamar != null) filters['tipe_kamar'] = _selectedTipeKamar;
                      if (_hargaMinCtrl.text.isNotEmpty) {
                        filters['harga_min'] = double.tryParse(_hargaMinCtrl.text);
                      }
                      if (_hargaMaxCtrl.text.isNotEmpty) {
                        filters['harga_max'] = double.tryParse(_hargaMaxCtrl.text);
                      }
                      if (_selectedFasilitas.isNotEmpty) {
                        filters['fasilitas_ids'] = _selectedFasilitas;
                      }
                      widget.onApply(filters);
                      Navigator.pop(context);
                    },
                    child: const Text('Terapkan Filter'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}