// lib/models/container_model.dart
class ContainerModel {
  final String id;
  final String containerNo;
  final String mfgMonth;
  final String mfgYear;
  final double grossWeight;
  final double tareWeight;
  final double payload;
  final String shippingLine;
  final String isoCode;
  final String sizeType;
  final String status;

  ContainerModel({
    required this.id,
    required this.containerNo,
    required this.mfgMonth,
    required this.mfgYear,
    required this.grossWeight,
    required this.tareWeight,
    required this.payload,
    required this.shippingLine,
    required this.isoCode,
    required this.sizeType,
    required this.status,
  });
}
