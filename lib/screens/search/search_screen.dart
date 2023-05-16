import 'package:flutter/material.dart';

import '../../ui_constants.dart';
import 'components/body.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
      ),
      body: Column(
        children: [
          // Appbar search
          Container(
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
          const Expanded(child: Body()),
        ],
      ),
    );
  }
}
