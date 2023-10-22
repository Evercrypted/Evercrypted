import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/contact_card.dart';
import 'add_new_contact_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  static const routeName = '/contacts';

  const ContactsScreen({Key? key}) : super(key: key);

  @override
  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends ConsumerState<ContactsScreen> {
  @override
  Widget build(BuildContext context) {
    final contacts = ref.watch(contactsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("People"),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () => {})
        ],
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (context, index) {
          final contact = contacts[index];
          return ContactCard(
            contact: contact,
            isActive: false, // for demo
            press: () {},
          );
        },
      ),
      floatingActionButton: Tooltip(
        message: 'Check Contact Requests',
        preferBelow: false,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pushNamed(context, AddNewContactScreen.routeName);
          },
          backgroundColor: primaryColor,
          child: const Icon(
            Icons.group_add_rounded,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
