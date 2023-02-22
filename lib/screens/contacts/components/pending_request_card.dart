import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class PendingRequestCard extends StatelessWidget {
  const PendingRequestCard({
    Key? key,
    required this.isReceived,
    required this.email,
    this.message,
    required this.requestSent,
    required this.press,
  }) : super(key: key);

  final String email;
  final String? message;
  final DateTime requestSent;
  final VoidCallback press;
  final bool isReceived;

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
        email,
      ),
      subtitle: Text(
        'Request was ${isReceived ? 'received' : 'sent'} ${timeago.format(requestSent)}',
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
        if (message != null)
          Container(
            margin: const EdgeInsets.only(left: 30, right: 30, bottom: 10),
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: const BorderRadius.all(Radius.circular(10)),
            ),
            child: Text(
              message!,
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
                  onPressed: () {},
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
                onPressed: () {},
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
