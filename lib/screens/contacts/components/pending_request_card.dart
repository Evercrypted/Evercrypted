import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/services/block_service.dart';
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

  void _showBlockDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Block User'),
          content: Text(
            'Are you sure you want to block ${contactRequest!.authorEmail}? They won\'t be able to send you messages or contact requests.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                final authorId = contactRequest!.authorId;
                if (authorId == null) return;

                final success = await BlockService.blockUser(authorId);

                if (success) {
                  // Also decline the contact request
                  contactRequestService.declineContactRequest(contactRequest!);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('User blocked successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('Failed to block user. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Block'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      leading: Container(
        padding: const EdgeInsets.fromLTRB(5, 4, 3, 5),
        decoration: BoxDecoration(
            color: Theme.of(context)
                .textTheme
                .bodyLarge!
                .color!
                .withAlpha((255 * 0.25).round()),
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
          color: Theme.of(context)
              .textTheme
              .bodyLarge!
              .color!
              .withAlpha((255 * 0.5).round()),
        ),
      ),
      expandedAlignment: Alignment.centerLeft,
      expandedCrossAxisAlignment: CrossAxisAlignment.start,
      backgroundColor: primaryColor,
      iconColor: Colors.white,
      textColor: Colors.white,
      children: [
        if (contactRequest!.message != null &&
            contactRequest!.message!.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(left: 30, right: 30, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha((255 * 0.3).round()),
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
              if (isReceived)
                RawMaterialButton(
                  onPressed: () => _showBlockDialog(context),
                  elevation: 2.0,
                  fillColor: Colors.white,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30))),
                  child: const Icon(
                    Icons.block,
                    color: Colors.orange,
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
                  color: errorColor,
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}
