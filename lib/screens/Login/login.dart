import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:meter_reading/models/contactinfomodel.dart';
import 'package:meter_reading/Database/controller.dart';
import 'package:meter_reading/screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});
  @override
  State<Login> createState() {
    return _LoginState();
  }
}

class _LoginState extends State<Login> {
  List<bool> listAllFalse = [];
  bool isUserNameSet = true;
  bool isYearMonthSet = true;
  bool isLoading = false;
  final _userCodeController = TextEditingController();
  late SharedPreferences _loginData;
  int refStartInt = 0;
  int refEndInt = 0;

  Future<String> _getMonth(String token) async {
    try {
      final response = await http
          .get(Uri.parse('https://pedo.cispvt.com/api/v1/get_month'), headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      });
      EasyLoading.dismiss();
      if (response.statusCode == 200) {
        var resData = json.decode(response.body);
        final monthData = resData['data'];

        List<String> meterListStatus = List.from(monthData['meter_status']);

        setUserPrefsMeterStatus(meterListStatus);
        monthData['meter_status'];
        if (monthData['month'] == 'not-set') {
          String month = await _presentDatePicker();
          return month;
        }
        return (monthData['month']);
      } else {
        return 'not-set';
      }
    } catch (e) {
      return 'not-set';
    }
  }

  void _login() async {
    try {
      setState(() {
        isLoading = true;
      });
      EasyLoading.show(status: 'Authenticating...');

      final response = await http.post(
          Uri.parse('https://pedo.cispvt.com/api/v1/login'),
          body: {'code': _userCodeController.text});

      if (response.statusCode == 200) {
        var resData = json.decode(response.body);

        final message = resData['data'];
        final month = await _getMonth(message['token']);
        List<UserGroups> userGroup = await _getUserGroup(message['token']);
        UserGroups choosenUserGroup = await _waitForSelectUserGroup(userGroup);
        if (choosenUserGroup.refEnd == 0 && choosenUserGroup.refEnd == 0) {
          setState(() {
            isLoading = false;
          });
          EasyLoading.removeAllCallbacks();
          EasyLoading.showError('Login Failed!');

          return;
        }

        setUserPrefs(message['name'], message['email'], message['token'], month,
            choosenUserGroup);

        setState(() {
          isLoading = false;
        });
        EasyLoading.removeAllCallbacks();
        EasyLoading.showSuccess('Login successful!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const MyHomePage(),
          ),
        );
      } else {
        setState(() {
          isLoading = false;
        });
        EasyLoading.removeAllCallbacks();
        EasyLoading.showError(
            'Please enter a valid authorization code to login');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      EasyLoading.removeAllCallbacks();
      EasyLoading.showError('Login failed, Please try again');
    }

    return;
  }

  Future<List<UserGroups>> _getUserGroup(String token) async {
    try {
      final response = await http.get(
          Uri.parse('https://pedo.cispvt.com/api/v1/get_list_for_reading'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          });

      if (response.statusCode == 200) {
        Map<String, dynamic> parsedData = jsonDecode(response.body);
        List<UserGroups> groupRange = [];
        List<Map<String, dynamic>> dataList = List.from(parsedData['data']);
        for (var dataEntry in dataList) {
          int refStart = dataEntry['ref_start'];
          int refEnd = dataEntry['ref_end'];
          groupRange.add(UserGroups(refStart: refStart, refEnd: refEnd));
        }
        await Controller().deleteAllLocalUserGroups();
        await Controller().addUserGroupsToLocalDB(groupRange);

        return groupRange;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  void setUserPrefs(
    String name,
    String email,
    String token,
    String month,
    UserGroups userGroup,
  ) {
    _loginData.setBool('newUser', false);
    _loginData.setString('user_name', name);
    _loginData.setString('email', email);
    _loginData.setString('token', token);
    _loginData.setString('month', month);
    _loginData.setInt('refStart', userGroup.refStart);
    _loginData.setInt('refEnd', userGroup.refEnd);
  }

  void setUserPrefsMeterStatus(
    List<String> meterStatus,
  ) {
    _loginData.setStringList('meterStatus', meterStatus);
  }

  Future<UserGroups> _waitForSelectUserGroup(List<UserGroups> groups) async {
    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: const Center(child: Text("Choose Your Group")),
                content: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.builder(
                    itemCount: groups.length,
                    itemBuilder: (ctx, index) {
                      listAllFalse.add(false);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 5.0),
                        child: ListTile(
                          tileColor: const Color.fromARGB(255, 216, 217, 247),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5)),
                          onTap: () {
                            setState(() {
                              if (index == 0) {
                                listAllFalse.fillRange(
                                    1, listAllFalse.length, false);
                                listAllFalse[index] = true;
                              } else if (index == listAllFalse.length) {
                                listAllFalse.fillRange(
                                    0, listAllFalse.length - 1, false);
                                listAllFalse[index] = true;
                              } else {
                                listAllFalse.fillRange(0, index, false);
                                listAllFalse.fillRange(
                                    index + 1, listAllFalse.length, false);
                                listAllFalse[index] = true;
                              }
                            });

                            refStartInt = groups[index].refStart;

                            refEndInt = groups[index].refEnd;
                          },
                          selectedColor: Colors.green,
                          title: Text(
                              'Group ${index + 1}: ${groups[index].refStart} - ${groups[index].refEnd}'),
                          trailing: Icon(
                            listAllFalse[index]
                                ? Icons.check_box
                                : Icons.check_box_outline_blank_rounded,
                            color: const Color(0xFF243A92),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                actions: <Widget>[
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (refStartInt == 0 || refEndInt == 0) {
                          Fluttertoast.cancel();
                          Fluttertoast.showToast(
                            msg: 'Please choose a group',
                            toastLength: Toast.LENGTH_SHORT,
                            gravity: ToastGravity.BOTTOM,
                            backgroundColor:
                                const Color.fromARGB(255, 181, 96, 88),
                          );
                          return;
                        }
                        Navigator.of(context).pop();
                      },
                      child: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    return UserGroups(
      refStart: refStartInt,
      refEnd: refEndInt,
    );
  }

  Future<String> _presentDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 10, now.month, now.day);
    final lastDate = DateTime(now.year + 10, now.month, now.day);
    firstDate.month;
    final pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: firstDate,
        lastDate: lastDate);
    if (pickedDate == null) {
      return 'not-set';
    }
    int year = pickedDate.year;
    int month = pickedDate.month;
    String twoDigitMonth = month.toString().padLeft(2, '0');
    return '$year-$twoDigitMonth';
  }

  void initPrefs() async {
    _loginData = await SharedPreferences.getInstance();
  }

  @override
  void initState() {
    super.initState();
    initPrefs();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    double height = MediaQuery.of(context).size.height;
    double diagonal = sqrt(pow(width, 2) + pow(height, 2));

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            vertical: diagonal * 0.02,
            horizontal: diagonal * 0.025,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      width: 1,
                      color: const Color(0xFF243A92),
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: diagonal * 0.15,
                  ),
                ),
                SizedBox(height: diagonal * 0.02),
                Text(
                  'PEDO LOGIN',
                  style: TextStyle(
                      color: const Color(0xFF243A92),
                      fontSize: diagonal * 0.02,
                      fontWeight: FontWeight.bold),
                ),
                SizedBox(height: diagonal * 0.1),
                TextField(
                  controller: _userCodeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    suffixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                    labelText: 'Code',
                    hintText: 'Enter your code here...',
                  ),
                ),
                if (!isUserNameSet)
                  const Padding(
                    padding: EdgeInsets.only(
                      top: 5,
                      bottom: 12,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Code is required',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: diagonal * 0.04),
                SizedBox(
                  width: double.infinity,
                  height: diagonal * 0.05,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            FocusScope.of(context).unfocus();

                            if (_userCodeController.text.isEmpty) {
                              setState(() {
                                isUserNameSet = false;
                              });
                              return;
                            } else {
                              setState(() {
                                isUserNameSet = true;
                              });
                            }
                            _login();
                            return;
                          },
                    child: Text(
                      'Login',
                      style: TextStyle(fontSize: diagonal * 0.018),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
