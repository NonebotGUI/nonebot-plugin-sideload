// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'package:provider/provider.dart';
import 'package:sideload_webui/main.dart';
import 'package:sideload_webui/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:sideload_webui/utils/global.dart';

class ChatPrivateMobile extends StatefulWidget {
  const ChatPrivateMobile({super.key});

  @override
  State<ChatPrivateMobile> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ChatPrivateMobile> {
  final myController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;
  bool _showScrollToBottomButton = false;
  @override
  void initState() {
    super.initState();
    setState(() {
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {});
      });
      startTimer();
    });

    // 监听滚动事件
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final isAtBottom = _scrollController.position.pixels >=
        (_scrollController.position.maxScrollExtent - 20);

    if (isAtBottom != _isAtBottom) {
      setState(() {
        _isAtBottom = isAtBottom;
        _showScrollToBottomButton = !isAtBottom;
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _updateMessages() {
    setState(() {
      if (_isAtBottom) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    });
  }

  Timer? timer;
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (friendOnOpen.isNotEmpty) {
        socket.send(
          '{"type":"get_friend_message","group_id":"$friendOnOpen", "password":"${Config.password}"}',
        );
        setState(() {});
        _updateMessages();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    myController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    friendOnOpen = '';
    friendOnOpenName = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;

    final themeNotifier = Provider.of<ThemeNotifier>(context);
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title:
            Text(friendOnOpenName, style: const TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: '返回',
          onPressed: () {
            Navigator.pop(context);
          },
        ),
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
        ],
      ),
      body: Stack(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Flexible(
                flex: 4,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: Data.friendMessage.length,
                  shrinkWrap: false,
                  padding: const EdgeInsets.all(24),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    final data = Data.friendMessage[index];
                    final userId = data['sender']['user_id'].toString();

                    return MessageBubble(
                      message: data,
                      isCurrentUser: userId == Data.botInfo['id'],
                      onResend: () async {
                        setState(() {
                          socket.send(
                            '{"type":"send_private_msg","user_id":"$friendOnOpen","message":"${data['message'].toString()}","password":"${Config.password}"}',
                          );
                          socket.send(
                            '{"type":"get_friend_message","user_id":"$friendOnOpen", "password":"${Config.password}"}',
                          );
                        });
                      },
                    );
                  },
                ),
              ),
              const Divider(
                height: 1,
                thickness: 1,
                color: Colors.grey,
              ),
              Container(
                height: 60,
                padding: EdgeInsets.only(
                  bottom: viewInsets.bottom > 0 ? 0 : 10,
                  left: 10,
                  right: 10,
                  top: 10,
                ),
                child: Stack(
                  children: [
                    TextField(
                      controller: myController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Say something...',
                        hintStyle: TextStyle(
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: IconButton(
                        icon: const Icon(Icons.send),
                        color: Config.user['color'] == 'default' ||
                                Config.user['color'] == 'light'
                            ? const Color.fromRGBO(0, 153, 255, 1)
                            : const Color.fromRGBO(147, 112, 219, 1),
                        onPressed: () {
                          if (myController.text.isNotEmpty) {
                            final messageText =
                                myController.text.replaceAll('\n', '\\n');
                            setState(() {
                              socket.send(
                                '{"type":"send_private_msg","user_id":"$friendOnOpen","message":"$messageText","password":"${Config.password}"}',
                              );
                            });
                            setState(() {
                              socket.send(
                                '{"type":"get_friend_message","user_id":"$friendOnOpen", "password":"${Config.password}"}',
                              );
                            });
                            myController.clear();
                            _isAtBottom = true;
                            _updateMessages();
                          }
                        },
                      ),
                    )
                  ],
                ),
              ),
            ],
          ),
          if (_showScrollToBottomButton)
            Positioned(
              right: 16,
              bottom: 80,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Theme.of(context).primaryColor,
                onPressed: () {
                  _scrollToBottom();
                },
                child: const Icon(
                  Icons.arrow_downward,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
