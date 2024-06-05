import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_service.dart';
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
  final _renamingController = TextEditingController();

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
              child: CircleAvatarWithActiveIndicator(
            image: widget.contact.avatar?.pic,
            radius: 64,
            name: name,
          )),
          const SizedBox(height: 20),
          if (renaming)
            Row(
              children: [
                Container(
                  margin: const EdgeInsets.only(left: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      width: 2,
                      color: primaryColor,
                    ),
                  ),
                  width: MediaQuery.of(context).size.width - 110,
                  child: TextFormField(
                    controller: _renamingController,
                    onTap: () {
                      showDialog(
                          context: context,
                          builder: (BuildContext context) => Dialog.fullscreen(
                                child: SecretInput(
                                  originalText: _renamingController.text,
                                ),
                              )).then((value) {
                        if (value.text.isNotEmpty) {
                          _renamingController.text = value.text;
                        }
                        if (value.done) {
                          _rename();
                        }
                      });
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
                  color: Colors.white,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(primaryColor),
                    shape: WidgetStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  onPressed: () {
                    _rename();
                  },
                ),
                IconButton(
                    color: Colors.white,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all(Colors.red),
                      shape: WidgetStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        renaming = false;
                      });
                    },
                    icon: const Icon(Icons.close))
              ],
            )
          else
            Text(
              name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Material(
                color: primaryColor,
                borderRadius: BorderRadius.circular(5),
                child: InkWell(
                    onTap: () {
                      chatService.openChat(context, ref, widget.contact);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      width: 100,
                      height: 100,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.chat,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Open Chat',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    )),
              ),
              Material(
                color: primaryColor,
                borderRadius: BorderRadius.circular(5),
                child: InkWell(
                    onTap: () {
                      setState(() {
                        renaming = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      width: 100,
                      height: 100,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Rename Contact',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    )),
              ),
              Material(
                color: Colors.red,
                borderRadius: BorderRadius.circular(5),
                child: InkWell(
                    onTap: () {
                      _deleteContact();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      width: 100,
                      height: 100,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 25,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'Delete Contact',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ),
                    )),
              ),
            ],
          )
        ],
      )),
    );
  }
}
