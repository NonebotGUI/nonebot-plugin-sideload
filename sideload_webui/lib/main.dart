import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sideload_webui/utils/core.dart';
import 'package:sideload_webui/utils/global.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sideload_webui/pages/main_page.dart';
import 'package:sideload_webui/pages/mobile/main_page.dart';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'package:dynamic_color/dynamic_color.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   version = '0.1.0';
//   debug = true;

//   runApp(
//     ChangeNotifierProvider(
//       create: (context) => ThemeNotifier(initialThemeMode),
//       child: const MyApp(),
//     ),
//   );
// }

void main() {
  version = '0.1.0';
  debug = true;
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details, forceReport: true);
  };
  runZonedGuarded(() {
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeNotifier(initialThemeMode),
        child: const MyApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    print('未捕获的异步错误: $error');
    print('堆栈信息: $stack');
  });
  WidgetsFlutterBinding.ensureInitialized();
}

class ThemeNotifier extends ChangeNotifier {
  ThemeData _themeData;
  String _themeMode;

  ThemeNotifier(String initialMode)
      : _themeMode = initialMode,
        _themeData = _getTheme(initialMode);

  ThemeData get themeData => _themeData;

  void toggleTheme() async {
    if (_themeMode == 'light') {
      _themeMode = 'dark';
      _themeData = _getTheme('dark');
      Config.user['color'] = 'dark';
    } else {
      _themeMode = 'light';
      _themeData = _getTheme('light');
      Config.user['color'] = 'light';
    }
    // 保存配置到SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('config', jsonEncode(Config.user));
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeNotifier = Provider.of<ThemeNotifier>(context);

    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        ColorScheme lightScheme;
        ColorScheme darkScheme;

        // 使用红色主题，匹配截图中的样式
        if (lightDynamic != null && darkDynamic != null) {
          lightScheme = lightDynamic.harmonized();
          darkScheme = darkDynamic.harmonized();
        } else {
          lightScheme = ColorScheme.fromSeed(
            seedColor: const Color(0xFFE94B4B), // 红色主题
            brightness: Brightness.light,
          );
          darkScheme = ColorScheme.fromSeed(
            seedColor: const Color(0xFFE94B4B), // 红色主题
            brightness: Brightness.dark,
          );
        }

        return MaterialApp(
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: lightScheme,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: lightScheme.surface,
              foregroundColor: lightScheme.onSurface,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: darkScheme,
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            appBarTheme: AppBarTheme(
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: darkScheme.surface,
              foregroundColor: darkScheme.onSurface,
            ),
          ),
          themeMode: themeNotifier._themeMode == 'dark' ? ThemeMode.dark : ThemeMode.light,
          home: const LoginPage(),
        );
      },
    );
  }
}

