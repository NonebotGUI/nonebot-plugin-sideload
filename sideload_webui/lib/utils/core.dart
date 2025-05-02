import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html';
import 'package:sideload_webui/utils/global.dart';
import 'package:sideload_webui/utils/ws_handler.dart';

Timer? timer;

void connectToWebSocket() {
  //连接到WebSocket
  late String wsUrl;
  if (debug) {
    wsUrl = 'ws://192.168.0.100:8081/nbgui/v1/sideload/ws';
  } else {
    wsUrl = (window.location.protocol == 'https:')
        ? 'wss://${window.location.hostname}:${Uri.base.port}/nbgui/v1/sideload/ws'
        : 'ws://${window.location.hostname}:${Uri.base.port}/nbgui/v1/sideload/ws';
  }
  socket = WebSocket(wsUrl);
  // socket = WebSocket('ws://localhost:2519/nbgui/v1/ws');
  socket.onMessage.listen((event) {
    MessageEvent msg = event;
    wsHandler(msg);
  }, cancelOnError: false);
}
