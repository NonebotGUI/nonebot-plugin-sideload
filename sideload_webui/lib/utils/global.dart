import 'dart:html';

late WebSocket socket;
late String version;
String groupOnOpen = '';
String groupOnOpenName = '';
String friendOnOpen = '';
String friendOnOpenName = '';
String initialThemeMode = 'light';

/// 配置文件
class Config {
  /// 访问密码
  static String password = 'Xt114514';

  /// token
  static String token = '';

  /// 用户个人配置
  static Map user = {
    "color": "light",
    "img": "default",
    "text": "default",
    "anti_recall": true,
    "display_time": true,
    "+1": true
  };
}

/// 应用程序数据
class Data {
  /// 群组列表
  static List groupList = [];

  /// 好友列表
  static List friendList = [];

  /// 群组消息
  static List groupMessage = [];

  /// 好友消息
  static List friendMessage = [];

  /// Bot 基本信息
  static Map botInfo = {};

  static String userAvatar = '';
}

// 神秘开关
bool debug = true;
