// lib/providers/pre_gate_inPdr.dart
import 'dart:io';

import 'package:esquare/core/models/photoMdl.dart';
import 'package:esquare/core/models/userMdl.dart';
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
  // ADD THIS NEW FLAG for container validation
  bool _isValidatingContainer = false;

  bool get isValidatingContainer => _isValidatingContainer;

  // ADD THIS NEW FLAG for the 'Make' field specifically
  bool _isFetchingDetails = false;

  bool get isFetchingDetails => _isFetchingDetails;
  bool _isFetchingMakes = false;

  bool get isFetchingMakes => _isFetchingMakes;
  final ApiService _apiService = ApiService();

  /// Container's Tab
  final surveyDateAndTimeController = TextEditingController();

  final containerNoController = TextEditingController();
  final grossWtController = TextEditingController();
  final tareWtController = TextEditingController();
  final mfgMonthController = TextEditingController();
  final mfgYearController = TextEditingController();

  /// Transporter's Tab
  final vehicleNoController = TextEditingController();
  final driverNameController = TextEditingController();
  final driverLicNoController = TextEditingController();

  // --- 1. FocusNodes ADDED to the Provider ---
  final FocusNode vehicleNoFocusNode = FocusNode();
  final FocusNode driverLicenseFocusNode = FocusNode();

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

  // int buId = 3;
  // int userId = 21;
  int? _buId;
  int? _userId;

  final Map<String, String> errors = {}; // Moved errors to provider
  String? selectedDODate; // if storing formatted string

  // Selected IDs
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
    if (mfgMonthController.text.isNotEmpty) completed++;
    if (mfgYearController.text.isNotEmpty) completed++;
    if (grossWtController.text.isNotEmpty) completed++;
    if (tareWtController.text.isNotEmpty) completed++;
    if (selectedIsoId != null) completed++;
    if (vehicleNoController.text.isNotEmpty) completed++;
    if (selectedTransId != null) completed++;
    if (driverNameController.text.isNotEmpty) completed++;
    return (completed / 10 * 100);
  }

  // ** MODIFIED - This method is now the master validation checker **
  bool validateForm() {
    errors.clear();

    // --- Container No Validations  ---
    if (containerNoController.text.trim().isEmpty) {
      errors['containerNo'] = 'Container Number is required';
    } else {
      final formatRegex = RegExp(r'^[A-Z]{4}[0-9]{7}$');
      if (!formatRegex.hasMatch(containerNoController.text.trim())) {
        errors['containerNo'] =
            'Format must be 4 letters and 7 digits (e.g., MSCU1234567)';
      }
    }

    // --- Shipping Line & ISO Code Validation  ---
    if (selectedSlId == null && hasValidatedShippingLine) {
      errors['shippingLine'] = 'Shipping Line is required';
    }

    if (selectedIsoId == null) {
      errors['isoCode'] = 'ISO Code is required';
    }

    // --- Weight Validations ---
    final double grossWt = double.tryParse(grossWtController.text) ?? 0.0;
    final double tareWt = double.tryParse(tareWtController.text) ?? 0.0;

    if (grossWtController.text.isEmpty) {
      errors['grossWeight'] = 'Gross Weight is required';
    } else if (grossWt <= 0) {
      errors['grossWeight'] = 'Gross Weight must be greater than 0';
    }

    if (tareWtController.text.isEmpty) {
      errors['tareWeight'] = 'Tare Weight is required';
    } else if (tareWt <= 0) {
      errors['tareWeight'] = 'Tare Weight must be greater than 0';
    }

    // Check tare vs gross only if both are valid numbers > 0
    if (grossWt > 0 && tareWt > 0 && tareWt > grossWt) {
      errors['tareWeight'] = 'Tare Weight cannot be greater than Gross Weight';
    }

    // --- MFG Year & Month Validation  ---
    if (mfgMonthController.text.isEmpty) {
      errors['mfgMonth'] = 'MFG Month is required';
    }

    if (mfgYearController.text.isEmpty) {
      errors['mfgYear'] = 'MFG Year is required';
    } else {
      final int? year = int.tryParse(mfgYearController.text);
      if (year == null || mfgYearController.text.length != 4) {
        errors['mfgYear'] = 'Enter a valid 4-digit year';
      } else {
        final int currentYear = DateTime.now().year;
        if (year > currentYear || year < (currentYear - 30)) {
          errors['mfgYear'] = 'Year must be within the last 30 years';
        }
      }
    }

    notifyListeners();
    return errors.isEmpty;
  }

  PreGateInProvider() {
    // Set the initial value to the current date and time when the provider is created.
    setInitialSurveyDateTime();
  }

  void setInitialSurveyDateTime() {
    surveyDateAndTimeController.text = DateFormat(
      'yyyy-MM-dd HH:mm',
    ).format(DateTime.now());
    notifyListeners();
  }

  void updateUser(UserModel? user) {
    // Check if the BUID is changing from null to a real value.
    // This is a reliable way to know the user has just been loaded.
    bool justLoggedIn = (_buId == null && user?.buid != null);

    _userId = user?.userId;
    _buId = user?.buid;

    // If the user's data was just loaded for the first time,
    // then it's the perfect time to fetch the dropdown data.
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
    mfgMonthController.dispose();
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

    // --- 2. Dispose FocusNodes ---
    vehicleNoFocusNode.dispose();
    driverLicenseFocusNode.dispose();

    super.dispose();
  }

  // lib/providers/pre_gate_inPdr.dart

  void resetFields() {
    setInitialSurveyDateTime();
    containerNoController.clear();
    grossWtController.clear();
    tareWtController.clear();
    mfgMonthController.clear();
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
    transporterValues.clear(); // Added
    surveyValues.clear(); // Added
    selectedIsoId = null;
    selectedSlId = null;
    selectedTransId = null;
    selectedExaminedId = null;
    selectedSurveyTypeId = null;
    selectedContainerStatusId = null;
    selectedConditionId = null;
    selectedMakeId = null;
    size = null;
    containerType = null;
    category = '';
    payload = null;
    containerValid = false;
    hasValidatedShippingLine = false; // Added
    conditions = []; // Added
    makes = []; // Added
    errors.clear();
    notifyListeners();
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

      containerValid = isValid; // Update the containerValid state
      return isValid;
    } catch (e) {
      debugPrint("validateContainer error: $e");
      containerValid = false; // Assume invalid on error
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

  /// Validates if the entered ISO code exists in the available ISO codes list
  bool validateIsoCode(String isoCodeText) {
    if (isoCodeText.isEmpty) return true; // Allow empty for now

    final foundIso = isoCodes.any(
      (iso) =>
          (iso['ISOCode'] as String).toUpperCase() == isoCodeText.toUpperCase(),
    );

    return foundIso;
  }

  /// Validates if the entered shipping line exists in the available shipping lines list
  bool validateShippingLine(String shippingLineText) {
    if (shippingLineText.isEmpty) return true; // Allow empty for now

    final foundShippingLine = shippingLines.any(
      (sl) =>
          (sl['SLName'] as String).toLowerCase() ==
          shippingLineText.toLowerCase(),
    );

    return foundShippingLine;
  }

  /// Validates if the selected shipping line ID exists in the available shipping lines list
  bool validateShippingLineId(String? shippingLineId) {
    if (shippingLineId == null || shippingLineId.isEmpty) return true;

    final foundShippingLine = shippingLines.any(
      (sl) => sl['SLID'].toString() == shippingLineId,
    );

    return foundShippingLine;
  }

  /// Validates if the entered transporter exists in the available transporters list
  bool validateTransporter(String transporterText) {
    if (transporterText.isEmpty) return true; // Allow empty for now

    final foundTransporter = transporters.any(
      (t) =>
          (t['TransporterName'] as String).toLowerCase() ==
          transporterText.toLowerCase(),
    );

    return foundTransporter;
  }

  /// Validates if the selected transporter ID exists in the available transporters list
  bool validateTransporterId(String? transporterId) {
    if (transporterId == null || transporterId.isEmpty) return true;

    final foundTransporter = transporters.any(
      (t) => t['TransID'].toString() == transporterId,
    );

    return foundTransporter;
  }

  /// Validates if the selected make ID exists in the available makes list
  bool validateMakeId(String? makeId) {
    if (makeId == null || makeId.isEmpty) return true;

    final foundMake = makes.any((m) => m['ID'].toString() == makeId);

    return foundMake;
  }

  /// Validates if the selected survey type ID exists in the available survey types list
  bool validateSurveyTypeId(String? surveyTypeId) {
    if (surveyTypeId == null || surveyTypeId.isEmpty) return true;

    final foundSurveyType = surveyTypes.any(
      (st) => st['ID'].toString() == surveyTypeId,
    );

    return foundSurveyType;
  }

  /// Validates if the selected container status ID exists in the available container status list
  bool validateContainerStatusId(String? containerStatusId) {
    if (containerStatusId == null || containerStatusId.isEmpty) return true;

    final foundContainerStatus = containerStatus.any(
      (cs) => cs['ID'].toString() == containerStatusId,
    );

    return foundContainerStatus;
  }

  /// Validates if the selected condition ID exists in the available conditions list
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
      // selectedIsoId = isoId;

      // Clear previous details
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
        // It's good practice to clear the ID if the code is invalid
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
        // --- FIX: ADD THIS CONDITIONAL CHECK ---
        // If the container is a Refrigerated Container ('RF'), fetch the makes.
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
    // 1. Set the dedicated 'makes' loading flag to true and notify UI
    _isFetchingMakes = true;
    notifyListeners();

    try {
      // 2. Make the API call to get the list of makes
      final dynamic response = await _apiService.postRequest(
        ApiEndpoints.getMake,
        {"Category": "ref"},
        // Assuming "ref" is the correct category for RF containers
        authToken: ApiEndpoints.surveyAuthToken,
      );
      debugPrint(
        "-------------------------------- GetMakeApi ------------------------------------",
      );
      debugPrint(response.toString());
      // It's safer to check the response type before assigning
      if (response is List) {
        makes = List<Map<String, dynamic>>.from(response);
      } else {
        // If the response is not a list, handle it gracefully
        makes = [];
      }
    } catch (e) {
      // In case of an error, clear the makes list
      makes = [];
      // Optionally, you can log the error: print('Error fetching makes: $e');
    } finally {
      // 3. ALWAYS set the loading flag to false and notify the UI
      _isFetchingMakes = false;
      notifyListeners();
    }
  }

  Future<void> fetchConditions(String statusId) async {
    selectedContainerStatusId = statusId;

    final status =
        containerStatus.firstWhere(
              (c) => c['ID'].toString() == statusId,
            )['Status']
            as String;

    final response = await _apiService.postRequest(ApiEndpoints.getCondition, {
      "ID": int.parse(statusId),
      "Status": status,
    }, authToken: ApiEndpoints.surveyAuthToken);

    // Ensure 'conditions' is always a list
    if (response is List) {
      conditions = response;
      debugPrint('Conditions Response: $response');
    } else if (response is Map<String, dynamic>) {
      conditions = [response]; // Wrap in a list
    } else {
      conditions = [];
    }

    notifyListeners();
  }

  Future<void> fetchDropdowns() async {
    // ADD THIS GUARD CLAUSE at the top of the method
    if (_buId == null) {
      debugPrint(
        "⚠️ fetchDropdowns called but BUID is null. Aborting API calls.",
      );
      return; // Stop the function here
    }
    // SET LOADING TO TRUE AT THE START
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

  void loadFromSurvey(Survey survey) {
    containerNoController.text = survey.container.containerNo;
    grossWtController.text = survey.container.grossWeight.toString();
    tareWtController.text = survey.container.tareWeight.toString();
    mfgMonthController.text = survey.container.mfgMonth;
    mfgYearController.text = survey.container.mfgYear;
    vehicleNoController.text = survey.transporter.vehicleNo;
    driverNameController.text = survey.transporter.driverName;
    driverLicNoController.text = survey.transporter.driverLicense;
    gradeController.text = survey.details.grade;
    doNoController.text = survey.details.doNo;
    doDateController.text = survey.details.doDate;
    remarksController.text = survey.details.description;
    cscAspController.text = survey.details.cscAsp;
    photos = survey.photos;
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
    ImageSource source,
    String docName,
    String description,
  ) async {
    isProcessingImage = true;
    notifyListeners();

    final ImagePicker picker = ImagePicker();
    final List<XFile> pickedFiles;
    if (source == ImageSource.gallery) {
      pickedFiles = await picker.pickMultiImage();
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
      if (photos.length >= 50) break;

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

  Future<List<Map<String, dynamic>>> uploadAttachments() async {
    List<Map<String, dynamic>> uploadedAttachments = [];

    if (_userId == null || _buId == null) return uploadedAttachments;

    for (var photo in photos) {
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

          // Override the FileDesc with our description
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

  Future<bool> saveSurvey(BuildContext context) async {
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
      return false;
    }

    try {
      final uploadedAttachments = await uploadAttachments();
      debugPrint('📤 Uploaded Attachments:\n$uploadedAttachments');

      String? formatDate(TextEditingController controller) {
        final text = controller.text.trim();
        return text.isEmpty ? null : text;
      }

      final body = {
        "SurveyID": 0,
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
        "MFGMonth": mfgMonthController.text.trim(),
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

      final response = await _apiService.postRequest(
        ApiEndpoints.insertPreGateInSurvey,
        body,
        authToken: ApiEndpoints.surveyAuthToken,
      );

      debugPrint('✅ SaveSurvey API Response:\n$response');

      if (response is Map && response['StatusCode'] == 1) {
        resetFields();
        return true;
      } else {
        throw Exception(response['StatusMessage'] ?? 'Unknown API error');
      }
    } catch (e) {
      debugPrint('❌ SaveSurvey Exception: $e');
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
