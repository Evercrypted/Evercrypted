import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';

class ContactRequestService {
  final _contactRequestCollection =
      FirebaseFirestore.instance.collection('profiles');

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

  Stream<List<ContactRequest>> getReceivedContactRequests(String userId) {
    var contactRequests = _contactRequestCollection
        .where('recipientId', isEqualTo: userId)
        .orderBy('timeSent', descending: true);
    return contactRequests.snapshots().map(
          (snapshot) => snapshot.docs.map((doc) {
            return ContactRequest.fromJson(doc.id, doc.data());
          }).toList(),
        );
  }

  Future<List<ContactRequest>> getSentContactRequests(String userId) async {
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
