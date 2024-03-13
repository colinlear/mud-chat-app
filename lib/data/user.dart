import 'package:isar/isar.dart';

part 'user.g.dart';

@collection
class UserGroup {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  late String name;

  late List<String> usernames;

  DateTime? lastMessage;

  DateTime? lastRead;

  DateTime? lastSeen;
}
