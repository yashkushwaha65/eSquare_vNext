import 'package:esquare/core/configs/input_config.dart';
import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:esquare/screens/pre_survey/tabs/widgets/container_number_field.dart';
import 'package:esquare/widgets/caution_dialog.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

class ContainerTab extends StatefulWidget {
  const ContainerTab({super.key});

  @override
  State<ContainerTab> createState() => _ContainerTabState();
}

class _ContainerTabState extends State<ContainerTab>
    with AutomaticKeepAliveClientMixin {
  late final PreGateInProvider _provider;
  final _isoCodeController = TextEditingController();
  final _containerNoFocus = FocusNode();
  final _isoFocus = FocusNode();
  final _slidFocus = FocusNode();
  final _grossWeightFocus = FocusNode();
  final _tareWeightFocus = FocusNode();
  final _locationFocus = FocusNode();
  final _mfgYearFocus = FocusNode();
  bool _isShowingValidationDialog = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _provider = Provider.of<PreGateInProvider>(context, listen: false);
    _provider.grossWtController.addListener(_validateWeights);
    _provider.tareWtController.addListener(_validateWeights);
    _provider.mfgYearController.addListener(_validateMfgYear);
    _isoCodeController.text = _provider.containerValues['isoCode'] ?? '';
  }

  void _validateWeights() async {
    // --- FIX: Check if the widget is still mounted before proceeding ---
    if (!mounted) return;

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
    // --- FIX: Check if the widget is still mounted before proceeding ---
    if (!mounted) return;

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
    // _containerNoFocus.removeListener(_onContainerNoFocusChange);
    _containerNoFocus.dispose();
    _isoFocus.dispose();
    _locationFocus.dispose();
    _slidFocus.dispose();
    _grossWeightFocus.dispose();
    _tareWeightFocus.dispose();
    _mfgYearFocus.dispose();
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
    if (pickedDate == null || !context.mounted) return;
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
    super.build(context);
    final provider = Provider.of<PreGateInProvider>(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
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
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Survey Date & Time',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () => _selectDateTime(context),
            ),
            const SizedBox(height: 16),
            ContainerNumberField(
              focusNode: _containerNoFocus,
              nextFocusNode: _isoFocus,
            ),
            const SizedBox(height: 16),
            AutoCompleteInputConfig(
              key: 'isoCode',
              label: 'ISO Code',
              isRequired: true,
              suggestions: provider.isoCodes
                  .map((e) => e['ISOCode'] as String)
                  .toList(),
              onFocusChanged: (value) async {
                final currentValue = value.trim().toUpperCase();
                if (currentValue.isNotEmpty &&
                    !provider.validateIsoCode(currentValue)) {
                  if (mounted && !_isShowingValidationDialog) {
                    _isShowingValidationDialog = true;
                    await CautionDialog.showInvalidIsoCode(context);
                    // ADDED: Check if the widget is still mounted after the dialog.
                    if (!mounted) return;
                    _isoCodeController.clear();
                    provider.containerValues['isoCode'] = '';
                    provider.selectedIsoId = null;
                    provider.notifyListeners();
                    _isShowingValidationDialog = false;
                  }
                }
              },
            ).buildWidget(
              context,
              provider.containerValues['isoCode'],
              (value) async {
                final selectedCode = value.toUpperCase();
                provider.containerValues['isoCode'] = selectedCode;
                _isoCodeController.text = selectedCode;

                final selectedObj = provider.isoCodes.firstWhere(
                  (e) => (e['ISOCode'] as String).toUpperCase() == selectedCode,
                  orElse: () => <String, dynamic>{},
                );

                if (selectedObj.isNotEmpty && selectedObj['ISOID'] != null) {
                  provider.selectedIsoId = selectedObj['ISOID'].toString();
                  await provider.fetchIsoDetails(selectedCode);
                } else {
                  provider.selectedIsoId = null;
                }
                FocusScope.of(context).requestFocus(_slidFocus);
              },
              provider.errors['isoCode'],
              _isoCodeController,
            ),
            const SizedBox(height: 16),
            if (provider.isFetchingDetails)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: SizedBox(
                    width: MediaQuery.sizeOf(context).width * .2,
                    height: MediaQuery.sizeOf(context).height * .2,
                    child: Lottie.asset('assets/anims/loading.json'),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child:
                        TextInputConfig(
                          key: 'type',
                          label: 'Type',
                          uppercase: true,
                          isRequired: true,
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
                          label: 'Size',
                          uppercase: true,
                          isRequired: true,
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
            Row(
              children: [
                Expanded(
                  child:
                      TextInputConfig(
                        key: 'category',
                        label: 'Category',
                        uppercase: true,
                        isRequired: true,
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
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Center(
                                  child: Lottie.asset(
                                    'assets/anims/loading.json',
                                  ),
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
              label: 'Shipping Line',
              isRequired: true,
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
            Row(
              children: [
                Expanded(
                  child:
                      TextInputConfig(
                        key: 'grossWeight',
                        label: 'Gross Weight (kg)',
                        hint: '30480',
                        keyboardType: TextInputType.number,
                        isRequired: true,
                      ).buildWidget(
                        context,
                        provider.grossWtController.text,
                        (value) => provider.grossWtController.text = value,
                        provider.errors['grossWeight'],
                        provider.grossWtController,
                        focusNode: _grossWeightFocus,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      TextInputConfig(
                        key: 'tareWeight',
                        label: 'Tare Weight (kg)',
                        hint: '3900',
                        keyboardType: TextInputType.number,
                        isRequired: true,
                      ).buildWidget(
                        context,
                        provider.tareWtController.text,
                        (value) => provider.tareWtController.text = value,
                        provider.errors['tareWeight'],
                        provider.tareWtController,
                        focusNode: _tareWeightFocus,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextInputConfig(key: 'payload', label: 'Payload (kg)').buildWidget(
              context,
              provider.payload?.toStringAsFixed(2) ?? '',
              null,
              null,
              TextEditingController(
                text: provider.payload?.toStringAsFixed(2) ?? '',
              ),
              readOnly: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child:
                      SelectInputConfig(
                        key: 'mfgMonth',
                        label: 'MFG Month',
                        isRequired: true,
                        options: List.generate(
                          12,
                          (i) => {
                            'value': (i + 1).toString(),
                            'display': (i + 1).toString(),
                          },
                        ),
                      ).buildWidget(
                        context,
                        // MODIFIED: Use the dedicated variable for value
                        provider.selectedMfgMonth,
                        // MODIFIED: Update the dedicated variable on change
                        (value) {
                          provider.selectedMfgMonth = value;
                          provider.notifyListeners(); // Notify UI of change
                        },
                        provider.errors['mfgMonth'],
                        null,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child:
                      TextInputConfig(
                        key: 'mfgYear',
                        label: 'MFG Year',
                        hint: '2025',
                        keyboardType: TextInputType.number,
                        isRequired: true,
                      ).buildWidget(
                        context,
                        provider.mfgYearController.text,
                        (value) =>
                            provider.mfgYearController.text = value.trim(),
                        provider.errors['mfgYear'],
                        provider.mfgYearController,
                        focusNode: _mfgYearFocus,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextInputConfig(
              key: 'fromLocation',
              label: 'Location',
              hint: 'Port of Rotterdam',
              uppercase: true,
              maxLength: 15,
            ).buildWidget(
              context,
              provider.fromLocationController.text,
              (value) => provider.fromLocationController.text = value,
              provider.errors['fromLocation'],
              provider.fromLocationController,
              focusNode: _locationFocus,
            ),
          ],
        ),
      ),
    );
  }
}
