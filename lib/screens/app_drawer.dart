import 'package:flutter/material.dart';
import 'package:meter_reading/screens/change_group_screen.dart';
import 'package:meter_reading/screens/readings/readings.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({
    super.key,
    required this.onLogout,
    required this.onInitial,
    required this.onUploadData,
    required this.onUpdateRange,
  });
  final void Function() onLogout;
  final void Function() onInitial;
  final void Function() onUploadData;
  final void Function() onUpdateRange;

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  late SharedPreferences _loginData;
  String userName = 'NA';
  String email = 'NA';
  String yearMonth = 'not-set';

  void getUserDetails() async {
    _loginData = await SharedPreferences.getInstance();
    userName = _loginData.get('user_name').toString();
    email = _loginData.get('email').toString();
    yearMonth = _loginData.getString('month') ?? 'Not-set';
    setState(() {});
    return;
  }

  void updateUsersGroupInHomeScreen() {
    widget.onUpdateRange();
  }

  @override
  void initState() {
    super.initState();
    getUserDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFF243A92),
            ),
            child: Column(
              children: [
                const Text(
                  'Metrocure',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 50,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                Text(
                  email,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.view_list),
            title: const Text('Readings'),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => Readings(yearMonth)));
            },
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Upload Data'),
            onTap: () {
              Navigator.pop(context);

              widget.onUploadData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.group),
            title: const Text('Change Group'),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (ctx) => ChangeGroupScreen(
                    onChangeUserGroup: (p0) {},
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () {
              widget.onLogout();
              Navigator.pop(context); // Close the drawer
            },
          ),
        ],
      ),
    );
  }
}
