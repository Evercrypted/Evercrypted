import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/screens/contacts/components/received_requests_list.dart';
import 'package:evercrypted/screens/contacts/components/sent_requests_list.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';

import '../../core/entities/contact-request/contact_request_service.dart';
import '../../core/entities/profile/profile_riverpod.dart';
import '../../core/helpers/field_validators.dart';
import '../../core/offline/action_queue/allowed_for_queue.dart';
import '../../ui_constants.dart';
import '../../widgets/primary_button.dart';

class AddNewContactScreen extends ConsumerStatefulWidget {
  static const routeName = '/add-new-contact';

  const AddNewContactScreen({Key? key}) : super(key: key);

  @override
  AddNewContactScreenState createState() => AddNewContactScreenState();
}

class AddNewContactScreenState extends ConsumerState<AddNewContactScreen> {
  final form = GlobalKey<FormState>();

  final ContactRequestService _contactRequestService = ContactRequestService();

  String? email;
  String? message;

  int _selectedIndex = 0;
  List<ContactRequest> sentRequests = [];

  void _onBotNavTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  submitForm() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (form.currentState!.validate()) {
      form.currentState?.save();
      showDialog<bool>(
        context: context,
        builder: (BuildContext context) => AlertDialog(
          title: const Text('Confirm Contact Request'),
          content: Text(
              'Are you sure that you want to send a contact request to $email?'),
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
          final cRequest =
              ContactRequest(recipientEmail: email!, message: message);
          _contactRequestService.createContactRequest(cRequest).then((resp) {
            print(resp);
            final ContactRequest returnedContactRequest =
                ContactRequest.fromJson(resp);
            ref
                .read(sentRequestsProvider.notifier)
                .addSentRequest(returnedContactRequest);
            Navigator.pop(context);
          }).onError((error, stackTrace) {
            Navigator.pop(context);
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
                                  onSaved: (value) {
                                    email = value;
                                  },
                                  keyboardType: TextInputType.emailAddress,
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
                                  minLines: 2,
                                  maxLines: 2,
                                  validator: (val) {
                                    return maxLengthValidator(val, 100);
                                  },
                                  textInputAction: TextInputAction.done,
                                  onSaved: (value) {
                                    message = value;
                                  },
                                  onFieldSubmitted: (_) {
                                    submitForm();
                                  },
                                  keyboardType: TextInputType.text,
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
