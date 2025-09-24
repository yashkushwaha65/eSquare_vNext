// lib/core/configs/input_config.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Abstract base class for input field configurations.
/// This allows dynamic generation of form fields based on config lists.
abstract class InputConfig {
  final String key;
  final String label;
  final bool isRequired;
  final String? hint;
  final ValueChanged<String>? onCompleted; // Add this

  InputConfig({
    required this.key,
    required this.label,
    this.isRequired = false,
    this.hint,
    this.onCompleted,
  });

  /// Builds the widget for this config, given the context, current value, onChange, and error.
  Widget buildWidget(
    BuildContext context,
    dynamic value,
    ValueChanged<dynamic>? onChanged,
    String? error,
    TextEditingController? controller, { // Add this parameter
    bool readOnly = false,
    ValueChanged<String>? onCompleted,
  });
}

/// Configuration for text input fields.
// Updated TextInputConfig class
class TextInputConfig extends InputConfig {
  final TextInputType keyboardType;
  final bool uppercase;
  final int? maxLength;
  final List<TextInputFormatter>? inputFormatters;

  TextInputConfig({
    required super.key,
    required super.label,
    super.isRequired = false,
    super.hint,
    this.keyboardType = TextInputType.text,
    this.uppercase = false,
    this.maxLength,
    this.inputFormatters,
  });

  @override
  Widget buildWidget(
    BuildContext context,
    dynamic value,
    ValueChanged<dynamic>? onChanged,
    String? error,
    TextEditingController? controller, {
    bool readOnly = false,
    ValueChanged<String>? onCompleted,
    ValueChanged<String>? onSubmitted,
    FocusNode? focusNode, // --- 1. ADD this parameter ---
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        maxLength: maxLength,
        inputFormatters: inputFormatters,
        // This line is now correctly added
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: error,
          border: const OutlineInputBorder(),
        ),
        keyboardType: keyboardType,
        textInputAction: TextInputAction.done,
        readOnly: readOnly,
        onChanged: (newValue) {
          String finalValue = uppercase ? newValue.toUpperCase() : newValue;
          controller?.value = controller.value.copyWith(
            text: finalValue,
            selection: TextSelection.collapsed(offset: finalValue.length),
          );
          onChanged?.call(finalValue);
        },
        onSubmitted: (value) {
          if (uppercase) value = value.toUpperCase();
          onSubmitted?.call(value);
        },
      ),
    );
  }
}

/// Configuration for select (dropdown) fields.
class SelectInputConfig extends InputConfig {
  final List<Map<String, String>> options; // value: display
  final Function(String)? onValidationFailed;

  SelectInputConfig({
    required super.key,
    required super.label,
    super.isRequired = false,
    required this.options,
    this.onValidationFailed,
  });

  @override
  Widget buildWidget(
    BuildContext context,
    dynamic value,
    ValueChanged<dynamic>? onChanged,
    String? error,
    TextEditingController? controller, {
    bool readOnly = false,
    ValueChanged<String>? onCompleted,
  }) {
    final List<DropdownMenuItem<String>> dropdownItems = options
        .where((opt) => opt['value'] != null && opt['display'] != null)
        .map(
          (opt) => DropdownMenuItem<String>(
            value: opt['value'],
            child: Text(opt['display']!.toUpperCase()),
          ),
        )
        .toList();

    String? effectiveValue = (value != null && value.toString().isNotEmpty)
        ? value.toString()
        : null;

    // Prevent invalid value being set
    if (effectiveValue != null &&
        !dropdownItems.any((item) => item.value == effectiveValue)) {
      effectiveValue = null;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: DropdownButtonFormField<String>(
        initialValue: effectiveValue,
        decoration: InputDecoration(
          labelText: label,
          errorText: error,
          border: const OutlineInputBorder(),
        ),
        items: dropdownItems,
        onChanged: readOnly
            ? null
            : (newValue) {
                // Validate the selection
                if (newValue != null && onValidationFailed != null) {
                  final isValid = options.any(
                    (option) => option['value'] == newValue,
                  );
                  if (!isValid) {
                    onValidationFailed!(newValue);
                    return;
                  }
                }
                onChanged?.call(newValue);
              },
      ),
    );
  }
}

/// Configuration for date picker fields.
// In your input_config.dart file

