import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatService {
  final _chatRoomsCollection =
      FirebaseFirestore.instance.collection('chatRooms');

  Stream<QuerySnapshot<Map<String, dynamic>>> getChatRooms() {
    final uId = FirebaseAuth.instance.currentUser?.uid;
    var contactRequests = _chatRoomsCollection
        .where('participants', arrayContains: uId)
        .orderBy('lastMessageTime', descending: true);
    return contactRequests.snapshots();
  }
}
