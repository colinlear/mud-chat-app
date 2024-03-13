import 'package:aachat/login/login_form.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 40),
            DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.secondaryContainer,
                borderRadius: const BorderRadius.all(Radius.circular(500)),
              ),
              child: SizedBox(
                height: 205,
                width: 205,
                child: Stack(
                  alignment: AlignmentDirectional.center,
                  children: [
                    Positioned(
                      left: 5,
                      bottom: 52,
                      child: Text(
                        "A",
                        style: GoogleFonts.donegalOne(
                          fontSize: 100,
                          height: 1.0,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                    Positioned(
                      bottom: 70,
                      left: 65,
                      child: Text(
                        "NCIENT\n\tNGUISH",
                        style: GoogleFonts.donegalOne(
                          fontSize: 30,
                          height: 1.0,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                        textScaler: TextScaler.noScaling,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text("Ancient Anguish Chat Client"),
            const SizedBox(height: 20),
            const LoginForm(),
          ],
        ),
      ),
    );
  }
}
