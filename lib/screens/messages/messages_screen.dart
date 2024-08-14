import 'dart:async';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/base_key.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/services/app_state.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
import 'package:evercrypted/screens/messages/chat_settings_screen.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/connection_status_appbar.dart';
import 'package:evercrypted/models/chat_message.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../core/entities/message/message_isar.dart';
import '../../ui_constants.dart';
import '../../widgets/primary_button.dart';
import 'components/chat_input_field.dart';
import 'components/message.dart';

class MessagesScreen extends ConsumerStatefulWidget {
  final Chat chat;
  const MessagesScreen({super.key, required this.chat});

  @override
  MessagesScreenState createState() => MessagesScreenState();
}

class MessagesScreenState extends ConsumerState<MessagesScreen> {
  final settingsForm = GlobalKey<FormState>();
  final MessageService _messageService = MessageService();
  late Isar? isar = Isar.getInstance();
  final userId = Auth.user?.uid;
  late int startingCreatedAtMSE;
  int nextPageKey = 1;
  bool startedListeningToIsar = false;
  bool _passwordVisible = false;
  final TextEditingController _passController = TextEditingController();
  String? pass;
  late Chat chat;
  late String participantNames;

  String? baseKey;

  static const _pageSize = 10;

  StreamSubscription? _isarSubscription;

  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();

    chat = widget.chat;
    participantNames =
        chatParticipantNames(chat: chat, widgetRef: ref).join(', ');
    setBaseKey();

