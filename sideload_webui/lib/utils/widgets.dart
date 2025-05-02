import 'dart:html';

import 'package:flutter/material.dart';
import 'package:sideload_webui/utils/global.dart';

class MessageBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isCurrentUser;
  final Function()? onResend;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isCurrentUser,
    this.onResend,
  });

  @override
  Widget build(BuildContext context) {
    final data = message;
    final sender = data['sender'];
    final nickname = sender['nickname'].toString();
    final userId = sender['user_id'];
    final isRecalled = data['drawed'] == "1";
    final hideIfRecalled = !Config.user["anti_recall"] && isRecalled;
    final messageType = data['type'] ?? "text";
    final messageContent = data['message'].toString();
    final msgId = data['msg_id'].toString();

    Widget buildMessageContent() {
      switch (messageType) {
        case "image":
          return Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.4,
              maxHeight: 300,
            ),
            child: InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    child: Image.network(
                      '${window.location.protocol}//${window.location.hostname}:${Uri.base.port}/sideload/image/$msgId',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
              child: Image.network(
                '${window.location.protocol}//${window.location.hostname}:${Uri.base.port}/sideload/image/$msgId',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 200,
                    height: 150,
                    alignment: Alignment.center,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 150,
                    height: 100,
                    color: Colors.grey[300],
                    child: const Icon(Icons.broken_image, size: 40),
                  );
                },
              ),
            ),
          );
        case "text":
        default:
          return Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.6,
            ),
            child: SelectableText(
              messageContent,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : null,
              ),
              toolbarOptions: const ToolbarOptions(
                copy: true,
                selectAll: true,
                cut: false,
                paste: false,
              ),
            ),
          );
      }
    }

    if (hideIfRecalled) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "$nickname撤回了一条消息",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (isCurrentUser) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Card(
                  color: messageType == "text"
                      ? const Color.fromRGBO(0, 153, 255, 1)
                      : null,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: buildMessageContent(),
                  ),
                ),
                Row(
                  children: [
                    if (Config.user['display_time'])
                      Text(
                        data['time'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (Config.user['display_time'] && isRecalled)
                      const SizedBox(width: 10),
                    if (isRecalled)
                      const Text(
                        "已撤回",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              backgroundImage: NetworkImage(
                '${window.location.protocol}//${window.location.hostname}:${Uri.base.port}/sideload/avatars/user/$userId.png',
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundImage: NetworkImage(
                '${window.location.protocol}//${window.location.hostname}:${Uri.base.port}/sideload/avatars/user/$userId.png',
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nickname,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: buildMessageContent(),
                      ),
                    ),
                    if (Config.user['+1'] && !isRecalled)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 2.0),
                        child: ResendButton(onPressed: onResend),
                      ),
                  ],
                ),
                if (Config.user['display_time'] || isRecalled)
                  const SizedBox(height: 2),
                Row(
                  children: [
                    if (Config.user['display_time'])
                      Text(
                        data['time'].toString(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    if (Config.user['display_time'] && isRecalled)
                      const SizedBox(width: 10),
                    if (isRecalled)
                      const Text(
                        "已撤回",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
    }
  }
}

class ResendButton extends StatelessWidget {
  final Function()? onPressed;
  const ResendButton({Key? key, this.onPressed}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: ElevatedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.all(
            Config.user['color'] == 'default' || Config.user['color'] == 'light'
                ? const Color.fromRGBO(0, 153, 255, 1)
                : const Color.fromRGBO(147, 112, 219, 1),
          ),
          shape: MaterialStateProperty.all(const CircleBorder()),
          iconSize: MaterialStateProperty.all(24),
          minimumSize: MaterialStateProperty.all(const Size(32, 32)),
        ),
        child: const Text('+1', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
