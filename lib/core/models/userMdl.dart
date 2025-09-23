class UserModel {
  final int userId;
  final String userName;
  final int buid;
  final String? companyName;
  final String? locationName;
  final String? message;
  final int status;

  UserModel({
    required this.userId,
    required this.userName,
    required this.buid,
    this.companyName,
    this.locationName,
    this.message,
    required this.status,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json["UserID"] as int,
      userName: json["UserName"] as String,
      buid: json["BUID"] as int,
      companyName: json["CompanyName"] as String?,
      locationName: json["LocationName"] as String?,
      message: json["Message"] as String?,
      status: json["Status"] as int,
    );
  }

  Map<String, dynamic> toJson() => {
    "UserID": userId,
    "UserName": userName,
    "BUID": buid,
    if (companyName != null) "CompanyName": companyName,
    if (locationName != null) "LocationName": locationName,
    if (message != null) "Message": message,
    "Status": status,
  };
}
