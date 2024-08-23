import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:meter_reading/models/contactinfomodel.dart';
import 'package:meter_reading/Database/controller.dart';
import 'package:meter_reading/screens/home/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChangeGroupScreen extends StatefulWidget {
  const ChangeGroupScreen({super.key, required this.onChangeUserGroup});
  final void Function(UserGroups) onChangeUserGroup;

  @override
  State<ChangeGroupScreen> createState() => _ChangeGroupScreenState();
}

class _ChangeGroupScreenState extends State<ChangeGroupScreen> {
  late SharedPreferences _setUserGroup;

  int refStartInt = 0;
  int refEndInt = 0;
  List<bool> listAllFalse = [];
  List<UserGroups> groups = [];

  void setUserPrefs(
    UserGroups userGroup,
  ) {
    _setUserGroup.setInt('refStart', userGroup.refStart);
    _setUserGroup.setInt('refEnd', userGroup.refEnd);
    return;
  }

  void initPrefs() async {
    _setUserGroup = await SharedPreferences.getInstance();
    refStartInt = _setUserGroup.getInt('refStart') ?? 0;
    refEndInt = _setUserGroup.getInt('refEnd') ?? 0;
  }

  void getUserGroupsLocally() async {
    List<UserGroups> localUserGroups =
        await Controller().fetchUserGroupsFromSqlLite();
    setState(() {
      groups.addAll(localUserGroups);
    });
  }

  @override
  void initState() {
    super.initState();
    initPrefs();
    getUserGroupsLocally();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change User Group'),
        actions: [
          ElevatedButton.icon(
              onPressed: () {
                setUserPrefs(
                    UserGroups(refStart: refStartInt, refEnd: refEndInt));
                widget.onChangeUserGroup(
                    UserGroups(refStart: refStartInt, refEnd: refEndInt));
                Fluttertoast.showToast(
                  msg: 'User group changed Successfully',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                  backgroundColor: const Color.fromARGB(255, 88, 181, 123),
                );
                Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (ctx) => const MyHomePage()));
              },
              icon: const Icon(Icons.save),
              label: const Text('Update')),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 12),
        child: ListView.builder(
          itemCount: groups.length,
          itemBuilder: (ctx, index) {
            for (var group in groups) {
              if (group.refStart == refStartInt) {
                listAllFalse.add(true);
              } else {
                listAllFalse.add(false);
              }
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: ListTile(
                tileColor: const Color.fromARGB(255, 216, 217, 247),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                onTap: () {
                  setState(
                    () {
                      if (index == 0) {
                        listAllFalse.fillRange(1, listAllFalse.length, false);
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
                    },
                  );
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
    );
  }
}
