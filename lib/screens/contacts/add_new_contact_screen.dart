import 'package:evercrypted/screens/contacts/components/received_requests_list.dart';
import 'package:evercrypted/screens/contacts/components/sent_requests_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entities/contact-request/contact_request_service.dart';
import '../../core/entities/profile/profile_riverpod.dart';
import '../../core/helpers/field_validators.dart';
import '../../ui_constants.dart';

class AddNewContactScreen extends ConsumerStatefulWidget {
  static const routeName = '/add-new-contact';

  const AddNewContactScreen({Key? key}) : super(key: key);

  @override
  AddNewContactScreenState createState() => AddNewContactScreenState();
}

class AddNewContactScreenState extends ConsumerState<AddNewContactScreen> {
  final form = GlobalKey<FormState>();

  ContactRequestService _contactRequestService = ContactRequestService();

  String? email;

  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    ReceivedRequestsList(),
    SentRequestsList(),
  ];

  void _onBotNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  submitForm() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (form.currentState!.validate()) {
      form.currentState?.save();
      // showDialog<bool>(
      //   context: context,
      //   builder: (BuildContext context) => AlertDialog(
      //     title: const Text('Confirm Contact Request'),
      //     content: Text(
      //         'Are you sure that you want to send a contact request to $email?'),
      //     actions: <Widget>[
      //       TextButton(
      //         onPressed: () => Navigator.pop(context, false),
      //         child: const Text('Cancel'),
      //       ),
      //       TextButton(
      //         onPressed: () => Navigator.pop(context, true),
      //         child: const Text('Yes'),
      //       ),
      //     ],
      //   ),
      // ).then((value) {
      //   if (value == null) return;
      //   if (value) {
      //     form.currentState?.reset();
      //     final _profileRP = ref.read(profileProvider);
      //     print(_profileRP.profile.email);
      //     // _contactRequestService.createContactRequest(email);
      //   }
      // });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Contact Requests"),
      ),
      body: Column(
        children: [
          // Appbar search
          Container(
            margin: const EdgeInsets.only(bottom: defaultPadding),
            padding: const EdgeInsets.fromLTRB(
              defaultPadding,
              0,
              defaultPadding,
              defaultPadding,
            ),
            color: primaryColor,
            child: Form(
              key: form,
              child: TextFormField(
                validator: validateEmail,
                textInputAction: TextInputAction.done,
                onSaved: (value) {
                  email = value;
                },
                onFieldSubmitted: (_) {
                  submitForm();
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.email,
                    color: contentColorLightTheme.withOpacity(0.64),
                  ),
                  suffixIcon: IconButton(
                    onPressed: submitForm,
                    icon: const Icon(Icons.send),
                  ),
                  hintText: "Email",
                  hintStyle: TextStyle(
                    color: contentColorLightTheme.withOpacity(0.64),
                  ),
                ),
              ),
            ),
          ),
          _widgetOptions.elementAt(_selectedIndex),
        ],
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
