import 'dart:async';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/services/app_state_riverpod.dart';
import 'package:evercrypted/core/services/appbar_service.dart';
import 'package:evercrypted/models/ChatMessage.dart';
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

  static const _pageSize = 10;

  StreamSubscription? _isarSubscription;

  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration.zero, () {
      ref.read(appStateProvider.notifier).setOpenedChatId(widget.chat.uid);
    });

    SchedulerBinding.instance.addPostFrameCallback((_) {
      openPasswordDialog(context).then((value) {
        getlastMessageCreatedAtMSE().then((value) {
          startingCreatedAtMSE = value ?? 0;
        }).then((value) async {
          if (startingCreatedAtMSE == 0) {
            await Future.delayed(const Duration(seconds: 1));
          }
          _fetchPage(0).then((value) {
            listenToIsarChanges();
            _pagingController.addPageRequestListener((pageKey) {
              _fetchPage(pageKey);
            });
          });
        });
      });
    });
  }

  @override
  void deactivate() {
    ref.read(appStateProvider.notifier).setOpenedChatId(null);
    super.deactivate();
  }

  @override
  void dispose() async {
    _isarSubscription?.cancel();
    _passController.dispose();
    _pagingController.dispose();
    super.dispose();
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
                            showDialog(
                                context: context,
                                builder: (BuildContext context) =>
                                    Dialog.fullscreen(
                                      child: SecretInput(
                                        originalText: pass,
                                      ),
                                    )).then((value) {
                              if (value.text.isNotEmpty) {
                                _passController.text = value.text;
                              }
                              if (value.done) {
                                setState(() {
                                  pass = _passController.text;
                                });
                              }
                            });
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
      final newItems =
          await _messageService.getMessagesFromDB(pageKey, _pageSize);
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
    return Scaffold(
        appBar: buildAppBar(context, ref),
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
                          messageType: ChatMessageType.text,
                          isSender: item.authorId == userId,
                          messageStatus: MessageStatus.viewed,
                        );
                        return MessageWidget(message: chatMessage, pass: pass);
                      }),
                ),
              ),
            ),
            ChatInputField(
              chatId: widget.chat.uid,
              pass: pass,
            ),
          ],
        ));
  }

  AppBar? buildAppBar(BuildContext context, WidgetRef ref) {
    return AppbarService.getAppbar(
      ref,
      const Row(
        children: [
          CircleAvatar(
            backgroundImage: AssetImage("assets/images/user_2.png"),
          ),
          SizedBox(width: defaultPadding * 0.75),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Kristin Watson",
                style: TextStyle(fontSize: 16),
              ),
            ],
          )
        ],
      ),
      [
        IconButton(
            icon: Icon(Icons.security,
                color: pass == null ? Colors.redAccent : primaryColor),
            onPressed: () {
              openPasswordDialog(context);
            }),
        const SizedBox(width: defaultPadding / 2),
      ],
    );
  }
}
