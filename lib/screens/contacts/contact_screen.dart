import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_service.dart';
import 'package:evercrypted/screens/profile/components/profile_pic.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/connection_status_appbar.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  final TextEditingController _renamingController = TextEditingController();

  bool renaming = false;

  late String name = widget.contact.name ?? widget.contact.email!;

  @override
  void initState() {
    super.initState();
    _renamingController.text = name;
  }

  @override
  void dispose() {
    _renamingController.dispose();
    super.dispose();
  }

  _rename() {
    contactService.renameContact(widget.contact.uid!, _renamingController.text);
    setState(() {
      renaming = false;
      name = _renamingController.text;
    });
  }

  _deleteContact() {
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
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
            icon: widget.contact.isFavorite ? Icons.star : Icons.star_border,
            circleRadius: 20,
            iconsSize: 30,
            iconBackgroundColor: Colors.white,
            iconColor: Colors.amber,
            iconBorderColor: primaryColor,
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        width: 1,
                        color: primaryColor,
                      ),
                    ),
                    width: MediaQuery.of(context).size.width - 150,
                    child: TextFormField(
                      controller: _renamingController,
                      onTap: () {
                        openSecretInput(
                            context: context,
                            controller: _renamingController,
                            done: (val) => _rename());
                      },
                      keyboardType: TextInputType.none,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(10)),
                        ),
                        fillColor: Colors.white,
                        hintStyle: TextStyle(
                          color: contentColorLightTheme.withOpacity(0.64),
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.check),
                    color: primaryColor,
                    onPressed: () {
                      _rename();
                    },
                  ),
                  IconButton(
                      color: errorColor,
                      onPressed: () {
                        setState(() {
                          renaming = false;
                        });
                      },
                      icon: const Icon(Icons.close))
                ],
              ),
            )
          else
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 10),
          Text(
            widget.contact.email!,
            style: const TextStyle(
              fontSize: 16,
              color: lightGrey,
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
                  style: TextStyle(fontSize: 16, color: contentColorLightTheme),
                ),
              ),
              const SizedBox(height: 5),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    renaming = true;
                  });
                },
                icon: const Icon(Icons.edit),
                label: const Text(
                  'Rename Contact',
                  style: TextStyle(fontSize: 16, color: contentColorLightTheme),
                ),
              ),
              const SizedBox(height: 5),
              TextButton.icon(
                  onPressed: () {
                    _deleteContact();
                  },
                  icon: const Icon(
                    Icons.delete,
                    color: errorColor,
                  ),
                  label: const Text(
                    'Delete Contact',
                    style:
                        TextStyle(color: contentColorLightTheme, fontSize: 16),
                  )),
            ],
          )
        ],
      )),
    );
  }
}
