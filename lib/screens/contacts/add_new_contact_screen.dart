import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/screens/contacts/components/add_contact_button.dart';
import 'package:evercrypted/screens/contacts/components/received_requests_list.dart';
import 'package:evercrypted/screens/contacts/components/sent_requests_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddNewContactScreen extends ConsumerStatefulWidget {
  static const routeName = '/add-new-contact';
  final String? initialTab;

  const AddNewContactScreen({super.key, this.initialTab});

  @override
  AddNewContactScreenState createState() => AddNewContactScreenState();
}

class AddNewContactScreenState extends ConsumerState<AddNewContactScreen> {
  int _selectedIndex = 0;
  List<ContactRequest> sentRequests = [];

  @override
  void initState() {
    super.initState();
    setState(() {
      if (widget.initialTab == 'sent') {
        _selectedIndex = 1;
      } else {
        _selectedIndex = 0;
      }
    });
  }

  void _onBotNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Contact Requests",
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text(
            _selectedIndex == 0 ? "Received Requests" : "Sent Requests",
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.left,
          )
        ],
      )),
      body: Consumer(
          builder: (BuildContext context, WidgetRef ref, Widget? child) {
        List<ContactRequest> receivedRequests =
            ref.watch(receivedRequestsProvider);
        List<ContactRequest> sentRequests = ref.watch(sentRequestsProvider);
        return _selectedIndex == 0
            ? ReceivedRequestsList(
                receivedRequests: receivedRequests,
              )
            : SentRequestsList(
                sentRequests: sentRequests,
              );
      }),
      floatingActionButton: AddContactButton(
        afterCallback: () => setState(() {
          _selectedIndex = 1;
        }),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.mark_as_unread),
            label: 'Received Requests',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.outgoing_mail),
            label: 'Sent Requests',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onBotNavTapped,
      ),
    );
  }
}
