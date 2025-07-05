import 'dart:async';

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/base_key.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/message/message_service.dart';
import 'package:evercrypted/core/entities/message/message_model.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue_service.dart';
import 'package:evercrypted/core/services/app_state.dart';
import 'package:evercrypted/core/socket/socket.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:evercrypted/screens/chats/components/chat_card.dart';
import 'package:evercrypted/screens/messages/chat_settings_screen.dart';
import 'package:evercrypted/screens/messages/components/password_icon.dart';
import 'package:evercrypted/widgets/circle_avatar_with_active_indicator.dart';
import 'package:evercrypted/widgets/connection_status_appbar.dart';
import 'package:evercrypted/models/chat_message.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:collection/collection.dart';
import 'package:flutter_expandable_fab/flutter_expandable_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sound/public/flutter_sound_player.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:swipe_to/swipe_to.dart';

import '../../ui_constants.dart';
import '../../widgets/primary_button.dart';
import 'components/chat_input_field.dart';
import 'components/message.dart';

class MessageObject {
  final Message message;
  final ChatMessage chatMessage;

  MessageObject({required this.message, required this.chatMessage});
}

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
  int nextPageKey = 0;
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

  PagingState<int, MessageObject> _pagingState = PagingState();

  List<MessageObject> obxAddedMessages = [];

  late StreamSubscription isConnectedListener;
  bool isConnected = ChatSocket.isConnectedSubject.value;
  StreamSubscription? messageStatusListener;

  final fabKey = GlobalKey<ExpandableFabState>();
  bool showFab = false;
  bool settingsDialogOpen = false;

  @override
  void initState() {
    super.initState();

    isConnectedListener =
        ChatSocket.isConnectedSubject.stream.listen((isConnected) async {
      setState(() {
        this.isConnected = isConnected;
      });
    });

    // Listen for message status updates from queue processing
    messageStatusListener = ActionQueueService
        .messageStatusUpdatesSubject.stream
        .where((message) => message.chatUid == widget.chat.uid)
        .listen((updatedMessage) {
      debugPrint(
          'MessagesScreen: Received message status update for message ${updatedMessage.id} ${updatedMessage.successfullySent} ${updatedMessage.queueId} ${updatedMessage.couldNotSend}');
      setState(() {
        // Update message in obxAddedMessages if it exists
        final index = obxAddedMessages
            .indexWhere((m) => m.message.id == updatedMessage.id);
        if (index != -1) {
          debugPrint('found message ${updatedMessage.id} in obxAddedMessages');
          obxAddedMessages[index] = MessageObject(
              message: updatedMessage,
              chatMessage: prepareMessage(updatedMessage));
        }

        // Update message in _pagingState if it exists
        if (_pagingState.pages != null) {
          final updatedPages = _pagingState.pages!.map((page) {
            return page.map((message) {
              return message.message.id == updatedMessage.id
                  ? MessageObject(
                      message: updatedMessage,
                      chatMessage: prepareMessage(updatedMessage))
                  : message;
            }).toList();
          }).toList();
          _pagingState = _pagingState.copyWith(pages: updatedPages);
        }
      });
      debugPrint(
          'MessagesScreen: Updated message ${updatedMessage.id} status in UI');
    });

    chat = widget.chat;
    participantNames =
        chatParticipantNames(chat: chat, widgetRef: ref).join(', ');

    basekeyListener = BaseKey.baseKeySubject.stream.listen((chatUid) {
      if (chatUid == chat.uid) {
        setBaseKey();
      }
    });

    setBaseKey().then((value) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        openPasswordDialog(context);
      });
    });

    AppState.setOpenedChatId(widget.chat.uid);

    getlastMessageCreatedAtMSE().then((value) {
      startingCreatedAtMSE = value ?? 0;
    }).then((value) async {
      _fetchPage(0).then((value) {
        listenToObxChanges();
      });
    });
  }

  @override
  void deactivate() {
    AppState.setOpenedChatId(null);
    isConnectedListener.cancel();
    super.deactivate();
  }

  @override
  void dispose() async {
    isConnectedListener.cancel();
    messageStatusListener?.cancel();
    _isarSubscription?.cancel();
    _passController.dispose();
    _pagingState.reset();
    basekeyListener?.cancel();
    super.dispose();
  }

  Future<String?> setBaseKey() async {
    final completer = Completer<String?>();
    BaseKey.getKeys(chat.uid).then((keys) {
      setState(() {
        baseKey = keys?.baseKey;
      });
      completer.complete(keys?.baseKey);
    });
    return completer.future;
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
    setState(() {
      settingsDialogOpen = true;
    });
    return showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        constraints: BoxConstraints(
          maxHeight:
              MediaQuery.of(context).size.height * 0.8, // 80% of screen height
        ),
        builder: (BuildContext context) {
          return SingleChildScrollView(
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? contentColorLightThemeSecondary
                    : primaryColor,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(defaultPadding),
                    topRight: Radius.circular(defaultPadding)),
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
                        PasswordDialogIcon(
                            settingsDialogOpen: false,
                            pass: pass,
                            openPasswordDialog: () => null,
                            chat: chat,
                            baseKey: baseKey,
                            color:
                                Theme.of(context).brightness == Brightness.light
                                    ? Colors.white
                                    : null),
                        if (chat.isOneToOne)
                          Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: defaultPadding / 2),
                            child: Row(
                              children: [
                                Icon(
                                  baseKey == null
                                      ? Icons.warning
                                      : Icons.check_circle,
                                  color: baseKey == null
                                      ? secondaryColor
                                      : Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.white
                                          : primaryColor,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    baseKey == null
                                        ? 'Chat End-to-End key is not synchronized yet. The other party needs to open Evercrypted at least once after the chat is created to generate Base-Encryption-Key, until then all sent messages will only be encrypted with entered password and make sure it is hard to guess.'
                                        : 'Base-Encryption-Key has successfully been synchronized. Entered passwords modify the Base-Encryption-Key.',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              ],
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
                            ref
                                .read(keyboardProvider.notifier)
                                .openKeyboard(controller: _passController);
                          },
                          keyboardType: TextInputType.none,
                          obscureText: !_passwordVisible,
                          style: TextStyle(
                            color: contentColorLightTheme,
                          ),
                          decoration: InputDecoration(
                            counterStyle: TextStyle(color: Colors.white),
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
                          margin:
                              const EdgeInsets.only(bottom: defaultPadding / 2),
                          child: Center(
                            child: const Text(
                              'Password can be Maximum 32 characters in Length.\n\nPasswords shorter than that will automatically be reinforced with the synchronized Base-Encryption-Key.',
                              style:
                                  TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                        const SizedBox(height: defaultPadding / 2),
                        Row(
                          children: [
                            PrimaryButton(
                              width: 100,
                              color: errorColor,
                              press: () {
                                _passController.clear();
                                setPass(null);
                                Navigator.pop(context);
                              },
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.cancel_outlined,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    'Clear',
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: defaultPadding),
                            Expanded(
                              child: PrimaryButton(
                                needsActivation: true,
                                press: () {
                                  setPass(_passController.text);
                                  Navigator.pop(context);
                                },
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? secondaryColor
                                    : primaryColor,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.health_and_safety_outlined,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 10),
                                    Text("Use Password",
                                        style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface))
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  )),
            ),
          );
        }).then((value) {
      setState(() {
        settingsDialogOpen = false;
      });
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

  void listenToObxChanges() {
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
          obxAddedMessages
                  .firstWhereOrNull((el) => el.message.id == element.id) ==
              null &&
          _pagingState.items
                  ?.firstWhereOrNull((el) => el.message.id == element.id) ==
              null);
      if (messages.isNotEmpty) {
        setState(() {
          obxAddedMessages = [
            ...messages.map((e) =>
                MessageObject(message: e, chatMessage: prepareMessage(e))),
            ...obxAddedMessages
          ];
        });
      }
    });
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = await _messageService.getMessagesFromDB(
          widget.chat.id, pageKey, _pageSize);
      final newItemsObjects = newItems
          .map((e) => MessageObject(message: e, chatMessage: prepareMessage(e)))
          .toList();
      newItemsObjects.retainWhere((element) =>
          _pagingState.items
              ?.firstWhereOrNull((el) => el.message.id == element.message.id) ==
          null);
      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        setState(() {
          _pagingState = _pagingState.copyWith(pages: [
            ...?_pagingState.pages,
            newItemsObjects,
          ], keys: [
            ...?_pagingState.keys,
            pageKey,
          ], hasNextPage: false, isLoading: false);
        });
      } else {
        setState(() {
          _pagingState = _pagingState.copyWith(
              pages: [...?_pagingState.pages, newItemsObjects],
              keys: [...?_pagingState.keys, pageKey],
              hasNextPage: true,
              isLoading: false);
        });
      }
      if (pageKey == 0 && newItems.isNotEmpty) {
        startingCreatedAtMSE = newItems.last.createdAtMSE;
      }
    } catch (error) {
      setState(() {
        _pagingState = _pagingState.copyWith(
          error: error,
          isLoading: false,
        );
      });
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
          _pagingState = _pagingState.copyWith(
            pages: [],
            keys: [],
            hasNextPage: false,
            isLoading: false,
          );
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

  ChatMessage prepareMessage(Message item) {
    print(
        'prepareMessage: successfullySent: ${item.successfullySent}, queueId: ${item.queueId}, couldNotSend: ${item.couldNotSend}');
    return ChatMessage(
      uid: item.uid,
      chatUid: widget.chat.uid,
      text: item.text,
      createdAtMSE: item.createdAtMSE,
      messageType: item.messageType,
      isSender: item.authorId == userId,
      isSystemMessage: item.messageType == MessageTypes.system,
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
      fileKey: item.fileKey,
      filePath: item.filepath,
      decodedDuration: (item.durationIV == null || item.durationMAC == null) &&
              item.playbackDurationMicroSeconds != null
          ? int.parse(item.playbackDurationMicroSeconds!)
          : null,
      encryptionStatus: item.iv != null && item.mac != null
          ? EncryptionStatus.encrypted
          : EncryptionStatus.notEncrypted,
    );
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
            PasswordDialogIcon(
              settingsDialogOpen: settingsDialogOpen,
              pass: pass,
              openPasswordDialog: () => openPasswordDialog(context),
              chat: chat,
              baseKey: baseKey,
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
                  backgroundColor: errorColor,
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
                          color: errorColor,
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
                padding: const EdgeInsets.symmetric(
                    horizontal: defaultPadding, vertical: defaultPadding / 2),
                child: CustomScrollView(
                  reverse: true,
                  slivers: [
                    if (obxAddedMessages.isNotEmpty)
                      SliverList(
                        delegate: SliverChildListDelegate(
                          [
                            ...obxAddedMessages.map((e) => MessageWidget(
                                  key: Key(
                                      '${e.message.id}_${e.message.successfullySent}_${e.message.queueId}_${baseKey}_$pass'),
                                  chat: chat,
                                  message: e.chatMessage
                                      .copyWith(baseKey: baseKey, pass: pass),
                                  player: player,
                                  sender: chat.participants.firstWhereOrNull(
                                      (element) =>
                                          element.uid == e.message.authorId),
                                )),
                          ],
                        ),
                      ),
                    if (_pagingState.items?.isNotEmpty ?? false)
                      PagedSliverList<int, MessageObject>(
                        state: _pagingState,
                        fetchNextPage: () {
                          _fetchPage(_pagingState.keys?.last == 0
                              ? 1
                              : _pagingState.keys!.last + 1);
                        },
                        builderDelegate:
                            PagedChildBuilderDelegate<MessageObject>(
                                newPageProgressIndicatorBuilder: (context) =>
                                    Container(),
                                itemBuilder: (context, item, index) {
                                  return MessageWidget(
                                    key: Key(
                                        '${item.message.id}_${item.message.successfullySent}_${item.message.queueId}_${baseKey}_$pass'),
                                    chat: chat,
                                    message: item.chatMessage
                                        .copyWith(baseKey: baseKey, pass: pass),
                                    sender: chat.participants.firstWhereOrNull(
                                        (element) =>
                                            element.uid ==
                                            item.message.authorId),
                                    player: player,
                                  );
                                }),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }
}
