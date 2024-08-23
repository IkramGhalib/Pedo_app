import 'dart:io';

import 'package:meter_reading/models/contactinfomodel.dart';
import 'databasehelper.dart';

class Controller {
  final conn = SqfliteDatabaseHelper.instance;

  Future<int> addData(ContactinfoModel contactinfoModel) async {
    var dbclient = await conn.db;
    int result = 0;
    try {
      result = await dbclient.insert(
          SqfliteDatabaseHelper.data_reading1, contactinfoModel.toJson());
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  //delete all
  Future<int> deleteData() async {
    var dbclient = await conn.db;
    int result = 0;
    try {
      result = await dbclient.delete(SqfliteDatabaseHelper.data_reading1);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<void> deleteSingleImage(String path) async {
    try {
      File file = File(path);
      if (await file.exists()) {
        await file.delete();
      } else {
        print('Image not found at the specified path');
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  Future<int> deleteSingleRecord(int refNo) async {
    var dbclient = await conn.db;
    int result = 0;
    try {
      result = await dbclient.delete(SqfliteDatabaseHelper.data_reading1,
          where: 'refNo=?', whereArgs: [refNo]);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<int> updateData(ContactinfoModel contactinfoModel) async {
    var dbclient = await conn.db;
    int result = 0;
    try {
      result = await dbclient.update(
          SqfliteDatabaseHelper.data_reading1, contactinfoModel.toJson(),
          where: 'refNo=?', whereArgs: [contactinfoModel.refNo]);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<int> updateOnlyRequiredField(
    int refNo,
    int curReadingValue,
  ) async {
    String DATA_READING1_TABLE = SqfliteDatabaseHelper.data_reading1;
    var dbClient = await conn.db;
    var result = await dbClient.rawUpdate(
        'UPDATE $DATA_READING1_TABLE SET curReading = \'$curReadingValue\' WHERE refNo = $refNo');

    return result;
  }

  Future<int> updateImageField(
    int refNo,
    String path,
  ) async {
    String DATA_READING1_TABLE = SqfliteDatabaseHelper.data_reading1;
    var dbClient = await conn.db;
    var result = await dbClient.rawUpdate(
        'UPDATE $DATA_READING1_TABLE SET offPeakImage = \'$path\' WHERE refNo = $refNo');

    return result;
  }

  Future<List<ContactinfoModel>> fetchData() async {
    var dbclient = await conn.db;
    List<ContactinfoModel> meterList = [];
    try {
      List<Map<String, dynamic>> maps = await dbclient
          .query(SqfliteDatabaseHelper.data_reading1, orderBy: 'refNo DESC');
      for (var item in maps) {
        meterList.add(ContactinfoModel(
            refNo: item['refNo'] as int,
            meterNo: item['meterNo'] as int,
            cmId: item['cmId'],
            status: item['status'],
            curReading: item['curReading'] as int,
            preReading: item['preReading'] as int,
            peakImage: item['peakImage'],
            offPeakImage: item['offPeakImage'],
            monthYear: item['monthYear']));
      }
    } catch (e) {
      print(e.toString());
    }
    return meterList;
  }

  Future<int> addDataLocalMeters(List<LocalMeterModel> localMeterModel) async {
    var dbclient = await conn.db;
    int result = 0;
    try {
      for (var meterNo in localMeterModel) {
        result = await dbclient.insert(
          SqfliteDatabaseHelper.local_meters,
          meterNo.localToJson(),
        );
        print(result);
      }
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<List<LocalMeterModel>> fetchDataFromSqlLite() async {
    var dbclient = await conn.db;
    List<LocalMeterModel> meterList = [];
    try {
      List<Map<String, dynamic>> maps = await dbclient
          .query(SqfliteDatabaseHelper.local_meters, orderBy: 'refNo DESC');
      for (var item in maps) {
        meterList.add(
          LocalMeterModel(
            refNo: item['refNo'],
            preReading: item['preReading'],
            cmId: item['cmId'],
            meterNo: item['meterNo'],
          ),
        );
      }
    } catch (e) {
      print(e.toString());
    }

    return meterList;
  }

  Future<List<LocalMeterModel>> fetchFilteredMetersFromSqlLite(
      int refStart, int refEnd) async {
    var dbclient = await conn.db;
    List<LocalMeterModel> meterList = [];
    try {
      List<Map<String, dynamic>> maps =
          await dbclient.query(SqfliteDatabaseHelper.local_meters,
              orderBy: 'refNo ASC', // DESC
              where: 'refNo >= ? AND refNo <= ?',
              whereArgs: [refStart, refEnd]);
      for (var item in maps) {
        meterList.add(
          LocalMeterModel(
            refNo: item['refNo'],
            preReading: item['preReading'],
            cmId: item['cmId'],
            meterNo: item['meterNo'],
          ),
        );
      }
    } catch (e) {
      print(e.toString());
    }

    return meterList;
  }

  Future<int> deleteSingleLocalRecord(int refNo) async {
    var dbclient = await conn.db;
    int result = 0;
    try {
      result = await dbclient.delete(SqfliteDatabaseHelper.local_meters,
          where: 'refNo=?', whereArgs: [refNo]);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<int> deleteAllLocal() async {
    var dbclient = await conn.db;
    int result = 0;
    try {
      result = await dbclient.delete(SqfliteDatabaseHelper.local_meters);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  // User groups store in device storage
  Future<int> addUserGroupsToLocalDB(List<UserGroups> userGroups) async {
    var dbclient = await conn.db;
    int result = 0;
    try {
      for (var group in userGroups) {
        result = await dbclient.insert(
          SqfliteDatabaseHelper.user_groups,
          group.userGroupsToJson(),
        );
        print(result);
      }
    } catch (e) {
      print(e.toString());
    }
    return result;
  }

  Future<List<UserGroups>> fetchUserGroupsFromSqlLite() async {
    var dbclient = await conn.db;
    List<UserGroups> userGroups = [];
    try {
      List<Map<String, dynamic>> maps = await dbclient.query(
        SqfliteDatabaseHelper.user_groups,
        orderBy: 'refStart ASC',
      );
      for (var group in maps) {
        userGroups.add(
            UserGroups(refStart: group['refStart'], refEnd: group['refEnd']));
      }
    } catch (e) {
      print(e.toString());
    }

    return userGroups;
  }

  Future<int> deleteAllLocalUserGroups() async {
    var dbclient = await conn.db;
    int result = 0;
    try {
      result = await dbclient.delete(SqfliteDatabaseHelper.user_groups);
    } catch (e) {
      print(e.toString());
    }
    return result;
  }
}
