import 'dart:collection';

import 'package:flutter/widgets.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareIntentQueue extends ChangeNotifier {
  final Map<String, Queue<SharedMediaFile>> _queues = {};

  ShareIntentQueue._();

  static final instance = ShareIntentQueue._();

  void add(
    SharedMediaFile file, {
    required String userId,
  }) {
    debugPrint("Adding received file to queue: ${file.path}");
    _getQueue(userId).add(file);
    notifyListeners();
  }

  void addAll(
    Iterable<SharedMediaFile> files, {
    required String userId,
  }) {
    debugPrint(
        "Adding received files to queue: ${files.map((e) => e.path).join(",")}");
    _getQueue(userId).addAll(files);
    notifyListeners();
  }

  SharedMediaFile? pop(String userId) {
    if (userHasUnhandlesFiles(userId)) {
      return _getQueue(userId).removeFirst();
      // Don't notify listeners, only when new item is added.
    } else {
      return null;
    }
  }

  Queue<SharedMediaFile> _getQueue(String userId) {
    if (!_queues.containsKey(userId)) {
      _queues[userId] = Queue<SharedMediaFile>();
    }
    return _queues[userId]!;
  }

  bool userHasUnhandlesFiles(String userId) => _getQueue(userId).isNotEmpty;
}

class UserAwareShareMediaFile {
  final String userId;
  final SharedMediaFile sharedFile;

  UserAwareShareMediaFile(this.userId, this.sharedFile);
}
