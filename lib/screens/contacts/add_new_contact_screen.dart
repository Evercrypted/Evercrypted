import 'package:evercrypted/screens/contacts/components/pending_request_card.dart';
import 'package:flutter/material.dart';

import '../../ui_constants.dart';
import '../search/components/body.dart';

class AddNewContactScreen extends StatefulWidget {
  static const routeName = '/add-new-contact';

  const AddNewContactScreen({Key? key}) : super(key: key);

  @override
  State<AddNewContactScreen> createState() => _AddNewContactScreenState();
}

class _AddNewContactScreenState extends State<AddNewContactScreen> {
  FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    super.dispose();
    _focus.removeListener(_onFocusChange);
    _focus.dispose();
  }

  void _onFocusChange() {
    debugPrint("Focus: ${_focus.hasFocus.toString()}");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add New Contact"),
      ),
      body: Column(
        children: [
          // Appbar search
          Container(
            margin: const EdgeInsets.only(bottom: defaultPadding),
            padding: const EdgeInsets.fromLTRB(
              defaultPadding,
              0,
              defaultPadding,
              defaultPadding,
            ),
            color: primaryColor,
            child: Form(
              child: TextFormField(
                focusNode: _focus,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (value) {
                  if (value.isEmpty) return;
                  showDialog<bool>(
                    context: context,
                    builder: (BuildContext context) => AlertDialog(
                      title: const Text('Confirm Contact Request'),
                      content: Text(
                          'Are you sure that you want to send a contact request to $value?'),
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
                  ).then((value) => print(value));
                },
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.email,
                    color: contentColorLightTheme.withOpacity(0.64),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send),
                  ),
                  hintText: "Email",
                  hintStyle: TextStyle(
                    color: contentColorLightTheme.withOpacity(0.64),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: defaultPadding),
                    child: Text(
                      "Pending Requests",
                      style: Theme.of(context).textTheme.subtitle2!.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .subtitle2!
                                .color!
                                .withOpacity(0.32),
                          ),
                    ),
                  ),
                  ...List.generate(
                    demoContactsImage.length,
                    (index) => PendingRequestCard(
                        email: "iraklikori@gmail.com",
                        requestSent:
                            DateTime.now().subtract(Duration(hours: 2)),
                        press: () {}),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
