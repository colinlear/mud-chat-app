import 'dart:async';

import 'package:aachat/services/connection_service.dart';
import 'package:aachat/services/services.dart';
import 'package:aachat/users/users_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

const usernameKey = "username";
const passwordKey = "password";

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  State<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final prefs = getIt<SharedPreferences>();
  final connectionService = getIt<ConnectionService>();

  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  StreamSubscription<String>? connectionListener;

  bool authenticating = false;

  @override
  void initState() {
    connectionListener = connectionService.connectionStatus.listen(
      (event) async {
        if (event == "not-logged-in") {
          Navigator.popUntil(context, ModalRoute.withName('/'));
          final savedUsername = prefs.getString(usernameKey);
          final savedPassword = prefs.getString(passwordKey);
          if (savedUsername != null && savedPassword != null) {
            connectionService.login(savedUsername, savedPassword);
          }
          return;
        }
        if (event == "password-failed") {
          setState(() {
            prefs.remove(passwordKey);
          });
          return;
        }
        if (authenticating) {
          if (event == "connected") {
            // save successful login via form...
            await prefs.setString(usernameKey, usernameController.text);
            await prefs.setString(passwordKey, passwordController.text);
            setState(() {
              authenticating = false;
            });
          }
        }
        if (event == "connected" && mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserListScreen()),
          );
        }
      },
    );
    usernameController.text = prefs.getString(usernameKey) ?? "";
    super.initState();
  }

  @override
  void dispose() {
    connectionListener?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final savedUsername = prefs.getString(usernameKey);
    final savedPassword = prefs.getString(passwordKey);

    return StreamBuilder<Object>(
        initialData: "not-logged-in",
        stream: connectionService.connectionStatus,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (savedUsername != null &&
              savedPassword != null &&
              snapshot.data == "not-login-in") {
            return const Center(child: CircularProgressIndicator());
          }
          return Padding(
            padding: const EdgeInsets.all(15.0),
            child: AutofillGroup(
              child: Column(
                children: [
                  TextField(
                    autofillHints: const [AutofillHints.username],
                    controller: usernameController,
                    keyboardType: TextInputType.name,
                    decoration: const InputDecoration(hintText: "Username"),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    autofillHints: const [AutofillHints.password],
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(hintText: "Password"),
                  ),
                  const SizedBox(height: 25),
                  const SizedBox(height: 25),
                  ElevatedButton(
                    onPressed: () async {
                      setState(() {
                        authenticating = true;
                      });
                      connectionService.login(
                          usernameController.text, passwordController.text);
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      backgroundColor: theme.colorScheme.onPrimary,
                    ),
                    child: const Text("Login"),
                  )
                ],
              ),
            ),
          );
        });
  }
}
