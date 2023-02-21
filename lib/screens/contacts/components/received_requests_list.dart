import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_service.dart';
import 'package:evercrypted/screens/contacts/components/pending_request_card.dart';
import 'package:flutter/material.dart';

class ReceivedRequestsList extends StatelessWidget {
  ReceivedRequestsList({Key? key}) : super(key: key);

  final ContactRequestService _contactRequestService = ContactRequestService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: _contactRequestService.getReceivedContactRequests(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Text('Something went wrong');
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Text("Loading");
          }
          List<ContactRequest> receivedRequests =
              snapshot.data!.docs.map((DocumentSnapshot doc) {
            return ContactRequest.fromJson(
                doc.id, doc.data() as Map<String, dynamic>);
          }).toList();
          //
          return ListView.builder(
            itemCount: receivedRequests.length,
            itemBuilder: (context, index) {
              final item = receivedRequests[index];
              return PendingRequestCard(
                isReceived: true,
                message: item.message ?? "",
                email: item.authorEmail ?? "",
                requestSent: item.timeSent ?? DateTime.now(),
                press: () {},
              );
            },
          );
        });
  }
}
