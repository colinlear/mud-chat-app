import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:aachat/data/user.dart';
import 'package:aachat/services/data_service.dart';
import 'package:aachat/services/services.dart';
import 'package:web_socket_client/web_socket_client.dart';

class ConnectionService {
  final dataService = getIt<DataService>();

  final Uri url;
  late WebSocket socket;
  String loginStatus = "";
  Set<String> onlineUserList = {};
  Set<String> onlineUserNameList = {};

  Connection get connection => socket.connection;
  Stream<dynamic> get messages => socket.messages;

  final _connectionStatusController = StreamController<String>.broadcast();
  Stream<String> get connectionStatus => _connectionStatusController.stream;

  final _onlineUsersController = StreamController<Set<String>>.broadcast();
  Stream<Set<String>> get onlineUsers => _onlineUsersController.stream;

  bool isUserOnline(UserGroup user) {
    return onlineUserNameList.intersection(Set.from(user.usernames)).isNotEmpty;
  }

  Stream<bool> isOnline(UserGroup user) =>
      _onlineUsersController.stream.map<bool>((event) {
        return event
            .map((e) => e.toLowerCase())
            .toSet()
            .intersection(Set.from(user.usernames))
            .isNotEmpty;
      });

  bool get connected =>
      connection.state is Connected || connection.state is Reconnected;

  bool get connecting =>
      connection.state is Connecting || connection.state is Reconnecting;

  ConnectionService(this.url) {
    socket = WebSocket(
      url,
      backoff: const ConstantBackoff(Duration(seconds: 2)),
      pingInterval: const Duration(seconds: 2),
      timeout: const Duration(seconds: 5),
    );
    socket.messages.listen((event) {
      log("Socket Message $event");
      final json = jsonDecode(event);
      if (json["status"] != null) {
        loginStatus = json["status"];
        _connectionStatusController.add(loginStatus);
      }
      if (json["event"] == "users") {
        onlineUserList = Set.from(json["users"]);
        onlineUserNameList = onlineUserList.map((e) => e.toLowerCase()).toSet();
        _onlineUsersController.add(onlineUserList);
      }
      if (json["message"] != null) {
        dataService.handleMessage(json["message"],
            json['timestamp'] ?? DateTime.now().millisecondsSinceEpoch);
      }
    });
  }

  void login(String username, String password) {
    final modified = dataService
        .listUsers()
        .map((u) => u.lastMessage ?? DateTime.fromMillisecondsSinceEpoch(0))
        .toList()
      ..sort();

    log("Modified $modified");

    socket.send(
      json.encode(
        {
          "action": "connect",
          "username": username,
          "password": password,
          "pushToken": username,
          "lastTimestamp": modified.lastOrNull?.millisecondsSinceEpoch ?? 0,
        },
      ),
    );
  }

  void logout() {
    socket.send(
      json.encode(
        {
          "action": "disconnect",
        },
      ),
    );
  }

  void sendTell(UserGroup user, String message) {
    socket.send(
      json.encode(
        {
          "action": "sendMessage",
          "username": user.usernames,
          "message": message,
        },
      ),
    );
  }
}
