import 'dart:async';
import 'dart:developer';

import 'package:aachat/login/login_form.dart';
import 'package:aachat/services/connection_service.dart';
import 'package:aachat/services/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web_socket_client/web_socket_client.dart';

class ConnectionStatusIcon extends StatefulWidget {
  const ConnectionStatusIcon({super.key});

  @override
  State<ConnectionStatusIcon> createState() => _ConnectionStatusIconState();
}

class _ConnectionStatusIconState extends State<ConnectionStatusIcon> {
  final prefs = getIt<SharedPreferences>();
  final connectionService = getIt<ConnectionService>();

  late StreamSubscription connected;

  @override
  void initState() {
    connected = connectionService.connection.listen((state) {
      log("Connection $state");
      if (state is Disconnected) {
        log("Disconnected ${state.reason} - ${state.code} ${state.error}");
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    connected.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          onTap: () async {
            await prefs.remove(passwordKey);
            connectionService.logout();
          },
          child: const Text("Logout"),
        ),
      ],
      icon: StreamBuilder(
          stream: connectionService.connection,
          builder: (context, snapshot) {
            if (connectionService.connected) {
              return StreamBuilder<Object>(
                initialData: connectionService.connection.state,
                stream: connectionService.connectionStatus,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Icon(
                      Icons.question_mark,
                      color: theme.colorScheme.onPrimary,
                    );
                  }
                  final status = snapshot.data!;
                  switch (status) {
                    case "connected":
                      return Icon(
                        Icons.cloud,
                        color: theme.colorScheme.onPrimary,
                      );
                    case "disconnected":
                      return Icon(
                        Icons.cloud,
                        color: theme.colorScheme.error,
                      );
                  }
                  return Icon(
                    Icons.cloud,
                    color: theme.colorScheme.onPrimary,
                  );
                },
              );
            }
            if (connectionService.connecting) {
              return CircularProgressIndicator(
                color: theme.colorScheme.onPrimary,
              );
            }
            return Icon(
              Icons.cloud_off,
              color: theme.colorScheme.error,
            );
          }),
    );
  }
}
