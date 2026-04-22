import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:frontendsharecare/shared/models/picked_location.dart';

import '../../../core/theme/app_theme.dart';
import '../../../screens/leaflet_map_location_picker_screen.dart';

/// Reusable section header with icon for donation forms.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.icon,
    required this.title,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: iconColor ?? AppTheme.primaryTeal),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryGreenDark,
          ),
        ),
      ],
    );
  }
}

/// Reusable quantity field with amount + unit selector.
class QuantityField extends StatelessWidget {
  const QuantityField({
    super.key,
    required this.quantityController,
    required this.unit,
    required this.units,
    required this.onUnitChanged,
    this.hintText = 'Amount',
    this.validator,
  });

  final TextEditingController quantityController;
  final String unit;
  final List<Map<String, String>> units;
  final ValueChanged<String?> onUnitChanged;
  final String hintText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: quantityController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: hintText,
              border: const OutlineInputBorder(),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            validator:
                validator ??
                ((v) => (v == null || v.isEmpty) ? 'Required' : null),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<String>(
            initialValue: unit,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            ),
            items: units
                .map(
                  (u) => DropdownMenuItem(
                    value: u['value'],
                    child: Text(
                      u['label']!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                )
                .toList(),
            onChanged: onUnitChanged,
          ),
        ),
      ],
    );
  }
}

/// Reusable pickup/delivery location field (text only).
class LocationField extends StatelessWidget {
  const LocationField({
    super.key,
    required this.controller,
    this.hintText = 'Address or area',
    this.validator,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.place_rounded, color: AppTheme.primaryTeal),
        border: OutlineInputBorder(),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator:
          validator ??
          ((v) => (v == null || v.isEmpty) ? 'Enter location' : null),
    );
  }
}

/// Read-only pickup field with map picker.
class PickupLocationField extends StatelessWidget {
  const PickupLocationField({
    super.key,
    required this.controller,
    this.hintText = 'Address or area',
    this.validator,
    this.onLocationPicked,
    this.initialLat,
    this.initialLng,
  });

  final TextEditingController controller;
  final String hintText;
  final String? Function(String?)? validator;

  /// Callback with selected latitude, longitude, and address.
  final void Function(double latitude, double longitude, String address)?
  onLocationPicked;
  final double? initialLat;
  final double? initialLng;

  Future<void> _openMapPicker(BuildContext context) async {
    final result = await Navigator.of(context).push<PickedLocation>(
      MaterialPageRoute(
        builder: (context) => LeafletMapLocationPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
          initialAddress: controller.text.trim().isEmpty
              ? null
              : controller.text.trim(),
        ),
      ),
    );
    if (result == null || !context.mounted) return;
    // Use full TextEditingValue update to force immediate field refresh.
    controller.value = TextEditingValue(
      text: result.address,
      selection: TextSelection.collapsed(offset: result.address.length),
    );
    onLocationPicked?.call(result.latitude, result.longitude, result.address);
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _openMapPicker(context),
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(Icons.place_rounded, color: AppTheme.primaryTeal),
        suffixIcon: IconButton(
          icon: const Icon(Icons.map_rounded),
          onPressed: () => _openMapPicker(context),
          tooltip: 'Pick on map',
          color: AppTheme.primaryTeal,
        ),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
      validator:
          validator ??
          ((v) => (v == null || v.isEmpty) ? 'Enter location' : null),
    );
  }
}

/// Urgency selector (Low / Medium / High).
class UrgencySelector extends StatelessWidget {
  const UrgencySelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  static const List<Map<String, String>> _options = [
    {'value': 'Low', 'label': 'Low'},
    {'value': 'Medium', 'label': 'Medium'},
    {'value': 'High', 'label': 'High'},
  ];

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _options.map((o) {
        final selected = value == o['value'];
        Color? chipColor;
        if (o['value'] == 'High') chipColor = AppTheme.statusError;
        if (o['value'] == 'Medium') chipColor = AppTheme.statusWarning;
        return FilterChip(
          label: Text(o['label']!),
          selected: selected,
          onSelected: (_) => onChanged(o['value']!),
          selectedColor: (chipColor ?? AppTheme.primaryTeal).withValues(
            alpha: 0.3,
          ),
        );
      }).toList(),
    );
  }
}

/// Date picker input field.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.value,
    required this.onDatePicked,
    this.label = 'Select date',
    this.firstDate,
    this.lastDate,
    this.badge,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onDatePicked;
  final String label;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final Widget? badge;

  Future<void> _pickDate(BuildContext context) async {
    final d = await showDatePicker(
      context: context,
      initialDate: value ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: firstDate ?? DateTime.now(),
      lastDate: lastDate ?? DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) onDatePicked(d);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _pickDate(context),
      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, color: AppTheme.primaryTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value != null
                    ? '${value!.day}/${value!.month}/${value!.year}'
                    : label,
                style: GoogleFonts.poppins(
                  color: value != null ? Colors.black87 : Colors.grey,
                  fontSize: 14,
                ),
              ),
            ),
            ?badge,
          ],
        ),
      ),
    );
  }
}
