import 'package:flutter/material.dart';
import '../../../ui_constants.dart';
import 'package:timeago/timeago.dart' as timeago;

class PendingRequestCard extends StatelessWidget {
  const PendingRequestCard({
    Key? key,
    required this.email,
    required this.requestSent,
    required this.press,
  }) : super(key: key);

  final String email;
  final DateTime requestSent;
  final VoidCallback press;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(horizontal: defaultPadding, vertical: 0),
      onTap: () {},
      leading: Container(
        padding: EdgeInsets.fromLTRB(5, 4, 3, 5),
        decoration: BoxDecoration(
            color:
                Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.25),
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
        'Request was sent ${timeago.format(requestSent)}',
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyText1!.color!.withOpacity(0.5),
        ),
      ),
    );
  }
}
