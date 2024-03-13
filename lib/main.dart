import 'package:aachat/login/login_screen.dart';
import 'package:aachat/services/services.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl_standalone.dart';

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting(await findSystemLocale(), null);
  await setup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ancient Anguish Chat',
      theme: ThemeData(
        colorSchemeSeed: const Color.fromARGB(255, 102, 130, 86),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color.fromARGB(255, 102, 130, 86),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.dark,
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
