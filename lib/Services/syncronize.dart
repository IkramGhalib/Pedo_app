import 'package:http/http.dart' as http;

import 'package:meter_reading/Database/controller.dart';
import 'package:meter_reading/Database/databasehelper.dart';
import 'package:meter_reading/models/contactinfomodel.dart';

class SyncronizationData {
  final conn = SqfliteDatabaseHelper.instance;

  Future<List<ContactinfoModel>> fetchAllInfo() async {
    final dbClient = await conn.db;
    List<ContactinfoModel> contactList = [];
    try {
      final maps = await dbClient.query(SqfliteDatabaseHelper.data_reading1);
      for (var item in maps) {
        contactList.add(ContactinfoModel.fromJson(item));
      }
    } catch (e) {
      print(e.toString());
    }
    return contactList;
  }

  Future<int> saveToMysqlWith(
      List<ContactinfoModel> contactList, String authToken) async {
    int returnStatus = 0;
    try {
      final url = Uri.parse("https://pedo.cispvt.com/api/v1/reading_save");

      for (var i = 0; i < contactList.length; i++) {
        final request = http.MultipartRequest('POST', url);
        request.headers['Authorization'] = "Bearer $authToken";

        request.headers['Accept'] = "application/json";
        Map<String, dynamic> data = {
          "cm_id": contactList[i].cmId.toString(),
          "offpeak": contactList[i].curReading.toString(),
          "status": contactList[i].status,
          "month_year": contactList[i].monthYear.toString(),
        };

        String offPkImgName = '';
        if (contactList[i].offPeakImage != null &&
            contactList[i].offPeakImage!.isNotEmpty) {
          offPkImgName = contactList[i].offPeakImage!.split('/').last;

          request.files.add(await http.MultipartFile.fromPath(
              'off_peak_image', contactList[i].offPeakImage!,
              filename: offPkImgName));
        }

        request.fields['cm_id'] = data['cm_id'];
        request.fields['offpeak'] = data['offpeak'];
        request.fields['status'] = data['status'];
        request.fields['month_year'] = data['month_year'];

        var response = await request.send();

        returnStatus = response.statusCode;
        if (response.statusCode == 200) {
          if (contactList[i].offPeakImage != null ||
              contactList[i].offPeakImage!.isNotEmpty) {
            Controller().deleteSingleImage(contactList[i].offPeakImage!);
          }
          Controller().deleteSingleRecord(contactList[i].refNo);
        }
      }
    } catch (e) {
      returnStatus = 400;
      print(e);
    }
    return returnStatus;
  }

  Future<List> fetchAllCustoemrInfo() async {
    final dbClient = await conn.db;
    List contactList = [];
    try {
      final maps = await dbClient.query(SqfliteDatabaseHelper.data_reading1);
      for (var item in maps) {
        contactList.add(item);
      }
    } catch (e) {
      print(e.toString());
    }
    return contactList;
  }
}
