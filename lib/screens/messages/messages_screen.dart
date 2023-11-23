import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/models/ChatMessage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:isar/isar.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../core/entities/message/message_isar.dart';
import '../../ui_constants.dart';
import '../../widgets/primary_button.dart';
import 'components/chat_input_field.dart';
import 'components/message.dart';

class MessagesScreen extends StatefulWidget {
  final Chat chat;
  const MessagesScreen({super.key, required this.chat});
  static const routeName = '/messages-screen';

  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  final settingsForm = GlobalKey<FormState>();
  final MessageService _messageService = MessageService();
  late Isar isar;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  late int startingCreateAtMSE;
  int nextPageKey = 1;
  bool startedListeningToIsar = false;
  bool _passwordVisible = false;
  bool _ivVisible = false;
  String? pass;
  String? iv;

  static const _pageSize = 10;

  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 1);

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      openPasswordDialog(context).then((value) {
        getlastMessageCreatedAtMSE().then((value) {
          startingCreateAtMSE = value ?? 0;
        }).then((value) async {
          if (startingCreateAtMSE == 0) {
            await Future.delayed(const Duration(seconds: 1));
          }
          _pagingController.addPageRequestListener((pageKey) {
            if (!startedListeningToIsar) {
              _fetchPage(pageKey).then((value) {
                listenToIsarChanges();
              });
            } else {
              _fetchPage(pageKey);
            }
          });
          _fetchPage(0).then((value) {});
        });
      });
    });
  }

  @override
  void dispose() {
    isar.close();
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
                          validator: (val) {
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onSaved: (value) {
                            setState(() {
                              pass = value;
                            });
                          },
                          keyboardType: TextInputType.text,
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
                        TextFormField(
                          validator: (val) {
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onSaved: (value) {
                            setState(() {
                              iv = value;
                            });
                          },
                          keyboardType: TextInputType.text,
                          obscureText: !_ivVisible,
                          decoration: InputDecoration(
                            errorMaxLines: 3,
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _ivVisible = !_ivVisible;
                                });
                              },
                              icon: Icon(_ivVisible
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
                              Icons.lock,
                              color: contentColorLightTheme.withOpacity(0.64),
                            ),
                            hintText: "Initialization Vector",
                            hintStyle: TextStyle(
                              color: contentColorLightTheme.withOpacity(0.64),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: defaultPadding / 2),
                          child: const Text(
                            'Initialization Vector can be of any length, but it\'s length will affect the encryption strength and the decryption speed',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        PrimaryButton(
                          text: 'DECRYPT',
                          press: () {
                            if (settingsForm.currentState!.validate()) {
                              settingsForm.currentState!.save();
                              Navigator.pop(context);
                            }
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
    final lastMessageCreatedAtMSE = isar.messages
        .where()
        .uidEqualTo(widget.chat.uid)
        .sortByCreatedAtMSE()
        .findFirstSync()
        ?.createdAtMSE;
    return lastMessageCreatedAtMSE;
  }

  void listenToIsarChanges() {
    startedListeningToIsar = true;
    Query<Message> messagesQuery = isar.messages
        .where()
        .chatUidEqualTo(widget.chat.uid)
        .filter()
        .createdAtMSEGreaterThan(startingCreateAtMSE)
        .sortByCreatedAtMSE()
        .limit(1)
        .build();

    Stream<List<Message>> queryChanged =
        messagesQuery.watch(fireImmediately: true);
    queryChanged.listen((messages) {
      _pagingController.value = PagingState(
          itemList: [...messages, ...(_pagingController.itemList ?? [])],
          nextPageKey: nextPageKey);
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems =
          await _messageService.getMessagesFromDB(pageKey, _pageSize);
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
      if (pageKey == 0 && newItems.isNotEmpty) {
        startingCreateAtMSE = newItems.first.createdAtMSE;
      }
    } catch (error) {
      _pagingController.error = error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildAppBar(context),
        body: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: defaultPadding),
                child: PagedListView<int, Message>(
                  reverse: true,
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<Message>(
                      itemBuilder: (context, item, index) {
                    final chatMessage = ChatMessage(
                      text: item.text!,
                      messageType: ChatMessageType.text,
                      isSender: item.authorId == userId,
                      messageStatus: MessageStatus.viewed,
                    );
                    return MessageWidget(
                        message: chatMessage, pass: pass, iv: iv);
                  }),
                ),
              ),
            ),
            ChatInputField(chatId: widget.chat.uid!, pass: pass, iv: iv),
          ],
        ));
  }

  AppBar buildAppBar(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      title: const Row(
        children: [
          BackButton(),
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
      actions: [
        IconButton(
            icon: Icon(Icons.security,
                color: pass == null && iv == null
                    ? Colors.redAccent
                    : Colors.white),
            onPressed: () {
              openPasswordDialog(context);
            }),
        const SizedBox(width: defaultPadding / 2),
      ],
    );
  }
}