class DateInputConfig extends InputConfig {
  final bool showTime;
  final bool autoNow;
  final bool readOnly;
  final String? initialDate; // store initial value

  DateInputConfig({
    required super.key,
    required super.label,
    super.isRequired = false,
    this.showTime = false,
    this.autoNow = false,
    this.readOnly = false,
    this.initialDate,
  });

  // In your input_config.dart file

  @override
  Widget buildWidget(
    BuildContext context,
    dynamic value,
    ValueChanged<dynamic>? onChanged,
    String? error,
    TextEditingController? controller, {
    bool readOnly = false,
    ValueChanged<String>? onCompleted,
  }) {
    // We must have a controller for this widget to function correctly.
    if (controller == null) {
      return const Text('Error: DateInputConfig requires a controller.');
    }

    // Set the initial value only if the controller is empty.
    if (controller.text.isEmpty) {
      String? defaultValue;
      if (initialDate != null) {
        defaultValue = initialDate;
      } else if (autoNow) {
        final now = DateTime.now();
        defaultValue = showTime
            ? DateFormat('yyyy-MM-dd HH:mm').format(now)
            : DateFormat('yyyy-MM-dd').format(now);
      }

      if (defaultValue != null) {
        // Use a post-frame callback to set the initial value without causing build errors.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          onChanged?.call(defaultValue);
        });
      }
    }

    final effectiveReadOnly = this.readOnly || autoNow;

    // --- THE FIX: Wrap the UI in an AnimatedBuilder to listen to the controller ---
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Now, displayValue is always the most current text from the controller.
        final String displayValue = controller.text;

        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: effectiveReadOnly
                ? null
                : () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate:
                          DateTime.tryParse(displayValue) ?? DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );

                    if (pickedDate != null) {
                      TimeOfDay? pickedTime;
                      if (showTime) {
                        pickedTime = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(
                            DateTime.tryParse(displayValue) ?? DateTime.now(),
                          ),
                        );
                      }

                      if (showTime && pickedTime != null) {
                        pickedDate = DateTime(
                          pickedDate.year,
                          pickedDate.month,
                          pickedDate.day,
                          pickedTime.hour,
                          pickedTime.minute,
                        );
                      }

                      final formatted = showTime
                          ? DateFormat('yyyy-MM-dd HH:mm').format(pickedDate)
                          : DateFormat('yyyy-MM-dd').format(pickedDate);

                      // This calls _onValueChanged, which updates the controller.
                      // The AnimatedBuilder will then automatically handle the rebuild.
                      onChanged?.call(formatted);
                    }
                  },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: label,
                errorText: error,
                border: const OutlineInputBorder(),
              ),
              child: Text(
                displayValue.isEmpty
                    ? (showTime ? 'Select date & time' : 'Select date')
                    : displayValue,
                style: TextStyle(
                  fontSize: 16,
                  color: effectiveReadOnly
                      ? Colors.grey.shade700
                      : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Configuration for textarea fields.
class TextAreaConfig extends InputConfig {
  TextAreaConfig({
    required super.key,
    required super.label,
    super.hint,
    super.isRequired = false,
  });

  @override
  Widget buildWidget(
    BuildContext context,
    dynamic value,
    ValueChanged<dynamic>? onChanged,
    String? error,
    TextEditingController? controller, {
    bool readOnly = false,
    ValueChanged<String>? onCompleted,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: TextEditingController(text: value ?? ''),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          errorText: error,
          border: const OutlineInputBorder(),
        ),
        maxLines: 4,
        readOnly: readOnly,
        onChanged: onChanged,
      ),
    );
  }
}

class SearchableDropdown extends StatelessWidget {
  final List<Map<String, String>> options;
  final String? selectedValue;
  final ValueChanged<String> onChanged;
  final String label;
  final String? error;
  final Function(String)? onValidationFailed;
  final String? validationMessage;