///颜色主题
ThemeData _getTheme(mode) {
  switch (mode) {
    case 'light':
      return ThemeData.light().copyWith(
          canvasColor: const Color.fromRGBO(254, 239, 239, 1),
          primaryColor: const Color.fromRGBO(0, 153, 255, 1),
          buttonTheme: const ButtonThemeData(
            buttonColor: Color.fromRGBO(0, 153, 255, 1),
          ),
          checkboxTheme: CheckboxThemeData(
            fillColor:
                MaterialStateProperty.resolveWith((Set<MaterialState> states) {
              if (states.contains(MaterialState.selected)) {
                return const Color.fromRGBO(0, 153, 255, 1);
              }
              return Colors.white;
            }),
            checkColor: MaterialStateProperty.all(Colors.white),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
              color: Color.fromRGBO(0, 153, 255, 1)),
          appBarTheme: const AppBarTheme(color: Color.fromRGBO(0, 153, 255, 1)),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color.fromRGBO(0, 153, 255, 1)),
          switchTheme: const SwitchThemeData(
              trackColor:
                  MaterialStatePropertyAll(Color.fromRGBO(0, 153, 255, 1))));
    case 'dark':
      return ThemeData.dark().copyWith(
          canvasColor: const Color.fromRGBO(18, 18, 18, 1),
          primaryColor: const Color.fromRGBO(147, 112, 219, 1),
          buttonTheme: const ButtonThemeData(
            buttonColor: Color.fromRGBO(147, 112, 219, 1),
          ),
          checkboxTheme: const CheckboxThemeData(
              checkColor: MaterialStatePropertyAll(
            Color.fromRGBO(147, 112, 219, 1),
          )),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color.fromRGBO(147, 112, 219, 1),
          ),
          appBarTheme: const AppBarTheme(
            color: Color.fromRGBO(147, 112, 219, 1),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
              backgroundColor: Color.fromRGBO(147, 112, 219, 1)),
          switchTheme: const SwitchThemeData(
              trackColor:
                  MaterialStatePropertyAll(Color.fromRGBO(147, 112, 219, 1))));
    default:
      return ThemeData.light().copyWith(
        canvasColor: const Color.fromRGBO(254, 239, 239, 1),
        primaryColor: const Color.fromRGBO(0, 153, 255, 1),
        buttonTheme:
            const ButtonThemeData(buttonColor: Color.fromRGBO(0, 153, 255, 1)),
        checkboxTheme: const CheckboxThemeData(
            checkColor:
                MaterialStatePropertyAll(Color.fromRGBO(0, 153, 255, 1))),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color.fromRGBO(0, 153, 255, 1)),
        appBarTheme: const AppBarTheme(color: Color.fromRGBO(0, 153, 255, 1)),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color.fromRGBO(0, 153, 255, 1)),
        switchTheme: const SwitchThemeData(
            trackColor:
                MaterialStatePropertyAll(Color.fromRGBO(0, 153, 255, 1))),
      );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final myController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!debug) {
      autoLogin();
    }
    getConfig();
  }

  // 获取用户配置文件
  Future<void> getConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final config = await prefs.getString('config');
    if (config == null) {
      String cfg = jsonEncode(Config.user);
      await prefs.setString('config', cfg);
    } else {
      Config.user = jsonDecode(config);
    }
    initialThemeMode = Config.user['color'] ?? 'light';
    setState(() {});
  }

  // 自动登录
  Future<void> autoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final token = await prefs.getString('token');
    if (token != null) {
      final res = await http.get(Uri.parse("/config"),
          headers: {"Authorization": 'Bearer $token'});
      if (res.statusCode == 200) {
        final config = jsonDecode(res.body);
        final connection = config['connection'];
        Config.token = connection['token'];
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => (MediaQuery.of(context).size.width >
                      MediaQuery.of(context).size.height)
                  ? const MainPage()
                  : const MainPageMobile()),
          (Route<dynamic> route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('自动登录失败'),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取屏幕的尺寸
    dynamic screenSize = MediaQuery.of(context).size;
    double screenWidth = screenSize.width;
    double screenHeight = screenSize.height;
    double logoSize =
        (screenHeight > screenWidth) ? screenWidth * 0.4 : screenHeight * 0.4;
    double inputFieldWidth =
        (screenHeight > screenWidth) ? screenWidth * 0.75 : screenHeight * 0.5;
    double buttonWidth =
        (screenHeight > screenWidth) ? screenWidth * 0.09 : screenHeight * 0.07;
    html.document.title = 'NoneBot SideLoad WebUI';
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: screenWidth,
              height: screenHeight * 0.075,
            ),
            Config.user['img'] == 'default'
                ? Image.asset(
                    'lib/assets/logo.png',
                    width: logoSize,
                    height: logoSize,
                  )
                : Image.network(
                    Config.user['img'],
                    width: logoSize,
                    height: logoSize,
                  ),
            // const SizedBox(
            //   height: 4,
            // ),
            Text(
              Config.user['text'] == 'default'
                  ? '登录到 NoneBot SideLoad WebUI'
                  : Config.user['text'],
              style: const TextStyle(
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: inputFieldWidth,
              height: inputFieldWidth * 0.175,
              child: TextField(
                controller: myController,
                obscureText: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '密码',
                ),
                onSubmitted: (String value) async {
                  final password = myController.text;
                  final res = await http.post(Uri.parse('/sideload/auth'),
                      body: jsonEncode({'password': password}),
                      headers: {"Content-Type": "application/json"});
                  if (res.statusCode == 200) {
                    // final getConfig = await http.get(
                    //   Uri.parse('/config'),
                    //   headers: {"Authorization": 'Bearer ${res.body}'},
                    // );
                    // final config = jsonDecode(getConfig.body);
                    // final connection = config['connection'];
                    Config.password = password;
                    // final prefs = await SharedPreferences.getInstance();
                    // await prefs.setString('token', res.body);
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      connectToWebSocket();
                      Completer<void> completer = Completer<void>();
                      socket.onOpen.listen((event) {
                        completer.complete();
                      });
                      completer.future.then((_) {
                        socket.send(
                          '{"type":"get_total","password":"${Config.password}"}',
                        );
                        setState(() {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('欢迎回来！'),
                              duration: Duration(seconds: 3),
                            ),
                          );

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  (MediaQuery.of(context).size.width >
                                          MediaQuery.of(context).size.height)
                                      ? const MainPage()
                                      : const MainPageMobile(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        });
                      });
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('验证失败了喵'),
                    ));
                  }
                },
              ),
            ),
            const SizedBox(
              height: 16,
            ),
            SizedBox(
              child: ElevatedButton(
                onPressed: () async {
                  if (debug) {
                    Config.token = '114514';
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      connectToWebSocket();
                      Completer<void> completer = Completer<void>();
                      socket.onOpen.listen((event) {
                        completer.complete();
                      });
                      completer.future.then((_) {
                        socket.send(
                          '{"type":"get_total","password":"${Config.password}"}',
                        );
                        setState(() {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('高贵的debugger不需要密码'),
                              duration: Duration(seconds: 3),
                            ),
                          );

                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  (MediaQuery.of(context).size.width >
                                          MediaQuery.of(context).size.height)
                                      ? const MainPage()
                                      : const MainPageMobile(),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        });
                      });
                    });
                  } else {
                    final password = myController.text;
                    final res = await http.post(Uri.parse('/sideload/auth'),
                        body: jsonEncode({'password': password}),
                        headers: {"Content-Type": "application/json"});
                    if (res.statusCode == 200) {
                      // final getConfig = await http.get(
                      //   Uri.parse('/config'),
                      //   headers: {"Authorization": 'Bearer ${res.body}'},
                      // );
                      // final config = jsonDecode(getConfig.body);
                      // final connection = config['connection'];
                      Config.password = password;
                      // final prefs = await SharedPreferences.getInstance();
                      // await prefs.setString('token', res.body);
                      Future.delayed(const Duration(milliseconds: 500),
                          () async {
                        connectToWebSocket();
                        Completer<void> completer = Completer<void>();
                        socket.onOpen.listen((event) {
                          completer.complete();
                        });
                        completer.future.then((_) {
                          socket.send(
                            '{"type":"get_total","password":"${Config.password}"}',
                          );
                          setState(() {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('欢迎回来！'),
                                duration: Duration(seconds: 3),
                              ),
                            );

                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    (MediaQuery.of(context).size.width >
                                            MediaQuery.of(context).size.height)
                                        ? const MainPage()
                                        : const MainPageMobile(),
                              ),
                              (Route<dynamic> route) => false,
                            );
                          });
                        });
                      });
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('验证失败了喵'),
                      ));
                    }
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                      Config.user['color'] == 'default' ||
                              Config.user['color'] == 'light'
                          ? const Color.fromRGBO(0, 153, 255, 1)
                          : const Color.fromRGBO(147, 112, 219, 1)),
                  shape: MaterialStateProperty.all(const CircleBorder()),
                  iconSize: MaterialStateProperty.all(24),
                  minimumSize:
                      MaterialStateProperty.all(Size(buttonWidth, buttonWidth)),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white,
                  size: buttonWidth * 0.75,
                ),
              ),
            ),
            Expanded(child: Container()),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Text(
                  'Powered by Flutter',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
            const Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.all(2),
                child: Text(
                  'Released under the GPL-3 License',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
