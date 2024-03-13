import 'dart:developer';

import 'package:aachat/data/chat.dart';
import 'package:aachat/data/user.dart' as userob;
import 'package:aachat/services/connection_service.dart';
import 'package:aachat/services/data_service.dart';
import 'package:aachat/services/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart' hide TextMessage;
import 'package:flutter_chat_types/flutter_chat_types.dart';

class ChatMessages extends StatefulWidget {
  final userob.UserGroup user;
  const ChatMessages({
    super.key,
    required this.user,
  });

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  final connectionService = getIt<ConnectionService>();
  final dataService = getIt<DataService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder(
      stream: dataService.watchMessages(),
      builder: (context, snapshot) {
        final messages = dataService.getMessages(widget.user);
        Future.delayed(const Duration(seconds: 2), () {
          // mark messages as read / failed etc...
          dataService.isar.writeTxn(() async {
            for (final mess in messages) {
              if (mess.status == "sending" &&
                  DateTime.now()
                      .subtract(const Duration(seconds: 30))
                      .isAfter(mess.timestamp)) {
                mess.status = "failed";
                await dataService.isar.chatMessages.put(mess);
              } else if (mess.status == "unread") {
                mess.status = "read";
                await dataService.isar.chatMessages.put(mess);
              } else if (mess.status == "failed" &&
                  DateTime.now()
                      .subtract(const Duration(hours: 24))
                      .isAfter(mess.timestamp)) {
                dataService.isar.chatMessages.delete(mess.id);
              } else if (mess.status == null) {
                mess.status = mess.username == "you" ? "delivered" : "read";
                await dataService.isar.chatMessages.put(mess);
              }
            }
            final lastReadTimestamp = messages.firstOrNull?.timestamp;
            if (lastReadTimestamp != null &&
                (widget.user.lastRead == null ||
                    lastReadTimestamp.isAfter(widget.user.lastRead!))) {
              log("Last Read: ${lastReadTimestamp.toIso8601String()} ${widget.user.lastMessage?.toIso8601String()}");
              widget.user.lastRead = lastReadTimestamp;
              await dataService.isar.userGroups.put(widget.user);
            }
          });
        });
        return Chat(
          theme: DarkChatTheme(
            inputBorderRadius: BorderRadius.zero,
            inputBackgroundColor: theme.colorScheme.secondaryContainer,
            inputTextColor: theme.colorScheme.onSecondaryContainer,
          ),
          messages: messages
              .map(
                (m) => TextMessage(
                  id: m.id.toString(),
                  author: User(
                    id: m.username,
                    firstName: m.username,
                  ),
                  text: m.message,
                  status: m.status == "sending"
                      ? Status.sending
                      : m.status == "failed"
                          ? Status.error
                          : m.status == "delivered"
                              ? Status.delivered
                              : m.status == "read"
                                  ? Status.seen
                                  : null,
                ),
              )
              .toList(),
          onSendPressed: (message) async {
            final messageid = await dataService.addMessage(
              ChatMessage()
                ..message = message.text.trim()
                // place in the future so reordering is less
                ..timestamp = DateTime.now().add(const Duration(seconds: 5))
                ..userid = widget.user.id
                ..username = "you"
                ..status = "sending",
            );
            connectionService.sendTell(widget.user, message.text.trim());
            Future.delayed(const Duration(seconds: 5), () async {
              final sent = await dataService.getMessage(messageid);
              if (sent?.status == "sending") {
                sent!.status = "failed";
                await dataService.addMessage(sent);
              }
            });
          },
          onMessageLongPress: (context, mess) async {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text("Delete message"),
                  content: const Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Message will be permanently deleted",
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        final id = int.tryParse(mess.id);
                        if (id != null) {
                          dataService.deleteMessage(id);
                        }
                        if (context.mounted) {
                          Navigator.pop(context);
                        }
                      },
                      child: const Text("Delete!"),
                    ),
                  ],
                );
              },
            );
          },
          onMessageStatusTap: (context, mess) async {
            log("tap message ${mess.status}");
            if (mess.status == Status.error) {
              showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Failed to send"),
                      content: const Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Message not sent. This could be for a number of reasons.",
                          ),
                          SizedBox(height: 15),
                          Text(
                            " • Recipient logged out.",
                          ),
                          Text(
                            " • Recipient linkdead.",
                          ),
                          Text(
                            " • Recipient doesn't exist.",
                          ),
                          Text(
                            " • Message blocked",
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () async {
                            final id = int.tryParse(mess.id);
                            if (id != null) {
                              final savedMess =
                                  await dataService.getMessage(id);
                              if (savedMess != null &&
                                  savedMess.status == "failed") {
                                savedMess
                                  ..timestamp = DateTime.now()
                                      .add(const Duration(seconds: 5))
                                  ..status = "sending";
                                await dataService.addMessage(savedMess);
                                connectionService.sendTell(
                                  widget.user,
                                  savedMess.message,
                                );
                              }
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Text("Retry"),
                        ),
                      ],
                    );
                  });
            }
          },
          user: const User(id: "you"),
        );
      },
    );
  }
}