  const SearchableDropdown({
    super.key,
    required this.options,
    this.selectedValue,
    required this.onChanged,
    required this.label,
    this.error,
    this.onValidationFailed,
    this.validationMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty)
            return const Iterable<String>.empty();
          return options
              .map((e) => e['display']!)
              .where(
                (option) => option.toLowerCase().contains(
                  textEditingValue.text.toLowerCase(),
                ),
              );
        },
        onSelected: (selection) {
          final selectedOption = options.firstWhere(
            (e) => e['display'] == selection,
          );
          onChanged(selectedOption['value']!);
        },
        fieldViewBuilder:
            (context, textController, focusNode, onFieldSubmitted) {
              textController.text =
                  options.firstWhere(
                    (e) => e['value'] == selectedValue,
                    orElse: () => {'value': '', 'display': ''},
                  )['display'] ??
                  '';

              // Add focus listener for validation
              focusNode.addListener(() {
                if (!focusNode.hasFocus && onValidationFailed != null) {
                  final currentText = textController.text;
                  final isValid = options.any(
                    (option) =>
                        option['display']?.toLowerCase() ==
                        currentText.toLowerCase(),
                  );

                  if (currentText.isNotEmpty && !isValid) {
                    onValidationFailed!(currentText);
                  }
                }
              });

              return TextField(
                controller: textController,
                focusNode: focusNode,
                decoration: InputDecoration(
                  labelText: label,
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
                onChanged: (newValue) {
                  // No direct onChanged needed
                },
              );
            },
      ),
    );
  }
}

/// Configuration for autocomplete input fields.
class AutoCompleteInputConfig extends InputConfig {
  final List<String> suggestions;
  final Function(String)? onFocusChanged;

  AutoCompleteInputConfig({
    required super.key,
    required super.label,
    super.isRequired = false,
    super.hint,
    required this.suggestions,
    this.onFocusChanged,
  });

  @override
  Widget buildWidget(
    BuildContext context,
    dynamic value,
    ValueChanged<dynamic>? onChanged,
    String? error,
    TextEditingController? controller, {
    ValueChanged<String>? onCompleted,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: _AutoCompleteWithFocusValidation(
        suggestions: suggestions,
        onChanged: onChanged,
        onFocusChanged: onFocusChanged,
        label: label,
        hint: hint,
        error: error,
        value: value,
        readOnly: readOnly,
        controller: controller,
      ),
    );
  }
}

// NEW WIDGET: Add this class to the same file.
// It handles focus detection for the autocomplete field.
class _AutoCompleteWithFocusValidation extends StatelessWidget {
  final List<String> suggestions;
  final ValueChanged<dynamic>? onChanged;
  final Function(String)? onFocusChanged;
  final String label;
  final String? hint;
  final String? error;
  final dynamic value;
  final bool readOnly;
  final TextEditingController? controller;

  const _AutoCompleteWithFocusValidation({
    required this.suggestions,
    this.onChanged,
    this.onFocusChanged,
    required this.label,
    this.hint,
    this.error,
    this.value,
    this.readOnly = false,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    // Use the controller passed from the parent to manage state.
    final externalController =
        controller ?? TextEditingController(text: value ?? '');

    return Focus(
      onFocusChange: (hasFocus) {
        if (!hasFocus && onFocusChanged != null) {
          // When focus is lost, trigger the validation callback
          onFocusChanged!(externalController.text);
        }
      },
      child: Autocomplete<String>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text.isEmpty) {
            return const Iterable<String>.empty();
          }
          return suggestions.where(
            (String option) => option.toLowerCase().contains(
              textEditingValue.text.toLowerCase(),
            ),
          );
        },
        fieldViewBuilder:
            (
              BuildContext context,
              TextEditingController fieldController,
              FocusNode fieldFocusNode,
              VoidCallback onFieldSubmitted,
            ) {
              // Sync our external controller's text to the Autocomplete's internal one
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (fieldController.text != externalController.text) {
                  fieldController.text = externalController.text;
                }
              });

              return TextFormField(
                controller: fieldController,
                focusNode: fieldFocusNode,
                decoration: InputDecoration(
                  labelText: label,
                  hintText: hint,
                  errorText: error,
                  border: const OutlineInputBorder(),
                ),
                readOnly: readOnly,
                // When the user types, update our external controller
                onChanged: (text) {
                  externalController.text = text;
                },
                onFieldSubmitted: (submittedValue) {
                  externalController.text = submittedValue;
                  if (onChanged != null) {
                    onChanged!(submittedValue);
                  }
                  onFieldSubmitted();
                },
              );
            },
        onSelected: (String selection) {
          externalController.text = selection;
          if (onChanged != null) {
            onChanged!(selection);
          }
        },
      ),
    );
  }
}
