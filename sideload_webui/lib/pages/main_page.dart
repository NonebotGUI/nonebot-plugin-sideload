// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'package:sideload_webui/main.dart';
import 'package:flutter/material.dart';
import 'package:sideload_webui/pages/chat_group.dart';
import 'package:sideload_webui/pages/private_chat.dart';
import 'package:sideload_webui/utils/global.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<MainPage> {
  final myController = TextEditingController();
  int _selectedIndex = 0;
  Timer? timer;
  Timer? timer2;
  int runningCount = 0;
  String title = '主页';

  @override
  void initState() {
    super.initState();
    setState(() {
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {});
      });
    });
    socket.onMessage.listen((MessageEvent msg) async {
      String? msg0 = msg.data;
      if (msg0 != null) {
        Map<String, dynamic> msgJson = jsonDecode(msg0);
        String type = msgJson['type'];
        switch (type) {
          case 'total':
            Map data = msgJson['data'];
            Data.botInfo = data;
            setState(() {
              Data.groupList = data['group_list'];
              Data.friendList = data['friend_list'];
            });
            break;
          case 'group_msg':
            List data = msgJson['data'];
            Data.groupMessage = data;
            setState(() {});
            break;
          case 'friend_msg':
            List data = msgJson['data'];
            Data.friendMessage = data;
            setState(() {});
            break;
        }
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    timer2?.cancel();
    super.dispose();
  }

  logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    dynamic size = MediaQuery.of(context).size;
    double height = size.height;
    html.document.title = '$title | NoneBot SideLoad WebUI';
    return Scaffold(
        appBar: AppBar(
          title: const Text('NoneBot SideLoad',
              style: TextStyle(color: Colors.white)),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.brightness_6),
              onPressed: () {
                themeNotifier.toggleTheme();
                setState(() {
                  if (Config.user['color'] == 'light' ||
                      Config.user['color'] == 'default') {
                    Config.user['color'] = 'dark';
                  } else {
                    Config.user['color'] = 'light';
                  }
                });
              },
              color: Colors.white,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              color: Colors.white,
              tooltip: '登出',
              onPressed: () {
                //logout();
                html.window.location.reload();
                // _showNotification();
              },
            )
          ],
        ),
        body: Row(
          children: [
            NavigationRail(
              leading: CircleAvatar(
                  backgroundImage: NetworkImage(
                      "${window.location.protocol}//${window.location.hostname}:${Uri.base.port}/sideload/avatars/user/${Data.botInfo['id']}.png")),
              useIndicator: false,
              selectedIconTheme: IconThemeData(
                  color: Config.user['color'] == 'light' ||
                          Config.user['color'] == 'default'
                      ? const Color.fromRGBO(0, 153, 255, 1)
                      : const Color.fromRGBO(147, 112, 219, 1),
                  size: height * 0.03),
              selectedLabelTextStyle: TextStyle(
                color: Config.user['color'] == 'light' ||
                        Config.user['color'] == 'default'
                    ? const Color.fromRGBO(0, 153, 255, 1)
                    : const Color.fromRGBO(147, 112, 219, 1),
                fontSize: height * 0.02,
              ),
              unselectedLabelTextStyle: TextStyle(
                fontSize: height * 0.02,
                color: Config.user['color'] == 'light' ||
                        Config.user['color'] == 'default'
                    ? Colors.grey[600]
                    : Colors.white,
              ),
              unselectedIconTheme: IconThemeData(
                  color: Config.user['color'] == 'light' ||
                          Config.user['color'] == 'default'
                      ? Colors.grey[600]
                      : Colors.white,
                  size: height * 0.03),
              elevation: 2,
              indicatorShape: const RoundedRectangleBorder(),
              onDestinationSelected: (int index) {
                setState(() {
                  _selectedIndex = index;
                  switch (index) {
                    case 0:
                      title = '好友';
                      break;
                    case 1:
                      title = '群组';
                      break;
                    case 2:
                      title = '开源许可证';
                      break;
                    case 3:
                      title = '设置';
                      break;
                    default:
                      title = 'Unknown';
                      break;
                  }
                });
              },
              selectedIndex: _selectedIndex,
              extended: false,
              destinations: <NavigationRailDestination>[
                NavigationRailDestination(
                  icon: Tooltip(
                    message: '好友',
                    child: Icon(
                      _selectedIndex == 0
                          ? Icons.person_rounded
                          : Icons.person_outline_rounded,
                    ),
                  ),
                  label: const Text('好友'),
                ),
                NavigationRailDestination(
                  icon: Tooltip(
                    message: '群组',
                    child: Icon(
                      _selectedIndex == 1
                          ? Icons.group_rounded
                          : Icons.group_outlined,
                    ),
                  ),
                  label: const Text('群组'),
                ),
                //     NavigationRailDestination(
                //       icon: Tooltip(
                //         message: '设置',
                //         child: Icon(
                //           _selectedIndex == 2
                //               ? Icons.settings_rounded
                //               : Icons.settings_outlined,
                //         ),
                //       ),
                //       label: const Text('设置'),
                //     ),
                //     NavigationRailDestination(
                //       icon: Tooltip(
                //         message: '开源许可证',
                //         child: Icon(
                //           _selectedIndex == 3
                //               ? Icons.balance_rounded
                //               : Icons.balance_outlined,
                //         ),
                //       ),
                //       label: const Text('开源许可证'),
                //     ),
              ],
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: const <Widget>[
                  ChatPrivate(),
                  ChatGroup(),
                  // Text('设置'),
                  // Text('开源许可证')
                ],
              ),
            )
          ],
        ));
  }
}
