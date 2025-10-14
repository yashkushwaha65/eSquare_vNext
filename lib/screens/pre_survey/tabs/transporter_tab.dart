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

class _TransporterTabState extends State<TransporterTab>
    with AutomaticKeepAliveClientMixin {
  final FocusNode _vehicleNoFocusNode = FocusNode();
  final FocusNode _driverLicenseFocusNode = FocusNode();
  bool _isShowingValidationDialog = false;

  late PreGateInProvider _provider;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<PreGateInProvider>(context, listen: false);
    _vehicleNoFocusNode.addListener(_onVehicleNoUnfocus);
    _driverLicenseFocusNode.addListener(_onDriverLicUnfocus);
  }

  @override
  void dispose() {
    _vehicleNoFocusNode.removeListener(_onVehicleNoUnfocus);
    _driverLicenseFocusNode.removeListener(_onDriverLicUnfocus);
    _vehicleNoFocusNode.dispose();
    _driverLicenseFocusNode.dispose();
    super.dispose();
  }

  void _onVehicleNoUnfocus() {
    // --- FIX: Check if the widget is still mounted before proceeding ---
    if (!mounted) return;
    if (!_vehicleNoFocusNode.hasFocus) {
      _validateVehicleNo();
    }
  }

  void _onDriverLicUnfocus() {
    // --- FIX: Check if the widget is still mounted before proceeding ---
    if (!mounted) return;
    if (!_driverLicenseFocusNode.hasFocus) {
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
      // ADDED: Check if the widget is still mounted after the dialog.
      if (!mounted) return;
      _provider.vehicleNoController.clear();
      _provider.transporterValues['vehicleNo'] = '';
      _provider.errors['vehicleNo'] = ' ';
      _provider.notifyListeners();
      // --- FIX: Check if mounted before requesting focus ---
      if (mounted) {
        _vehicleNoFocusNode.requestFocus();
      }
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
      // ADDED: Check if the widget is still mounted after the dialog.
      if (!mounted) return;
      _provider.driverLicNoController.clear();
      _provider.transporterValues['driverLicense'] = '';
      _provider.errors['driverLicense'] = ' ';
      _provider.notifyListeners();
      // --- FIX: Check if mounted before requesting focus ---
      if (mounted) {
        _driverLicenseFocusNode.requestFocus();
      }
      _isShowingValidationDialog = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
          SearchableDropdown(
            label: 'Transporter Name',
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
            selectedValue: provider.selectedTransId,
            onChanged: (value) => provider.selectedTransId = value,
            error: provider.errors['transporterName'],
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
          ),
          const SizedBox(height: 16),
          TextInputConfig(
            key: 'vehicleNo',
            label: 'Vehicle Number',
            hint: 'GJ-15-AG-1234',
            isRequired: false,
            uppercase: true,
            maxLength: 10,
          ).buildWidget(
            context,
            provider.transporterValues['vehicleNo'],
            (value) => provider.transporterValues['vehicleNo'] = value,
            provider.errors['vehicleNo'],
            provider.vehicleNoController,
            focusNode: _vehicleNoFocusNode,
            onSubmitted: (_) => _validateVehicleNo(),
          ),

          const SizedBox(height: 16),
          TextInputConfig(
            key: 'driverName',
            label: 'Driver Name',
            hint: 'John Doe',
            isRequired: false,
            maxLength: 15,
          ).buildWidget(
            context,
            provider.transporterValues['driverName'],
            (value) => provider.transporterValues['driverName'] = value,
            provider.errors['driverName'],
            provider.driverNameController,
          ),
          const SizedBox(height: 16),
          TextInputConfig(
            key: 'driverLicense',
            label: 'Driver License Number',
            hint: 'MH1234567890123',
            isRequired: false,
            maxLength: 16,
          ).buildWidget(
            context,
            provider.transporterValues['driverLicense'],
            (value) => provider.transporterValues['driverLicense'] = value,
            provider.errors['driverLicense'],
            provider.driverLicNoController,
            focusNode: _driverLicenseFocusNode,
            onSubmitted: (_) => _validateDriverLic(),
          ),
        ],
      ),
    );
  }
}
