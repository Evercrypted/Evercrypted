import 'package:collection/collection.dart';
import 'package:evercrypted/core/entities/chat/participant_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:evercrypted/core/navigation/navigation_state.dart';
import 'package:evercrypted/core/services/hidden_contact_service.dart';
import 'package:evercrypted/screens/contacts/components/add_contact_button.dart';
import 'package:evercrypted/screens/contacts/components/check_requests_icon.dart';
import 'package:evercrypted/screens/contacts/contact_screen.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/connection_status_appbar.dart';
import 'package:evercrypted/widgets/grid.dart';
import 'package:evercrypted/widgets/search_header.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'components/contact_card.dart';
import 'add_new_contact_screen.dart';

class ContactsScreen extends ConsumerStatefulWidget {
  static const routeName = '/contacts';

  final bool isParticipantSelect;
  final bool isGroupCreate;

  final bool isAddNewParticipants;

  final List<Participant>? participants;

  const ContactsScreen(
      {super.key,
      this.isParticipantSelect = false,
      this.participants,
      this.isAddNewParticipants = false,
      this.isGroupCreate = false});

  @override
  ContactsScreenState createState() => ContactsScreenState();
}

class ContactsScreenState extends ConsumerState<ContactsScreen> {
  final EvercryptedTextController _searchController =
      EvercryptedTextController();
  String searchValue = '';
  List<Participant>? participants;
  final EvercryptedTextController newGroupName = EvercryptedTextController();
  final HiddenContactService hiddenContactService = HiddenContactService();

