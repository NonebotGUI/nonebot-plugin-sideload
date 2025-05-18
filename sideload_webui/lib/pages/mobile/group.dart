// ignore_for_file: avoid_web_libraries_in_flutter

import 'dart:async';
import 'package:provider/provider.dart';
import 'package:sideload_webui/main.dart';
import 'package:sideload_webui/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:sideload_webui/utils/global.dart';

class ChatGroupMobile extends StatefulWidget {
  const ChatGroupMobile({super.key});

  @override
  State<ChatGroupMobile> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<ChatGroupMobile> {
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
    if (Data.groupMessage.isEmpty) return;

    setState(() {
      _visibleMessages = Data.groupMessage.length > _pageSize
          ? Data.groupMessage.sublist(Data.groupMessage.length - _pageSize)
          : [...Data.groupMessage];

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

    int endIndex = Data.groupMessage.indexOf(_visibleMessages.first);
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
          Data.groupMessage.sublist(startIndex, endIndex);

      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _visibleMessages.insertAll(0, moreMessages);
            _isLoading = false;
            if (startIndex == 0) {
              _hasMoreData = false;
            }
          });

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
    if (Data.groupMessage.isEmpty) return;

    if (_visibleMessages.isEmpty) {
      _loadInitialMessages();
      return;
    }

    // 检查是否有新消息
    if (Data.groupMessage.isNotEmpty &&
        (_visibleMessages.isEmpty ||
            Data.groupMessage.last != _visibleMessages.last)) {
      int lastVisibleIndex = -1;
      if (_visibleMessages.isNotEmpty) {
        for (int i = Data.groupMessage.length - 1; i >= 0; i--) {
          if (Data.groupMessage[i] == _visibleMessages.last) {
            lastVisibleIndex = i;
            break;
          }
        }
      }

      // 加载新消息
      setState(() {
        if (lastVisibleIndex >= 0 &&
            lastVisibleIndex < Data.groupMessage.length - 1) {
          List<dynamic> newMessages =
              Data.groupMessage.sublist(lastVisibleIndex + 1);
          _visibleMessages.addAll(newMessages);
        } else if (lastVisibleIndex == -1) {
          _visibleMessages = Data.groupMessage.length > _pageSize
              ? Data.groupMessage.sublist(Data.groupMessage.length - _pageSize)
              : [...Data.groupMessage];
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
      if (groupOnOpen.isNotEmpty) {
        socket.send(
          '{"type":"get_group_message","group_id":"$groupOnOpen", "password":"${Config.password}"}',
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
    groupOnOpen = '';
    groupOnOpenName = '';
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
            Text(groupOnOpenName, style: const TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          tooltip: '返回',
          onPressed: () {
            groupOnOpen = '';
            groupOnOpenName = '';
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
                child: _visibleMessages.isEmpty && !_isLoading
                    ? const Center(child: Text(''))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _visibleMessages.length + 1,
                        shrinkWrap: false,
                        padding: const EdgeInsets.all(16),
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _isLoading
                                ? const SizedBox(
                                    height: 60,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  )
                                : _hasMoreData
                                    ? const SizedBox(height: 10)
                                    : const Padding(
                                        padding: EdgeInsets.all(8.0),
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
                          final userId = data['sender']['user_id'].toString();

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
                                '{"type":"send_group_msg","group_id":"$groupOnOpen","message":"$messageText","password":"${Config.password}"}',
                              );
                            });
                            setState(() {
                              socket.send(
                                '{"type":"get_group_message","group_id":"$groupOnOpen", "password":"${Config.password}"}',
                              );
                            });
                            myController.clear();
                            Future.delayed(const Duration(milliseconds: 300),
                                () {
                              _scrollToBottom();
                            });
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
