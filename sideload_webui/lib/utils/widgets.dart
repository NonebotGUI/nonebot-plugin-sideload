import 'dart:html' as html;
import 'dart:ui' as ui;

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
    final colorScheme = Theme.of(context).colorScheme;
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
                      '${html.window.location.protocol}//${html.window.location.hostname}:${Uri.base.port}/sideload/image/$msgId',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
              child: Image.network(
                '${html.window.location.protocol}//${html.window.location.hostname}:${Uri.base.port}/sideload/image/$msgId',
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
                color: isCurrentUser 
                  ? colorScheme.onPrimaryContainer 
                  : colorScheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.4,
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
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colorScheme.outline.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              "$nickname撤回了一条消息",
              style: TextStyle(
                fontSize: 12, 
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      );
    }

    if (isCurrentUser) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: Text(
                    nickname,
                    style: TextStyle(
                      fontSize: 13, 
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                         filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFE94B4B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: buildMessageContent(),
                      ),
                    ),
                  ),
                ),
                Row(
                  children: [
                    if (Config.user['display_time'])
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child: Text(
                          data['time'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
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
                '${html.window.location.protocol}//${html.window.location.hostname}:${Uri.base.port}/sideload/avatars/user/$userId.png',
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: colorScheme.primaryContainer,
                child: CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage(
                    '${html.window.location.protocol}//${html.window.location.hostname}:${Uri.base.port}/sideload/avatars/user/$userId.png',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                  child: Text(
                    nickname,
                    style: TextStyle(
                      fontSize: 13, 
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: buildMessageContent(),
                          ),
                        ),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 4, right: 8),
                        child: Text(
                          data['time'].toString(),
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                            fontWeight: FontWeight.w400,
                          ),
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
          backgroundColor: WidgetStateProperty.all(
            const Color(0xFFE94B4B),
          ),
          shape: WidgetStateProperty.all(const CircleBorder()),
          iconSize: WidgetStateProperty.all(24),
          minimumSize: WidgetStateProperty.all(const Size(32, 32)),
        ),
        child: const Text('+1', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
