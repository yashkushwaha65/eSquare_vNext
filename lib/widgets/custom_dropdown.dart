import 'package:flutter/material.dart';

class CustomDropdown extends StatelessWidget {
  final String label;
  final List<dynamic> items;
  final dynamic value;
  final Function(dynamic) onChanged;

  const CustomDropdown({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: DropdownButtonFormField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
        value: value,
        items: items
            .map<DropdownMenuItem<dynamic>>(
              (e) => DropdownMenuItem(value: e, child: Text(e.toString())),
            )
            .toList(),
        onChanged: onChanged,
        validator: (value) => value == null ? "Select $label" : null,
      ),
    );
  }
}
