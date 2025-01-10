import 'dart:async';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/base_key.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/services/app_state.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
import 'package:evercrypted/screens/messages/chat_settings_screen.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/connection_status_appbar.dart';
import 'package:evercrypted/models/chat_message.dart';
import 'package:evercrypted/widgets/secret_keyboard/secret_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:collection/collection.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:swipe_to/swipe_to.dart';

import '../../core/entities/message/message_model.dart';
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

  StreamSubscription? basekeyListener;

  final FlutterSoundPlayer player = FlutterSoundPlayer();

  static const _pageSize = 10;

  StreamSubscription? _isarSubscription;

  final PagingController<int, Message> _pagingController =
      PagingController(firstPageKey: 1);

  late StreamSubscription isConnectedListener;
  bool isConnected = ChatSocket.isConnectedSubject.value;

  final fabKey = GlobalKey<ExpandableFabState>();
  bool showFab = false;

  @override
  void initState() {
    super.initState();

    isConnectedListener =
        ChatSocket.isConnectedSubject.stream.listen((isConnected) async {
      setState(() {
        this.isConnected = isConnected;
      });
    });

    chat = widget.chat;
    participantNames =
        chatParticipantNames(chat: chat, widgetRef: ref).join(', ');

    basekeyListener = BaseKey.baseKeySubject.stream.listen((chatUid) {
      if (chatUid == chat.uid) {
        setBaseKey();
      }
    });

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
    isConnectedListener.cancel();
    _isarSubscription?.cancel();
    _passController.dispose();
    _pagingController.dispose();
    basekeyListener?.cancel();
    super.dispose();
  }

  void setBaseKey() async {
    BaseKey.getKeys(chat.uid).then((keys) {
      setState(() {
        baseKey = keys?.baseKey;
      });
    });
  }

  setPass(value) {
    setState(() {
      if (value == null || value.isEmpty) {
        pass = null;
      } else {
        pass = value;
      }
    });
  }

  Future openPasswordDialog(BuildContext context) {
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (BuildContext context) {
          return Wrap(children: [
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20)),
              ),
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
                        if (chat.isOneToOne)
                          baseKey == null
                              ? const Icon(Icons.security,
                                  color: Colors.redAccent)
                              : const Icon(Icons.security, color: Colors.white),
                        if (chat.isOneToOne)
                          Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: defaultPadding / 2),
                            child: Text(
                              baseKey == null
                                  ? 'Chat Base-Encryption-Key is not synchronized yet. The other party needs to open Evercrypted at least once to generate base encryption key, until then all sent messages will only be encrypted with entered password and make sure it is hard to guess.'
                                  : 'Base-Encryption-Key has successfully been synchronized. All the passwords less then 32 characters will automatically be reinforced with the synchronized key.',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        if (!chat.isOneToOne)
                          Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: defaultPadding / 2),
                            child: const Text(
                              'All the encryption in group chats is done with only the entered password. Make sure it is hard to guess.',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                        const SizedBox(height: defaultPadding / 2),
                        TextFormField(
                          controller: _passController,
                          maxLength: 32,
                          textInputAction: TextInputAction.done,
                          onTap: () {
                            openSecretInput(
                                isSingleLine: true,
                                obscureText: true,
                                context: context,
                                controller: _passController,
                                done: (val) => setPass(val.text));
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
                              color: contentColorLightTheme
                                  .withAlpha((0.64 * 255).round()),
                            ),
                            hintText: "Password",
                            hintStyle: TextStyle(
                              color: contentColorLightTheme
                                  .withAlpha((0.64 * 255).round()),
                            ),
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(
                              vertical: defaultPadding / 2),
                          child: const Text(
                            'Password can be Maximum 32 characters in Length.',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        PrimaryButton(
                          text: 'DECRYPT',
                          press: () {
                            setPass(_passController.text);
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
    final query = obx.messages
        .query(Message_.chatUid.equals(widget.chat.uid))
        .order(Message_.createdAtMSE)
        .build();
    final message = query.findFirst();
    query.close();
    final lastMessageCreatedAtMSE = message?.createdAtMSE;
    return lastMessageCreatedAtMSE;
  }

  void listenToIsarChanges() {
    startedListeningToIsar = true;
    final query = obx.messages
        .query(Message_.chatUid
            .equals(widget.chat.uid)
            .and(Message_.createdAtMSE.greaterThan(startingCreatedAtMSE)))
        .order(Message_.createdAtMSE, flags: Order.descending);

    Stream<List<Message>>? queryChanged =
        query.watch(triggerImmediately: true).map((query) => query.find());
    _isarSubscription?.cancel();
    _isarSubscription = queryChanged.listen((messages) {
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
          widget.chat.id, pageKey, _pageSize);
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

  onDelete({close = false}) {
    if (showFab) {
      fabKey.currentState?.toggle();
      setState(() {
        showFab = false;
      });
    } else {
      setState(() {
        showFab = true;
      });
      Future.delayed(const Duration(milliseconds: 100), () {
        fabKey.currentState?.toggle();
      });
    }
  }

  deteleMessages() async {
    try {
      await _messageService.deleteAllMessages(widget.chat.uid);

      // Only update UI after successful deletion
      if (mounted) {
        setState(() {
          _pagingController.itemList = [];
        });
        // Double toggle - first closes "Are you sure?", second closes the FAB
        fabKey.currentState?.toggle();
      }
    } catch (e) {
      // Handle error - revert UI if needed
      if (mounted) {
        // Show error to user
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete messages: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Chat>>(chatsProvider, (prev, next) {
      setState(() {
        late final Chat? chatOrNull;
        chatOrNull = next.firstWhereOrNull((c) => c.uid == widget.chat.uid);
        if (chatOrNull != null) {
          chat = chatOrNull;
          setBaseKey();
        } else {
          Navigator.popUntil(context, (r) => r.isFirst);
        }
      });

      if (chat.name == null) {
        participantNames =
            chatParticipantNames(chat: chat, widgetRef: ref).join(', ');
      }
    });

    return Scaffold(
        appBar: ConnectionStatusAppbar(
          isConnected: isConnected,
          title: Row(
            children: [
              CircleAvatarWithActiveIndicator(
                image: chat.avatar?.pic,
                radius: isConnected ? 28 : 14,
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
                        color: !chat.isOneToOne
                            ? Colors.grey
                            : baseKey == null
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
            const SizedBox(width: defaultPadding / 4),
          ],
        ),
        bottomNavigationBar: ChatInputField(
            chatId: chat.uid,
            baseKey: baseKey,
            pass: pass,
            player: player,
            onDelete: onDelete),
        floatingActionButton: showFab
            ? ExpandableFab(
                key: fabKey,
                pos: ExpandableFabPos.left,
                openButtonBuilder: RotateFloatingActionButtonBuilder(
                  child: const Icon(Icons.delete),
                  fabSize: ExpandableFabSize.small,
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.red,
                ),
                closeButtonBuilder: DefaultFloatingActionButtonBuilder(
                  child: const Icon(Icons.close),
                  fabSize: ExpandableFabSize.small,
                  foregroundColor: Colors.white,
                  backgroundColor: primaryColor,
                ),
                onClose: () {
                  setState(() {
                    showFab = false;
                  });
                },
                children: [
                  SwipeTo(
                      offsetDx: 0.5,
                      onRightSwipe: (details) async {
                        deteleMessages();
                      },
                      onLeftSwipe: (details) async {
                        deteleMessages();
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.red,
                        ),
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Yes!',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      )),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black,
                    ),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.delete_sweep,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Swipe "YES" to delete all messages',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : null,
        floatingActionButtonLocation: ExpandableFab.location,
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
                          uid: item.uid,
                          chatUid: widget.chat.uid,
                          text: item.text,
                          createdAtMSE: item.createdAtMSE,
                          messageType: item.messageType,
                          isSender: item.authorId == userId,
                          isSystemMessage:
                              item.messageType == MessageTypes.system,
                          queueId: item.queueId,
                          messageStatus: item.successfullySent
                              ? MessageStatus.successfullySent
                              : item.queueId != null
                                  ? MessageStatus.queued
                                  : item.couldNotSend
                                      ? MessageStatus.couldNotSend
                                      : MessageStatus.successfullySent,
                          pass: pass,
                          baseKey: baseKey,
                          iv: item.iv,
                          error: item.error,
                          mac: item.mac,
                          duration: item.playbackDurationMicroSeconds,
                          durationIV: item.durationIV,
                          durationMAC: item.durationMAC,
                          withBaseKey: item.withBaseKey ?? false,
                          decodedDuration: (item.durationIV == null ||
                                      item.durationMAC == null) &&
                                  item.playbackDurationMicroSeconds != null
                              ? int.parse(item.playbackDurationMicroSeconds!)
                              : null,
                          encryptionStatus: item.iv != null && item.mac != null
                              ? EncryptionStatus.encrypted
                              : EncryptionStatus.notEncrypted,
                        );
                        return MessageWidget(
                          key: ValueKey(item.id),
                          chat: chat,
                          message: chatMessage,
                          sender: chat.participants.firstWhereOrNull(
                              (element) => element.uid == item.authorId),
                          player: player,
                        );
                      }),
                ),
              ),
            ),
          ],
        ));
  }
}
