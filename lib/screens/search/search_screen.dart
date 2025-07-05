import 'package:flutter/material.dart';

import '../../ui_constants.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

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
                    color: contentColorLightTheme.withAlpha(
                      (255 * 0.64).round(),
                    ),
                  ),
                  hintText: "Search",
                  hintStyle: TextStyle(
                    color: contentColorLightTheme.withAlpha(
                      (255 * 0.64).round(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
