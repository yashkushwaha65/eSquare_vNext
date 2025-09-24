// lib/screens/pre_survey/tabs/transporter_tab.dart
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

  // 1. Declare a variable to hold the provider instance.
  late PreGateInProvider _provider;

  @override
  void initState() {
    super.initState();
    // 2. Initialize the provider immediately and safely.
    _provider = Provider.of<PreGateInProvider>(context, listen: false);

    // 3. Use the stored _provider instance to add listeners.
    _provider.vehicleNoFocusNode.addListener(_onVehicleNoUnfocus);
    _provider.driverLicenseFocusNode.addListener(_onDriverLicUnfocus);
  }

  @override
  void dispose() {
    // 4. Use the stored _provider instance to safely remove listeners.
    _provider.vehicleNoFocusNode.removeListener(_onVehicleNoUnfocus);
    _provider.driverLicenseFocusNode.removeListener(_onDriverLicUnfocus);
    super.dispose();
  }

  // Listener for vehicle number field unfocus
  void _onVehicleNoUnfocus() {
    // 5. Use the stored _provider, which is guaranteed to be initialized.
    if (!_provider.vehicleNoFocusNode.hasFocus) {
      _validateVehicleNo();
    }
  }

  // Listener for driver license field unfocus
  void _onDriverLicUnfocus() {
    if (!_provider.driverLicenseFocusNode.hasFocus) {
      _validateDriverLic();
    }
  }

  Future<void> _validateVehicleNo() async {
    final value = _provider.vehicleNoController.text.trim();
    final vehicleNoRegex = RegExp(r'^[A-Z]{2}[0-9]{2}[A-Z]{2}[0-9]{4}$');

    if (mounted &&
        !_isShowingValidationDialog &&
        value.isNotEmpty &&
        !vehicleNoRegex.hasMatch(value)) {
      _isShowingValidationDialog = true;
      await CautionDialog.show(
        context: context,
        title: 'Invalid Vehicle Number',
        message:
            'Format must be like GJ15AG1234 (2 letters, 2 numbers, 2 letters, 4 numbers).',
      );
      _provider.vehicleNoController.clear();
      _provider.transporterValues['vehicleNo'] = '';
      _provider.errors['vehicleNo'] = ' ';
      _provider.notifyListeners();
      _provider.vehicleNoFocusNode.requestFocus();
      _isShowingValidationDialog = false;
    }
  }

  Future<void> _validateDriverLic() async {
    final value = _provider.driverLicNoController.text.trim();

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
      _provider.driverLicNoController.clear();
      _provider.transporterValues['driverLicense'] = '';
      _provider.errors['driverLicense'] = ' ';
      _provider.notifyListeners();
      _provider.driverLicenseFocusNode.requestFocus();
      _isShowingValidationDialog = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // The build method can still get the provider normally.
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
          TextInputConfig(
            key: 'vehicleNo',
            label: 'Vehicle Number',
            hint: 'GJ-15-AG-1234',
            isRequired: true,
            uppercase: true,
            maxLength: 10,
          ).buildWidget(
            context,
            provider.transporterValues['vehicleNo'],
            (value) => provider.transporterValues['vehicleNo'] = value,
            provider.errors['vehicleNo'],
            provider.vehicleNoController,
            focusNode: provider.vehicleNoFocusNode,
            onSubmitted: (_) => _validateVehicleNo(),
          ),
          const SizedBox(height: 16),
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
            onSubmitted: (_) => _validateDriverLic(),
          ),
          const SizedBox(height: 16),
          TextInputConfig(
            key: 'driverName',
            label: 'Driver Name',
            hint: 'John Doe',
            isRequired: true,
            maxLength: 15,
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
