class PostRepairSummary {
  final int srNo;
  final String containerNo;
  final String containerType;
  final String inDate;
  final double grossWt;
  final double tareWt;
  final double payLoad;
  final int size;
  final String surveyDate;
  final int surveyID;
  final String lineName;
  final int entryID;
  final String addedBy;
  final double estimateAmount;
  final String repairDate;
  final int isApproved;
  final int estimateId;

  PostRepairSummary({
    required this.srNo,
    required this.containerNo,
    required this.containerType,
    required this.inDate,
    required this.grossWt,
    required this.tareWt,
    required this.payLoad,
    required this.size,
    required this.surveyDate,
    required this.surveyID,
    required this.lineName,
    required this.entryID,
    required this.addedBy,
    required this.estimateAmount,
    required this.repairDate,
    required this.isApproved,
    required this.estimateId,
  });

  factory PostRepairSummary.fromJson(Map<String, dynamic> json) {
    return PostRepairSummary(
      srNo: json['SrNo'] as int,
      containerNo: json['ContainerNo'] as String,
      containerType: json['ContainerType'] as String,
      inDate: json['InDate'] as String,

      // -- FIX: Safely handle potentially null or missing numeric fields --
      grossWt: (json['GrossWt'] as num?)?.toDouble() ?? 0.0,
      tareWt: (json['TareWt'] as num?)?.toDouble() ?? 0.0,
      payLoad: (json['PayLoad'] as num?)?.toDouble() ?? 0.0,

      size: json['Size'] as int,

      // -- FIX: Use the correct JSON key for survey date --
      surveyDate: json['Est_date'] as String? ?? '',

      surveyID: json['SurveyID'] as int? ?? 0,
      lineName: json['SLName'] as String? ?? '',
      entryID: json['EntryID'] as int,
      addedBy: json['AddedBy'] as String? ?? 'Unknown',
      estimateAmount: (json['Estimate_Amount'] as num?)?.toDouble() ?? 0.0,
      repairDate: json['RepairDate'] as String? ?? '',
      isApproved: json['IsApproved'] as int? ?? 0,
      estimateId: json['Estimate_ID'] as int? ?? 0,
    );
  }
}
