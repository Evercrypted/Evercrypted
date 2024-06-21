import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/search_header.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/contact_card.dart';
import 'add_new_contact_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  static const routeName = '/contacts';

  const ContactsScreen({super.key});

  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool searching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  String searchValue = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchValue = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Contact> contacts = ref.watch(contactsProvider);

    late final List<Contact> contactsToUse;
    if (searchValue.isNotEmpty) {
      final contactsAfterSearch = contacts
          .where((e) =>
              (e.name?.toLowerCase().contains(searchValue.toLowerCase()) ??
                  false) ||
              e.email!.toLowerCase().contains(searchValue.toLowerCase()))
          .toList();
      contactsToUse = contactsAfterSearch;
    } else {
      contactsToUse = contacts;
    }

    final alphabetFromContacts =
        contactsToUse.map((e) => (e.name ?? e.email)![0]).toSet();

    final contactTree = {
      for (var e1 in alphabetFromContacts)
        e1: contactsToUse.where((e) => (e.name ?? e.email)![0] == e1).toList()
    };

    return Scaffold(
      body: Column(
        children: [
          SearchHeader(
              label: const Text(
                'Contacts',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              searching: searching,
              searchFocus: searchFocus,
              searchController: _searchController,
              onSearchIconPressed: () {
                setState(() {
                  searching = true;
                  searchFocus.requestFocus();
                  openSecretInput(
                      context: context, controller: _searchController);
                });
              },
              onCloseIconPressed: () {
                setState(() {
                  searching = false;
                  _searchController.clear();
                });
              }),
          SizedBox(
            height: MediaQuery.of(context).size.height - 243,
            child: contacts.isNotEmpty
                ? contactsToUse.isNotEmpty
                    ? ListView.builder(
                        itemCount: contactTree.length,
                        itemBuilder: (context, index) {
                          String key = contactTree.keys.elementAt(index);
                          final contactsFromIndex = contactTree[key] ?? [];
                          return Column(
                            children: [
                              Container(
                                margin: const EdgeInsets.only(
                                    top: 15, left: 20, right: 20),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey[100]!,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  key.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  for (var contact in contactsFromIndex)
                                    ContactCard(
                                      contact: contact,
                                      isActive: false,
                                    ),
                                ],
                              ),
                            ],
                          );
                        },
                      )
                    : Container(
                        padding:
                            const EdgeInsets.only(left: 20, right: 20, top: 50),
                        alignment: Alignment.topCenter,
                        child: const Text(
                          'Could not find such contacts.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 30, fontWeight: FontWeight.bold),
                        ),
                      )
                : Container(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 50),
                    alignment: Alignment.topCenter,
                    child: const Text(
                      'Your contacts list is empty. Add new contacts to start chatting.',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                  ),
          ),
        ],
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
