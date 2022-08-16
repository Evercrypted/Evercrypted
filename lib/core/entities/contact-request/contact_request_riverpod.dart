import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_service.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//-- riverpods
class SentContactRequestRiverpod {
  late List<ContactRequest> sentRequests;

  final ContactRequestService _contactRequestService = ContactRequestService();

  setSentRequests(String userId) {
    _contactRequestService.getSentContactRequests(userId).then((value) {
      sentRequests = value;
    });
  }
}

class ReceivedContactRequestRiverpod {
  late Stream<List<ContactRequest>> receivedstream;

  final ContactRequestService _contactRequestService = ContactRequestService();

  setReceivedRequests(String userId) {
    receivedstream = _contactRequestService.getReceivedContactRequests(userId);
  }
}

//-- providers
final sentRequestsProvider = Provider<SentContactRequestRiverpod>((ref) {
  return SentContactRequestRiverpod();
});

final receivedRequestsProvider = StreamProvider<List<ContactRequest>>((ref) {
  final riverpod = ReceivedContactRequestRiverpod();
  final user = FirebaseAuth.instance.currentUser;
  riverpod.setReceivedRequests(user!.uid);
  return riverpod.receivedstream;
});
