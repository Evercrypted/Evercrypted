import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/entities/contact-request/contact_request_service.dart';

class PendingRequestCard extends StatelessWidget {
  PendingRequestCard({
    super.key,
    this.contactRequest,
    this.isReceived = false,
  });

  final ContactRequest? contactRequest;
  final bool isReceived;

  final ContactRequestService contactRequestService = ContactRequestService();

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.fromLTRB(5, 4, 3, 5),
        decoration: BoxDecoration(
            color:
                Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.25),
            borderRadius: const BorderRadius.all(Radius.circular(20))),
        child: const Icon(
          Icons.person_search,
          color: Colors.white,
          size: 30,
        ),
      ),
      title: Text(
        isReceived
            ? contactRequest!.authorEmail!
            : contactRequest!.recipientEmail!,
        style: TextStyle(
            fontWeight: isReceived && contactRequest!.unread == true
                ? FontWeight.bold
                : FontWeight.normal),
      ),
      onExpansionChanged: (value) {
        if (isReceived && contactRequest!.unread == true) {
          contactRequest!.unread = false;
          contactRequestService.updateUnread(contactRequest!);
        }
      },
      subtitle: Text(
        'Request was ${isReceived ? 'received' : 'sent'} ${contactRequest!.timeSent != null ? timeago.format(contactRequest!.timeSent!) : null}',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge!.color!.withOpacity(0.5),
        ),
      ),
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      backgroundColor: primaryColor,
      iconColor: Colors.white,
      textColor: Colors.white,
      children: [
        if (contactRequest!.message != null)
          Container(
            margin: const EdgeInsets.only(left: 30, right: 30, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Text(
              contactRequest!.message!,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        Container(
          margin: const EdgeInsets.only(left: 30, right: 30, bottom: 10),
          child: Row(
            mainAxisAlignment: isReceived
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.end,
            children: [
              if (isReceived)
                RawMaterialButton(
                  onPressed: () {
                    contactRequestService.acceptContactRequest(contactRequest!);
                  },
                  elevation: 2.0,
                  fillColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30))),
                  child: const Icon(
                    Icons.check,
                    color: primaryColor,
                  ),
                ),
              RawMaterialButton(
                onPressed: () {
                  isReceived
                      ? contactRequestService
                          .declineContactRequest(contactRequest!)
                      : contactRequestService
                          .cancelContactReqeuest(contactRequest!);
                },
                elevation: 2.0,
                fillColor: Colors.white,
                shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(30))),
                child: const Icon(
                  Icons.delete,
                  color: Colors.redAccent,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
