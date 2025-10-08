import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:esquare/widgets/caution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ContainerNumberField extends StatefulWidget {
  final FocusNode focusNode;
  final FocusNode nextFocusNode;

  const ContainerNumberField({
    super.key,
    required this.focusNode,
    required this.nextFocusNode,
  });

  @override
  State<ContainerNumberField> createState() => _ContainerNumberFieldState();
}

class _ContainerNumberFieldState extends State<ContainerNumberField> {
  bool _isValidationRunning = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_onFocusChange);
    super.dispose();
  }

  void _onFocusChange() {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    // Run validation only when focus is lost and the field has text
    if (!widget.focusNode.hasFocus &&
        provider.containerNoController.text.isNotEmpty) {
      _runValidation(provider.containerNoController.text);
    }
  }

  Future<void> _runValidation(String value) async {
    // Prevent validation from running multiple times simultaneously
    if (_isValidationRunning) return;
    setState(() => _isValidationRunning = true);

    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    final formatRegex = RegExp(r'^[A-Z]{4}[0-9]{7}$');
    debugPrint("--- Starting Container Validation for: $value ---");

    // 1. Format Validation
    debugPrint("1. Checking format...");
    if (!formatRegex.hasMatch(value)) {
      debugPrint("   -> Format INVALID.");
      if (!mounted) return;
      await CautionDialog.show(
        context: context,
        title: 'Invalid Format',
        message:
            'Container number must be 4 letters followed by 7 digits (e.g., ABCD1234567).',
        onConfirm: () {
          provider.containerNoController.clear();
        },
      );
      setState(() => _isValidationRunning = false);
      debugPrint("--- Validation Ended: Invalid Format ---");
      return;
    }
    debugPrint("   -> Format OK.");

    // 2. Existence Validation
    debugPrint("2. Checking container existence (API)...");
    final isValidFromApi = await provider.validateContainer(value);
    debugPrint("   -> Container is valid: $isValidFromApi");
    if (!mounted) {
      setState(() => _isValidationRunning = false);
      return;
    }

    if (isValidFromApi) {
      // 3. Survey Done Validation
      debugPrint("3. Checking if survey is done (API)...");
      final isSurveyDone = await provider.checkSurveyDone(value);
      debugPrint("   -> Survey is done: $isSurveyDone");
      if (!mounted) {
        setState(() => _isValidationRunning = false);
        return;
      }

      if (isSurveyDone) {
        await CautionDialog.show(
          context: context,
          title: 'Survey Already Completed',
          message:
              'A survey for this container number has already been completed.',
          icon: Icons.error_outline,
          iconColor: Colors.red,
          onConfirm: () {
            provider.containerNoController.clear();
          },
        );
        debugPrint("--- Validation Ended: Survey Done ---");
      } else {
        provider.containerValid = true;
        widget.nextFocusNode.requestFocus();
        debugPrint("--- Validation Ended: Success ---");
      }
    } else {
      // Container does not exist in the system
      final shouldProceed =
          await CautionDialog.showInvalidContainerConfirmation(context);
      debugPrint(
        "   -> User choose to continue with invalid container: $shouldProceed",
      );
      if (!mounted) {
        setState(() => _isValidationRunning = false);
        return;
      }

      if (shouldProceed) {
        provider.containerValid =
            false; // User wants to continue with invalid number
        widget.nextFocusNode.requestFocus();
      } else {
        provider.containerNoController.clear(); // User wants to clear
      }
      debugPrint("--- Validation Ended: Container Not Found ---");
    }

    setState(() => _isValidationRunning = false);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PreGateInProvider>(
      builder: (context, provider, child) {
        return TextFormField(
          controller: provider.containerNoController,
          focusNode: widget.focusNode,
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
            if (value.isNotEmpty) {
              await _runValidation(value);
            } else {
              // If user submits an empty field, just move focus
              widget.nextFocusNode.requestFocus();
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Container Number is required.';
            }
            // Basic format check for inline validation, full logic runs on submit/unfocus
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
