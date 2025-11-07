import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'contact_model.dart';

part 'contact_riverpod.g.dart';

@Riverpod(keepAlive: true)
class Contacts extends _$Contacts {
  // We initialize the list of contacts to an empty list
  @override
  List<Contact> build() => [];

  void setContacts(List<Contact> contacts) {
    state = [...contacts];
  }

  void addContact(Contact contact) {
    state = [contact, ...state];
  }
}
