import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/screens/contacts/components/received_requests_list.dart';
import 'package:evercrypted/screens/contacts/components/sent_requests_list.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';

import '../../core/entities/contact-request/contact_request_service.dart';
import '../../core/entities/contact/contact_model.dart';
import '../../core/entities/profile/profile_riverpod.dart';
import '../../core/helpers/field_validators.dart';
import '../../core/offline/action_queue/allowed_for_queue.dart';
import '../../ui_constants.dart';
import '../../widgets/primary_button.dart';

class AddNewContactScreen extends ConsumerStatefulWidget {
  static const routeName = '/add-new-contact';
  final String? initialTab;

  const AddNewContactScreen({super.key, this.initialTab});

  @override
  AddNewContactScreenState createState() => AddNewContactScreenState();
}

class AddNewContactScreenState extends ConsumerState<AddNewContactScreen> {
  final form = GlobalKey<FormState>();

  final ContactRequestService _contactRequestService = ContactRequestService();

  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _messageFocus = FocusNode();

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

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    _messageFocus.dispose();
    super.dispose();
  }

  void _onBotNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  submitForm() {
    final List<Contact> contacts = ref.read(contactsProvider);
    if (contacts
        .any((Contact element) => element.email == _emailController.text)) {
      showSimpleNotification(
          const Text(
            "You already have a contact with this email",
            style: TextStyle(color: Colors.white),
          ),
          background: Colors.redAccent);
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    if (form.currentState!.validate()) {
      form.currentState?.save();
      showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Confirm Contact Request'),
          content: Text(
              'Are you sure that you want to send a contact request to ${_emailController.text}?'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Yes'),
            ),
          ],
        ),
      ).then((value) {
        if (value == null) return;
        if (value) {
          form.currentState?.reset();
          final cRequest = ContactRequest(
              recipientEmail: _emailController.text,
              message: _messageController.text);
          _contactRequestService.createContactRequest(cRequest).then((resp) {
            setState(() {
              _selectedIndex = 1;
            });
            if (mounted) {
              _emailController.clear();
              _messageController.clear();
              Navigator.pop(context);
            }
          }).onError((error, stackTrace) {
            if (mounted) {
              _emailController.clear();
              _messageController.clear();
              Navigator.pop(context);
            }
            if (error == 'queued') {
              showQueuedNotification();
            } else {
              showSimpleNotification(
                  Text(
                    error.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                  background: Colors.redAccent);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    sentRequests = ref.watch(sentRequestsProvider);
    return Scaffold(
      appBar: AppBar(
          title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Contact Requests"),
          Text(
            _selectedIndex == 0 ? "Received Requests" : "Sent Requests",
            style: const TextStyle(fontSize: 12),
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
      floatingActionButton: Tooltip(
        message: 'Send Contact Request',
        preferBelow: false,
        child: FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (BuildContext context) {
                  return Wrap(children: [
                    Container(
                      color: primaryColor,
                      padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom),
                      child: Container(
                          margin: const EdgeInsets.all(defaultPadding),
                          padding: const EdgeInsets.fromLTRB(
                            defaultPadding,
                            0,
                            defaultPadding,
                            defaultPadding,
                          ),
                          child: Form(
                            key: form,
                            child: Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  validator: (val) {
                                    String? emailError = validateEmail(val);
                                    if (emailError != null) return emailError;
                                    final profile = ref.read(profileProvider);
                                    if (val == profile?.email) {
                                      return "You can't send a contact request to yourself";
                                    } else if (sentRequests
                                        .map((e) => e.recipientEmail)
                                        .contains(val)) {
                                      return "You have already sent a contact request to this email";
                                    } else {
                                      return null;
                                    }
                                  },
                                  textInputAction: TextInputAction.next,
                                  onTap: () {
                                    openSecretInput(
                                        context: context,
                                        controller: _emailController,
                                        done: (val) => FocusScope.of(context)
                                            .requestFocus(_messageFocus));
                                  },
                                  keyboardType: TextInputType.none,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                    fillColor: Colors.white,
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: contentColorLightTheme
                                          .withOpacity(0.64),
                                    ),
                                    hintText: "Email",
                                    hintStyle: TextStyle(
                                      color: contentColorLightTheme
                                          .withOpacity(0.64),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: defaultPadding / 2),
                                TextFormField(
                                  controller: _messageController,
                                  focusNode: _messageFocus,
                                  validator: (val) {
                                    return maxLengthValidator(val, 100);
                                  },
                                  onTap: () {
                                    openSecretInput(
                                        context: context,
                                        controller: _messageController,
                                        done: (val) => submitForm());
                                  },
                                  keyboardType: TextInputType.none,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(
                                      borderSide: BorderSide.none,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(10)),
                                    ),
                                    fillColor: Colors.white,
                                    prefixIcon: Icon(
                                      Icons.message,
                                      color: contentColorLightTheme
                                          .withOpacity(0.64),
                                    ),
                                    hintText: "Message",
                                    hintStyle: TextStyle(
                                      color: contentColorLightTheme
                                          .withOpacity(0.64),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: defaultPadding / 2),
                                PrimaryButton(
                                  text: 'SEND REQUEST',
                                  press: submitForm,
                                  color: secondaryColor,
                                )
                              ],
                            ),
                          )),
                    ),
                  ]);
                });
          },
          backgroundColor: primaryColor,
          child: const Icon(
            Icons.add,
            color: Colors.white,
          ),
        ),
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
