import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:esquare/widgets/caution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ContainerNumberField extends StatelessWidget {
  final FocusNode focusNode;
  final FocusNode nextFocusNode;

  const ContainerNumberField({
    super.key,
    required this.focusNode,
    required this.nextFocusNode,
  });

  @override
  @override
  Widget build(BuildContext context) {
    return Consumer<PreGateInProvider>(
      builder: (context, provider, child) {
        return TextFormField(
          controller: provider.containerNoController,
          focusNode: focusNode,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          textCapitalization: TextCapitalization.characters,
          maxLength: 11,
          decoration: InputDecoration(
            label: RichText(
              text: TextSpan(
                text: 'Container No.',
                style: DefaultTextStyle.of(context).style,
                children: const [
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: Colors.red),
                  ),
                ],
              ),
            ),
            hintText: 'MSCU1234567',
            border: const OutlineInputBorder(),
            errorText: provider.errors['containerNo'],
            counterText: "",
          ),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
          ],
          onChanged: (value) {
            final upperCaseValue = value.toUpperCase();
            if (provider.containerNoController.text != upperCaseValue) {
              provider.containerNoController.value = provider
                  .containerNoController
                  .value
                  .copyWith(
                    text: upperCaseValue,
                    selection: TextSelection.collapsed(
                      offset: upperCaseValue.length,
                    ),
                  );
            }
          },
          onFieldSubmitted: (value) async {
            final formatRegex = RegExp(r'^[A-Z]{4}[0-9]{7}$');
            final isFormatValid = formatRegex.hasMatch(value);

            if (!isFormatValid) {
              provider.containerValid = false; // Mark invalid
              // ADDED: Check context before showing a dialog.
              if (!context.mounted) return;
              await showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Invalid Format'),
                  content: const Text(
                    'Container number is invalid. Please enter a valid container number in the format ABCD1234567.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
              return;
            }

            // --- MODIFIED: Perform parallel checks first ---
            final canProceed = await provider.canProceedWithContainer(value);
            if (!context.mounted) return;

            if (!canProceed) {
              await CautionDialog.show(
                context: context,
                title: 'Container Already Processed',
                message: 'already this container has survey done',
                // As requested by user
                icon: Icons.info_outline,
                iconColor: Colors.blue,
              );
              if (!context.mounted) return;
              provider.containerNoController.clear();
              return; // Stop further validation
            }
            // --- END OF MODIFICATION ---

            // API validation
            final isValidFromApi = await provider.validateContainer(value);
            // ADDED: Check context after an async API call.
            if (!context.mounted) return;
            provider.containerValid = isValidFromApi;

            if (!isValidFromApi) {
              final shouldProceed =
                  await CautionDialog.showInvalidContainerConfirmation(context);
              // ADDED: Check context after the confirmation dialog.
              if (!context.mounted) return;

              if (!shouldProceed) {
                provider.containerNoController.clear();
              } else {
                provider.containerValid =
                    false; // User chooses to continue even if invalid
              }
            }
            nextFocusNode.requestFocus();
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Container Number is required.';
            }
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
