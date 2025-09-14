import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_text_controller.dart';
import 'package:evercrypted/core/helpers/show_snackbar.dart';
import 'package:evercrypted/core/navigation/navigation_state.dart';
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
  final ChatService chatService = ChatService();

  final EvercryptedTextController _searchController =
      EvercryptedTextController();
  String searchValue = '';

  NewGroupChatDTO? newGroupChatDTO;

  void _onSearchChanged() {
    setState(() {
      searchValue = _searchController.text;
    });
  }

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_onSearchChanged);

    // Set navigation state to chats when this screen is active
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navigationProvider.notifier).navigateToChats();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SearchHeader(
              label: Text('Chats', style: TextStyle(fontSize: 24)),
              searching: false,
              searchController: _searchController,
              hintText: 'Search chats...',
              onCloseIconPressed: () {
                setState(() {
                  searchValue = '';
                  _searchController.clear();
                });
                // Unfocus the search field to close the keyboard
                _searchController.unfocus();
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
