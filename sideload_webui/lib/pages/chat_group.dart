// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html';
import 'package:sideload_webui/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:sideload_webui/utils/global.dart';

class ChatGroup extends StatefulWidget {
  const ChatGroup({super.key});

  @override
  State<ChatGroup> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ChatGroup> {
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
      if (groupOnOpen.isNotEmpty) {
        socket.send(
          '{"type":"get_group_message","group_id":"$groupOnOpen", "password":"${Config.password}"}',
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
    groupOnOpen = '';
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          Expanded(
              flex: 2,
              child: Container(
                alignment: Alignment.topCenter,
                child: ListView.builder(
                  itemCount: Data.groupList.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Container(
                        color: Data.groupList[index]['group_id'].toString() ==
                                groupOnOpen
                            ? Config.user['color'] == 'default' ||
                                    Config.user['color'] == 'light'
                                ? const Color.fromRGBO(0, 153, 255, 1)
                                : const Color.fromRGBO(147, 112, 219, 1)
                            : Colors.transparent,
                        child: ListTile(
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
                                color: Data.groupList[index]['group_id']
                                            .toString() ==
                                        groupOnOpen
                                    ? Colors.white
                                    : Config.user['color'] == 'default' ||
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
                            setState(() {
                              groupOnOpen =
                                  Data.groupList[index]['group_id'].toString();
                              Data.groupMessage = [];
                              socket.send(
                                '{"type":"get_group_message","group_id":"${Data.groupList[index]['group_id'].toString()}", "password":"${Config.password}"}',
                              );
                            });
                          },
                        ));
                  },
                ),
              )),
          const VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.grey,
          ),
          Expanded(
              flex: 11,
              child: groupOnOpen.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Select a group to chat',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ))
                  : Stack(
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 4,
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: Data.groupMessage.length,
                                shrinkWrap: false,
                                padding: const EdgeInsets.all(24),
                                physics: const AlwaysScrollableScrollPhysics(),
                                itemBuilder: (context, index) {
                                  final data = Data.groupMessage[index];
                                  final userId =
                                      data['sender']['user_id'].toString();

                                  return MessageBubble(
                                    message: data,
                                    isCurrentUser: userId == Data.botInfo['id'],
                                    onResend: () async {
                                      setState(() {
                                        socket.send(
                                          '{"type":"send_group_msg","group_id":"$groupOnOpen","message":"${data['message'].toString()}","password":"${Config.password}"}',
                                        );
                                        socket.send(
                                          '{"type":"get_group_message","group_id":"$groupOnOpen", "password":"${Config.password}"}',
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
                            Expanded(
                              flex: 1,
                              child: Container(
                                  padding: const EdgeInsets.all(10),
                                  child: Stack(
                                    children: [
                                      TextField(
                                        controller: myController,
                                        maxLines: null,
                                        expands: true,
                                        textAlignVertical:
                                            TextAlignVertical.top,
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
                                          color: Config.user['color'] ==
                                                      'default' ||
                                                  Config.user['color'] ==
                                                      'light'
                                              ? const Color.fromRGBO(
                                                  0, 153, 255, 1)
                                              : const Color.fromRGBO(
                                                  147, 112, 219, 1),
                                          onPressed: () {
                                            if (myController.text.isNotEmpty) {
                                              final messageText = myController
                                                  .text
                                                  .replaceAll('\n', '\\n');
                                              setState(() {
                                                socket.send(
                                                  '{"type":"send_group_msg","group_id":"$groupOnOpen","message":"$messageText","password":"${Config.password}"}',
                                                );
                                              });
                                              setState(() {
                                                socket.send(
                                                  '{"type":"get_group_message","group_id":"$groupOnOpen", "password":"${Config.password}"}',
                                                );
                                              });
                                              myController.clear();
                                            }
                                          },
                                        ),
                                      )
                                    ],
                                  )),
                            )
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
                    ))
        ],
      ),
    );
  }
}
