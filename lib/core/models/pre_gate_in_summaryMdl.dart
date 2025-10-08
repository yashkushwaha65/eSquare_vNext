// lib/core/models/pre_gate_in_summaryMdl.dart

import 'package:esquare/core/models/survey_attachment_mdl.dart';

class PreGateInSummary {
  final int srNo;
  final int surveyID;
  final String containerNo;
  final String containerType;
  final String vehicleNo;
  final double grossWt;
  final double tareWt;
  final double payLoad;
  final int size;
  final String lineName;
  final String surveyDate;
  final String isoCode;
  final String category;
  final String surveyType;
  final String containerStatus;
  final String condition;
  final int mfgYear;
  final String mfgMonth;
  final String surveyNo;
  final String addedBy;
  final List<SurveyAttachment> attachments;
  final String location;
  final String examinType;
  final String cscAsp;
  final String grade;
  final String doNo;
  final String doValidityDate;
  final String transporter;
  final String driverName;
  final String driverLicenceNo;
  final String remarks;

  PreGateInSummary({
    required this.srNo,
    required this.surveyID,
    required this.containerNo,
    required this.containerType,
    required this.vehicleNo,
    required this.grossWt,
    required this.tareWt,
    required this.payLoad,
    required this.size,
    required this.lineName,
    required this.surveyDate,
    required this.isoCode,
    required this.category,
    required this.surveyType,
    required this.containerStatus,
    required this.condition,
    required this.mfgYear,
    required this.mfgMonth,
    required this.surveyNo,
    required this.addedBy,
    this.attachments = const [],
    required this.location,
    required this.examinType,
    required this.cscAsp,
    required this.grade,
    required this.doNo,
    required this.doValidityDate,
    required this.transporter,
    required this.driverName,
    required this.driverLicenceNo,
    required this.remarks,
  });

  factory PreGateInSummary.fromJson(Map<String, dynamic> json) {
    return PreGateInSummary(
      srNo: json['SRNo'] ?? 0,
      surveyID: json['SurveyID'] ?? 0,
      containerNo: json['ContainerNo'] ?? '',
      containerType: json['ContainerType'] ?? '',
      vehicleNo: json['VehicleNo'] ?? '',
      grossWt: (json['GrossWt'] as num?)?.toDouble() ?? 0.0,
      tareWt: (json['TareWt'] as num?)?.toDouble() ?? 0.0,
      payLoad: (json['PayLoad'] as num?)?.toDouble() ?? 0.0,
      size: json['Size'] ?? 0,
      lineName: json['LineName'] ?? '',
      surveyDate: json['SurveyDate'] ?? '',
      isoCode: json['ISOCode'] ?? '',
      category: json['Category'] ?? '',
      surveyType: json['SurveyType'] ?? '',
      containerStatus: json['ContainerStatus'] ?? '',
      condition: json['Condition'] ?? '',
      mfgYear: json['MFGYear'] ?? 0,
      mfgMonth: json['MFGMonth'] ?? '',
      surveyNo: json['SurveyNo'] ?? '',
      addedBy: json['AddedBy'] ?? '',
      attachments: [],
      // Correctly initialized
      location: json['Location'] ?? '',
      examinType: json['ExaminType'] ?? '',
      cscAsp: json['CSCASP'] ?? '',
      grade: json['Grade'] ?? '',
      doNo: json['DONo'] ?? '',
      doValidityDate: json['DOValidityDate'] ?? '',
      transporter: json['Transporter'] ?? '',
      driverName: json['DriverName'] ?? '',
      driverLicenceNo: json['DriverLicenceNo'] ?? '',
      remarks: json['Remarks'] ?? '',
    );
  }

  PreGateInSummary copyWith({
    int? srNo,
    int? surveyID,
    String? containerNo,
    String? containerType,
    String? vehicleNo,
    double? grossWt,
    double? tareWt,
    double? payLoad,
    int? size,
    String? lineName,
    String? surveyDate,
    String? isoCode,
    String? category,
    String? surveyType,
    String? containerStatus,
    String? condition,
    int? mfgYear,
    String? mfgMonth,
    String? surveyNo,
    String? addedBy,
    List<SurveyAttachment>? attachments,
    String? location,
    String? examinType,
    String? cscAsp,
    String? grade,
    String? doNo,
    String? doValidityDate,
    String? transporter,
    String? driverName,
    String? driverLicenceNo,
    String? remarks,
  }) {
    return PreGateInSummary(
      srNo: srNo ?? this.srNo,
      surveyID: surveyID ?? this.surveyID,
      containerNo: containerNo ?? this.containerNo,
      containerType: containerType ?? this.containerType,
      vehicleNo: vehicleNo ?? this.vehicleNo,
      grossWt: grossWt ?? this.grossWt,
      tareWt: tareWt ?? this.tareWt,
      payLoad: payLoad ?? this.payLoad,
      size: size ?? this.size,
      lineName: lineName ?? this.lineName,
      surveyDate: surveyDate ?? this.surveyDate,
      isoCode: isoCode ?? this.isoCode,
      category: category ?? this.category,
      surveyType: surveyType ?? this.surveyType,
      containerStatus: containerStatus ?? this.containerStatus,
      condition: condition ?? this.condition,
      mfgYear: mfgYear ?? this.mfgYear,
      mfgMonth: mfgMonth ?? this.mfgMonth,
      surveyNo: surveyNo ?? this.surveyNo,
      addedBy: addedBy ?? this.addedBy,
      attachments: attachments ?? this.attachments,
      location: location ?? this.location,
      examinType: examinType ?? this.examinType,
      cscAsp: cscAsp ?? this.cscAsp,
      grade: grade ?? this.grade,
      doNo: doNo ?? this.doNo,
      doValidityDate: doValidityDate ?? this.doValidityDate,
      transporter: transporter ?? this.transporter,
      driverName: driverName ?? this.driverName,
      driverLicenceNo: driverLicenceNo ?? this.driverLicenceNo,
      remarks: remarks ?? this.remarks,
    );
  }
}
