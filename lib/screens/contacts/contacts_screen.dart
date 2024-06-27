import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/screens/contacts/contact_screen.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/connection_status_appbar.dart';
import 'package:evercrypted/widgets/grid.dart';
import 'package:evercrypted/widgets/search_header.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/contact_card.dart';
import 'add_new_contact_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  static const routeName = '/contacts';

  final bool isParticipantSelect;

  final List<Contact>? participants;

  const ContactsScreen(
      {super.key, this.isParticipantSelect = false, this.participants});

  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends ConsumerState<ContactsScreen> {
  bool searching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  String searchValue = '';
  List<Contact>? participants;

  @override
  void initState() {
    if (widget.participants != null) {
      participants = [...widget.participants!];
    }
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
      contactsToUse = [...contactsAfterSearch];
    } else {
      contactsToUse = [...contacts];
    }

    final List<Contact> favorites =
        contactsToUse.where((e) => e.isFavorite).toList();
    contactsToUse.removeWhere((e) => e.isFavorite);

    final alphabetFromContacts =
        contactsToUse.map((e) => (e.name ?? e.email)![0]).toSet();

    Map<String, List<Contact>> contactTree = {
      'participants': participants ?? [],
      'Favorites': favorites,
      for (var e1 in alphabetFromContacts)
        e1: contactsToUse.where((e) => (e.name ?? e.email)![0] == e1).toList()
    };

    return Scaffold(
      appBar: widget.isParticipantSelect
          ? const ConnectionStatusAppbar(
              title: Text(
                'Participants',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: null,
            )
          : null,
      body: Column(
        children: [
          SearchHeader(
              label: Text(
                widget.isParticipantSelect ? 'Search' : 'Contacts',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: widget.isParticipantSelect
                        ? FontWeight.normal
                        : FontWeight.bold,
                    color: widget.isParticipantSelect
                        ? Colors.black54
                        : Colors.black),
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
              child: _contactList(
                  widget: widget,
                  contacts: contacts,
                  contactsToUse: contactsToUse,
                  favorites: favorites,
                  contactTree: contactTree)),
        ],
      ),
      floatingActionButton: widget.isParticipantSelect
          ? null
          : Tooltip(
              message: 'Check Contact Requests',
              preferBelow: false,
              child: FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, AddNewContactScreen.routeName);
                },
                backgroundColor: primaryColor,
                child: const Icon(
                  Icons.person_add,
                  color: Colors.white,
                ),
              ),
            ),
    );
  }

  Widget _contactList(
      {widget, contacts, contactsToUse, favorites, contactTree}) {
    return contacts.isNotEmpty
        ? contactsToUse.isNotEmpty || favorites.isNotEmpty
            ? ListView.builder(
                itemCount: contactTree.length,
                itemBuilder: (context, index) {
                  String key = contactTree.keys.elementAt(index);
                  final contactsFromIndex = contactTree[key] ?? [];
                  if (contactsFromIndex.isEmpty) {
                    return const SizedBox.shrink();
                  } else if (key == 'participants') {
                    return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey[100]!,
                            ),
                          ),
                        ),
                        child: Grid(
                          childWidth: 57,
                          children: [
                            for (var contact in contactsFromIndex)
                              SizedBox(
                                width: 50,
                                child: Column(
                                  children: [
                                    CircleAvatarWithActiveIndicator(
                                      image: contact.avatar?.pic,
                                      isActive: false,
                                      radius: 24,
                                      name: contact.name ??
                                          contact.email!.split('@')[0],
                                      icon: Icons.close,
                                      onIconTap: () {
                                        setState(() {
                                          participants!.remove(contact);
                                        });
                                      },
                                    ),
                                    Text(
                                      contact.name != null
                                          ? contact.name!
                                          : contact.email!.split('@')[0],
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ));
                  } else {
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
                            key.capitalize,
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
                                isParticipantSelect: widget.isParticipantSelect,
                                onTap: () {
                                  if (widget.isParticipantSelect) {
                                    setState(() {
                                      if (!participants!.contains(contact)) {
                                        participants!.add(contact);
                                      }
                                    });
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) {
                                        return ContactScreen(
                                          contact: contact,
                                        );
                                      }),
                                    );
                                  }
                                },
                              ),
                          ],
                        ),
                      ],
                    );
                  }
                },
              )
            : Container(
                padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
                alignment: Alignment.topCenter,
                child: const Text(
                  'Could not find such contacts.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              )
        : Container(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
            alignment: Alignment.topCenter,
            child: const Text(
              'Your contacts list is empty. Add new contacts to start chatting.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          );
  }
}
