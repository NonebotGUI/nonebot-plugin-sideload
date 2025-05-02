// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html';
import 'package:sideload_webui/main.dart';
import 'package:flutter/material.dart';
import 'package:sideload_webui/pages/mobile/group.dart';
import 'package:sideload_webui/pages/mobile/private.dart';
import 'package:sideload_webui/utils/global.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainPageMobile extends StatefulWidget {
  const MainPageMobile({super.key});

  @override
  State<MainPageMobile> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<MainPageMobile> {
  final myController = TextEditingController();
  int _selectedIndex = 0;
  Timer? timer;
  Timer? timer2;
  int runningCount = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    timer?.cancel();
    timer2?.cancel();
    super.dispose();
  }

  logout() async {
    // 从 SharedPreference 中删除 token
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);
    html.document.title = 'NoneBot SideLoad WebUI';
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
              },
            )
          ],
        ),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: '好友',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: '群组',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: const Color.fromRGBO(0, 153, 255, 1),
          backgroundColor: Config.user['color'] == 'default' ||
                  Config.user['color'] == 'light'
              ? Colors.white
              : const Color.fromRGBO(18, 18, 18, 1),
          onTap: _onItemTapped,
        ),
        body: Container(
          margin: const EdgeInsets.all(4),
          child: Column(
            children: <Widget>[
              _selectedIndex == 1
                  ? Container(
                      alignment: Alignment.topCenter,
                      child: ListView.builder(
                        itemCount: Data.groupList.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                '${window.location.protocol}//${window.location.hostname}:${Uri.base.port}/sideload/avatars/group/${Data.groupList[index]['group_id']}.png',
                              ),
                            ),
                            title: Text(
                              Data.groupList[index]['group_name'].toString(),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Config.user['color'] == 'default' ||
                                          Config.user['color'] == 'light'
                                      ? Colors.black
                                      : Colors.white),
                            ),
                            subtitle: Text(
                              Data.groupList[index]['group_id'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Data.groupList[index]['group_id']
                                            .toString() ==
                                        groupOnOpen
                                    ? Colors.grey[200]
                                    : Colors.grey[600],
                              ),
                            ),
                            onTap: () {
                              groupOnOpen =
                                  Data.groupList[index]['group_id'].toString();
                              groupOnOpenName = Data.groupList[index]
                                      ['group_name']
                                  .toString();
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return const ChatGroupMobile();
                              }));
                            },
                          );
                        },
                      ),
                    )
                  : Container(
                      alignment: Alignment.topCenter,
                      child: ListView.builder(
                        itemCount: Data.friendList.length,
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(
                                '${window.location.protocol}//${window.location.hostname}:${Uri.base.port}/sideload/avatars/user/${Data.friendList[index]['user_id']}.png',
                              ),
                            ),
                            title: Text(
                              Data.friendList[index]['nickname'].toString(),
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Config.user['color'] == 'default' ||
                                          Config.user['color'] == 'light'
                                      ? Colors.black
                                      : Colors.white),
                            ),
                            subtitle: Text(
                              Data.friendList[index]['user_id'].toString(),
                              style: TextStyle(
                                fontSize: 14,
                                color: Data.friendList[index]['user_id']
                                            .toString() ==
                                        friendOnOpen
                                    ? Colors.grey[200]
                                    : Colors.grey[600],
                              ),
                            ),
                            onTap: () {
                              friendOnOpen =
                                  Data.friendList[index]['user_id'].toString();
                              friendOnOpenName =
                                  Data.friendList[index]['nickname'].toString();
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return const ChatPrivateMobile();
                              }));
                            },
                          );
                        },
                      ),
                    )
            ],
          ),
        ));
  }
}
