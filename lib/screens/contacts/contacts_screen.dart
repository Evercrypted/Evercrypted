import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';

import '../search/components/body.dart';
import 'components/contact_card.dart';
import 'add_new_contact_screen.dart';

class ContactsScreen extends StatelessWidget {
  static const routeName = '/contacts';

  const ContactsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("People"),
        actions: [IconButton(icon: const Icon(Icons.search), onPressed: () => {})],
      ),
      body: ListView.builder(
        itemCount: demoContactsImage.length,
        itemBuilder: (context, index) => ContactCard(
          name: "Jenny Wilson",
          number: "(239) 555-0108",
          image: demoContactsImage[index],
          isActive: index.isEven, // for demo
          press: () {},
        ),
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
