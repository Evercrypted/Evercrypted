import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MessageService {
  Stream<QuerySnapshot<Map<String, dynamic>>> startListeningAndWritingToDB(
      String chatRoomId, int lastMessageTime) {
    final messagesCollection = FirebaseFirestore.instance
        .collection('chatRooms')
        .doc(chatRoomId)
        .collection('messages');
    final uId = FirebaseAuth.instance.currentUser?.uid;
    var contactRequests = messagesCollection
        .where('downloadedBy', arrayContains: uId)
        .orderBy('lastMessageTime', descending: true);
    return contactRequests.snapshots();
  }
}
