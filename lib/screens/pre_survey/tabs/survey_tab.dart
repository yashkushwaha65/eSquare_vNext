// lib/tabs/survey_tab.dart
import 'package:esquare/core/configs/input_config.dart';
import 'package:esquare/providers/pre_gate_inPdr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SurveyTab extends StatelessWidget {
  const SurveyTab({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PreGateInProvider>(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Survey Details',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          // Build survey fields dynamically
          ..._surveyFields(provider)
              .map(
                (config) => config.buildWidget(
                  context,
                  _getValueForKey(provider, config.key),
                  (value) {
                    _onValueChanged(provider, config.key, value);
                  },
                  provider.errors[config.key],
                  _getControllerForKey(provider, config.key),
                ),
              )
              .toList(),
        ],
      ),
    );
  }

  // Helper to get the initial value for each field
  dynamic _getValueForKey(PreGateInProvider provider, String key) {
    switch (key) {
      case 'examination':
        return provider.selectedExaminedId;
      case 'surveyType':
        return provider.selectedSurveyTypeId;
      case 'containerInStatus':
        return provider.selectedContainerStatusId;
      case 'condition':
        return provider.selectedConditionId;
      default:
        return null;
    }
  }

  // Helper to connect the right controller to the right field
  TextEditingController? _getControllerForKey(
    PreGateInProvider provider,
    String key,
  ) {
    switch (key) {
      case 'grade':
        return provider.gradeController;
      case 'cscAsp':
        return provider.cscAspController;
      case 'doNo':
        return provider.doNoController;
      // REMOVED 'doDate' case
      case 'doValidityDate':
        return provider.doValidityDateController;
      case 'description':
        return provider.remarksController;
      default:
        return null;
    }
  }

  // Helper to update the provider's state when a field changes
  void _onValueChanged(PreGateInProvider provider, String key, dynamic value) {
    // Update dedicated provider variables for dropdowns
    switch (key) {
      case 'examination':
        provider.selectedExaminedId = value as String?;
        break;
      case 'surveyType':
        provider.selectedSurveyTypeId = value as String?;
        break;
      case 'containerInStatus':
        provider.selectedContainerStatusId = value as String?;
        if (value != null) {
          provider.fetchConditions(value);
        }
        break;
      case 'condition':
        provider.selectedConditionId = value as String?;
        break;
      // For fields with controllers, update the controller's text
      default:
        final controller = _getControllerForKey(provider, key);
        if (controller != null) {
          controller.text = value?.toString() ?? '';
        }
    }
  }

  List<InputConfig> _surveyFields(PreGateInProvider provider) {
    return [
      SelectInputConfig(
        key: 'examination',
        label: 'Examined*',
        isRequired: true,
        options: provider.examineList
            .map<Map<String, String>>(
              (e) => {
                'value': e['ExamineID'].toString(),
                'display': e['ExamineType'].toString(),
              },
            )
            .toList(),
      ),
      SelectInputConfig(
        key: 'surveyType',
        label: 'Survey Type*',
        isRequired: true,
        options: provider.surveyTypes
            .map<Map<String, String>>(
              (s) => {
                'value': s['SurveyTypeID'].toString(),
                'display': s['SurveyTypeName'].toString(),
              },
            )
            .toList(),
      ),
      SelectInputConfig(
        key: 'containerInStatus',
        label: 'Container Status*',
        isRequired: true,
        options: provider.containerStatus
            .map<Map<String, String>>(
              (c) => {
                'value': c['ID'].toString(),
                'display': c['Status'].toString(),
              },
            )
            .toList(),
      ),
      SelectInputConfig(
        key: 'condition',
        label: 'Condition*',
        isRequired: true,
        options: (provider.conditions)
            .where(
              (c) => c != null && c['ID'] != null && c['Condition'] != null,
            )
            .map<Map<String, String>>(
              (c) => {
                'value': c['ID'].toString(),
                'display': c['Condition'].toString(),
              },
            )
            .toList(),
      ),
      TextInputConfig(
        key: 'grade',
        label: 'Grade*',
        hint: 'A, B, C, or D.',
        isRequired: true,
        maxLength: 1,
        uppercase: true,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[A-D]')),
          UpperCaseTextFormatter(),
        ],
      ),
      // --- 1. CSC/ASP length limited to 20 ---
      TextInputConfig(
        key: 'cscAsp',
        label: 'CSC/ASP',
        hint: 'CSC/ASP Number',
        maxLength: 20,
      ),
      // --- 2. DO Number length limited to 20 ---
      TextInputConfig(
        key: 'doNo',
        label: 'DO Number',
        hint: 'Delivery Order No',
        maxLength: 20,
      ),

      // --- 4. DO Validity is now optional ---
      DateInputConfig(
        key: 'doValidityDate',
        label: 'DO Validity Date', // Asterisk removed
        isRequired: false, // Set to false
      ),
      TextAreaConfig(
        key: 'description',
        label: 'Remarks',
        hint: 'Enter any additional notes...',
      ),
    ];
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
