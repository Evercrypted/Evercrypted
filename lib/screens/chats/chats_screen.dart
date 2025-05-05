import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:evercrypted/core/helpers/show_snackbar.dart';
import 'package:evercrypted/screens/contacts/contacts_screen.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/search_header.dart';
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

  final ChatService chatService = ChatService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  String searchValue = '';

  NewGroupChatDTO? newGroupChatDTO;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardNotifier = ref.read(keyboardProvider.notifier);
    return Scaffold(
      body: Column(
        children: [
          SearchHeader(
              label: Text('Chats', style: TextStyle(fontSize: 24)),
              searching: searching,
              searchFocus: searchFocus,
              searchController: _searchController,
              onTapHandler: () {
                keyboardNotifier.openKeyboard(
                  controller: _searchController,
                  onChange: (val) {
                    setState(() {
                      searchValue = val;
                    });
                  },
                  onClose: () => searchFocus.unfocus(),
                );
              },
              onSearchIconPressed: () {
                keyboardNotifier.openKeyboard(
                    controller: _searchController,
                    onChange: (val) {
                      setState(() {
                        searchValue = val;
                      });
                    },
                    onClose: () => searchFocus.unfocus());
                setState(() {
                  searching = true;
                  searchFocus.requestFocus();
                });
              },
              onCloseIconPressed: () {
                ref.read(keyboardProvider.notifier).close();
                setState(() {
                  searching = false;
                  searchValue = '';
                  _searchController.clear();
                });
              }),
          Expanded(
              child: ChatList(
            searchValue: searchValue,
          )),
        ],
      ),
      floatingActionButton: Tooltip(
        message: 'Create New Group',
        preferBelow: false,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ContactsScreen(
                  isParticipantSelect: true,
                  participants: null,
                  isGroupCreate: true,
                ),
              ),
            ).then((val) {
              newGroupChatDTO = NewGroupChatDTO(
                participants: val['participants'],
                name: val['groupName'],
              );

              chatService
                  .createNewGroupChat(newGroupChatDTO!)
                  .then((Chat chat) {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MessagesScreen(
                        chat: chat,
                      ),
                    ),
                  );
                }
              }).catchError((error) {
                if (context.mounted) {
                  showErrorSnackBar(context, error.toString());
                }
              });
            });
          },
          backgroundColor: primaryColor,
          child: const Icon(
            Icons.group_add,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
