import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageService {
  StreamSubscription? listener;

  void startListeningAndWritingToDB(String chatRoomId, int? lastMessageTime) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final messagesCollection = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages');
    final messageRequests = lastMessageTime != null
        ? messagesCollection
            .where('authorId', isNotEqualTo: userId)
            .where('createdAtMSE', isGreaterThan: lastMessageTime)
        : messagesCollection.where('authorId', isNotEqualTo: userId);
    listener = messageRequests.snapshots().listen((event) {
      for (var change in event.docChanges) {
        if (change.type == DocumentChangeType.added) {
          print(change.doc.data());
        }
      }
    });
  }

  void stopListening() {
    listener?.cancel();
  }
}
