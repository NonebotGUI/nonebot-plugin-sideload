// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'dart:html';
import 'package:sideload_webui/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:sideload_webui/utils/global.dart';

class ChatPrivate extends StatefulWidget {
  const ChatPrivate({super.key});

  @override
  State<ChatPrivate> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ChatPrivate> {
  final myController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAtBottom = true;
  bool _showScrollToBottomButton = false;

  List<dynamic> _visibleMessages = [];
  final int _pageSize = 20;
  bool _isLoading = false;
  bool _hasMoreData = true;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    setState(() {
      Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          socket.send(
            '{"type":"get_total","password":"${Config.password}"}',
          );
        });
        _loadInitialMessages();
      });
      startTimer();
    });

    // 监听滚动事件
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final isAtBottom = _scrollController.position.pixels >=
        (_scrollController.position.maxScrollExtent - 20);

    if (_scrollController.position.pixels <= 50 &&
        !_isLoading &&
        _hasMoreData) {
      _loadMoreMessages();
    }

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

  void _loadInitialMessages() {
    if (Data.friendMessage.isEmpty) return;

    setState(() {
      _visibleMessages = Data.friendMessage.length > _pageSize
          ? Data.friendMessage.sublist(Data.friendMessage.length - _pageSize)
          : [...Data.friendMessage];

      // 确保从底部开始显示
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    });
  }

  void _loadMoreMessages() {
    if (_isLoading || _visibleMessages.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    // 计算下一页的起始索引
    int endIndex = Data.friendMessage.indexOf(_visibleMessages.first);
    if (endIndex <= 0) {
      setState(() {
        _isLoading = false;
        _hasMoreData = false;
      });
      return;
    }

    int startIndex = (endIndex - _pageSize) > 0 ? (endIndex - _pageSize) : 0;

    if (startIndex < endIndex) {
      List<dynamic> moreMessages =
          Data.friendMessage.sublist(startIndex, endIndex);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _visibleMessages.insertAll(0, moreMessages);
            _isLoading = false;
            if (startIndex == 0) {
              _hasMoreData = false;
            }
          });

          // 保持滚动位置
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final currentPosition = _scrollController.position.pixels;
              final scrollAmount = 50.0 * moreMessages.length;
              _scrollController.jumpTo(currentPosition + scrollAmount);
            }
          });
        }
      });
    } else {
      setState(() {
        _isLoading = false;
        _hasMoreData = false;
      });
    }
  }

  void _updateMessages() {
    if (Data.friendMessage.isEmpty) return;

    if (_visibleMessages.isEmpty) {
      _loadInitialMessages();
      return;
    }

    // 检查是否有新消息
    if (Data.friendMessage.isNotEmpty &&
        (_visibleMessages.isEmpty ||
            Data.friendMessage.last != _visibleMessages.last)) {
      int lastVisibleIndex = -1;
      if (_visibleMessages.isNotEmpty) {
        for (int i = Data.friendMessage.length - 1; i >= 0; i--) {
          if (Data.friendMessage[i] == _visibleMessages.last) {
            lastVisibleIndex = i;
            break;
          }
        }
      }

      // 加载新消息
      setState(() {
        if (lastVisibleIndex >= 0 &&
            lastVisibleIndex < Data.friendMessage.length - 1) {
          List<dynamic> newMessages =
              Data.friendMessage.sublist(lastVisibleIndex + 1);
          _visibleMessages.addAll(newMessages);
        } else if (lastVisibleIndex == -1) {
          _visibleMessages = Data.friendMessage.length > _pageSize
              ? Data.friendMessage
                  .sublist(Data.friendMessage.length - _pageSize)
              : [...Data.friendMessage];
        }

        if (_isAtBottom) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });
        }
      });
    }
  }

  void _debouncedUpdateMessages() {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _updateMessages();
    });
  }

  Timer? timer;
  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (friendOnOpen.isNotEmpty) {
        socket.send(
          '{"type":"get_friend_message","user_id":"$friendOnOpen", "password":"${Config.password}"}',
        );
        _debouncedUpdateMessages();
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _debounceTimer?.cancel();
    myController.dispose();
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    friendOnOpen = '';
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
                  itemCount: Data.friendList.length,
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return Container(
                        color: Data.friendList[index]['user_id'].toString() ==
                                friendOnOpen
                            ? Config.user['color'] == 'default' ||
                                    Config.user['color'] == 'light'
                                ? const Color.fromRGBO(0, 153, 255, 1)
                                : const Color.fromRGBO(147, 112, 219, 1)
                            : Colors.transparent,
                        child: ListTile(
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
                                color: Data.friendList[index]['user_id']
                                            .toString() ==
                                        friendOnOpen
                                    ? Colors.white
                                    : Config.user['color'] == 'default' ||
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
                            setState(() {
                              friendOnOpen =
                                  Data.friendList[index]['user_id'].toString();
                              Data.friendMessage = [];
                              _visibleMessages = [];
                              _hasMoreData = true;
                              socket.send(
                                '{"type":"get_friend_message","user_id":"${Data.friendList[index]['user_id'].toString()}", "password":"${Config.password}"}',
                              );
                              Future.delayed(const Duration(milliseconds: 500),
                                  () {
                                _loadInitialMessages();
                              });
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
              child: friendOnOpen.isEmpty
                  ? Container(
                      alignment: Alignment.center,
                      child: const Text(
                        'Select a friend to chat',
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
                              child: Stack(
                                children: [
                                  ListView.builder(
                                    controller: _scrollController,
                                    itemCount: _visibleMessages.length + 1,
                                    shrinkWrap: false,
                                    padding: const EdgeInsets.all(24),
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    itemBuilder: (context, index) {
                                      if (index == 0) {
                                        return _isLoading
                                            ? const SizedBox(
                                                height: 60,
                                              )
                                            : _hasMoreData
                                                ? const SizedBox(height: 20)
                                                : const Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Center(
                                                      child: Text(
                                                        '没有更多了',
                                                        style: TextStyle(
                                                          color: Colors.grey,
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ),
                                                  );
                                      }

                                      final data = _visibleMessages[index - 1];
                                      final userId =
                                          data['sender']['user_id'].toString();

                                      return MessageBubble(
                                        message: data,
                                        isCurrentUser:
                                            userId == Data.botInfo['id'],
                                        onResend: () async {
                                          setState(() {
                                            socket.send(
                                              '{"type":"send_private_msg","user_id":"$friendOnOpen","message":"${data['message'].toString().replaceAll('\n', '\\n')}","password":"${Config.password}"}',
                                            );
                                            socket.send(
                                              '{"type":"get_friend_message","user_id":"$friendOnOpen", "password":"${Config.password}"}',
                                            );
                                          });
                                        },
                                      );
                                    },
                                  ),
                                  if (_visibleMessages.isEmpty)
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                ],
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
                                                  '{"type":"send_private_msg","user_id":"$friendOnOpen","message":"$messageText","password":"${Config.password}"}',
                                                );
                                              });
                                              setState(() {
                                                socket.send(
                                                  '{"type":"get_friend_message","user_id":"$friendOnOpen", "password":"${Config.password}"}',
                                                );
                                              });
                                              myController.clear();
                                              Future.delayed(
                                                  const Duration(
                                                      milliseconds: 300), () {
                                                _scrollToBottom();
                                              });
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