    AppState.setOpenedChatId(widget.chat.uid);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      openPasswordDialog(context);
    });

    getlastMessageCreatedAtMSE().then((value) {
      startingCreatedAtMSE = value ?? 0;
    }).then((value) async {
      _fetchPage(0).then((value) {
        listenToIsarChanges();
        _pagingController.addPageRequestListener((pageKey) {
          _fetchPage(pageKey);
        });
      });
    });
  }

  @override
  void deactivate() {
    AppState.setOpenedChatId(null);
    super.deactivate();
  }

  @override
  void dispose() async {
    _isarSubscription?.cancel();
    _passController.dispose();
    _pagingController.dispose();
    super.dispose();
  }

  void setBaseKey() async {
    BaseKey.getBase(chat.uid).then((key) {
      setState(() {
        baseKey = key;
      });
      print(baseKey);
    });
  }

  Future openPasswordDialog(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Wrap(children: [
            Container(
              color: primaryColor,
              padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Container(
                  margin: const EdgeInsets.all(defaultPadding),
                  padding: const EdgeInsets.fromLTRB(
                    defaultPadding,
                    0,
                    defaultPadding,
                    defaultPadding,
                  ),
                  child: Form(
                    key: settingsForm,
                    child: Column(
                      children: [
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: _passController,
                          maxLength: 32,
                          textInputAction: TextInputAction.done,
                          onTap: () {
                            openSecretInput(
                                context: context,
                                controller: _passController,
                                done: (val) => setState(() {
                                      if (val.text == null ||
                                          val.text.isEmpty) {
                                        pass = null;
                                      } else {
                                        var fullKeyString = val.text as String;
                                        if (fullKeyString.length < 32) {
                                          fullKeyString = fullKeyString +
                                              '0' * (32 - fullKeyString.length);
                                        }
                                        pass = fullKeyString;
                                      }
                                    }));
                          },
                          keyboardType: TextInputType.none,
                          obscureText: !_passwordVisible,
                          decoration: InputDecoration(
                            errorMaxLines: 3,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordVisible = !_passwordVisible;
                                });
                              },
                              icon: Icon(_passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                            ),
                            border: const OutlineInputBorder(
                              borderSide: BorderSide.none,
                              borderRadius:
                                  BorderRadius.all(Radius.circular(10)),
                            ),
                            fillColor: Colors.white,
                            prefixIcon: Icon(
                              Icons.password,
                              color: contentColorLightTheme.withOpacity(0.64),
                            ),
                            hintText: "Password",
                            hintStyle: TextStyle(
                              color: contentColorLightTheme.withOpacity(0.64),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: defaultPadding / 2),
                          child: const Text(
                            'Password can be Maximum 32 characters in Length',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        PrimaryButton(
                          text: 'DECRYPT',
                          press: () {
                            setState(() {
                              pass = _passController.text;
                              setState(() {
                                if (_passController.text.isEmpty) {
                                  pass = null;
                                } else {
                                  var fullKeyString = _passController.text;
                                  if (fullKeyString.length < 32) {
                                    fullKeyString = fullKeyString +
                                        '0' * (32 - fullKeyString.length);
                                  }
                                  pass = fullKeyString;
                                }
                              });
                            });
                            Navigator.pop(context);
                          },
                          color: secondaryColor,
                        )
                      ],
                    ),
                  )),
            ),
          ]);
        });
  }

  Future<int?> getlastMessageCreatedAtMSE() async {
    final lastMessageCreatedAtMSE = isar?.messages
        .where()
        .chatUidEqualTo(widget.chat.uid)
        .sortByCreatedAtMSE()
        .findFirstSync()
        ?.createdAtMSE;
    return lastMessageCreatedAtMSE;
  }

  void listenToIsarChanges() {
    startedListeningToIsar = true;
    Query<Message>? messagesQuery = isar?.messages
        .where()
        .chatUidEqualTo(widget.chat.uid)
        .filter()
        .createdAtMSEGreaterThan(startingCreatedAtMSE)
        .sortByCreatedAtMSEDesc()
        .limit(1)
        .build();

    Stream<List<Message>>? queryChanged =
        messagesQuery?.watch(fireImmediately: true);
    _isarSubscription?.cancel();
    _isarSubscription = queryChanged?.listen((messages) {
      messages.retainWhere((element) =>
          _pagingController.itemList
              ?.firstWhereOrNull((el) => el.id == element.id) ==
          null);
      _pagingController.itemList = [
        ...messages,
        ...(_pagingController.itemList ?? []),
      ];
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await _messageService.getMessagesFromDB(
          widget.chat.uid, pageKey, _pageSize);
      newItems.retainWhere((element) =>
          _pagingController.itemList
              ?.firstWhereOrNull((el) => el.id == element.id) ==
          null);
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.itemList = [
          ...(_pagingController.itemList ?? []),
          ...newItems,
        ];
        _pagingController.nextPageKey = null;
      } else {
        nextPageKey = pageKey + 1;
        _pagingController.itemList = [
          ...(_pagingController.itemList ?? []),
          ...newItems,
        ];
        _pagingController.nextPageKey = nextPageKey;
      }
      if (pageKey == 0 && newItems.isNotEmpty) {
        startingCreatedAtMSE = newItems.last.createdAtMSE;
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Chat>>(chatsProvider, (prev, next) {
      setState(() {
        chat = next.firstWhere((c) => c.uid == widget.chat.uid);
        if (chat.syncRequired == false) {
          setBaseKey();
        }
      });

      if (chat.name == null) {
        participantNames =
            chatParticipantNames(chat: chat, widgetRef: ref).join(', ');
      }
    });

    return Scaffold(
        appBar: ConnectionStatusAppbar(
          title: Row(
            children: [
              CircleAvatarWithActiveIndicator(
                image: chat.avatar?.pic,
                radius: 28,
                name: (chat.name ?? participantNames),
              ),
              const SizedBox(width: defaultPadding * 0.5),
              Expanded(
                child: Text(
                  chat.name ?? participantNames,
                  style: const TextStyle(fontSize: 16),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings),
              color: primaryColor,
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ChatSettingsScreen(chat)));
              },
            ),
            SizedBox(
              width: 34,
              height: 34,
              child: Stack(
                children: [
                  IconButton(
                      visualDensity: VisualDensity.compact,
                      style: ButtonStyle(
                          padding: WidgetStateProperty.all<EdgeInsets>(
                              const EdgeInsets.all(0)),
                          shape:
                              WidgetStateProperty.all<RoundedRectangleBorder>(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20.0),
                                      side: BorderSide(
                                          width: 2,
                                          color: pass == null
                                              ? Colors.redAccent
                                              : primaryColor)))),
                      icon: Icon(Icons.security,
                          size: 22,
                          color:
                              pass == null ? Colors.redAccent : primaryColor),
                      onPressed: () {
                        openPasswordDialog(context);
                      }),
                  Positioned(
                    right: 1,
                    bottom: 1,
                    child: Container(
                      height: 12,
                      width: 12,
                      decoration: BoxDecoration(
                        color: chat.syncRequired == true
                            ? Colors.redAccent
                            : primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Theme.of(context).scaffoldBackgroundColor,
                            width: 2),
                      ),
                    ),
                  )
                ],
              ),
            ),
            SizedBox(width: defaultPadding / 4),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: PagedListView<int, Message>(
                  reverse: true,
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<Message>(
                      newPageProgressIndicatorBuilder: (context) => Container(),
                      itemBuilder: (context, item, index) {
                        final chatMessage = ChatMessage(
                          text: item.text!,
                          messageType: MessageTypes.text,
                          isSender: item.authorId == userId,
                          isSystemMessage:
                              item.messageType == MessageTypes.system,
                          messageStatus: MessageStatus.successfullySent,
                          pass: pass,
                          iv: item.iv,
                          mac: item.mac,
                          encryptionStatus: item.iv != null && item.mac != null
                              ? EncryptionStatus.encrypted
                              : EncryptionStatus.notEncrypted,
                        );
                        return MessageWidget(
                          key: ValueKey(item.id),
                          message: chatMessage,
                          sender: chat.participants.firstWhereOrNull(
                              (element) => element.uid == item.authorId),
                        );
                      }),
                ),
              ),
            ),
            ChatInputField(
              chatId: chat.uid,
              pass: pass,
            ),
          ],
        ));
  }
}
