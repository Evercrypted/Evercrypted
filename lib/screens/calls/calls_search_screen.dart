import 'package:flutter/material.dart';

import '../../ui_constants.dart';
import '../search/components/body.dart';
import 'components/call_history_card.dart';

class CallsSearchScreen extends StatelessWidget {
  const CallsSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Calls"),
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
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) {
                  // search
                },
                decoration: InputDecoration(
                  fillColor: Colors.white,
                  prefixIcon: Icon(
                    Icons.search,
                    color: contentColorLightTheme.withOpacity(0.64),
                  ),
                  hintText: "Search",
                  hintStyle: TextStyle(
                    color: contentColorLightTheme.withOpacity(0.64),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              child: ListView(
                children: [
                  // For demo
                  ...List.generate(
                    demoContactsImage.length,
                    (index) => CallHistoryCard(
                      name: "Darlene Robert",
                      image: demoContactsImage[index],
                      time: "3m ago",
                      isActive: index.isEven,
                      isOutgoingCall: index.isOdd,
                      isVideoCall: index.isEven,
                      press: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
