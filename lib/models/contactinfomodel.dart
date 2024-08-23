class ContactinfoModel {
  ContactinfoModel({
    required this.refNo,
    required this.meterNo,
    required this.cmId,
    required this.status,
    required this.curReading,
    required this.preReading,
    required this.monthYear,
    this.offPeak,
    this.peakImage,
    this.offPeakImage,
  });

  int refNo;
  int meterNo;
  int cmId;
  String status;
  int curReading;
  int preReading;
  String monthYear;
  String? offPeak;
  String? peakImage;
  String? offPeakImage;

  factory ContactinfoModel.fromJson(Map<String, dynamic> json) =>
      ContactinfoModel(
        refNo: json["refNo"],
        meterNo: json["meterNo"],
        cmId: json["cmId"],
        status: json['status'],
        curReading: json["curReading"],
        preReading: json["preReading"],
        offPeak: json["offPeak"],
        peakImage: json["peakImage"],
        offPeakImage: json["offPeakImage"],
        monthYear: json["monthYear"],
      );

  Map<String, dynamic> toJson() => {
        "refNo": refNo,
        "meterNo": meterNo,
        "cmId": cmId,
        "status": status,
        "curReading": curReading,
        "preReading": preReading,
        "offPeak": offPeak,
        "peakImage": peakImage,
        "offPeakImage": offPeakImage,
        "monthYear": monthYear,
      };
}

class LocalMeterModel {
  LocalMeterModel(
      {required this.refNo,
      required this.preReading,
      required this.cmId,
      required this.meterNo});

  int refNo;
  int preReading;
  int cmId;
  int meterNo;

  factory LocalMeterModel.localFromJson(Map<String, dynamic> json) =>
      LocalMeterModel(
          refNo: json['refNo'],
          preReading: json['preReading'],
          cmId: json['cmId'],
          meterNo: json['meterNo']);

  Map<String, dynamic> localToJson() => {
        "refNo": refNo,
        "preReading": preReading,
        "cmId": cmId,
        "meterNo": meterNo,
      };
}

class UserGroups {
  UserGroups({
    required this.refStart,
    required this.refEnd,
  });

  int refStart;
  int refEnd;

  factory UserGroups.userGroupsFromJson(Map<String, dynamic> json) =>
      UserGroups(
        refStart: json['refStart'],
        refEnd: json['refEnd'],
      );

  Map<String, dynamic> userGroupsToJson() => {
        "refStart": refStart,
        "refEnd": refEnd,
      };
}