  @override
  void initState() {
    if (widget.participants != null && !widget.isAddNewParticipants) {
      participants = [...widget.participants!];
    } else {
      participants = [];
    }
    super.initState();
    _searchController.addListener(setSearchValue);

    // Set navigation state to contacts when this screen is active
    // Only do this for the main contacts screen, not participant selection
    if (!widget.isParticipantSelect) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(navigationProvider.notifier).navigateToContacts();
      });
    }
  }

  setSearchValue() {
    setState(() {
      searchValue = _searchController.text;
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(setSearchValue);
    _searchController.dispose();
    newGroupName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Contact> contacts = ref.watch(contactsProvider);
    final List<ContactRequest> receivedRequests =
        ref.watch(receivedRequestsProvider);
    final profile = ref.watch(profileProvider);

    final isThereUnread =
        receivedRequests.where((element) => element.unread == true).isNotEmpty;

    late final List<Contact> contactsToUse;
    if (searchValue.isNotEmpty) {
      // Check if search value matches any hidden contact password
      final hiddenContactUids = hiddenContactService
          .getContactsMatchingPassword(searchValue, profile);

      final contactsAfterSearch = contacts
          .where((e) =>
              (e.name?.toLowerCase().contains(searchValue.toLowerCase()) ??
                  false) ||
              e.email!.toLowerCase().contains(searchValue.toLowerCase()) ||
              hiddenContactUids.contains(e.contactPersonUid))
          .toList();
      contactsToUse = [...contactsAfterSearch];
    } else {
      // Filter out hidden contacts when not searching
      final hiddenContactUids =
          hiddenContactService.getHiddenContactUids(profile);
      contactsToUse = contacts
          .where((e) => !hiddenContactUids.contains(e.contactPersonUid))
          .toList();
    }

    final List<Contact> favorites =
        contactsToUse.where((e) => e.isFavorite).toList();

    contactsToUse.removeWhere((e) => e.isFavorite);

    if (widget.isAddNewParticipants) {
      contactsToUse.removeWhere((e) => widget.participants!
          .map((e) => e.uid)
          .toList()
          .contains(e.contactPersonUid));
      favorites.removeWhere((e) => widget.participants!
          .map((e) => e.uid)
          .toList()
          .contains(e.contactPersonUid));
    }

    final alphabetFromContacts =
        contactsToUse.map((e) => (e.name ?? e.email)![0]).toSet();

    Map<String, List<dynamic>> contactTree = {
      'participants': participants ?? [],
      'Favorites': favorites
          .where((e) =>
              participants!
                  .firstWhereOrNull((p) => p.uid == e.contactPersonUid) ==
              null)
          .toList(),
      for (var e1 in alphabetFromContacts)
        e1: contactsToUse
            .where((e) =>
                (e.name ?? e.email)![0] == e1 &&
                participants!
                        .firstWhereOrNull((p) => p.uid == e.contactPersonUid) ==
                    null)
            .toList()
    };

    return Scaffold(
      appBar: widget.isParticipantSelect
          ? ConnectionStatusAppbar(
              title: Text(
                widget.participants == null
                    ? 'Create New Group'
                    : 'Manage Participants',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              actions: widget.isParticipantSelect
                  ? [
                      IconButton(
                          onPressed: () {
                            if (widget.isGroupCreate) {
                              if (participants != null &&
                                  participants!.isNotEmpty &&
                                  newGroupName.text.isNotEmpty) {
                                Navigator.pop(context, {
                                  'participants': participants,
                                  'groupName': newGroupName.text
                                });
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('Missing information'),
                                    content: Text(
                                        'Please enter a group name and select participants'),
                                  ),
                                );
                              }
                            } else {
                              if (participants != null &&
                                  participants!.isNotEmpty) {
                                Navigator.pop(context, participants);
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title:
                                        Text('New participants not selected'),
                                    content: Text('Please select participants'),
                                  ),
                                );
                              }
                            }
                          },
                          icon: Icon(
                            Icons.check_circle,
                            color:
                                participants != null && participants!.isNotEmpty
                                    ? primaryColor
                                    : Colors.grey,
                            size: 30,
                          ))
                    ]
                  : null,
            )
          : null,
      body: Column(
        children: [
          if (widget.isParticipantSelect && widget.isGroupCreate)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: defaultPadding * 2),
              child: EvercryptedTextField(
                controller: newGroupName,
                decoration: InputDecoration(
                  hintText: 'Group Name',
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: SearchHeader(
                    label: Text('Contacts', style: TextStyle(fontSize: 24)),
                    searching: false,
                    searchController: _searchController,
                    hintText: 'Search contacts...',
                    onCloseIconPressed: () {
                      setState(() {
                        searchValue = '';
                        _searchController.clear();
                      });
                      // Unfocus the search field to close the keyboard
                      _searchController.unfocus();
                    }),
              ),
              if (!widget.isParticipantSelect)
                Padding(
                  padding: const EdgeInsets.only(right: defaultPadding / 2),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      shadowColor: WidgetStateProperty.all(Colors.transparent),
                      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(
                          color: primaryColor,
                        ),
                      )),
                    ),
                    onPressed: () {
                      Navigator.pushNamed(
                          context, AddNewContactScreen.routeName);
                    },
                    child: Row(
                      children: [
                        Text('Requests'),
                        SizedBox(width: defaultPadding / 2),
                        CheckRequestsIcon(isThereUnread: isThereUnread)
                      ],
                    ),
                  ),
                )
            ],
          ),
          Expanded(
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
              message: 'Add new contact',
              preferBelow: false,
              child: AddContactButton(
                afterCallback: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) {
                      return const AddNewContactScreen(
                        initialTab: 'sent',
                      );
                    }),
                  );
                },
              )),
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
                  final List<dynamic> contactsFromIndex =
                      contactTree[key] ?? [];
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
                            for (var participant in contactsFromIndex)
                              SizedBox(
                                width: 50,
                                child: Column(
                                  children: [
                                    CircleAvatarWithActiveIndicator(
                                      image: participant.avatar?.pic,
                                      isActive: false,
                                      radius: 24,
                                      name: participant.name ??
                                          participant.email!.split('@')[0],
                                      icon: Icons.close,
                                      onIconTap: () {
                                        setState(() {
                                          participants!.remove(participant);
                                        });
                                      },
                                    ),
                                    Text(
                                      participant.name != null
                                          ? participant.name!
                                          : participant.email!.split('@')[0],
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
                                      if (participants!.firstWhereOrNull((p) =>
                                              p.uid ==
                                              contact.contactPersonUid) ==
                                          null) {
                                        participants!.add(
                                            Participant.fromContact(contact));
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
                  'No contacts found',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),
              )
        : Container(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 50),
            alignment: Alignment.topCenter,
            child: const Text(
              'Your contacts list is empty',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          );
  }
}
