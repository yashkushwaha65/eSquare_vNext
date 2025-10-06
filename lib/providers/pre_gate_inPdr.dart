// lib/providers/pre_gate_inPdr.dart
import 'dart:io';

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
  final font = img.arial48; // Use the largest base font for best quality

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

  // 3. Calculate a dynamic scale factor. Target width is 40% of the main image.
  double targetWidth = image.width * 0.40;
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

  static const int maxPhotos = 5;

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

    if (selectedTransId == null) {
      errors['transporterName'] = 'Transporter Name is required.';
    }

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
    bool justLoggedIn = (_buId == null && user?.buid != null);

    _userId = user?.userId;
    _buId = user?.buid;

    if (justLoggedIn) {
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

    final selectedShippingLine = shippingLines.firstWhere(
      (element) => element['SLName'] == survey.container.shippingLine,
      orElse: () => null,
    );
    if (selectedShippingLine != null) {
      selectedSlId = selectedShippingLine['SLID'].toString();
    }

    final selectedIso = isoCodes.firstWhere(
      (element) => element['ISOCode'] == survey.container.isoCode,
      orElse: () => null,
    );
    if (selectedIso != null) {
      selectedIsoId = selectedIso['ISOID'].toString();
      containerValues['isoCode'] = survey.container.isoCode;
      await fetchIsoDetails(survey.container.isoCode);
    }

    final selectedSurveyType = surveyTypes.firstWhere(
      (element) => element['SurveyTypeName'] == survey.details.surveyType,
      orElse: () => null,
    );
    if (selectedSurveyType != null) {
      selectedSurveyTypeId = selectedSurveyType['SurveyTypeID'].toString();
    }

    final selectedStatus = containerStatus.firstWhere(
      (element) => element['Status'] == survey.details.containerInStatus,
      orElse: () => null,
    );

    if (selectedStatus != null) {
      await updateContainerStatus(selectedStatus['ID'].toString());

      final selectedCondition = conditions.firstWhere(
        (element) => element['Condition'] == survey.details.condition,
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
    String description,
  ) async {
    if (photos.length >= maxPhotos) {
      debugPrint("Photo limit reached. Cannot add more photos.");
      await CautionDialog.show(
        context: context,
        title: 'Photo Limit Reached',
        message:
            'You can only upload a maximum of $maxPhotos photos per survey.',
        icon: Icons.info_outline,
        iconColor: Colors.blue,
      );
      return;
    }

    isProcessingImage = true;
    notifyListeners();

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles;

    final int remainingSlots = maxPhotos - photos.length;

    if (source == ImageSource.gallery) {
      final selectedFiles = await picker.pickMultiImage();
      if (selectedFiles.length > remainingSlots) {
        pickedFiles = selectedFiles.sublist(0, remainingSlots);
        await CautionDialog.show(
          context: context,
          title: 'Some Images Not Added',
          message:
              'You selected ${selectedFiles.length} images, but only ${pickedFiles.length} could be added to stay within the $maxPhotos photo limit.',
          icon: Icons.info_outline,
          iconColor: Colors.blue,
        );
      } else {
        pickedFiles = selectedFiles;
      }
    } else {
      final XFile? pickedFile = await picker.pickImage(source: source);
      pickedFiles = pickedFile != null ? [pickedFile] : [];
    }

    if (pickedFiles.isEmpty) {
      isProcessingImage = false;
      notifyListeners();
      return;
    }

    final tempDir = await path_provider.getTemporaryDirectory();
    final RootIsolateToken token = RootIsolateToken.instance!;

    for (var file in pickedFiles) {
      if (photos.length >= maxPhotos) break;

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

    isProcessingImage = false;
    notifyListeners();
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

  Future<void> replacePhoto(Photo photoToReplace, ImageSource source) async {
    isProcessingImage = true;
    notifyListeners();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

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
      final bool isExistingPhoto =
          photo.url.contains(RegExp(r'^[a-zA-Z]:\\')) ||
          photo.url.startsWith('http');

      if (isExistingPhoto) {
        debugPrint("✅ Detected an existing photo. Original path: ${photo.url}");

        String serverPath;
        if (photo.url.startsWith('http')) {
          final uri = Uri.parse(photo.url);
          serverPath = uri.queryParameters['FilePath'] ?? photo.url;
        } else {
          serverPath = photo.url;
        }

        final fileName = serverPath.split(RegExp(r'[/\\]')).last;

        debugPrint("✅ Extracted FileName: $fileName");

        uploadedAttachments.add({
          'DocName': photo.docName,
          'FilePath': fileName,
          'FilePath1': serverPath,
          'ContainerNo': containerNoController.text.trim(),
          'FileName': fileName,
          'FileDesc': photo.description,
          'RelativePath':
              "/Uploads/TempDocument/Location $_buId/PreGateINSurvey/${containerNoController.text.trim()}/$fileName",
          'ContentType': 'image/jpeg',
        });
        continue;
      }
      debugPrint("Uploading a new photo from local path: ${photo.url}");
      final file = File(photo.url);

      try {
        final response = await _apiService.uploadFile(
          'https://esquarevnextmobilesurvey.ddplesquare.com/api/UploadAttachment',
          file,
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

        if (response is List && response.isNotEmpty) {
          final uploadedData = Map<String, dynamic>.from(response.first);
          uploadedData['FileDesc'] = photo.description;
          uploadedAttachments.add(uploadedData);
        } else {
          debugPrint(
            'UploadAttachment API returned unexpected format: $response',
          );
        }
      } catch (e) {
        debugPrint('Attachment upload failed: $e');
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
        "ContainerTypeID": 1,
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

      debugPrint('📤 Full SaveSurvey Payload:\n$body');

      final bool isUpdating = surveyIdForEdit != null && surveyIdForEdit! > 0;
      final String endpoint = isUpdating
          ? ApiEndpoints.updatePreGateInSurvey
          : ApiEndpoints.insertPreGateInSurvey;

      debugPrint("✅ Using endpoint: $endpoint (Is Updating: $isUpdating)");

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
