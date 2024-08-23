import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meter_reading/Data/constants.dart';
import 'package:meter_reading/Database/controller.dart';
import 'package:meter_reading/Services/syncronize.dart';
import 'package:meter_reading/models/contactinfomodel.dart';
import 'package:meter_reading/screens/Login/login.dart';
import 'package:meter_reading/screens/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final Connectivity _connectivity = Connectivity();

  bool isNot1PhaseImageSelected = false;
  bool isNot3PhaseImageSelected = false;
  bool isNoRefNoSelected = false;
  bool isNoMeterStatusSelect = false;
  bool isNoPeakUnit = false;
  bool isNoOffPeakUnit = false;
  bool loadingData = false;
  bool isLoading = false;
  bool is3Phase = false;
  bool isMobileConnectedToNet = false;
  bool startValidating = false;

  List<String> statusList = [];
  String currentStatus = 'Functional';
  int currentRefNo = -1;
  int meterNo = 0;
  int cmId = 0;
  List<LocalMeterModel> refsNo = [
    LocalMeterModel(refNo: -1, preReading: -1, cmId: -1, meterNo: -1)
  ];
  SharedPreferences? prefs;
  String userName = '';
  String monthYear = 'not-set';
  String formattedDate = 'not-set';
  String token = '';
  int preReading = -1;
  int difference = 0;

  int refStartInt = 0;
  int refEndInt = 0;

  late File imgFile1;
  bool pikedimgFile1 = false;
  String imageFilePath1 = '';

  final TextEditingController peakUnit = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  Future<void> _checkConnectivity() async {
    try {
      var status = await _connectivity.checkConnectivity();
      if (status == ConnectivityResult.mobile ||
          status == ConnectivityResult.wifi ||
          status == ConnectivityResult.ethernet) {
        isMobileConnectedToNet = true;
      }
      setState(() {});
    } catch (e) {
      print(e);
      setState(() {});
      //network is already unregistered
    }
    return;
  }

  void _subscribeToConnectivityChanges() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (result == ConnectivityResult.mobile ||
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.ethernet) {
        isMobileConnectedToNet = true;
      } else {
        isMobileConnectedToNet = false;
      }

      setState(() {});
    });
    return;
  }

  Future<String> _saveImage(File imgFile, int name) async {
    final imgName = '$name.jpg';
    Directory appDir = await getApplicationDocumentsDirectory();
    final savePath = '${appDir.path}/$imgName';
    await imgFile.copy(savePath);
    return savePath;
  }

  void resetApp() {
    setState(() {
      peakUnit.clear();
      currentRefNo = -1;
      currentStatus = 'Functional';
      preReading = -1;
      difference = 0;
      isNot1PhaseImageSelected = false;
      isNoRefNoSelected = false;
      isNoPeakUnit = false;
      loadingData = false;
      isLoading = false;
      pikedimgFile1 = false;
      isNoMeterStatusSelect = false;
      startValidating = false;
    });
  }

  Future<void> pickSinglePhaseImage() async {
    final imagePicker = ImagePicker();
    final pickedImage = await imagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 96);
    if (pickedImage != null) {
      setState(() {
        imgFile1 = File(pickedImage.path);
        pikedimgFile1 = true;
      });
    }
  }

  Future<void> fetchMeterNumbersFromApi() async {
    try {
      final response = await http.get(
          Uri.parse('https://pedo.cispvt.com/api/v1/get_list_for_reading'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          });

      if (response.statusCode == 200) {
        var refNoList = json.decode(response.body)['data'];
        List<LocalMeterModel> tempList = [];
        for (final group in refNoList) {
          final groupList = group['list'];
          for (var list in groupList) {
            tempList.add(
              LocalMeterModel(
                refNo: list['ref_no'],
                preReading: list['pre_reading'],
                cmId: list['cm_id'],
                meterNo: list['meter_no'],
              ),
            );
          }
        }

        await Controller().addDataLocalMeters(tempList);
        List<LocalMeterModel> localMeterNo = await Controller()
            .fetchFilteredMetersFromSqlLite(refStartInt, refEndInt);

        setState(() {
          refsNo.addAll(localMeterNo);
        });

        return;
      } else {
        print(response.statusCode);
        return;
      }
    } catch (e) {
      print(e);
      return;
    }
  }

  Future syncToMysql() async {
    print('syncToMysql is executed');
    EasyLoading.show(
        status: 'انتظار کریں! ڈیٹا اپ لوڈ ہو رہا ہے موبائل بند نہ کریں۔');
    await SyncronizationData().fetchAllInfo().then((userList) async {
      if (userList.isEmpty) {
        EasyLoading.showError('موجودہ ریکارڈ لسٹ خالی ہے');
        return;
      }
      int statusCode =
          await SyncronizationData().saveToMysqlWith(userList, token);

      if (statusCode == 200) {
        EasyLoading.showSuccess('ڈیٹا کامیابی کے ساتھ اپ لوڈ ہوگیا');
        return;
      } else if (statusCode == 422) {
        EasyLoading.showError('ریکارڈ پہلے سے موجود ہے');
        return;
      } else if (statusCode == 400) {
        EasyLoading.showError('Something went wrong!');
        // EasyLoading.showError('براہ کرم اپنا انٹرنیٹ کنیکشن چیک کریں');
        return;
      } else if (statusCode == 0) {
        EasyLoading.showError('Something went wrong!');
        return;
      }
      EasyLoading.showError('Something went wrong!');
      return;
    });
  }

  Future _logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all shared preferences data
    await Controller().deleteAllLocalUserGroups();

    // Navigate to login page or any other page
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const Login()),
    );
  }

  void getSharedPrefs() async {
    prefs = await SharedPreferences.getInstance();
    token = await initial();
    getMetersLocally();
    return;
  }

  bool validateInputs() {
    if (currentRefNo == -1 || peakUnit.text.isEmpty || difference < 0) {
      if (currentRefNo == -1) {
        isNoRefNoSelected = true;
      } else {
        isNoRefNoSelected = false;
      }
      setState(() {});
      return false;
    }
    return true;
  }

  void _saveDatatoLocalDB() async {
    // Focus.of(context).unfocus();

    setState(() {
      startValidating = true;
      validateCurrentReading(peakUnit.text);
    });
    var isValidated = validateInputs();
    if (!isValidated) {
      return;
    }

    // Saving 1phase image to devcice storage locally
    if (pikedimgFile1) {
      String path = await _saveImage(imgFile1, currentRefNo);
      imageFilePath1 = path;
    }

    ContactinfoModel contactinfoModel = ContactinfoModel(
      refNo: currentRefNo,
      meterNo: meterNo,
      cmId: cmId,
      status: currentStatus,
      curReading: int.parse(peakUnit.text),
      preReading: preReading,
      offPeakImage: imageFilePath1,
      monthYear: monthYear,
    );
    int result = await Controller().addData(contactinfoModel);
    if (result > 0) {
      var res = await Controller().deleteSingleLocalRecord(currentRefNo);
      if (res > 0) {
        refsNo.removeWhere((refNo) => refNo.refNo == currentRefNo);
      }

      Fluttertoast.showToast(
        msg: 'Data Saved Successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color.fromARGB(255, 88, 181, 123),
      );

      resetApp();
      return;
    } else {
      Fluttertoast.showToast(
        msg: 'Data Saving Failed',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: const Color.fromARGB(255, 232, 87, 87),
      );
      return;
    }
  }

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _subscribeToConnectivityChanges();

    getSharedPrefs();
  }

  Future<String> initial() async {
    token = prefs!.getString('token') ?? '';
    monthYear = prefs!.getString('month') ?? 'not-set';
    monthYear = prefs!.getString('month') ?? 'not-set';
    setState(() {
      statusList = prefs!.getStringList('meterStatus') ?? [];
    });
    int start = prefs!.getInt('refStart') ?? 0;
    int end = prefs!.getInt('refEnd') ?? 0;

    refStartInt = start;
    refEndInt = end;

    String monthNumber = monthYear.substring(5);

    // Get the corresponding month name from the map
    String monthText = monthMappings[monthNumber] ?? 'Not-set';

    formattedDate = monthYear.replaceRange(5, null, monthText);

    setState(() {
      monthYear = prefs!.getString('month') ?? 'not-set';
    });
    return token;
  }

  void updateMetersLocally() async {
    int start = prefs!.getInt('refStart') ?? 0;
    int end = prefs!.getInt('refEnd') ?? 0;

    refStartInt = start;
    refEndInt = end;
    List<LocalMeterModel> localMeterNo =
        await Controller().fetchFilteredMetersFromSqlLite(start, end);

    refsNo = [
      LocalMeterModel(refNo: -1, preReading: -1, cmId: -1, meterNo: -1)
    ];
    refsNo.addAll(localMeterNo);

    setState(() {});
  }

  void getMetersLocally() async {
    List<LocalMeterModel> localMeterNo = await Controller()
        .fetchFilteredMetersFromSqlLite(refStartInt, refEndInt);

    if (localMeterNo.isEmpty) {
      token = await initial();
      if (token.isNotEmpty) {
        fetchMeterNumbersFromApi();
      }
      return;
    } else {
      setState(() {
        refsNo.addAll(localMeterNo);
      });
    }
  }

  List<DropdownMenuItem<String>> createDropdownItems(
      List<LocalMeterModel> dataList) {
    List<DropdownMenuItem<String>> dropdownItems = [];
    for (var meterItem in dataList) {
      var m = DropdownMenuItem<String>(
        value: meterItem.refNo.toString(),
        child: Text(
            '${meterItem.refNo == -1 ? 'Select ref no' : '${meterItem.refNo}'}  - ${meterItem.meterNo == -1 ? 'meter no' : '${meterItem.meterNo}'}'),
      );
      dropdownItems.add(m);
    }
    return dropdownItems;
  }

  String? validateCurrentReading(String reading) {
    if (reading.isEmpty) {
      return "Current reading is required";
    }
    if (difference < 0) {
      return "Readings cannot be less than previous reading"; // Please eneter correct readings
    }

    return null;
  }

  @override
  void dispose() {
    super.dispose();
    peakUnit.dispose();
    searchController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;

    double diagonal = sqrt(pow(width, 2) + pow(height, 2));
    return Scaffold(
      appBar: AppBar(
        title: const Text("Metrocure", textAlign: TextAlign.center),
        actions: [
          IconButton(
            onPressed: !isMobileConnectedToNet
                ? null
                : () {
                    _logout();
                  },
            icon: const Icon(Icons.logout),
          ),
        ],
        elevation: 0,
        toolbarHeight: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_sharp,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      formattedDate,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
                Text(
                  'Group: $refStartInt - $refEndInt',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: AppDrawer(
        onLogout: _logout,
        onInitial: initial,
        onUploadData: syncToMysql,
        onUpdateRange: updateMetersLocally,
      ),
      body: Container(
        margin: const EdgeInsets.all(12.0),
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  items: createDropdownItems(refsNo),
                  value: currentRefNo.toString(),
                  onChanged: (value) {
                    var res = refsNo.firstWhere(
                        (meter) => meter.refNo == int.parse(value!));
                    setState(() {
                      currentRefNo = int.parse(value!);

                      preReading = res.preReading;
                      meterNo = res.meterNo;
                      cmId = res.cmId;
                      difference = 0;
                      if (value != 'Select ref no') isNoRefNoSelected = false;
                    });
                  },
                  buttonStyleData: ButtonStyleData(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFF243A92),
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                  dropdownSearchData: DropdownSearchData(
                    searchController: searchController,
                    searchInnerWidgetHeight: 50,
                    searchInnerWidget: Container(
                      height: 50,
                      padding: const EdgeInsets.only(
                        top: 8,
                        bottom: 4,
                        right: 8,
                        left: 8,
                      ),
                      child: TextFormField(
                        expands: true,
                        maxLines: null,
                        controller: searchController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                          hintText: 'Search meter no',
                          hintStyle: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                    searchMatchFn: (item, searchValue) {
                      return item.value.toString().contains(searchValue);
                    },
                  ),
                  onMenuStateChange: (isOpen) {
                    if (!isOpen) {
                      searchController.clear();
                    }
                  },
                ),
              ),
              if (isNoRefNoSelected)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: Text(
                    'Meter number is required',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(color: Colors.red[700]),
                  ),
                ),
              if (preReading != -1)
                Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.all(8),
                  // width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFF243A92),
                      ),
                      borderRadius: BorderRadius.circular(5)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Text('Previous: $preReading'),
                      Text(
                        'Units: $difference',
                        style: TextStyle(
                          color: difference > 300 ? Colors.red : Colors.black,
                        ),
                      )
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                maxLength: 8,
                onTap: () {
                  startValidating = true;
                },
                controller: peakUnit,
                onChanged: (newValue) {
                  setState(
                    () {
                      if (newValue.isEmpty) {
                        difference = preReading;
                        return;
                      }
                      difference = int.parse(newValue) - preReading;
                    },
                  );
                },
                decoration: InputDecoration(
                    errorText: startValidating
                        ? validateCurrentReading(peakUnit.text)
                        : null,
                    border: const OutlineInputBorder(),
                    label: const Text('Current Reading'),
                    hintText: 'Enter current reading'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              DropdownButtonHideUnderline(
                child: DropdownButton2<String>(
                  isExpanded: true,
                  items: statusList
                      .map((status) => DropdownMenuItem<String>(
                          value: status, child: Text(status)))
                      .toList(),
                  value: currentStatus,
                  onChanged: (newStatus) {
                    setState(() {
                      currentStatus = newStatus!;
                    });
                    print(currentStatus);
                  },
                  buttonStyleData: ButtonStyleData(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: const Color(0xFF243A92),
                      ),
                      borderRadius: BorderRadius.circular(5),
                    ),
                  ),
                ),
              ),
              isNoMeterStatusSelect
                  ? Align(
                      heightFactor: 1.5,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Meter status is required',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  : Container(),
              const SizedBox(height: 16),
              InkWell(
                onTap: pickSinglePhaseImage,
                child: Container(
                  color: const Color.fromARGB(255, 216, 217, 247),
                  width: double.infinity,
                  height: MediaQuery.of(context).size.width * 0.4,
                  child: DottedBorder(
                    color: const Color(0xFF243A92),
                    child: Center(
                      child: pikedimgFile1
                          ? Image.file(imgFile1)
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_outlined,
                                  color: Color(0xFF243A92),
                                ),
                                SizedBox(height: 12),
                                Text(
                                  'Add an image',
                                  style: TextStyle(
                                    color: Color(0xFF243A92),
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: diagonal * 0.18,
                    height: diagonal * 0.05,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.save_alt_rounded),
                      onPressed: _saveDatatoLocalDB,
                      label: const Text('Save Record'),
                    ),
                  ),
                  SizedBox(
                    width: diagonal * 0.18,
                    height: diagonal * 0.05,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.delete),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red),
                      onPressed: resetApp,
                      label: const Text('Clear Data'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
