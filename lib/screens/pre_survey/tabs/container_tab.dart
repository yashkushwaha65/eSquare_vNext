import 'package:esquare/core/configs/input_config.dart';
import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:esquare/screens/pre_survey/tabs/widgets/container_number_field.dart';
import 'package:esquare/widgets/caution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ContainerTab extends StatefulWidget {
  const ContainerTab({super.key});

  @override
  State<ContainerTab> createState() => _ContainerTabState();
}

class _ContainerTabState extends State<ContainerTab> {
  late final PreGateInProvider _provider;
  String surveyDateTime = DateFormat(
    'dd MMM yyyy HH:mm',
  ).format(DateTime.now());

  final _containerNoFocus = FocusNode();
  final _isoCodeFocus = FocusNode();
  final _grossWeightFocus = FocusNode();
  final _tareWeightFocus = FocusNode();
  final _mfgYearFocus = FocusNode();
  final _fromLocationFocus = FocusNode();

  // Add controller for ISO code field
  final _isoCodeController = TextEditingController();

  // Add validation state to prevent multiple dialogs
  // bool isValidIsoSelected = false;
  bool _isShowingValidationDialog = false;

  // String _lastValidatedValue = '';

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<PreGateInProvider>(context, listen: false);

    _provider.grossWtController.addListener(_validateWeights);
    _provider.tareWtController.addListener(_validateWeights);
    _provider.mfgYearController.addListener(_validateMfgYear);
    _containerNoFocus.addListener(_onContainerNoFocusChange);
  }

  // New method to handle focus change for Container No.
  void _onContainerNoFocusChange() async {
    if (!_containerNoFocus.hasFocus) {
      final provider = Provider.of<PreGateInProvider>(context, listen: false);
      final value = provider.containerNoController.text;
      final formatRegex = RegExp(r'^[A-Z]{4}[0-9]{7}$');
      final isFormatValid = formatRegex.hasMatch(value);

      if (value.isNotEmpty && !isFormatValid) {
        provider.containerValid = false; // Mark invalid

        // MODIFIED: Using your custom CautionDialog for consistency
        if (mounted && !_isShowingValidationDialog) {
          _isShowingValidationDialog = true;
          await CautionDialog.show(
            context: context,
            title: 'Invalid Format',
            message:
                'Container number is invalid. Please enter a valid container number in the format ABCD1234567.',
          );
          _isShowingValidationDialog = false;
        }
        return;
      }

      // API validation
      final isValidFromApi = await provider.validateContainer(value);
      provider.containerValid = isValidFromApi;

      if (!isValidFromApi && context.mounted) {
        _isShowingValidationDialog = true;
        // This dialog remains an AlertDialog because it needs to return a boolean.
        final shouldProceed =
            await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Invalid Container Number'),
                content: const Text(
                  'Container number is invalid. Do you still want to continue?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ) ??
            false;
        _isShowingValidationDialog = false;

        if (!shouldProceed) {
          provider.containerValues['containerNo'] = '';
          provider.containerNoController.clear();
          _containerNoFocus.requestFocus();
        } else {
          provider.containerValid = false;
        }
      }
      FocusScope.of(context).requestFocus(_grossWeightFocus);
    }
  }

  void _validateWeights() async {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    final String grossText = provider.grossWtController.text;
    final String tareText = provider.tareWtController.text;

    provider.errors.remove('grossWeight');
    provider.errors.remove('tareWeight');

    final double gross = double.tryParse(grossText) ?? -1;
    final double tare = double.tryParse(tareText) ?? -1;

    if (gross <= 0 && grossText.isNotEmpty) {
      provider.errors['grossWeight'] = 'Gross Weight cannot be 0';

      if (!_isShowingValidationDialog && mounted) {
        _isShowingValidationDialog = true;

        await CautionDialog.show(
          context: context,
          title: 'Invalid Gross Weight',
          message: 'Gross weight should be greater than 0.',
        );

        // Clear the field
        provider.grossWtController.clear();
        provider.errors.remove('grossWeight');
        provider.notifyListeners();

        _isShowingValidationDialog = false;
      }
    }

    if (tare <= 0 && tareText.isNotEmpty) {
      provider.errors['tareWeight'] = 'Tare Weight cannot be 0';

      if (!_isShowingValidationDialog && mounted) {
        _isShowingValidationDialog = true;

        await CautionDialog.show(
          context: context,
          title: 'Invalid Tare Weight',
          message: 'Tare weight should be greater than 0.',
        );

        // Clear the field
        provider.tareWtController.clear();
        provider.errors.remove('tareWeight');
        provider.notifyListeners();

        _isShowingValidationDialog = false;
      }
    }

    if (gross > 0 && tare > 0) {
      if (tare > gross) {
        provider.errors['tareWeight'] = 'Tare cannot be greater than Gross';

        if (!_isShowingValidationDialog && mounted) {
          _isShowingValidationDialog = true;

          await CautionDialog.show(
            context: context,
            title: 'Invalid Weights',
            message: 'Tare weight cannot be greater than gross weight.',
          );

          // Clear both fields
          provider.grossWtController.clear();
          provider.tareWtController.clear();
          provider.errors.remove('grossWeight');
          provider.errors.remove('tareWeight');
          provider.notifyListeners();

          _isShowingValidationDialog = false;
        }
      } else {
        provider.errors.remove('grossWeight');
        provider.errors.remove('tareWeight');
        provider.calculatePayload();
      }
    }

    provider.notifyListeners();
  }

  void _validateMfgYear() async {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);
    final String yearText = provider.mfgYearController.text;
    final int currentYear = DateTime.now().year;

    if (yearText.isEmpty || yearText.length < 4) {
      provider.errors.remove('mfgYear'); // Clear error if user is deleting
      provider.notifyListeners();
      return;
    }

    final int? year = int.tryParse(yearText);

    if (year == null || year > currentYear || year < (currentYear - 30)) {
      provider.errors['mfgYear'] = 'Year must be within the last 30 years';

      if (!_isShowingValidationDialog && mounted) {
        _isShowingValidationDialog = true;

        await CautionDialog.show(
          context: context,
          title: 'Invalid MFG Year',
          message: 'Year must be within the last 30 years.',
        );

        // Clear invalid input
        provider.mfgYearController.clear();
        provider.errors.remove('mfgYear');
        provider.notifyListeners();

        _isShowingValidationDialog = false;
      }
    } else {
      provider.errors.remove('mfgYear');
      provider.notifyListeners();
    }
  }

  @override
  void dispose() {
    _provider.grossWtController.removeListener(_validateWeights);
    _provider.tareWtController.removeListener(_validateWeights);
    _provider.mfgYearController.removeListener(_validateMfgYear);

    _containerNoFocus.removeListener(_onContainerNoFocusChange);

    _containerNoFocus.dispose();
    _isoCodeFocus.dispose();
    _grossWeightFocus.dispose();
    _tareWeightFocus.dispose();
    _mfgYearFocus.dispose();
    _fromLocationFocus.dispose();
    _isoCodeController.dispose();

    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context) async {
    final provider = Provider.of<PreGateInProvider>(context, listen: false);

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );

    if (pickedDate == null) return;
    if (!context.mounted) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(DateTime.now()),
    );

    if (pickedTime == null) return;

    final DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    provider.surveyDateAndTimeController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(finalDateTime);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreGateInProvider>(context);

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard and validate ISO code when tapping outside
        FocusScope.of(context).unfocus();
        // _validateIsoCodeOnFocusLoss();
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Container Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter container specifications and shipping information',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: provider.surveyDateAndTimeController,
              readOnly: true, // Prevents keyboard from appearing
              decoration: const InputDecoration(
                labelText: 'Survey Date & Time*',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () {
                // Call the picker method when the field is tapped
                _selectDateTime(context);
              },
            ),

            const SizedBox(height: 16),

            // USE YOUR NEW WIDGET
            ContainerNumberField(focusNode: _containerNoFocus),

            const SizedBox(height: 16),

            // ISO Code field with validation
            AutoCompleteInputConfig(
              key: 'isoCode',
              label: 'ISO Code*',
              isRequired: true,
              suggestions: provider.isoCodes
                  .map((e) => e['ISOCode'] as String)
                  .toList(),
              // This callback now handles validation on unfocus
              onFocusChanged: (value) async {
                final currentValue = value.trim().toUpperCase();

                // Only validate if there is text and it's not a valid code
                if (currentValue.isNotEmpty &&
                    !provider.validateIsoCode(currentValue)) {
                  if (mounted && !_isShowingValidationDialog) {
                    _isShowingValidationDialog = true;
                    await CautionDialog.showInvalidIsoCode(context);

                    if (mounted) {
                      _isoCodeController.clear();
                      provider.containerValues['isoCode'] = '';
                      provider.selectedIsoId = null;
                      provider.notifyListeners();
                    }
                    _isShowingValidationDialog = false;
                  }
                }
              },
            ).buildWidget(
              context,
              provider.containerValues['isoCode'],
              (value) async {
                // This `onChanged` logic handles when a user selects an item
                // or submits the field. It remains the same.
                final selectedCode = value.toUpperCase();
                provider.containerValues['isoCode'] = selectedCode;
                _isoCodeController.text = selectedCode;

                final selectedObj = provider.isoCodes.firstWhere(
                  (e) => (e['ISOCode'] as String).toUpperCase() == selectedCode,
                  orElse: () =>
                      <String, dynamic>{}, // Return empty map if not found
                );

                if (selectedObj.isNotEmpty && selectedObj['ISOID'] != null) {
                  provider.selectedIsoId = selectedObj['ISOID'].toString();
                  await provider.fetchIsoDetails(selectedCode);
                } else {
                  provider.selectedIsoId = null;
                }

                // Don't set isValidIsoSelected flag, just validate the value directly.

                FocusScope.of(context).requestFocus(_grossWeightFocus);
              },
              provider.errors['isoCode'],
              _isoCodeController,
            ),

            const SizedBox(height: 16),

            // Check the general details loading flag from the provider
            if (provider.isFetchingDetails)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(child: CircularProgressIndicator()),
              )
            else
              // If not loading general details, show the fields
              // --- Type + Size in one row ---
              Row(
                children: [
                  Expanded(
                    child:
                        TextInputConfig(
                          key: 'type',
                          label: 'Type*',
                          uppercase: true,
                        ).buildWidget(
                          context,
                          provider.containerType?.toUpperCase() ?? '',
                          null,
                          null,
                          TextEditingController(
                            text: provider.containerType?.toUpperCase() ?? '',
                          ),
                          readOnly: true,
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child:
                        TextInputConfig(
                          key: 'size',
                          label: 'Size*',
                          uppercase: true,
                        ).buildWidget(
                          context,
                          provider.size?.toUpperCase() ?? '',
                          null,
                          null,
                          TextEditingController(
                            text: provider.size?.toUpperCase() ?? '',
                          ),
                          readOnly: true,
                        ),
                  ),
                ],
              ),

            const SizedBox(height: 16),

            // --- Category + Make (conditional) in one row ---
            Row(
              children: [
                Expanded(
                  child:
                      TextInputConfig(
                        key: 'category',
                        label: 'Category*',
                        uppercase: true,
                      ).buildWidget(
                        context,
                        provider.category?.toUpperCase() ?? '',
                        null,
                        null,
                        TextEditingController(
                          text: provider.category?.toUpperCase() ?? '',
                        ),
                        readOnly: true,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: (provider.containerType?.toUpperCase() == 'RF')
                      ? (provider.isFetchingMakes
                            ? const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                            : SelectInputConfig(
                                key: 'make',
                                label: 'Make',
                                options: provider.makes
                                    .where(
                                      (m) =>
                                          m['ID'] != null && m['Make'] != null,
                                    )
                                    .map<Map<String, String>>(
                                      (m) => {
                                        'value': m['ID'].toString(),
                                        'display': m['Make'].toString(),
                                      },
                                    )
                                    .toList(),
                                onValidationFailed: (invalidValue) async {
                                  if (mounted && !_isShowingValidationDialog) {
                                    _isShowingValidationDialog = true;
                                    await CautionDialog.showInvalidMake(
                                      context,
                                    );
                                    provider.selectedMakeId = null;
                                    provider.notifyListeners();
                                    _isShowingValidationDialog = false;
                                  }
                                },
                              ).buildWidget(
                                context,
                                provider.selectedMakeId,
                                (value) {
                                  provider.selectedMakeId = value.toString();
                                  provider.notifyListeners();
                                },
                                provider.errors['make'],
                                null,
                              ))
                      : const SizedBox.shrink(),
                ),
              ],
            ),

            const SizedBox(height: 16),

            SearchableDropdown(
              label: 'Shipping Line*',
              options: provider.shippingLines
                  .map<Map<String, String>>(
                    (s) => {
                      'value': (s['SLID'] as int).toString(),
                      'display': s['SLName'] as String,
                    },
                  )
                  .toList(),
              selectedValue: provider.selectedSlId,
              onChanged: (value) => provider.selectedSlId = value,
              error: provider.errors['shippingLine'],
              onValidationFailed: (invalidValue) async {
                if (mounted && !_isShowingValidationDialog) {
                  _isShowingValidationDialog = true;
                  await CautionDialog.showInvalidShippingLine(context);
                  provider.selectedSlId = null;
                  provider.notifyListeners();
                  _isShowingValidationDialog = false;
                }
              },
            ),

            const SizedBox(height: 16),

            // --- Gross & Tare in one row with validation ---
            Row(
              children: [
                Expanded(
                  child:
                      TextInputConfig(
                        key: 'grossWeight',
                        label: 'Gross Weight (kg)*',
                        hint: '30480',
                        keyboardType: TextInputType.number,
                        isRequired: true,
                        uppercase: true,
                      ).buildWidget(
                        context,
                        provider.grossWtController.text,
                        (value) {
                          final gross =
                              double.tryParse(
                                provider.grossWtController.text,
                              ) ??
                              0;
                          final tare =
                              double.tryParse(provider.tareWtController.text) ??
                              0;

                          if (tare > 0 && tare > gross) {
                            provider.errors['grossWeight'] =
                                'Gross must be ≥ Tare';
                            provider.notifyListeners();
                          } else {
                            provider.errors.remove('grossWeight');
                            provider.errors.remove('tareWeight');
                            provider.calculatePayload(); // ✅ only valid case
                          }

                          _tareWeightFocus.requestFocus();
                        },
                        provider.errors['grossWeight'],
                        provider.grossWtController,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      TextInputConfig(
                        key: 'tareWeight',
                        label: 'Tare Weight (kg)*',
                        hint: '3900',
                        keyboardType: TextInputType.number,
                        isRequired: true,
                        uppercase: true,
                      ).buildWidget(
                        context,
                        provider.tareWtController.text,
                        (value) {
                          final gross =
                              double.tryParse(
                                provider.grossWtController.text,
                              ) ??
                              0;
                          final tare =
                              double.tryParse(provider.tareWtController.text) ??
                              0;

                          if (tare > gross) {
                            provider.errors['tareWeight'] =
                                'Tare cannot exceed Gross';
                            provider.notifyListeners();
                          } else {
                            provider.errors.remove('tareWeight');
                            provider.errors.remove('grossWeight');
                            provider.calculatePayload(); // ✅ only valid case
                          }

                          _mfgYearFocus.requestFocus();
                        },
                        provider.errors['tareWeight'],
                        provider.tareWtController,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextInputConfig(
              key: 'payload',
              label: 'Payload (kg)',
              uppercase: true,
            ).buildWidget(
              context,
              provider.payload?.toStringAsFixed(2) ?? '',
              null,
              null,
              TextEditingController(text: provider.payload?.toStringAsFixed(2)),
              readOnly: true,
            ),

            const SizedBox(height: 16),

            // --- MFG Month & Year in one row ---
            Row(
              children: [
                Expanded(
                  child:
                      SelectInputConfig(
                        key: 'mfgMonth',
                        label: 'MFG Month*',
                        options: List.generate(
                          12,
                          (i) => {
                            'value': (i + 1).toString().padLeft(2, '0'),
                            'display': '${i + 1}', // show 1–12
                          },
                        ),
                      ).buildWidget(
                        context,
                        provider.mfgMonthController.text,
                        (value) {
                          final monthNum = int.tryParse(value ?? '0') ?? 0;
                          if (monthNum > 0 && monthNum <= 12) {
                            final monthName = DateFormat(
                              'MMMM',
                            ).format(DateTime(0, monthNum));
                            provider.mfgMonthController.text = monthName
                                .toUpperCase();
                          }
                        },
                        provider.errors['mfgMonth'],
                        provider.mfgMonthController,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      TextInputConfig(
                        key: 'mfgYear',
                        label: 'MFG Year*',
                        hint: '2025',
                        keyboardType: TextInputType.number,
                        isRequired: true,
                        uppercase: false,
                      ).buildWidget(
                        context,
                        provider.mfgYearController.text,
                        (value) =>
                            provider.mfgYearController.text = value.trim(),

                        provider.errors['mfgYear'],
                        provider.mfgYearController,
                      ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            TextInputConfig(
              key: 'fromLocation',
              label: 'From Location',
              hint: 'Port of Rotterdam',
              uppercase: true,
            ).buildWidget(
              context,
              provider.fromLocationController.text,
              (value) {
                provider.fromLocationController.text = value.toUpperCase();
              },
              provider.errors['fromLocation'],
              provider.fromLocationController,
            ),
          ],
        ),
      ),
    );
  }

  // Method to validate ISO code when focus is lost
  // void _validateIsoCodeOnFocusLoss() async {
  //   final provider = Provider.of<PreGateInProvider>(context, listen: false);
  //   final currentValue = _isoCodeController.text;
  //
  //   if (mounted &&
  //       currentValue.isNotEmpty &&
  //       !provider.validateIsoCode(currentValue) &&
  //       !_isShowingValidationDialog &&
  //       currentValue != _lastValidatedValue) {
  //     _isShowingValidationDialog = true;
  //     _lastValidatedValue = currentValue;
  //
  //     // Show caution dialog for invalid ISO code
  //     if (mounted) {
  //       await CautionDialog.showInvalidIsoCode(context);
  //     }
  //
  //     // Clear the field after dialog is dismissed
  //     if (mounted) {
  //       _isoCodeController.clear();
  //       provider.containerValues['isoCode'] = '';
  //       provider.selectedIsoId = null;
  //       provider.notifyListeners();
  //     }
  //
  //     _isShowingValidationDialog = false;
  //     _lastValidatedValue = '';
  //   }
  // }
}
