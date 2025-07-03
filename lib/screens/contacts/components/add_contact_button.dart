import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_service.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:evercrypted/core/offline/action_queue/allowed_for_queue.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';

class AddContactButton extends ConsumerStatefulWidget {
  final VoidCallback? afterCallback;

  const AddContactButton({super.key, this.afterCallback});

  @override
  AddContactButtonState createState() => AddContactButtonState();
}

class AddContactButtonState extends ConsumerState<AddContactButton> {
  final form = GlobalKey<FormState>();

  final ContactRequestService _contactRequestService = ContactRequestService();

  final _emailController = TextEditingController();
  final _messageController = TextEditingController();
  final _messageFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    _messageFocus.dispose();
    super.dispose();
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
          background: errorColor);
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
            widget.afterCallback?.call();
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
                  background: errorColor);
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = ref.read(keyboardProvider.notifier);

    return FloatingActionButton.extended(
      onPressed: () {
        showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height *
                  0.8, // 80% of screen height
            ),
            builder: (BuildContext context) {
              return SingleChildScrollView(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(defaultPadding * 2),
                      topRight: Radius.circular(defaultPadding * 2),
                    ),
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
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
                            Icon(Icons.forward_to_inbox,
                                size: 60,
                                color: Theme.of(context)
                                    .textTheme
                                    .titleMedium!
                                    .color),
                            const SizedBox(height: defaultPadding / 2),
                            Text(
                              "Send a contact request",
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: defaultPadding / 2),
                            Text(
                              "The person will receive a request to add you as a contact. You can add a message to the request.",
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _emailController,
                              validator: (val) {
                                final List<ContactRequest> sentRequests =
                                    ref.read(sentRequestsProvider);
                                String? emailError = validateEmail(val);
                                if (emailError != null) return emailError;
                                if (val == Auth.getUser?.email) {
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
                                keyboardNotifier.openKeyboard(
                                    controller: _emailController);
                              },
                              keyboardType: TextInputType.none,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                prefixIcon: Icon(
                                  Icons.email,
                                ),
                                hintText: "Email",
                              ),
                            ),
                            const SizedBox(height: defaultPadding),
                            TextFormField(
                              controller: _messageController,
                              focusNode: _messageFocus,
                              validator: (val) {
                                return maxLengthValidator(val, 100);
                              },
                              onTap: () {
                                keyboardNotifier.openKeyboard(
                                    controller: _messageController);
                              },
                              keyboardType: TextInputType.none,
                              decoration: InputDecoration(
                                border: const OutlineInputBorder(
                                  borderSide: BorderSide.none,
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(10)),
                                ),
                                prefixIcon: Icon(
                                  Icons.message,
                                ),
                                hintText: "Message",
                              ),
                            ),
                            const SizedBox(height: defaultPadding),
                            PrimaryButton(
                              text: 'SEND REQUEST',
                              press: submitForm,
                              color: primaryColor,
                            )
                          ],
                        ),
                      )),
                ),
              );
            });
      },
      backgroundColor: primaryColor,
      label: const Text(
        'Add Contact',
        style: TextStyle(color: Colors.white),
      ),
      icon: const Icon(
        Icons.person_add,
        color: Colors.white,
      ),
    );
  }
}
