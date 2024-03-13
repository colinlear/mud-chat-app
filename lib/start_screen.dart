import 'package:aachat/login/login_screen.dart';
import 'package:aachat/services/connection_service.dart';
import 'package:aachat/services/services.dart';
import 'package:aachat/users/users_screen.dart';
import 'package:flutter/material.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final connectionService = getIt<ConnectionService>();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: connectionService.connectionStatus,
        builder: (content, snapshot) {
          if (snapshot.hasData) {
            if (snapshot.data == "not-logged-in") {
              return const LoginScreen();
            } else {
              return const UserListScreen();
            }
          }
          return const CircularProgressIndicator();
        });
  }
}
