import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_model.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_riverpod.dart';
import 'package:evercrypted/core/entities/contact-request/contact_request_service.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_riverpod.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/core/helpers/field_validators.dart';
import 'package:evercrypted/core/offline/action_queue/allowed_for_queue.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:evercrypted/widgets/primary_button.dart';
import 'package:evercrypted/widgets/secret_keyboard/qr_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:overlay_support/overlay_support.dart';

class AddContactSheet extends ConsumerStatefulWidget {
  final VoidCallback? afterCallback;
  final String? initialEmail;
  final String? initialMessage;

  const AddContactSheet({
    super.key,
    this.afterCallback,
    this.initialEmail,
    this.initialMessage,
  });

  @override
  AddContactSheetState createState() => AddContactSheetState();
}

class AddContactSheetState extends ConsumerState<AddContactSheet> {
  final form = GlobalKey<FormState>();

  final ContactRequestService _contactRequestService = ContactRequestService();

  late final EvercryptedTextController _emailController;
  late final EvercryptedTextController _messageController;

  @override
  void initState() {
    super.initState();
    _emailController =
        EvercryptedTextController(initialText: widget.initialEmail);
    _messageController =
        EvercryptedTextController(initialText: widget.initialMessage);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  submitForm() {
    final List<Contact> contacts = ref.read(contactsProvider);
    final List<ContactRequest> sentRequests =
        ref.read(sentContactRequestsProvider);
    final email = _emailController.text;
    final message = _messageController.text;

    // Validate email
    String? emailError = validateEmail(email);
    if (emailError != null) {
      showSimpleNotification(
          Text(emailError, style: TextStyle(color: Colors.white)),
          background: errorColor);
      return;
    }

    // Check if email is user's own email
    if (email.toLowerCase() == Auth.getUser?.email.toLowerCase()) {
      showSimpleNotification(
          const Text(
            "You can't send a contact request to yourself",
            style: TextStyle(color: Colors.white),
          ),
          background: errorColor);
      return;
    }

    // Check if already have contact
    if (contacts.any((Contact element) =>
        element.email?.toLowerCase() == email.toLowerCase())) {
      showSimpleNotification(
          const Text(
            "You already have a contact with this email",
            style: TextStyle(color: Colors.white),
          ),
          background: errorColor);
      return;
    }

    // Check if already sent request
    if (sentRequests.map((e) => e.recipientEmail).contains(email)) {
      showSimpleNotification(
          const Text(
            "You have already sent a contact request to this email",
            style: TextStyle(color: Colors.white),
          ),
          background: errorColor);
      return;
    }

    // Validate message length
    if (message.length > 100) {
      showSimpleNotification(
          const Text(
            "Message must be 100 characters or less",
            style: TextStyle(color: Colors.white),
          ),
          background: errorColor);
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();
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
        final cRequest = ContactRequest(
            recipientEmail: _emailController.text,
            message: _messageController.text);
        form.currentState?.reset();
        _contactRequestService.createContactRequest(cRequest).then((resp) {
          widget.afterCallback?.call();
          if (mounted) {
            _emailController.clear();
            _messageController.clear();
            Navigator.popUntil(context, (route) => route.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(defaultPadding * 2),
            topRight: Radius.circular(defaultPadding * 2),
          ),
          color: Theme.of(context).scaffoldBackgroundColor,
        ),
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                      color: Theme.of(context).textTheme.titleMedium!.color),
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
                  EvercryptedTextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
                      ),
                      prefixIcon: Icon(
                        Icons.email,
                      ),
                      hintText: "Email",
                    ),
                  ),
                  const SizedBox(height: defaultPadding),
                  EvercryptedTextField(
                    controller: _messageController,
                    maxLength: 100,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(
                        borderSide: BorderSide.none,
                        borderRadius: BorderRadius.all(Radius.circular(10)),
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
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        vertical: defaultPadding / 2),
                    child: Text(
                      '- or -',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  PrimaryButton(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_scanner, color: Colors.white),
                          const SizedBox(width: defaultPadding / 2),
                          Text('SCAN QR CODE',
                              style: TextStyle(color: Colors.white)),
                        ],
                      ),
                      press: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.of(context).size.height *
                                0.8, // 80% of screen height
                          ),
                          builder: (context) => QrScanner(
                            whenScanned: (value) {
                              if (value != null) {
                                _emailController.text = value;
                                _messageController.text =
                                    'Hello, it\'s ${Auth.getUser?.email ?? 'me'}! I just scanned your QR code and want to add you as a contact.';
                                submitForm();
                                Navigator.pop(context);
                              }
                            },
                          ),
                        );
                      }),
                ],
              ),
            )),
      ),
    );
  }
}
