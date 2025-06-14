import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart'; // Import ThemeNotifier from main.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../utils/global.dart';
// import '../utils/theme.dart';
import 'chat_group.dart';
import 'private_chat.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;
  Timer? timer;
  Timer? timer2;
  late WebSocketChannel socket;
  String title = 'NoneBot SideLoad WebUI';

  @override
  void initState() {
    super.initState();
    socket = WebSocketChannel.connect(Uri.parse(
        'ws://${html.window.location.hostname}:${Uri.base.port}/sideload/ws'));
    socket.stream.listen((message) {
      if (message != null) {
        Map<String, dynamic> msgJson = jsonDecode(message);
        switch (msgJson['type']) {
          case 'bot_info':
            Data.botInfo = msgJson['data'];
            setState(() {
              title = Data.botInfo['nickname'];
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
    final colorScheme = Theme.of(context).colorScheme;
    dynamic size = MediaQuery.of(context).size;
    double height = size.height;
    html.document.title = '$title | NoneBot SideLoad WebUI';
    
    return Scaffold(
      backgroundColor: colorScheme.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Chat',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            )),
        automaticallyImplyLeading: false,
        backgroundColor: const Color(0xFFE94B4B),
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              themeNotifier.themeData.brightness == Brightness.dark ? Icons.light_mode : Icons.dark_mode,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              themeNotifier.toggleTheme();
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: colorScheme.onSurface,
            ),
            onSelected: (String value) {
              switch (value) {
                case 'logout':
                  logout();
                  Navigator.pushReplacementNamed(context, '/login');
                  break;
                case 'about':
                  showAboutDialog(
                    context: context,
                    applicationName: 'NoneBot SideLoad WebUI',
                    applicationVersion: '1.0.0',
                    applicationIcon: const Icon(Icons.chat),
                    children: [
                      const Text('一个基于 Flutter 的 NoneBot 侧载插件 WebUI'),
                    ],
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'logout',
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('退出登录'),
                ),
              ),
              const PopupMenuItem<String>(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info),
                  title: Text('关于'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF0F0), // 浅红色背景
        ),
        child: Row(
          children: <Widget>[
            Container(
              margin: const EdgeInsets.only(top: 80, left: 8, bottom: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE94B4B), // 红色导航栏
                  borderRadius: BorderRadius.circular(24),
                ),
                child: NavigationRail(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (int index) {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  backgroundColor: Colors.transparent,
                  elevation: null,
                  labelType: NavigationRailLabelType.all,
                  leading: Container(
                    margin: const EdgeInsets.only(top: 16, bottom: 16),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 20,
                        backgroundImage: NetworkImage(
                          "${html.window.location.protocol}//${html.window.location.hostname}:${Uri.base.port}/sideload/avatars/user/${Data.botInfo['id']}.png"),
                      ),
                    ),
                  ),
                  useIndicator: false,
                  selectedIconTheme: const IconThemeData(
                    color: Colors.white,
                    size: 28,
                  ),
                  unselectedIconTheme: const IconThemeData(
                    color: Colors.white70,
                    size: 24,
                  ),
                  selectedLabelTextStyle: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  unselectedLabelTextStyle: const TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.chat_outlined),
                      selectedIcon: Icon(Icons.chat),
                      label: Text('私聊'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.group_outlined),
                      selectedIcon: Icon(Icons.group),
                      label: Text('群聊'),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 80, right: 8, bottom: 8, left: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: const <Widget>[
                      ChatPrivate(),
                      ChatGroup(),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
