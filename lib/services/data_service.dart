import 'dart:developer';

import 'package:aachat/data/chat.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../data/user.dart';

class DataService {
  late final Isar isar;

  init() async {
    final dir = await getApplicationDocumentsDirectory();
    isar = await Isar.open(
      [UserGroupSchema, ChatMessageSchema],
      directory: dir.path,
    );
    if (isar.userGroups.countSync() == 0) {
      await isar.writeTxn(() async {
        await isar.userGroups.put(
          UserGroup()
            ..name = "Me"
            ..usernames = ["serf"],
        );
      });
    }
  }

  Stream<void> watchUsers() => isar.userGroups.watchLazy();

  List<UserGroup> listUsers() {
    return isar.userGroups.where().sortByName().findAllSync();
  }

  Future<int> addUser(UserGroup user) async {
    return await isar.writeTxn(() => isar.userGroups.put(user));
  }

  Future<ChatMessage?> getMessage(Id id) {
    return isar.chatMessages.get(id);
  }

  List<ChatMessage> getMessages(UserGroup user) {
    return isar.chatMessages
        .where()
        .useridEqualToAnyTimestamp(user.id)
        .sortByTimestampDesc()
        .findAllSync();
  }

  Stream<void> watchMessages() => isar.chatMessages.watchLazy();

  Future<int> addMessage(ChatMessage msg) async {
    return await isar.writeTxn(() => isar.chatMessages.put(msg));
  }

  Future<bool> deleteMessage(Id msgId) async {
    return await isar.writeTxn(() => isar.chatMessages.delete(msgId));
  }

  Future<ChatMessage?> findUnsentMessage(Id? userid, String message) async {
    if (userid == null) return Future.value(null);
    final sending = await isar.chatMessages
        .where()
        .statusUseridEqualTo("sending", userid)
        .sortByTimestamp()
        .findAll();
    final matching = sending
        .where(
          (m) => m.message == message,
        )
        .lastOrNull;
    if (matching != null) return matching;
    final failed = await isar.chatMessages
        .where()
        .statusUseridEqualTo("failed", userid)
        .sortByTimestamp()
        .findAll();
    final errored = failed
        .where(
          (m) => m.message == message,
        )
        .lastOrNull;
    return errored;
  }

  final RegExp messageRegex = RegExp(r'^(.*?) (tells?|says? to) (.*?): (.*)');
  Future<void> handleMessage(String message, int timestamp) async {
    final datetime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final match = messageRegex.firstMatch(message);
    if (match != null) {
      final from = match[1];
      final to = match[3];
      final text = match[4];
      if (text == null || text.trim() == "") {
        log("Empty tell $message");
      }
      final otherUser = from == "You" ? to : from;
      if (otherUser == null) {
        log("Message parsing error $from -> $to ($message)");
        return;
      }
      var user = listUsers()
          .where((u) => u.usernames.contains(otherUser.toLowerCase()))
          .firstOrNull;
      // log("Message from user $user ($otherUser)");

      var existingMessage =
          from == "You" ? await findUnsentMessage(user?.id, text!) : null;
      existingMessage?.status = "delivered";
      existingMessage?.timestamp = datetime;

      user ??= UserGroup()
        ..name = otherUser
        ..usernames = [otherUser.toLowerCase()];

      // log("Adding message to ${user.id}: $from -> $to: $text ($datetime)");
      await isar.writeTxn(() async {
        if (from != "You" &&
            (user!.lastMessage == null ||
                datetime.isAfter(user.lastMessage!))) {
          user.lastMessage = datetime;
        }
        user!.lastSeen = datetime;
        await isar.userGroups.put(user);
        await isar.chatMessages.put(
          existingMessage ?? ChatMessage()
            ..message = text!
            ..timestamp = datetime
            ..status = from == "You" ? "delivered" : "unread"
            ..userid = user.id
            ..username = from!.toLowerCase(),
        );
      });
    } else {
      log("Invalid message '$message'");
    }
  }
}
