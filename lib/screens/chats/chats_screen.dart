import 'package:evercrypted/widgets/search_header.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'components/chat_list.dart';

class ChatsScreen extends ConsumerStatefulWidget {
  const ChatsScreen({super.key});

  @override
  ChatsScreenState createState() => ChatsScreenState();
}

class ChatsScreenState extends ConsumerState<ChatsScreen> {
  bool searching = false;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  String searchValue = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchValue = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SearchHeader(
              label: const Text(
                'Chats',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              searching: searching,
              searchFocus: searchFocus,
              searchController: _searchController,
              onSearchIconPressed: () {
                setState(() {
                  searching = true;
                  searchFocus.requestFocus();
                  openSecretInput(
                      context: context, controller: _searchController);
                });
              },
              onCloseIconPressed: () {
                setState(() {
                  searching = false;
                  _searchController.clear();
                });
              }),
          SizedBox(
              height: MediaQuery.of(context).size.height - 243,
              child: ChatList(
                searchValue: searchValue,
              )),
        ],
      ),
    );
  }
}
