import 'package:flutter/material.dart';

import '../search/components/body.dart';
import 'components/contact_card.dart';
import 'contact_search_screen.dart';

class ContactsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("People"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ContactSearchScreen(),
              ),
            ),
          )
        ],
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
    );
  }
}
