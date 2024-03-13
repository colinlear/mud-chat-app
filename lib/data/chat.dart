import 'package:isar/isar.dart';

part 'chat.g.dart';

@collection
class ChatMessage {
  Id id = Isar.autoIncrement; // you can also use id = null to auto increment

  @Index(composite: [CompositeIndex('timestamp')])
  late int userid;

  late DateTime timestamp;

  DateTime? readStamp;

  late String username;
  late String message;

  @Index(composite: [CompositeIndex('userid')])
  String? status;
}
