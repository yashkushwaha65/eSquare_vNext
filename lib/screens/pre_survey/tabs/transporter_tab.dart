// TransporterTab.dart
import 'package:esquare/core/configs/input_config.dart';
import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:esquare/widgets/caution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TransporterTab extends StatefulWidget {
  const TransporterTab({super.key});

  @override
  State<TransporterTab> createState() => _TransporterTabState();
}

class _TransporterTabState extends State<TransporterTab> {
  bool _isShowingValidationDialog = false;

  @override
  void initState() {
    super.initState();

    // Use a post-frame callback to safely access the provider
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final provider = Provider.of<PreGateInProvider>(context, listen: false);
        // Add listeners to the FocusNodes from the provider
        provider.vehicleNoFocusNode.addListener(_onVehicleNoUnfocus);
        provider.driverLicenseFocusNode.addListener(_onDriverLicUnfocus);
      }
    });
  }

  @override
  void dispose() {
    // Access provider without listening to remove listeners
    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    provider.vehicleNoFocusNode.removeListener(_onVehicleNoUnfocus);
    provider.driverLicenseFocusNode.removeListener(_onDriverLicUnfocus);
    super.dispose();
  }

  // Listener for vehicle number field unfocus
  void _onVehicleNoUnfocus() {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    // Trigger validation only when focus is lost
    if (!provider.vehicleNoFocusNode.hasFocus) {
      _validateVehicleNo();
    }
  }

  // Listener for driver license field unfocus
  void _onDriverLicUnfocus() {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    // Trigger validation only when focus is lost
    if (!provider.driverLicenseFocusNode.hasFocus) {
      _validateDriverLic();
    }
  }

  Future<void> _validateVehicleNo() async {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    final value = provider.vehicleNoController.text.trim();

    // --- 1. UPDATED Validation Logic ---
    // Regex for format: 2 letters, 2 numbers, 2 letters, 4 numbers (e.g., GJ15AG1234)
    final vehicleNoRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{2}[0-9]{4}$');

    if (mounted &&
        !_isShowingValidationDialog &&
        value.isNotEmpty &&
        !vehicleNoRegex.hasMatch(value)) {
      // Check against the new regex
      _isShowingValidationDialog = true;

      await CautionDialog.show(
        context: context,
        title: 'Invalid Vehicle Number',
        message:
            'Format must be like GJ15AG1234 (2 letters, 2 numbers, 2 letters, 4 numbers).',
      );

      provider.vehicleNoController.clear();
      provider.transporterValues['vehicleNo'] = '';
      provider.errors['vehicleNo'] = ' ';
      provider.notifyListeners();

      // Optionally, request focus back to the field for user convenience
      provider.vehicleNoFocusNode.requestFocus();

      _isShowingValidationDialog = false;
    }
  }

  Future<void> _validateDriverLic() async {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    final value = provider.driverLicNoController.text.trim();

    if (mounted &&
        !_isShowingValidationDialog &&
        value.isNotEmpty &&
        (value.length < 16 || value.length > 17)) {
      _isShowingValidationDialog = true;

      await CautionDialog.show(
        context: context,
        title: 'Invalid Driver License Number',
        message: 'Driver License number must be 16 or 17 characters long.',
      );

      provider.driverLicNoController.clear();
      provider.transporterValues['driverLicense'] = '';
      provider.errors['driverLicense'] = ' ';
      provider.notifyListeners();

      // Optionally, request focus back to the field
      provider.driverLicenseFocusNode.requestFocus();

      _isShowingValidationDialog = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreGateInProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Transporter Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter vehicle and driver information',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Vehicle Number Field
          TextInputConfig(
            key: 'vehicleNo',
            label: 'Vehicle Number',
            hint: 'GJ-15-AG-1234',
            // Updated hint
            isRequired: true,
            uppercase: true,
            maxLength: 10
          ).buildWidget(
            context,
            provider.transporterValues['vehicleNo'],
            (value) => provider.transporterValues['vehicleNo'] = value,
            provider.errors['vehicleNo'],
            provider.vehicleNoController,
            focusNode: provider.vehicleNoFocusNode,
            // Pass FocusNode from provider
            onSubmitted: (_) => _validateVehicleNo(),
          ),

          const SizedBox(height: 16),

          // Transporter Name Dropdown
          SelectInputConfig(
            key: 'transporterName',
            label: 'Transporter Name',
            isRequired: true,
            options: provider.transporters
                .where(
                  (t) =>
                      (t['Transporter'] as String).toLowerCase() !=
                      '--define new--',
                )
                .map<Map<String, String>>(
                  (t) => {
                    'value': (t['TransporterID'] as int).toString(),
                    'display': t['Transporter'] as String,
                  },
                )
                .toList(),
            onValidationFailed: (invalidValue) async {
              if (mounted && !_isShowingValidationDialog) {
                _isShowingValidationDialog = true;

                await CautionDialog.show(
                  context: context,
                  title: 'Invalid Transporter',
                  message:
                      'Please select a valid transporter from the dropdown.',
                );

                provider.selectedTransId = null;
                provider.notifyListeners();

                _isShowingValidationDialog = false;
              }
            },
          ).buildWidget(
            context,
            provider.selectedTransId,
            (value) => provider.selectedTransId = value,
            provider.errors['transporterName'],
            null,
          ),

          const SizedBox(height: 16),

          // Driver License Number Field
          TextInputConfig(
            key: 'driverLicense',
            label: 'Driver License Number',
            hint: 'MH1234567890123',
            isRequired: true,
            maxLength: 16,
          ).buildWidget(
            context,
            provider.transporterValues['driverLicense'],
            (value) => provider.transporterValues['driverLicense'] = value,
            provider.errors['driverLicense'],
            provider.driverLicNoController,
            focusNode: provider.driverLicenseFocusNode,
            // Pass FocusNode from provider
            onSubmitted: (_) => _validateDriverLic(),
          ),

          const SizedBox(height: 16),

          // Driver Name Field
          TextInputConfig(
            key: 'driverName',
            label: 'Driver Name',
            hint: 'John Doe',
            isRequired: true,
            maxLength: 15
          ).buildWidget(
            context,
            provider.transporterValues['driverName'],
            (value) => provider.transporterValues['driverName'] = value,
            provider.errors['driverName'],
            provider.driverNameController,
          ),
        ],
      ),
    );
  }
}
