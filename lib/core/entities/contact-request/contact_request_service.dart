import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContactRequestService {
  final _contactRequestCollection =
      FirebaseFirestore.instance.collection('contactRequests');

  Future<void> createContactRequest(ContactRequest cRequest) {
    return _contactRequestCollection.add(cRequest.toJson()).then(
      (resp) {
        resp.get().then((doc) {
          print('Contact Request Created');
          print(doc.data());
        });
      },
    );
  }

  Future<void> updateContactRequest(ContactRequest cRequest) {
    return _contactRequestCollection
        .doc(cRequest.fbUid)
        .update(cRequest.toJson())
        .then(
      (_) {
        print('Profile updated');
      },
    );
  }

  Future<void> deleteContactRequest(ContactRequest cRequest) {
    return _contactRequestCollection.doc(cRequest.fbUid).delete().then(
      (_) {
        print('Profile deleted');
      },
    );
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getReceivedContactRequests() {
    final userEmail = FirebaseAuth.instance.currentUser?.email;
    var contactRequests = _contactRequestCollection
        .where('recipientEmail', isEqualTo: userEmail)
        .orderBy('timeSent', descending: true);
    return contactRequests.snapshots();
  }

  Future<List<ContactRequest>> getSentContactRequests() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    var contactRequests = _contactRequestCollection
        .where('authorId', isEqualTo: userId)
        .orderBy('timeSent', descending: true);
    return contactRequests.get().then(
          (snapshot) => snapshot.docs.map((doc) {
            return ContactRequest.fromJson(doc.id, doc.data());
          }).toList(),
        );
  }
}
