// lib/models/survey_model.dart

enum ContainerCategory {
  dry('Dry'),
  reefer('Reefer'),
  tank('Tank');

  const ContainerCategory(this.displayName);
  final String displayName;
}

enum ExaminationType {
  onWheel('On wheel'),
  onGround('On ground');

  const ExaminationType(this.displayName);
  final String displayName;
}

enum SurveyType {
  iicl('IICL'),
  cargoWorthy('Cargo Worthy');

  const SurveyType(this.displayName);
  final String displayName;
}

enum ContainerStatus {
  damage('Damage'),
  clean('Clean');

  const ContainerStatus(this.displayName);
  final String displayName;
}

enum ContainerStatusEnum {
  survey('survey'),
  repair('repair'),
  ready('ready');

  const ContainerStatusEnum(this.value);
  final String value;
}

enum PhotoType {
  preGate('pre-gate'),
  repair('repair'),
  gateOut('gate-out');

  const PhotoType(this.value);
  final String value;
}

class Container {
  final String id;
  final String containerNo;
  final String mfgMonth;
  final String mfgYear;
  final double grossWeight;
  final double tareWeight;
  final double payload;
  final String shippingLine;
  final String? isoCode;
  final String? sizeType;
  final ContainerStatusEnum status;

  Container({
    required this.id,
    required this.containerNo,
    required this.mfgMonth,
    required this.mfgYear,
    required this.grossWeight,
    required this.tareWeight,
    required this.payload,
    required this.shippingLine,
    this.isoCode,
    this.sizeType,
    required this.status,
  });

  Container copyWith({
    String? id,
    String? containerNo,
    String? mfgMonth,
    String? mfgYear,
    double? grossWeight,
    double? tareWeight,
    double? payload,
    String? shippingLine,
    String? isoCode,
    String? sizeType,
    ContainerStatusEnum? status,
  }) {
    return Container(
      id: id ?? this.id,
      containerNo: containerNo ?? this.containerNo,
      mfgMonth: mfgMonth ?? this.mfgMonth,
      mfgYear: mfgYear ?? this.mfgYear,
      grossWeight: grossWeight ?? this.grossWeight,
      tareWeight: tareWeight ?? this.tareWeight,
      payload: payload ?? this.payload,
      shippingLine: shippingLine ?? this.shippingLine,
      isoCode: isoCode ?? this.isoCode,
      sizeType: sizeType ?? this.sizeType,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'containerNo': containerNo,
      'mfgMonth': mfgMonth,
      'mfgYear': mfgYear,
      'grossWeight': grossWeight,
      'tareWeight': tareWeight,
      'payload': payload,
      'shippingLine': shippingLine,
      'isoCode': isoCode,
      'sizeType': sizeType,
      'status': status.value,
    };
  }

  factory Container.fromJson(Map<String, dynamic> json) {
    return Container(
      id: json['id'],
      containerNo: json['containerNo'],
      mfgMonth: json['mfgMonth'],
      mfgYear: json['mfgYear'],
      grossWeight: (json['grossWeight'] as num).toDouble(),
      tareWeight: (json['tareWeight'] as num).toDouble(),
      payload: (json['payload'] as num).toDouble(),
      shippingLine: json['shippingLine'],
      isoCode: json['isoCode'],
      sizeType: json['sizeType'],
      status: ContainerStatusEnum.values.firstWhere(
            (e) => e.value == json['status'],
        orElse: () => ContainerStatusEnum.survey,
      ),
    );
  }
}

class Transporter {
  final String vehicleNo;
  final String transporterName;
  final String driverLicense;
  final String driverName;

  Transporter({
    required this.vehicleNo,
    required this.transporterName,
    required this.driverLicense,
    required this.driverName,
  });

  Transporter copyWith({
    String? vehicleNo,
    String? transporterName,
    String? driverLicense,
    String? driverName,
  }) {
    return Transporter(
      vehicleNo: vehicleNo ?? this.vehicleNo,
      transporterName: transporterName ?? this.transporterName,
      driverLicense: driverLicense ?? this.driverLicense,
      driverName: driverName ?? this.driverName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleNo': vehicleNo,
      'transporterName': transporterName,
      'driverLicense': driverLicense,
      'driverName': driverName,
    };
  }

  factory Transporter.fromJson(Map<String, dynamic> json) {
    return Transporter(
      vehicleNo: json['vehicleNo'],
      transporterName: json['transporterName'],
      driverLicense: json['driverLicense'],
      driverName: json['driverName'],
    );
  }
}

class SurveyDetails {
  final ContainerCategory category;
  final ExaminationType examination;
  final SurveyType surveyType;
  final ContainerStatus containerInStatus;
  final String? grade;
  final String? cscAsp;
  final String? doNo;
  final String? doDate;
  final String? description;

  SurveyDetails({
    required this.category,
    required this.examination,
    required this.surveyType,
    required this.containerInStatus,
    this.grade,
    this.cscAsp,
    this.doNo,
    this.doDate,
    this.description,
  });

