import 'package:aachat/data/user.dart';
import 'package:aachat/services/connection_service.dart';
import 'package:aachat/services/services.dart';
import 'package:flutter/material.dart';

class UserStatusOnlineIcon extends StatelessWidget {
  final UserGroup user;
  final bool inverseColors;

  const UserStatusOnlineIcon({
    super.key,
    required this.user,
    this.inverseColors = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final connectionService = getIt<ConnectionService>();
    return StreamBuilder<Object>(
        initialData: connectionService.isUserOnline(user),
        stream: connectionService.isOnline(user),
        builder: (context, snapshot) {
          return Icon(
            Icons.account_circle,
            color: snapshot.data == true
                ? inverseColors
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.primary
                : inverseColors
                    ? Colors.grey.shade400
                    : theme.colorScheme.error,
          );
        });
  }
}
