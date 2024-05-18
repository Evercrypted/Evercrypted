import 'package:evercrypted/core/entities/contact/contact_model.dart';
import 'package:evercrypted/core/entities/contact/contact_service.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/connection_status_appbar.dart';
import 'package:flutter/material.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({
    super.key,
    required this.contact,
  });

  final Contact contact;

  @override
  ContactScreenState createState() => ContactScreenState();
}

class ContactScreenState extends State<ContactScreen> {
  ContactService contactService = ContactService();

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
            isActive: false,
            radius: 64,
            name: widget.contact.name ?? widget.contact.email!.split('@')[0],
          )),
          const SizedBox(height: 20),
          Text(
            widget.contact.name ?? widget.contact.email!,
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
                    onTap: () {},
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
                    onTap: () {},
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
                      contactService.deleteContact(widget.contact.uid!);
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
