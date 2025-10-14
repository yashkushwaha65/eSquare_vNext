// lib/providers/pre_gate_inPdr.dart
import 'dart:convert';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:esquare/core/models/photoMdl.dart';
import 'package:esquare/core/models/userMdl.dart';
import 'package:esquare/widgets/caution_dialog.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart' as path_provider;

import '../api_endpoints.dart';
import '../core/models/surveyMdl.dart';
import '../core/services/api_services.dart';
import '../screens/pre_survey/pre_gate_in_summary/widgets/custom_camera_screen.dart';

// Helper function to calculate the width of the text
num textWidth(img.BitmapFont font, String text) {
  num width = 0;
  for (var c in text.codeUnits) {
    if (font.characters.containsKey(c)) {
      width += font.characters[c]!.xAdvance;
    }
  }
  return width;
}

// Helper function to process the image in the background
Future<File?> _processImageInBackground(Map<String, dynamic> args) async {
  final String filePath = args['filePath'];
  final RootIsolateToken token = args['token'];

  BackgroundIsolateBinaryMessenger.ensureInitialized(token);

  final tempDir = await path_provider.getTemporaryDirectory();
  final originalFile = File(filePath);
  final image = img.decodeImage(await originalFile.readAsBytes());
  if (image == null) return null;

  // --- NEW LOGIC FOR LARGER, SCALED TIMESTAMP ---

  final timestamp = DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now());
  final font = img.arial24; // Use the largest base font for best quality

  // 1. Create a temporary, transparent image to draw the text on.
  final textImage = img.Image(
    width: textWidth(font, timestamp).toInt(),
    height: font.lineHeight,
  );

  // 2. Draw the white text onto the temporary image.
  img.drawString(
    textImage,
    timestamp,
    font: font,
    color: img.ColorRgb8(255, 255, 255),
  );

  // 3. Calculate a dynamic scale factor. Target width is 20% of the main image.
  double targetWidth = image.width * 0.20;
  double scale = targetWidth / textImage.width;
  if (scale < 1.0) scale = 1.0; // Don't make it smaller than the original

  final scaledTextImage = img.copyResize(
    textImage,
    width: (textImage.width * scale).round(),
    height: (textImage.height * scale).round(),
    interpolation: img.Interpolation.linear,
  );

  // 4. Define position and padding
  const padding = 20;
  final xPos = image.width - scaledTextImage.width - padding;
  final yPos = image.height - scaledTextImage.height - padding;

  // 5. Add a semi-transparent background for better readability.
  img.fillRect(
    image,
    x1: xPos - 10,
    // Background padding
    y1: yPos - 10,
    x2: xPos + scaledTextImage.width + 10,
    y2: yPos + scaledTextImage.height + 10,
    color: img.ColorRgba8(0, 0, 0, 150),
    // Semi-transparent black
    radius: 10,
  );

  // 6. Draw the scaled text image onto the main image.
  img.compositeImage(image, scaledTextImage, dstX: xPos, dstY: yPos);

  // Save the modified image to a new file
  final timestampedFile = File(
    p.join(tempDir.path, '${p.basename(filePath)}_timestamped.jpg'),
  );
  await timestampedFile.writeAsBytes(img.encodeJpg(image));
  return timestampedFile;
}

class PreGateInProvider extends ChangeNotifier {
  bool _isValidatingContainer = false;

  bool get isValidatingContainer => _isValidatingContainer;

  bool _isFetchingDetails = false;

  bool get isFetchingDetails => _isFetchingDetails;
  bool _isFetchingMakes = false;

  bool get isFetchingMakes => _isFetchingMakes;

  bool _isFetchingConditions = false;

  bool get isFetchingConditions => _isFetchingConditions;

  int _maxPhotosTotal = 50;

  int get maxPhotosTotal => _maxPhotosTotal;

  final ApiService _apiService = ApiService();

  /// Container's Tab
  final surveyDateAndTimeController = TextEditingController();

  final containerNoController = TextEditingController();
  final grossWtController = TextEditingController();
  final tareWtController = TextEditingController();

  final mfgYearController = TextEditingController();

  /// Transporter's Tab
  final vehicleNoController = TextEditingController();
  final driverNameController = TextEditingController();
  final driverLicNoController = TextEditingController();

  /// Survey's Tab
  final gradeController = TextEditingController();
  final doNoController = TextEditingController();
  final doDateController = TextEditingController();
  final remarksController = TextEditingController();
  final sizeTypeController = TextEditingController();
  final categoryController = TextEditingController();
  final cscAspController = TextEditingController();
  final fromLocationController = TextEditingController();
  final doValidityDateController = TextEditingController();

  // State
  List<Photo> photos = [];
  bool isLoading = false;
  bool isProcessingImage = false;
  double? payload;
  bool containerValid = false;
  int? surveyIdForEdit;

  int? _buId;
  int? _userId;
  int? _containerTypeId;

  final Map<String, String> errors = {}; // Moved errors to provider
  String? selectedDODate; // if storing formatted string

  // Selected IDs
  String? selectedMfgMonth;
  String? selectedIsoId;
  String? selectedSlId;
  String? selectedTransId;
  String? selectedExaminedId;
  String? selectedSurveyTypeId;
  String? selectedContainerStatusId;
  String? selectedConditionId;
  String? selectedMakeId;
  String? surveyDateTime;
  String? selectedSurveyDateTime;

  // Values maps for dynamic
  Map<String, dynamic> containerValues = {};
  Map<String, dynamic> transporterValues = {};
  Map<String, dynamic> surveyValues = {};

