import 'package:aachat/chat/chat_messages.dart';
import 'package:aachat/data/user.dart';
import 'package:aachat/services/connection_service.dart';
import 'package:aachat/services/data_service.dart';
import 'package:aachat/services/services.dart';
import 'package:aachat/users/user_status_online.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final UserGroup user;
  const ChatScreen({
    super.key,
    required this.user,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final connectionService = getIt<ConnectionService>();

  final dataService = getIt<DataService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat.yMd().add_Hms();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        title: Text(widget.user.name),
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => StreamBuilder(
                  stream: dataService.watchUsers(),
                  builder: (context, snapshot) {
                    return SimpleDialog(
                      children: [
                        Icon(
                          Icons.person,
                          color: theme.colorScheme.primary,
                          size: 70,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.user.name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          "[${widget.user.usernames.join(", ")}]",
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 10),
                        StreamBuilder(
                          initialData:
                              connectionService.isUserOnline(widget.user),
                          stream: connectionService.isOnline(widget.user),
                          builder: (context, snapshot) => Text(
                            snapshot.data == true
                                ? "Currently online"
                                : widget.user.lastSeen != null
                                    ? "Last seen: ${dateFormat.format(widget.user.lastSeen!)}"
                                    : "Never Online",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: snapshot.data == true
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              );
            },
            icon: UserStatusOnlineIcon(
              user: widget.user,
              inverseColors: true,
            ),
          ),
        ],
      ),
      body: ChatMessages(
        user: widget.user,
      ),
    );
  }
}
