import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_service.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/core/services/block_service.dart';
import 'package:evercrypted/widgets/evercrypted_text_field.dart';
import 'package:evercrypted/core/services/hidden_contact_service.dart';
import 'package:evercrypted/screens/profile/components/profile_pic.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/connection_status_appbar.dart';
import 'package:evercrypted/widgets/password_dialog.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:evercrypted/widgets/material_icon_registry.dart';

class ContactScreen extends ConsumerStatefulWidget {
  const ContactScreen({
    super.key,
    required this.contact,
  });

  final Contact contact;

  @override
  ContactScreenState createState() => ContactScreenState();
}

class ContactScreenState extends ConsumerState<ContactScreen> {
  ContactService contactService = ContactService();
  ChatService chatService = ChatService();
  HiddenContactService hiddenContactService = HiddenContactService();
  final EvercryptedTextController _renamingController =
      EvercryptedTextController();

  bool renaming = false;

  late String name = widget.contact.displayName ?? widget.contact.email!;

  @override
  void initState() {
    super.initState();
    _renamingController.text = name;
    _renamingController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _renamingController.dispose();
    super.dispose();
  }

  _rename() {
    ref.read(keyboardProvider.notifier).close();
    contactService.renameContact(widget.contact.uid!, _renamingController.text);
    setState(() {
      renaming = false;
      name = _renamingController.text;
    });
  }

  _deleteContact(context) {
    showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Confirm Contact Request'),
        content:
            Text('Are you sure that you want to delete $name from contacts?'),
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
        contactService.deleteContact(widget.contact.uid!);
        if (context.mounted) {
          Navigator.pop(context);
        }
      }
    });
  }

  Future<bool> _showConfirmationDialog({
    required String title,
    required String content,
    required String confirmText,
    Color? confirmColor,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(content),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: confirmColor ?? errorColor,
                  ),
                  child: Text(confirmText),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      appBar: const ConnectionStatusAppbar(
        title: Text('Contact Information'),
      ),
      body: SingleChildScrollView(
          child: Column(
        children: [
          const SizedBox(height: 30),
          Center(
              child: ProfilePic(
            image: widget.contact.avatar?.pic,
            radius: 64,
            name: name,
            avatarColor: widget.contact.avatar?.color != null
                ? Color(int.parse(widget.contact.avatar!.color!))
                : null,
            avatarIcon: widget.contact.avatar?.icon != null
                ? MaterialIconRegistry.iconDataFromCodePoint(
                    int.parse(widget.contact.avatar!.icon!))
                : null,
            icon: widget.contact.isFavorite ? Icons.star : Icons.star_border,
            circleRadius: 20,
            iconsSize: 30,
            iconBackgroundColor: Colors.white,
            iconColor: Colors.amber,
            iconBorderColor: primaryColor,
            confirmText: widget.contact.isFavorite
                ? 'You want to Remove this contact from the favorites list?'
                : 'You want to Add this contact to the favorites list?',
            btnPress: () {
              contactService.toggleFavorite(widget.contact.uid!);
              setState(() {
                widget.contact.isFavorite = !widget.contact.isFavorite;
              });
            },
          )),
          const SizedBox(height: 20),
          if (renaming)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    margin: const EdgeInsets.only(left: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: 1,
                        color: primaryColor,
                      ),
                    ),
                    width: MediaQuery.of(context).size.width - 150,
                    child: EvercryptedTextField(
                      controller: _renamingController,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        hintStyle: TextStyle(
                          color: contentColorLightTheme
                              .withAlpha((255 * 0.64).round()),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    color: _renamingController.text.trim().isEmpty
                        ? Colors.grey
                        : primaryColor,
                    onPressed: _renamingController.text.trim().isEmpty
                        ? null
                        : () {
                            _rename();
                          },
                  ),
                  IconButton(
                      color: errorColor,
                      onPressed: () {
                        ref.read(keyboardProvider.notifier).close();
                        setState(() {
                          renaming = false;
                        });
                      },
                      icon: const Icon(Icons.close))
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              widget.contact.email!,
              style: const TextStyle(
                fontSize: 16,
                color: lightGrey,
              ),
            ),
          ),
          const SizedBox(height: 40),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextButton.icon(
                onPressed: () {
                  chatService.openOneToOneChat(context, ref, widget.contact);
                },
                icon: const Icon(Icons.chat),
                label: const Text(
                  'Open Chat',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 5),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    renaming = true;
                  });
                  _renamingController.selection = TextSelection.collapsed(
                    offset: _renamingController.text.length,
                  );
                  _renamingController.focus();
                },
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Rename Contact',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 5),
              TextButton.icon(
                onPressed: () {
                  if (hiddenContactService.isContactHidden(
                      widget.contact.contactPersonUid!, profile)) {
                    // Show confirmation to unhide
                    _showConfirmationDialog(
                      title: 'Unhide Contact',
                      content: 'Are you sure you want to unhide this contact?',
                      confirmText: 'Unhide',
                      confirmColor: primaryColor,
                    ).then((confirmed) {
                      if (confirmed) {
                        hiddenContactService
                            .unhideContact(widget.contact.contactPersonUid!);
                        setState(() {}); // Refresh the UI
                      }
                    });
                  } else {
                    // Show password dialog to hide
                    PasswordDialog.show(
                      context: context,
                      ref: ref,
                      title: 'Hide Contact',
                      description:
                          'This contact will be hidden from your contact list. You can access it by entering the password in the search field.',
                      hintText: 'Enter password to hide contact',
                      confirmButtonText: 'Hide Contact',
                      onConfirm: (password) {
                        hiddenContactService.hideContact(
                            widget.contact.contactPersonUid!, password);
                        Navigator.pop(context); // Go back to contacts list
                      },
                    );
                  }
                },
                icon: Icon(
                  hiddenContactService.isContactHidden(
                          widget.contact.contactPersonUid!, profile)
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                label: Text(
                  hiddenContactService.isContactHidden(
                          widget.contact.contactPersonUid!, profile)
                      ? 'Unhide Contact'
                      : 'Hide Contact',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 5),
              TextButton.icon(
                  onPressed: () {
                    _deleteContact(context);
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: errorColor,
                  ),
                  label: const Text(
                    'Delete Contact',
                    style: TextStyle(fontSize: 16, color: errorColor),
                  )),
              const SizedBox(height: 5),
              TextButton.icon(
                  onPressed: () {
                    _showConfirmationDialog(
                      title: 'Block Contact',
                      content:
                          'Are you sure you want to block ${widget.contact.email}? They won\'t be able to send you messages or contact requests. This will also delete the contact.',
                      confirmText: 'Block',
                    ).then((confirmed) async {
                      if (confirmed) {
                        final success = await BlockService.blockUser(
                            widget.contact.contactPersonUid!);
                        if (success) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('User blocked successfully'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        } else {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Failed to block user. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      }
                    });
                  },
                  icon: const Icon(
                    Icons.block,
                    color: Colors.orange,
                  ),
                  label: const Text(
                    'Block Contact',
                    style: TextStyle(fontSize: 16, color: Colors.orange),
                  )),
            ],
          )
        ],
      )),
    );
  }
}
