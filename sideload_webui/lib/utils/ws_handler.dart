import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:sideload_webui/utils/global.dart';

/// 处理WebSocket消息
Future<void> wsHandler(MessageEvent msg) async {
  /// 解析json
  String? msg0 = msg.data;
  // 检查是否为json
  if (msg0 != null) {
    if (msg0 == "Unauthorized") {
      print("WebSocket message: Unauthorized");
      // TODO: Handle unauthorized access, e.g., notify user or attempt re-authentication
      return;
    }
    Map<String, dynamic> msgJson = jsonDecode(msg0);
    String type = msgJson['type'];
    switch (type) {
      case 'total':
        Map data = msgJson['data'];
        Data.botInfo = data;
        Data.groupList = data['group_list'];
        Data.friendList = data['friend_list'];
        break;
      case 'group_msg':
        List data = msgJson['data'];
        Data.groupMessage = data;
        break;
      case 'friend_msg':
        List data = msgJson['data'];
        Data.friendMessage = data;
        break;
    }
  }
}
