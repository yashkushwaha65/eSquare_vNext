import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:esquare/providers/pre_gate_inPdr.dart';

class ContainerNumberField extends StatelessWidget {
  final FocusNode focusNode;

  const ContainerNumberField({
    super.key,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    // Use Consumer to get the provider and rebuild only this widget on changes
    return Consumer<PreGateInProvider>(
      builder: (context, provider, child) {
        return TextFormField(
          controller: provider.containerNoController,
          focusNode: focusNode,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textCapitalization: TextCapitalization.characters,
          maxLength: 11,
          decoration: InputDecoration(
            labelText: 'Container No.*',
            hintText: 'MSCU1234567',
            border: const OutlineInputBorder(),
            errorText: provider.errors['containerNo'],
            counterText: "",
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          ],
          validator: (value) {
            if (value == null || value.isEmpty) return null;
            final formatRegex = RegExp(r'^[A-Z]{4}[0-9]{7}$');
            if (!formatRegex.hasMatch(value)) {
              return 'Format must be 4 letters, 7 digits.';
            }
            return null;
          },
        );
      },
    );
  }
}