  // Dropdown lists
  List<dynamic> isoCodes = [];
  List<dynamic> shippingLines = [];
  List<dynamic> transporters = [];
  List<dynamic> examineList = [];
  List<dynamic> surveyTypes = [];
  List<dynamic> containerStatus = [];
  List<dynamic> conditions = [];
  List<dynamic> makes = [];
  List<dynamic> docTypes = [];
  bool hasValidatedShippingLine = false;
  bool _isDropdownsLoading = false;

  bool get isDropdownsLoading => _isDropdownsLoading;

  // Auto-populated
  String? size;
  String? containerType;
  String category = '';

  double get completionPercentage {
    int completed = 0;
    if (containerNoController.text.isNotEmpty) completed++;
    if (selectedSlId != null) completed++;
    if (mfgYearController.text.isNotEmpty) completed++;
    if (grossWtController.text.isNotEmpty) completed++;
    if (tareWtController.text.isNotEmpty) completed++;
    if (selectedIsoId != null) completed++;
    if (vehicleNoController.text.isNotEmpty) completed++;
    if (selectedTransId != null) completed++;
    if (driverNameController.text.isNotEmpty) completed++;
    return (completed / 10 * 100);
  }

  void updateMaxPhotosTotal(int? limit) {
    if (limit != null && limit > 0) {
      _maxPhotosTotal = limit;

      notifyListeners();
    }
  }