  SurveyDetails copyWith({
    ContainerCategory? category,
    ExaminationType? examination,
    SurveyType? surveyType,
    ContainerStatus? containerInStatus,
    String? grade,
    String? cscAsp,
    String? doNo,
    String? doDate,
    String? description,
  }) {
    return SurveyDetails(
      category: category ?? this.category,
      examination: examination ?? this.examination,
      surveyType: surveyType ?? this.surveyType,
      containerInStatus: containerInStatus ?? this.containerInStatus,
      grade: grade ?? this.grade,
      cscAsp: cscAsp ?? this.cscAsp,
      doNo: doNo ?? this.doNo,
      doDate: doDate ?? this.doDate,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': category.name,
      'examination': examination.name,
      'surveyType': surveyType.name,
      'containerInStatus': containerInStatus.name,
      'grade': grade,
      'cscAsp': cscAsp,
      'doNo': doNo,
      'doDate': doDate,
      'description': description,
    };
  }

  factory SurveyDetails.fromJson(Map<String, dynamic> json) {
    return SurveyDetails(
      category: ContainerCategory.values.firstWhere(
            (e) => e.name == json['category'],
        orElse: () => ContainerCategory.dry,
      ),
      examination: ExaminationType.values.firstWhere(
            (e) => e.name == json['examination'],
        orElse: () => ExaminationType.onWheel,
      ),
      surveyType: SurveyType.values.firstWhere(
            (e) => e.name == json['surveyType'],
        orElse: () => SurveyType.iicl,
      ),
      containerInStatus: ContainerStatus.values.firstWhere(
            (e) => e.name == json['containerInStatus'],
        orElse: () => ContainerStatus.clean,
      ),
      grade: json['grade'],
      cscAsp: json['cscAsp'],
      doNo: json['doNo'],
      doDate: json['doDate'],
      description: json['description'],
    );
  }
}

class SurveyPhoto {
  final String id;
  final String url;
  final DateTime timestamp;
  final PhotoType type;
  final String? description;

  SurveyPhoto({
    required this.id,
    required this.url,
    required this.timestamp,
    required this.type,
    this.description,
  });

  SurveyPhoto copyWith({
    String? id,
    String? url,
    DateTime? timestamp,
    PhotoType? type,
    String? description,
  }) {
    return SurveyPhoto(
      id: id ?? this.id,
      url: url ?? this.url,
      timestamp: timestamp ?? this.timestamp,
      type: type ?? this.type,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'timestamp': timestamp.toIso8601String(),
      'type': type.value,
      'description': description,
    };
  }

  factory SurveyPhoto.fromJson(Map<String, dynamic> json) {
    return SurveyPhoto(
      id: json['id'],
      url: json['url'],
      timestamp: DateTime.parse(json['timestamp']),
      type: PhotoType.values.firstWhere(
            (e) => e.value == json['type'],
        orElse: () => PhotoType.preGate,
      ),
      description: json['description'],
    );
  }
}

class Survey {
  final String id;
  final String containerId;
  final Container container;
  final Transporter transporter;
  final SurveyDetails details;
  final List<SurveyPhoto> photos;
  final DateTime createdAt;
  final DateTime updatedAt;

  Survey({
    required this.id,
    required this.containerId,
    required this.container,
    required this.transporter,
    required this.details,
    required this.photos,
    required this.createdAt,
    required this.updatedAt,
  });

  Survey copyWith({
    String? id,
    String? containerId,
    Container? container,
    Transporter? transporter,
    SurveyDetails? details,
    List<SurveyPhoto>? photos,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Survey(
      id: id ?? this.id,
      containerId: containerId ?? this.containerId,
      container: container ?? this.container,
      transporter: transporter ?? this.transporter,
      details: details ?? this.details,
      photos: photos ?? this.photos,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'containerId': containerId,
      'container': container.toJson(),
      'transporter': transporter.toJson(),
      'details': details.toJson(),
      'photos': photos.map((photo) => photo.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Survey.fromJson(Map<String, dynamic> json) {
    return Survey(
      id: json['id'],
      containerId: json['containerId'],
      container: Container.fromJson(json['container']),
      transporter: Transporter.fromJson(json['transporter']),
      details: SurveyDetails.fromJson(json['details']),
      photos: (json['photos'] as List)
          .map((photo) => SurveyPhoto.fromJson(photo))
          .toList(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

// Utility class for shipping line suggestions
class ShippingLineData {
  static const List<String> suggestions = [
    'Maersk Line',
    'MSC',
    'CMA CGM',
    'COSCO',
    'Evergreen',
    'Hapag-Lloyd',
    'ONE',
    'Yang Ming',
    'HMM',
    'PIL Pacific International Lines',
    'OOCL',
    'Wan Hai Lines',
    'TS Lines',
    'Zim',
    'APL',
  ];

  static List<String> getFilteredSuggestions(String query) {
    if (query.isEmpty) return suggestions;

    return suggestions
        .where((line) => line.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}