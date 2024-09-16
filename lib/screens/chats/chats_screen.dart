import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/helpers/show_snackbar.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
import 'package:evercrypted/screens/contacts/contacts_screen.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/primary_button.dart';
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

  final ChatService chatService = ChatService();

  final TextEditingController _searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();
  String searchValue = '';

  final TextEditingController newGroupName = TextEditingController();

  NewGroupChatDTO? newGroupChatDTO;
  String name = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchValue = _searchController.text;
      });
    });
    newGroupName.addListener(() {
      setState(() {
        name = newGroupName.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    searchFocus.dispose();
    newGroupName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
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
                ),
              ),
            ).then((val) {
              if (val == null) {
                return;
              }
              newGroupChatDTO = NewGroupChatDTO(
                participants: val,
              );
              if (context.mounted) {
                showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (BuildContext context) {
                      return StatefulBuilder(builder: (context, setModalState) {
                        bool isEmpty = newGroupName.text.isEmpty;
                        return Wrap(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.all(defaultPadding),
                              child: Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  CircleAvatarWithActiveIndicator(
                                    image: newGroupChatDTO?.avatar?.pic,
                                    radius: 50,
                                    name: newGroupChatDTO?.name ??
                                        chatParticipantNames(
                                                chat: newGroupChatDTO,
                                                widgetRef: ref)
                                            .join(', '),
                                  ),
                                  Padding(
                                    padding:
                                        const EdgeInsets.only(left: 5, top: 5),
                                    child: InkWell(
                                      onTap: () {},
                                      child: const CircleAvatar(
                                        backgroundColor: Colors.white,
                                        radius: 17,
                                        child: CircleAvatar(
                                          radius: 15,
                                          backgroundColor: lightGrey,
                                          child: Icon(
                                            Icons.file_upload_outlined,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: defaultPadding * 2),
                              child: Row(
                                children: [
                                  const Text(
                                    'Enter Group Name:',
                                    style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      autofocus: true,
                                      controller: newGroupName,
                                      onTap: () {
                                        openSecretInput(
                                            context: context,
                                            controller: newGroupName,
                                            done: (val) {
                                              setModalState(() {
                                                isEmpty = val.text.isEmpty;
                                              });
                                            });
                                      },
                                      keyboardType: TextInputType.none,
                                      decoration: InputDecoration(
                                        border: const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                        ),
                                        focusedBorder:
                                            const UnderlineInputBorder(
                                          borderSide: BorderSide(
                                            color: Colors.grey,
                                            width: 1,
                                          ),
                                        ),
                                        fillColor: Colors.white,
                                        hintStyle: TextStyle(
                                          color: contentColorLightTheme
                                              .withOpacity(0.64),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              margin: const EdgeInsets.only(
                                top: defaultPadding * 2,
                                left: defaultPadding,
                                right: defaultPadding,
                              ),
                              padding: const EdgeInsets.only(
                                  bottom: defaultPadding / 4),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.shade300, width: 1),
                                ),
                              ),
                              child: const Text(
                                'Participants',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            SizedBox(
                              height: 300,
                              child: ListView(
                                padding: const EdgeInsets.all(defaultPadding),
                                shrinkWrap: true,
                                children: [
                                  for (var contact in val)
                                    Container(
                                      margin: const EdgeInsets.only(
                                          bottom: defaultPadding / 3),
                                      child: Row(
                                        children: [
                                          CircleAvatarWithActiveIndicator(
                                            image: contact.avatar?.pic,
                                            radius: 24,
                                            name: contact.name ?? contact.email,
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: defaultPadding),
                                            child: SizedBox(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width -
                                                  4 * defaultPadding -
                                                  130,
                                              child: Text(
                                                contact.name ?? contact.email!,
                                                style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight:
                                                        FontWeight.w500),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: defaultPadding,
                                  vertical: defaultPadding * 2),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  SizedBox(
                                    width:
                                        MediaQuery.of(context).size.width / 2 -
                                            2 * defaultPadding,
                                    child: PrimaryButton(
                                      color: lightGrey,
                                      press: () {
                                        Navigator.pop(context, false);
                                      },
                                      child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.close,
                                              color: Colors.white),
                                          SizedBox(width: 10),
                                          Text('Cancel',
                                              style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold))
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      width: MediaQuery.of(context).size.width /
                                              2 -
                                          2 * defaultPadding,
                                      child: PrimaryButton(
                                          disabled: isEmpty,
                                          press: () {
                                            if (newGroupName.text.isEmpty) {
                                              setModalState(() {
                                                isEmpty = true;
                                              });
                                              return;
                                            }
                                            newGroupChatDTO = newGroupChatDTO!
                                                .copyWith(
                                                    name: newGroupName.text);
                                            Navigator.pop(context, true);
                                          },
                                          child: const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(Icons.check,
                                                  color: Colors.white),
                                              SizedBox(width: 10),
                                              Text('Create Group',
                                                  style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.bold))
                                            ],
                                          ))),
                                ],
                              ),
                            )
                          ],
                        );
                      });
                    }).then((val) {
                  if (val != null && val) {
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
                  }
                  newGroupName.clear();
                });
              }
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
