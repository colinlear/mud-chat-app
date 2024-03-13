import 'package:aachat/chat/chat_screen.dart';
import 'package:aachat/data/user.dart';
import 'package:aachat/services/connection_service.dart';
import 'package:aachat/services/data_service.dart';
import 'package:aachat/services/services.dart';
import 'package:aachat/users/user_list.dart';
import 'package:aachat/widgets/connection_icon.dart';
import 'package:flutter/material.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final connectionService = getIt<ConnectionService>();
  final dataService = getIt<DataService>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ancient Anguish"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        automaticallyImplyLeading: false,
        actions: const [
          ConnectionStatusIcon(),
        ],
      ),
      body: const UserList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text("New Conversation"),
              content: SingleChildScrollView(
                child: StreamBuilder(
                  initialData: connectionService.onlineUserList,
                  stream: connectionService.onlineUsers,
                  builder: (context, snapshot) {
                    final existingUsers = <String>{};
                    for (final user in dataService.listUsers()) {
                      existingUsers.addAll(user.usernames);
                    }
                    final newUsers = snapshot.data!
                        .where((username) =>
                            !existingUsers.contains(username.toLowerCase()))
                        .toList()
                      ..sort();
                    return Column(
                      children: newUsers
                          .map(
                            (username) => ListTile(
                              onTap: () async {
                                final user = UserGroup()
                                  ..name = username
                                  ..usernames = [username.toLowerCase()]
                                  ..lastSeen = DateTime.now();
                                await dataService.addUser(user);
                                if (context.mounted) {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ChatScreen(user: user),
                                    ),
                                  );
                                }
                              },
                              leading: const Icon(Icons.person),
                              title: Text(username),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text("Cancel"),
                )
              ],
            ),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}
