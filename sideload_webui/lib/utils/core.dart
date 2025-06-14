import 'dart:async';// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:sideload_webui/utils/global.dart';
import 'package:sideload_webui/utils/ws_handler.dart';

Timer? timer;

void connectToWebSocket() {
  //连接到WebSocket
  late String wsUrl;
  if (debug) {
    wsUrl = 'ws://127.0.0.1:8081/nbgui/v1/sideload/ws';
  } else {
    wsUrl = (html.window.location.protocol == 'https:')
        ? 'wss://${html.window.location.hostname}:${Uri.base.port}/nbgui/v1/sideload/ws'
        : 'ws://${html.window.location.hostname}:${Uri.base.port}/nbgui/v1/sideload/ws';
  }
  socket = html.WebSocket(wsUrl);
  //et = WebSocket('ws://localhost:2519/nbgui/v1/ws');
  socket.onMessage.listen((event) {
    html.MessageEvent msg = event;
    wsHandler(msg);
  }, cancelOnError: false);
}