  // ADDED: New method to process and add photos that were staged in the UI.
  Future<void> processAndAddStagedPhotos(
    List<XFile> stagedPhotos,
    String docName,
    String description,
  ) async {
    isProcessingImage = true;
    notifyListeners();

    try {
      final tempDir = await path_provider.getTemporaryDirectory();
      final RootIsolateToken token = RootIsolateToken.instance!;

      for (var file in stagedPhotos) {
        if (photos.length >= _maxPhotosTotal) break;

        final timestampedFile = await compute(_processImageInBackground, {
          'filePath': file.path,
          'token': token,
        });
        if (timestampedFile == null) continue;

        final String fileNameWithoutExt = p.basenameWithoutExtension(file.path);
        final String targetPath = p.join(
          tempDir.path,
          "${fileNameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}.jpg",
        );

        final XFile? compressedFile =
            await FlutterImageCompress.compressAndGetFile(
              timestampedFile.path,
              targetPath,
              quality: 25,
              format: CompressFormat.jpeg,
            );

        if (compressedFile != null) {
          photos.add(
            Photo(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: compressedFile.path,
              timestamp: DateTime.now().toIso8601String(),
              docName: docName,
              description: description,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error processing staged images: $e");
    } finally {
      isProcessingImage = false;
      notifyListeners();
    }
  }

  bool validateForm() {
    errors.clear();

    // --- Container Tab Validations  ---
    if (containerNoController.text.trim().isEmpty) {
      errors['containerNo'] = 'Container Number is required.';
    } else {
      final formatRegex = RegExp(r'^[A-Z]{4}[0-9]{7}$');
      if (!formatRegex.hasMatch(containerNoController.text.trim())) {
        errors['containerNo'] =
            'Format must be 4 letters and 7 digits (e.g., MSCU1234567).';
      }
    }

    if (selectedSlId == null) {
      errors['shippingLine'] = 'Shipping Line is required.';
    }

    if (selectedIsoId == null) {
      errors['isoCode'] = 'ISO Code is required.';
    }

    final double grossWt = double.tryParse(grossWtController.text) ?? 0.0;
    final double tareWt = double.tryParse(tareWtController.text) ?? 0.0;

    if (grossWtController.text.isEmpty) {
      errors['grossWeight'] = 'Gross Weight is required.';
    } else if (grossWt <= 0) {
      errors['grossWeight'] = 'Gross Weight must be greater than 0.';
    }

    if (tareWtController.text.isEmpty) {
      errors['tareWeight'] = 'Tare Weight is required.';
    } else if (tareWt <= 0) {
      errors['tareWeight'] = 'Tare Weight must be greater than 0.';
    }

    if (grossWt > 0 && tareWt > 0 && tareWt > grossWt) {
      errors['tareWeight'] = 'Tare Weight cannot be greater than Gross Weight.';
    }
    if (selectedMfgMonth == null || selectedMfgMonth!.isEmpty) {
      errors['mfgMonth'] = 'MFG Month is required.';
    }

    if (mfgYearController.text.isEmpty) {
      errors['mfgYear'] = 'MFG Year is required.';
    } else {
      final int? year = int.tryParse(mfgYearController.text);
      if (year == null || mfgYearController.text.length != 4) {
        errors['mfgYear'] = 'Enter a valid 4-digit year.';
      } else {
        final int currentYear = DateTime.now().year;
        if (year > currentYear || year < (currentYear - 30)) {
          errors['mfgYear'] = 'Year must be within the last 30 years.';
        }
      }
    }

    // if (selectedTransId == null) {
    //   errors['transporterName'] = 'Transporter Name is required.';
    // }

    // --- Survey Tab Validations ---
    if (selectedExaminedId == null) {
      errors['examination'] = 'Examined is required.';
    }
    if (selectedSurveyTypeId == null) {
      errors['surveyType'] = 'Survey Type is required.';
    }
    if (selectedContainerStatusId == null) {
      errors['containerInStatus'] = 'Container Status is required.';
    }
    if (selectedConditionId == null) {
      errors['condition'] = 'Condition is required.';
    }
    if (gradeController.text.trim().isEmpty) {
      errors['grade'] = 'Grade is required.';
    }

    notifyListeners();
    return errors.isEmpty;
  }

  PreGateInProvider() {
    setInitialSurveyDateTime();
  }

  void setInitialSurveyDateTime() {
    surveyDateAndTimeController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime.now());
    notifyListeners();
  }

  void updateUser(UserModel? user) {
    final bool isNewUser = user != null && user.buid != _buId;
    final bool isLoggingOut = user == null && _buId != null;

    if (isNewUser || isLoggingOut) {
      debugPrint(
        "User changed or logged out. Resetting PreGateInProvider state.",
      );
      resetFields();
    }

    _userId = user?.userId;
    _buId = user?.buid;

    if (user != null) {
      debugPrint(
        "✅ User data received in provider. Fetching dropdowns with BUID: $_buId",
      );
      fetchDropdowns();
    }
  }

  @override
  void dispose() {
    containerNoController.dispose();
    grossWtController.dispose();
    tareWtController.dispose();
    mfgYearController.dispose();
    vehicleNoController.dispose();
    driverNameController.dispose();
    driverLicNoController.dispose();
    gradeController.dispose();
    doNoController.dispose();
    doDateController.dispose();
    remarksController.dispose();
    sizeTypeController.dispose();
    categoryController.dispose();
    cscAspController.dispose();
    fromLocationController.dispose();
    doValidityDateController.dispose();

    super.dispose();
  }

  void resetFields({bool notify = true}) {
    setInitialSurveyDateTime();
    containerNoController.clear();
    grossWtController.clear();
    tareWtController.clear();
    mfgYearController.clear();
    vehicleNoController.clear();
    driverNameController.clear();
    driverLicNoController.clear();
    gradeController.clear();
    doNoController.clear();
    doDateController.clear();
    remarksController.clear();
    sizeTypeController.clear();
    categoryController.clear();
    cscAspController.clear();
    fromLocationController.clear();
    doValidityDateController.clear();
    photos.clear();
    containerValues.clear();
    transporterValues.clear();
    surveyValues.clear();
    selectedIsoId = null;
    selectedSlId = null;
    selectedTransId = null;
    selectedExaminedId = null;
    selectedSurveyTypeId = null;
    selectedContainerStatusId = null;
    selectedConditionId = null;
    selectedMakeId = null;
    selectedMfgMonth = null;
    size = null;
    containerType = null;
    _containerTypeId = null; // MODIFIED: Reset the container type ID
    category = '';
    payload = null;
    containerValid = false;
    hasValidatedShippingLine = false;
    conditions = [];
    makes = [];
    errors.clear();
    surveyIdForEdit = null;
    if (notify) {
      notifyListeners();
    }
  }

  void removePhoto(Photo photo) {
    photos.remove(photo);
    notifyListeners();
  }

  Future<bool> checkSurveyDone(String containerNo) async {
    if (_buId == null) {
      debugPrint("checkSurveyDone failed: BUID is null.");
      return false;
    }
    try {
      final res = await _apiService.postRequest(
        ApiEndpoints.checkContainerSurveyDone,
        {"ContainerNo": containerNo, "BUID": _buId},
        authToken: ApiEndpoints.surveyAuthToken,
      );

      debugPrint("CheckContainerSurveyDone API Response: $res");

      if (res is List && res.isNotEmpty) {
        final firstItem = res.first;
        if (firstItem is Map && firstItem.containsKey('Status')) {
          return firstItem['Status'] == true;
        }
      } else if (res is Map && res.containsKey('Status')) {
        return res['Status'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("checkSurveyDone error: $e");
      return false;
    }
  }

  // --- ADDED: Method to check gate-in status ---
  Future<bool> checkContainerGateInDone(String containerNo) async {
    if (_buId == null) {
      debugPrint("checkContainerGateInDone failed: BUID is null.");
      return false;
    }
    try {
      final res = await _apiService.postRequest(
        ApiEndpoints.checkContainerGateInDone,
        {"ContainerNo": containerNo, "BUID": _buId},
        authToken: ApiEndpoints.surveyAuthToken,
      );

      debugPrint("CheckContainerGateInDone API Response: $res");

      if (res is List && res.isNotEmpty) {
        final firstItem = res.first;
        if (firstItem is Map && firstItem.containsKey('Status')) {
          return firstItem['Status'] == true;
        }
      } else if (res is Map && res.containsKey('Status')) {
        return res['Status'] == true;
      }
      return false;
    } catch (e) {
      debugPrint("checkContainerGateInDone error: $e");
      return false;
    }
  }

  Future<bool> canProceedWithContainer(String containerNo) async {
    if (_buId == null) {
      debugPrint("canProceedWithContainer failed: BUID is null.");
      return true;
    }

    try {
      // Run both API calls in parallel
      final results = await Future.wait([
        checkSurveyDone(containerNo),
        checkContainerGateInDone(containerNo),
      ]);

      final surveyCanProceed = results[0];
      final gateInCanProceed = results[1];

      // User can only proceed if BOTH are true
      final bool canProceed = surveyCanProceed && gateInCanProceed;

      if (!canProceed) {
        debugPrint(
          "Container '$containerNo' cannot be processed. Survey API returned: $surveyCanProceed, Gate-In API returned: $gateInCanProceed.",
        );
      } else {
        debugPrint("Container '$containerNo' can be processed.");
      }

      return canProceed;
    } catch (e) {
      debugPrint("Error in canProceedWithContainer: $e");
      return true; // Default to allow proceed on unexpected error
    }
  }

  Future<bool> validateContainer(String containerNo) async {
    _isValidatingContainer = true;
    notifyListeners();

    try {
      final res = await _apiService.postRequest(
        ApiEndpoints.getContainerValidator,
        {"ContainerNo": containerNo},
        authToken: ApiEndpoints.validatorAuthToken,
      );

      bool isValid = false;
      if (res is Map && res.containsKey('Status')) {
        isValid = res['Status'] == true;
      } else if (res is List && res.isNotEmpty) {
        isValid = res.first['Status'] == true;
      }

      containerValid = isValid;
      return isValid;
    } catch (e) {
      debugPrint("validateContainer error: $e");
      containerValid = false;
      return false;
    } finally {
      _isValidatingContainer = false;
      notifyListeners();
    }
  }

  Future<void> calculatePayload() async {
    if (grossWtController.text.isEmpty || tareWtController.text.isEmpty) return;

    final dynamic raw = await _apiService.postRequest(ApiEndpoints.getPayload, {
      "GrossWeight": double.parse(grossWtController.text),
      "TareWeight": double.parse(tareWtController.text),
    }, authToken: ApiEndpoints.surveyAuthToken);

    Map<String, dynamic>? data;

    if (raw is List && raw.isNotEmpty) {
      data = raw.first as Map<String, dynamic>;
    } else if (raw is Map<String, dynamic>) {
      data = raw;
    }

    if (data != null && data.containsKey("PayLoad")) {
      payload = (data["PayLoad"] as num).toDouble();
    } else {
      payload = 0.0;
    }

    notifyListeners();
  }

  bool validateIsoCode(String isoCodeText) {
    if (isoCodeText.isEmpty) return true;

    final foundIso = isoCodes.any(
      (iso) =>
          (iso['ISOCode'] as String).toUpperCase() == isoCodeText.toUpperCase(),
    );

    return foundIso;
  }

  bool validateShippingLine(String shippingLineText) {
    if (shippingLineText.isEmpty) return true;

    final foundShippingLine = shippingLines.any(
      (sl) =>
          (sl['SLName'] as String).toLowerCase() ==
          shippingLineText.toLowerCase(),
    );

    return foundShippingLine;
  }

  bool validateShippingLineId(String? shippingLineId) {
    if (shippingLineId == null || shippingLineId.isEmpty) return true;

    final foundShippingLine = shippingLines.any(
      (sl) => sl['SLID'].toString() == shippingLineId,
    );

    return foundShippingLine;
  }

  bool validateTransporter(String transporterText) {
    if (transporterText.isEmpty) return true;

    final foundTransporter = transporters.any(
      (t) =>
          (t['TransporterName'] as String).toLowerCase() ==
          transporterText.toLowerCase(),
    );

    return foundTransporter;
  }

  bool validateTransporterId(String? transporterId) {
    if (transporterId == null || transporterId.isEmpty) return true;

    final foundTransporter = transporters.any(
      (t) => t['TransID'].toString() == transporterId,
    );

    return foundTransporter;
  }

  bool validateMakeId(String? makeId) {
    if (makeId == null || makeId.isEmpty) return true;

    final foundMake = makes.any((m) => m['ID'].toString() == makeId);

    return foundMake;
  }

  bool validateSurveyTypeId(String? surveyTypeId) {
    if (surveyTypeId == null || surveyTypeId.isEmpty) return true;

    final foundSurveyType = surveyTypes.any(
      (st) => st['ID'].toString() == surveyTypeId,
    );

    return foundSurveyType;
  }

  bool validateContainerStatusId(String? containerStatusId) {
    if (containerStatusId == null || containerStatusId.isEmpty) return true;

    final foundContainerStatus = containerStatus.any(
      (cs) => cs['ID'].toString() == containerStatusId,
    );

    return foundContainerStatus;
  }

  bool validateConditionId(String? conditionId) {
    if (conditionId == null || conditionId.isEmpty) return true;

    final foundCondition = conditions.any(
      (c) => c['ID'].toString() == conditionId,
    );

    return foundCondition;
  }

  Future<void> fetchIsoDetails(String isoCodeText) async {
    _isFetchingDetails = true;
    notifyListeners();

    try {
      size = '';
      containerType = '';
      _containerTypeId = null; // MODIFIED: Reset container type ID
      category = '';
      sizeTypeController.text = '';
      categoryController.text = '';
      makes = [];
      selectedMakeId = null;

      final foundIso = isoCodes.firstWhere(
        (i) =>
            i['ISOCode'].toString().toUpperCase() == isoCodeText.toUpperCase(),
        orElse: () => null,
      );

      if (foundIso == null) {
        selectedIsoId = null;
        return;
      }

      final isoCode = foundIso['ISOCode'] as String;
      final dynamic raw = await _apiService.postRequest(
        ApiEndpoints.getISOCodeDetails,
        {"ISOCode": isoCode, "BUID": _buId},
        authToken: ApiEndpoints.surveyAuthToken,
      );
      debugPrint(
        "-------------------------------------- FetchIsoDetails ----------------------------------------",
      );
      debugPrint(raw.toString());

      Map<String, dynamic>? data;
      if (raw is List && raw.isNotEmpty) {
        data = raw.first as Map<String, dynamic>;
      } else if (raw is Map<String, dynamic>) {
        data = raw;
      }

      if (data != null) {
        size = data['Size']?.toString() ?? '';
        containerType = data['ContainerType']?.toString() ?? '';
        _containerTypeId = data['ContainerTypeID'] as int?;
        category = data['Category']?.toString() ?? '';
        sizeTypeController.text = '$size $containerType'.toUpperCase();
        categoryController.text = category.toUpperCase();
        if (containerType?.toUpperCase() == 'RF') {
          await fetchMakes();
        }
      }
    } finally {
      _isFetchingDetails = false;
      notifyListeners();
    }
  }

  Future<void> fetchMakes() async {
    _isFetchingMakes = true;
    notifyListeners();

    try {
      final dynamic response = await _apiService.postRequest(
        ApiEndpoints.getMake,
        {"Category": "ref"},
        authToken: ApiEndpoints.surveyAuthToken,
      );
      debugPrint(
        "-------------------------------- GetMakeApi ------------------------------------",
      );
      debugPrint(response.toString());
      if (response is List) {
        makes = List<Map<String, dynamic>>.from(response);
      } else {
        makes = [];
      }
    } catch (e) {
      makes = [];
    } finally {
      _isFetchingMakes = false;
      notifyListeners();
    }
  }

  void resetConditionState() {
    if (selectedConditionId != null || conditions.isNotEmpty) {
      selectedConditionId = null;
      conditions = [];
      notifyListeners();
    }
  }

  Future<void> updateContainerStatus(String? statusId) async {
    if (selectedContainerStatusId == statusId) return;

    selectedContainerStatusId = statusId;

    if (statusId == null || statusId.isEmpty) {
      _isFetchingConditions = false;
      conditions = [];
      notifyListeners();
      return;
    }

    _isFetchingConditions = true;
    notifyListeners();

    try {
      final status =
          containerStatus.firstWhere(
                (c) => c['ID'].toString() == statusId,
                orElse: () => {'Status': ''},
              )['Status']
              as String;

      final response = await _apiService.postRequest(
        ApiEndpoints.getCondition,
        {"ID": int.parse(statusId), "Status": status},
        authToken: ApiEndpoints.surveyAuthToken,
      );

      if (response is List) {
        conditions = response;
      } else {
        conditions = [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching conditions: $e');
      conditions = [];
    } finally {
      _isFetchingConditions = false;
      notifyListeners();
    }
  }

  Future<void> fetchDropdowns() async {
    if (_buId == null) {
      debugPrint(
        "⚠️ fetchDropdowns called but BUID is null. Aborting API calls.",
      );
      return;
    }
    _isDropdownsLoading = true;
    notifyListeners();

    try {
      isoCodes = await _apiService.postRequest(ApiEndpoints.getISOCode, {
        "BUID": _buId,
      }, authToken: ApiEndpoints.surveyAuthToken);

      shippingLines = await _apiService.postRequest(
        ApiEndpoints.getShippingLines,
        {"BUID": _buId},
        authToken: ApiEndpoints.surveyAuthToken,
      );

      transporters = await _apiService.postRequest(
        ApiEndpoints.getTransporter,
        {"BUID": _buId},
        authToken: ApiEndpoints.surveyAuthToken,
      );

      examineList = await _apiService.postRequest(
        ApiEndpoints.getExamineList,
        {},
        authToken: ApiEndpoints.surveyAuthToken,
      );

      surveyTypes = await _apiService.postRequest(ApiEndpoints.getSurveyTypes, {
        "BUID": _buId,
      }, authToken: ApiEndpoints.surveyAuthToken);

      containerStatus = await _apiService.postRequest(
        ApiEndpoints.getContainerStatus,
        {},
        authToken: ApiEndpoints.surveyAuthToken,
      );

      docTypes = await _apiService.postRequest(
        ApiEndpoints.getDocTypeList,
        {},
        authToken: ApiEndpoints.surveyAuthToken,
      );
    } catch (e) {
      debugPrint("Dropdown fetch error: $e");
    } finally {
      _isDropdownsLoading = false;
      notifyListeners();
    }
  }

  static const Map<String, String> _monthAbbreviationToNumber = {
    'JAN': '1',
    'FEB': '2',
    'MAR': '3',
    'APR': '4',
    'MAY': '5',
    'JUN': '6',
    'JUL': '7',
    'AUG': '8',
    'SEP': '9',
    'OCT': '10',
    'NOV': '11',
    'DEC': '12',
  };

  static const Map<String, String> _monthNumberToAbbreviation = {
    '1': 'JAN',
    '2': 'FEB',
    '3': 'MAR',
    '4': 'APR',
    '5': 'MAY',
    '6': 'JUN',
    '7': 'JUL',
    '8': 'AUG',
    '9': 'SEP',
    '10': 'OCT',
    '11': 'NOV',
    '12': 'DEC',
  };

  Future<void> loadFromSurvey(Survey survey) async {
    // Reset fields before loading new data to avoid state conflicts
    resetFields(notify: false);

    surveyIdForEdit = int.tryParse(survey.id ?? '0');
    containerNoController.text = survey.container.containerNo;
    grossWtController.text = survey.container.grossWeight.toString();
    tareWtController.text = survey.container.tareWeight.toString();
    payload = survey.container.payload;
    selectedMfgMonth =
        _monthAbbreviationToNumber[survey.container.mfgMonth.toUpperCase()] ??
        '';
    mfgYearController.text = survey.container.mfgYear;
    vehicleNoController.text = survey.transporter.vehicleNo;
    driverNameController.text = survey.transporter.driverName;
    driverLicNoController.text = survey.transporter.driverLicense;
    gradeController.text = survey.details.grade;
    doNoController.text = survey.details.doNo;
    doDateController.text = survey.details.doDate;
    remarksController.text = survey.details.description;
    cscAspController.text = survey.details.cscAsp;
    photos = List.from(survey.photos);
    fromLocationController.text = survey.container.fromLocation;

    // Find and set Shipping Line ID
    final selectedShippingLine = shippingLines.firstWhere(
      (element) =>
          (element['SLName'] as String? ?? '').trim().toLowerCase() ==
          survey.container.shippingLine.trim().toLowerCase(),
      orElse: () => null,
    );
    if (selectedShippingLine != null) {
      selectedSlId = selectedShippingLine['SLID'].toString();
    }

    // Find and set Transporter ID
    final selectedTransporter = transporters.firstWhere(
      (element) =>
          (element['Transporter'] as String? ?? '').trim().toLowerCase() ==
          survey.transporter.transporterName.trim().toLowerCase(),
      orElse: () => null,
    );
    if (selectedTransporter != null) {
      selectedTransId = selectedTransporter['TransporterID'].toString();
    }

    // Find and set ISO Code ID
    final selectedIso = isoCodes.firstWhere(
      (element) =>
          (element['ISOCode'] as String? ?? '').trim().toLowerCase() ==
          survey.container.isoCode.trim().toLowerCase(),
      orElse: () => null,
    );
    if (selectedIso != null) {
      selectedIsoId = selectedIso['ISOID'].toString();
      containerValues['isoCode'] = survey.container.isoCode;
      await fetchIsoDetails(survey.container.isoCode);
    }

    // Find and set Survey Type ID
    final selectedSurveyType = surveyTypes.firstWhere(
      (element) =>
          (element['SurveyTypeName'] as String? ?? '').trim().toLowerCase() ==
          survey.details.surveyType.trim().toLowerCase(),
      orElse: () => null,
    );
    if (selectedSurveyType != null) {
      selectedSurveyTypeId = selectedSurveyType['SurveyTypeID'].toString();
    }

    // Find and set Examined ID
    final selectedExamineType = examineList.firstWhere(
      (element) =>
          (element['ExamineType'] as String? ?? '').trim().toLowerCase() ==
          survey.details.examination.trim().toLowerCase(),
      orElse: () => null,
    );
    if (selectedExamineType != null) {
      selectedExaminedId = selectedExamineType['ExamineID'].toString();
    }

    // Find, set, and fetch related data for Container Status
    final selectedStatus = containerStatus.firstWhere(
      (element) =>
          (element['Status'] as String? ?? '').trim().toLowerCase() ==
          survey.details.containerInStatus.trim().toLowerCase(),
      orElse: () => null,
    );

    if (selectedStatus != null) {
      // This will set the status and fetch conditions
      await updateContainerStatus(selectedStatus['ID'].toString());

      // Now that conditions are fetched, find and set the Condition ID
      final selectedCondition = conditions.firstWhere(
        (element) =>
            (element['Condition'] as String? ?? '').trim().toLowerCase() ==
            survey.details.condition.trim().toLowerCase(),
        orElse: () => null,
      );

      if (selectedCondition != null) {
        selectedConditionId = selectedCondition['ID'].toString();
      }
    }

    notifyListeners();
  }

  String _getContainerStatusDisplay(String? statusId) {
    if (statusId == null) return '';
    final found = containerStatus.firstWhere(
      (cs) => cs['ID'].toString() == statusId,
      orElse: () => null,
    );
    return found != null ? found['Status'].toString() : '';
  }

  String _getConditionDisplay(String? conditionId) {
    if (conditionId == null) return '';
    final found = conditions.firstWhere(
      (c) => c['ID'].toString() == conditionId,
      orElse: () => null,
    );
    return found != null ? found['Condition'].toString() : '';
  }

  Future<void> pickAndProcessImages(
    BuildContext context,
    ImageSource source,
    String docName,
    String description, {
    bool allowMultiple = false,
  }) async {
    final int currentPhotoCount = photos.length;
    if (currentPhotoCount >= _maxPhotosTotal) {
      debugPrint("Photo limit reached. Cannot add more photos.");
      if (!context.mounted) return;
      await CautionDialog.show(
        context: context,
        title: 'Photo Limit Reached',
        message:
            'You can only upload a maximum of $_maxPhotosTotal photos per survey.',
        icon: Icons.info_outline,
        iconColor: Colors.blue,
      );
      return;
    }

    isProcessingImage = true;
    notifyListeners();

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles = [];
    final int remainingSlots = _maxPhotosTotal - currentPhotoCount;

    try {
      if (allowMultiple) {
        if (source == ImageSource.gallery) {
          final selectedFiles = await picker.pickMultiImage();
          if (selectedFiles.isNotEmpty) {
            if (selectedFiles.length > remainingSlots) {
              pickedFiles.addAll(selectedFiles.sublist(0, remainingSlots));
              if (context.mounted) {
                await CautionDialog.show(
                  context: context,
                  title: 'Photo Limit Exceeded',
                  message:
                      'You can only add $remainingSlots more photos. ${pickedFiles.length} have been added.',
                );
              }
            } else {
              pickedFiles.addAll(selectedFiles);
            }
          }
        } else {
          // Custom camera for multiple shots
          final cameras = await availableCameras();
          if (context.mounted) {
            final capturedImages = await Navigator.push<List<XFile>>(
              context,
              MaterialPageRoute(
                builder: (_) => CustomCameraScreen(cameras: cameras),
              ),
            );
            if (capturedImages != null && capturedImages.isNotEmpty) {
              if (capturedImages.length > remainingSlots) {
                pickedFiles.addAll(capturedImages.sublist(0, remainingSlots));
                if (context.mounted) {
                  await CautionDialog.show(
                    context: context,
                    title: 'Photo Limit Exceeded',
                    message:
                        'You can only add $remainingSlots more photos. ${pickedFiles.length} have been added.',
                  );
                }
              } else {
                pickedFiles.addAll(capturedImages);
              }
            }
          }
        }
      } else {
        final XFile? pickedFile = await picker.pickImage(
          source: source,
          preferredCameraDevice: CameraDevice.rear,
          requestFullMetadata: false,
        );
        if (pickedFile != null) {
          pickedFiles.add(pickedFile);
        }
      }

      if (pickedFiles.isEmpty) {
        isProcessingImage = false;
        notifyListeners();
        return;
      }

      final tempDir = await path_provider.getTemporaryDirectory();
      final RootIsolateToken token = RootIsolateToken.instance!;

      for (var file in pickedFiles) {
        if (photos.length >= _maxPhotosTotal) break;

        final timestampedFile = await compute(_processImageInBackground, {
          'filePath': file.path,
          'token': token,
        });
        if (timestampedFile == null) continue;

        final String fileNameWithoutExt = p.basenameWithoutExtension(file.path);
        final String targetPath = p.join(
          tempDir.path,
          "${fileNameWithoutExt}_${DateTime.now().millisecondsSinceEpoch}.jpg",
        );

        final XFile? compressedFile =
            await FlutterImageCompress.compressAndGetFile(
              timestampedFile.path,
              targetPath,
              quality: 25,
              format: CompressFormat.jpeg,
            );

        if (compressedFile != null) {
          photos.add(
            Photo(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              url: compressedFile.path,
              timestamp: DateTime.now().toIso8601String(),
              docName: docName,
              description: description,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Error picking images: $e");
    } finally {
      isProcessingImage = false;
      notifyListeners();
    }
  }

  void updatePhotoDetails(
    Photo photoToUpdate,
    String newDocName,
    String newDescription,
  ) {
    final index = photos.indexWhere((p) => p.id == photoToUpdate.id);
    if (index != -1) {
      photos[index] = Photo(
        id: photoToUpdate.id,
        url: photoToUpdate.url,
        timestamp: photoToUpdate.timestamp,
        docName: newDocName,
        description: newDescription,
      );
      notifyListeners();
    }
  }

  // ADDED: New method to efficiently update all photos in a group.
  void updatePhotoGroupDetails(
    String oldDocName,
    String newDocName,
    String newDescription,
  ) {
    // Create a new list to avoid concurrent modification errors.
    List<Photo> updatedPhotos = [];
    for (var photo in photos) {
      if (photo.docName == oldDocName) {
        // If the photo is in the group, create a new Photo object with updated details.
        updatedPhotos.add(
          Photo(
            id: photo.id,
            url: photo.url,
            timestamp: photo.timestamp,
            docName: newDocName,
            description: newDescription,
          ),
        );
      } else {
        // Otherwise, add the original photo to the new list.
        updatedPhotos.add(photo);
      }
    }
    // Replace the old list with the new one and notify listeners.
    photos = updatedPhotos;
    notifyListeners();
  }

  // ADDED: New method to remove all photos in a group.
  void removePhotoGroup(String docName) {
    photos.removeWhere((photo) => photo.docName == docName);
    notifyListeners();
  }

  Future<void> replacePhoto(Photo photoToReplace, ImageSource source) async {
    isProcessingImage = true;
    notifyListeners();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      preferredCameraDevice: CameraDevice.rear,
      requestFullMetadata: false,
    );

    if (pickedFile == null) {
      isProcessingImage = false;
      notifyListeners();
      return;
    }

    final tempDir = await path_provider.getTemporaryDirectory();
    final token = RootIsolateToken.instance!;

    final timestampedFile = await compute(_processImageInBackground, {
      'filePath': pickedFile.path,
      'token': token,
    });

    if (timestampedFile != null) {
      final targetPath = p.join(
        tempDir.path,
        "${p.basenameWithoutExtension(pickedFile.path)}_${DateTime.now().millisecondsSinceEpoch}.jpg",
      );

      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        timestampedFile.path,
        targetPath,
        quality: 25,
        format: CompressFormat.jpeg,
      );

      if (compressedFile != null) {
        final index = photos.indexWhere((p) => p.id == photoToReplace.id);
        if (index != -1) {
          photos[index] = Photo(
            id: photoToReplace.id,
            url: compressedFile.path,
            timestamp: DateTime.now().toIso8601String(),
            docName: photoToReplace.docName,
            description: photoToReplace.description,
          );
        }
      }
    }

    isProcessingImage = false;
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> uploadAttachments() async {
    List<Map<String, dynamic>> uploadedAttachments = [];
    if (_userId == null || _buId == null) return uploadedAttachments;

    for (var photo in photos) {
      final bool isExistingPhoto = photo.url.startsWith('http');

      if (isExistingPhoto) {
        debugPrint("✅ Including existing photo metadata: ${photo.url}");
        final uri = Uri.parse(photo.url);
        String serverPath = uri.queryParameters['FilePath'] ?? photo.url;

        // Handle both forward and backward slashes
        final fileName = serverPath.split(RegExp(r'[/\\]')).last;

        // DON'T reconstruct the path - use the original structure
        // The server path might already have the correct relative path embedded
        String relativePath;
        if (serverPath.contains('/Uploads/') ||
            serverPath.contains('\\Uploads\\')) {
          // Extract the relative path from the server path
          final uploadIndex = serverPath.indexOf(RegExp(r'[/\\]Uploads[/\\]'));
          if (uploadIndex != -1) {
            relativePath = serverPath
                .substring(uploadIndex)
                .replaceAll('\\', '/');
          } else {
            // Fallback: construct it
            relativePath =
                "/Uploads/TempDocument/Location $_buId/PreGateINSurvey/${containerNoController.text.trim()}/$fileName";
          }
        } else {
          // If server path doesn't contain Uploads, construct the relative path
          relativePath =
              "/Uploads/TempDocument/Location $_buId/PreGateINSurvey/${containerNoController.text.trim()}/$fileName";
        }

        uploadedAttachments.add({
          "DocName": photo.docName,
          "FilePath": fileName,
          "FilePath1": serverPath,
          "ContainerNo": containerNoController.text.trim(),
          "FileName": fileName,
          "FileDesc": photo.description,
          "RelativePath": relativePath,
          "ContentType": "image/jpeg",
        });
        continue;
      }

      // --- FIX: Upload the already-processed file directly ---
      // The file at `photo.url` has already been timestamped by `pickAndProcessImages`.
      // There is no need to process it again here.
      debugPrint("📤 Uploading new photo directly: ${photo.url}");
      final File fileToUpload = File(photo.url);

      try {
        final response = await _apiService.uploadFile(
          ApiEndpoints.uploadAttachment,
          fileToUpload, // Use the file directly
          fields: {
            'UserID': _userId.toString(),
            'BUID': _buId.toString(),
            'BULocationName': 'Location $_buId',
            'ContainerNo': containerNoController.text.trim(),
            'EnqType': 'PreGateINSurvey',
            'DocName': photo.docName,
            'UploadType': 'PreGateINSurvey',
          },
        );

        Map<String, dynamic>? uploadedData;
        if (response is List && response.isNotEmpty) {
          uploadedData = Map<String, dynamic>.from(response.first);
        } else if (response is Map) {
          uploadedData = Map<String, dynamic>.from(response);
        }

        if (uploadedData != null && uploadedData.containsKey('FileName')) {
          uploadedAttachments.add({
            'DocName': uploadedData['DocName'],
            'FilePath': uploadedData['FilePath'],
            'FilePath1': uploadedData['FilePath1'],
            'ContainerNo': uploadedData['ContainerNo'],
            'FileName': uploadedData['FileName'],
            'FileDesc': photo.description,
            'RelativePath': uploadedData['RelativePath'],
            'ContentType': uploadedData['ContentType'],
          });
        } else {
          debugPrint(
            'UploadAttachment API returned unexpected format: $response',
          );
        }
      } catch (e) {
        debugPrint('Attachment upload failed for ${photo.url}: $e');
      }
    }

    return uploadedAttachments;
  }

  Future<String?> saveSurvey(BuildContext context) async {
    isLoading = true;
    notifyListeners();

    if (_userId == null || _buId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Error: User session expired. Please log in again."),
          ),
        );
      }
      isLoading = false;
      notifyListeners();
      return "User session expired. Please log in again.";
    }

    try {
      final uploadedAttachments = await uploadAttachments();
      debugPrint('📤 Uploaded Attachments:\n$uploadedAttachments');

      String? formatDate(TextEditingController controller) {
        final text = controller.text.trim();
        return text.isEmpty ? null : text;
      }

      final body = {
        "SurveyID": surveyIdForEdit ?? 0,
        "ContainerNo": containerNoController.text.trim(),
        "ISOCodeID": int.tryParse(selectedIsoId ?? '0') ?? 0,
        "ContainerTypeID": _containerTypeId ?? 0,
        "Size": size ?? "",
        "SLID": int.tryParse(selectedSlId ?? '0') ?? 0,
        "GrossWt": grossWtController.text.trim(),
        "TareWt": tareWtController.text.trim(),
        "PayLoad": payload?.toStringAsFixed(2) ?? '0',
        "Category": category.toUpperCase(),
        "MakeID": int.tryParse(selectedMakeId ?? '0') ?? 0,
        "MFGMonth":
            _monthNumberToAbbreviation[selectedMfgMonth?.trim() ?? ''] ?? '',
        "MFGYear": mfgYearController.text.trim(),
        "FromLocation": fromLocationController.text.trim(),
        "IsValidContainer": containerValid ? 1 : 0,
        "ExaminedID": int.tryParse(selectedExaminedId ?? '0') ?? 0,
        "SurveyType": int.tryParse(selectedSurveyTypeId ?? '0') ?? 0,
        "ContainerStatus": _getContainerStatusDisplay(
          selectedContainerStatusId,
        ),
        "Condition": _getConditionDisplay(selectedConditionId),
        "CSCASP": cscAspController.text.trim(),
        "Grade": gradeController.text.trim(),
        "DONo": doNoController.text.trim(),
        "Remarks": remarksController.text.trim(),
        "DODate": formatDate(doDateController),
        "DOValidityDate": formatDate(doValidityDateController),
        "TransID": int.tryParse(selectedTransId ?? '0') ?? 0,
        "VehicleNo": vehicleNoController.text.trim(),
        "DriverName": driverNameController.text.trim(),
        "DriverLicNo": driverLicNoController.text.trim(),
        "Surveydate": surveyDateAndTimeController.text.trim(),
        "UserID": _userId,
        "BUID": _buId,
        "attachmentList": uploadedAttachments,
      };

      body.removeWhere((key, value) => value == null);

      // --- DEBUGGING: Added extensive logging ---
      final bool isUpdating = surveyIdForEdit != null && surveyIdForEdit! > 0;
      final String endpoint = isUpdating
          ? ApiEndpoints.updatePreGateInSurvey
          : ApiEndpoints.insertPreGateInSurvey;

      debugPrint("===================== SAVING SURVEY =====================");
      debugPrint("SURVEY ACTION: ${isUpdating ? 'UPDATE' : 'INSERT'}");
      debugPrint("ENDPOINT: $endpoint");
      // Using jsonEncode with an indent for readability
      final prettyPrint = const JsonEncoder.withIndent('  ').convert(body);
      debugPrint("PAYLOAD:\n$prettyPrint");
      debugPrint("=========================================================");

      final response = await _apiService.postRequest(
        endpoint,
        body,
        authToken: ApiEndpoints.surveyAuthToken,
      );

      debugPrint('✅ SaveSurvey API Response:\n$response');

      if (response is Map && response['StatusCode'] == 1) {
        resetFields(notify: false);
        return null;
      } else {
        return response['StatusMessage'] ?? 'Unknown API error';
      }
    } catch (e) {
      debugPrint('❌ SaveSurvey Exception: $e');
      final errorMessage = e.toString();
      if (errorMessage.contains(
        'A survey for this container number has already been done.',
      )) {
        return 'A survey for this container number has already been done.';
      }
      return 'An unexpected error occurred. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
