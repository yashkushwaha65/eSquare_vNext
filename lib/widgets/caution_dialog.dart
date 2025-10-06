import 'package:flutter/material.dart';

/// Utility class for showing caution dialogs
class CautionDialog {
  /// Shows a customizable dialog
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'OK',
    VoidCallback? onConfirm,
    bool barrierDismissible = false,
    IconData icon = Icons.warning,
    Color iconColor = Colors.orange,
    List<Widget>? extraActions,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: Row(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            if (extraActions != null) ...extraActions,
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm?.call();
              },
              child: Text(buttonText, style: TextStyle(color: iconColor)),
            ),
          ],
        );
      },
    );
  }


  /// NEW: Shows a confirmation dialog for an invalid container number
  static Future<bool> showInvalidContainerConfirmation(
      BuildContext context,
      ) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange, size: 28),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Invalid Container',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: const Text(
            'This container number is not valid. Do you want to continue with this number?',
            style: TextStyle(fontSize: 15, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // "Clear"
              child: const Text('CLEAR', style: TextStyle(color: Colors.grey)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true), // "Continue"
              child: const Text(
                'CONTINUE',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        );
      },
    );
    // Return false if the dialog is dismissed (e.g., by back button)
    return result ?? false;
  }


  /// Shows an invalid input dialog specifically for ISO codes
  static Future<void> showInvalidIsoCode(BuildContext context) async {
    return show(
      context: context,
      title: 'Invalid ISO Code',
      message:
          'The entered ISO code is not valid. Please select a valid ISO code from the suggestions.',
    );
  }

  /// Shows an invalid input dialog for shipping lines
  static Future<void> showInvalidShippingLine(BuildContext context) async {
    return show(
      context: context,
      title: 'Invalid Shipping Line',
      message:
          'The entered shipping line is not valid. Please select a valid shipping line from the dropdown.',
    );
  }

  /// Shows an invalid input dialog for transporters
  static Future<void> showInvalidTransporter(BuildContext context) async {
    return show(
      context: context,
      title: 'Invalid Transporter',
      message:
          'The entered transporter is not valid. Please select a valid transporter from the dropdown.',
    );
  }

  /// Shows an invalid input dialog for make selection
  static Future<void> showInvalidMake(BuildContext context) async {
    return show(
      context: context,
      title: 'Invalid Make',
      message:
          'The selected make is not valid. Please select a valid make from the dropdown.',
    );
  }

  /// Shows a generic invalid selection dialog
  static Future<void> showInvalidSelection(
    BuildContext context,
    String fieldName,
  ) async {
    return show(
      context: context,
      title: 'Invalid $fieldName',
      message:
          'The entered $fieldName is not valid. Please select a valid option from the available choices.',
    );
  }
}
