import 'package:aachat/chat/chat_screen.dart';
import 'package:aachat/data/user.dart';
import 'package:aachat/services/connection_service.dart';
import 'package:aachat/services/data_service.dart';
import 'package:aachat/services/services.dart';
import 'package:aachat/users/user_status_online.dart';
import 'package:flutter/material.dart';

class UserList extends StatefulWidget {
  const UserList({super.key});

  @override
  State<UserList> createState() => _UserListState();
}

class _UserListState extends State<UserList> {
  final dataService = getIt<DataService>();
  final connectionService = getIt<ConnectionService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return StreamBuilder(
      stream: dataService.watchUsers(),
      builder: (context, snapshot) {
        final users = dataService.listUsers()
          ..sort((a, b) {
            final aOnline = connectionService.isUserOnline(a);
            final bOnline = connectionService.isUserOnline(b);
            if (aOnline == bOnline) {
              return a.name.compareTo(b.name);
            }
            if (aOnline) {
              return -1;
            }
            return 1;
          });
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final key = GlobalObjectKey(user);
            return ListTile(
              key: key,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(user: user),
                  ),
                );
              },
              onLongPress: () {
                final RenderBox renderBox =
                    key.currentContext!.findRenderObject() as RenderBox;
                var offset = renderBox.localToGlobal(Offset.zero);
                debugPrint('Widget position: ${offset.dx} ${offset.dy}');
                var rect = Rect.fromLTWH(offset.dx / 3.1, offset.dy * 1.05,
                    renderBox.size.width, renderBox.size.height);
                final menuPosition =
                    RelativeRect.fromSize(rect, const Size(200, 0));
                showMenu(context: context, position: menuPosition, items: [
                  PopupMenuItem(
                    child: const Text("Delete User"),
                    onTap: () {
                      dataService.isar.writeTxn(() async {
                        await dataService.isar.userGroups.delete(user.id);
                      });
                    },
                  ),
                ]);
              },
              title: Text(user.name),
              subtitle: Text(
                user.usernames.join(", "),
              ),
              leading: StreamBuilder<bool>(
                  initialData: connectionService.isUserOnline(user),
                  stream: connectionService.isOnline(user),
                  builder: (context, snapshot) {
                    return CircleAvatar(
                      backgroundColor: user.lastRead == null ||
                              user.lastMessage?.isAfter(user.lastRead!) == true
                          ? Colors.blue.shade700
                          : Colors.transparent,
                      radius: 23,
                      child: CircleAvatar(
                        backgroundColor: snapshot.data == true
                            ? theme.colorScheme.secondaryContainer
                            : Colors.grey,
                        foregroundColor: theme.colorScheme.onSecondaryContainer,
                        child: Text(user.name.characters.first),
                      ),
                    );
                  }),
              trailing: UserStatusOnlineIcon(
                user: user,
              ),
            );
          },
        );
      },
    );
  }
}
