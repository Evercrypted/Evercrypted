import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:back_button_interceptor/back_button_interceptor.dart';
import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/deep_link/app_link_service.dart';
import 'package:evercrypted/core/deep_link/pending_contact_link.dart';
import 'package:evercrypted/core/deep_link/pending_invite_token.dart';
import 'package:evercrypted/screens/messages/messages_screen.dart';
import 'package:evercrypted/core/entities/chat/chat_state.dart';
import 'package:evercrypted/core/navigation/navigation_state.dart';
import 'package:evercrypted/core/obx_init.dart';
import 'package:evercrypted/core/helpers/navigator_observer.dart';
import 'package:evercrypted/core/notifications/notification_events_service.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_service.dart';
import 'package:evercrypted/core/socket/event_types/general_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/objectbox.g.dart';
import 'package:evercrypted/screens/activation/activation_mainscreen.dart';
import 'package:evercrypted/screens/auth/sign_in_screen.dart';
import 'package:evercrypted/screens/auth/sign_up_screen.dart';
import 'package:evercrypted/screens/auth/signin_or_signup_screen.dart';
import 'package:evercrypted/screens/auth/verification_screen.dart';
import 'package:evercrypted/screens/contacts/add_new_contact_screen.dart';
import 'package:evercrypted/screens/contacts/contacts_screen.dart';
import 'package:evercrypted/screens/main/main_screen.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/screens/profile/otp_screen.dart';
import 'package:evercrypted/theme.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_widget.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:rhttp/rhttp.dart';
import 'package:screen_protector/screen_protector.dart';
import 'core/entities/contact-request/contact_request_riverpod.dart';
import 'core/entities/contact/contact_riverpod.dart';
import 'core/socket/socket.dart';
import 'core/entities/profile/profile_service.dart';
import 'core/http.dart';
import 'firebase_options.dart';
import 'services/biometric_service.dart';
import 'package:app_badge_plus/app_badge_plus.dart';

ValueNotifier shouldShowKeyboard = ValueNotifier(false);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);s

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  if (await Auth.appKeyFromStorage == null) {
    await Auth.setAppKey();
  }

  await Auth.getAppKey;

  await ObxInit.initialize();

  await Rhttp.init();
  await AppHttpClient.initialize();

  // Initialize ChatSocket connection listener for queue processing
  ChatSocket.initializeConnectionListener();

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    BackButtonInterceptor.add(myInterceptor);
    // Initialize screen protection
    ScreenProtector.preventScreenshotOn();
    ScreenProtector.protectDataLeakageWithBlur();
  }

  bool myInterceptor(bool stopDefaultButtonEvent, RouteInfo info) {
    if (shouldShowKeyboard.value) {
      shouldShowKeyboard.value = false;
      return true;
    } else {
      return false;
    }
  }

  @override
  void dispose() {
    BackButtonInterceptor.remove(myInterceptor);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: Column(
        children: [
          Expanded(
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorObservers: [
                NavObserver(onChange: () {
                  shouldShowKeyboard.value = false;
                }),
              ],
              title: 'EverCrypted',
              theme: lightThemeData(context),
              darkTheme: darkThemeData(context),
              home: const AuthGate(),
              routes: {
                SigninOrSignupScreen.routeName: (ctx) =>
                    const SigninOrSignupScreen(),
                SignUpScreen.routeName: (ctx) => const SignUpScreen(),
                SignInScreen.routeName: (ctx) => const SignInScreen(),
                // ChangePasswordScreen.routeName: (ctx) => const ChangePasswordScreen(),
                ContactsScreen.routeName: (ctx) => const ContactsScreen(),
                AddNewContactScreen.routeName: (ctx) =>
                    const AddNewContactScreen(),
                OtpScreen.routeName: (ctx) => const OtpScreen(),
                MainScreen.routeName: (ctx) => const MainScreen(),
                ActivationMainScreen.routeName: (ctx) =>
                    const ActivationMainScreen(),
              },
            ),
          ),
          ValueListenableBuilder(
              valueListenable: shouldShowKeyboard,
              builder: (context, value, child) {
                return value ? EvercryptedKeyboard() : SizedBox.shrink();
              }),
        ],
      ),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  AuthGateState createState() => AuthGateState();
}

class AuthGateState extends ConsumerState<AuthGate>
    with WidgetsBindingObserver {
  AuthUser? user;
  Timer? userReloadTimer;
  Timer? ioConnectionTimer;
  final ProfileService profileService = ProfileService();
  final NotificationEventsService notificationEventsService =
      NotificationEventsService();

  bool isOtpActiveAndNoToken = false;
  bool tokenAndUserNotLoaded = false;
  bool isAuthCheckComplete = false;
  bool isBiometricLocked = false;
  bool biometricAuthFailed = false;

  late StreamSubscription authListener;
  late StreamSubscription resetConnectionListener;
  late StreamSubscription fcmTokenListener;
  late StreamSubscription<String?> blockedListener;
  StreamSubscription<Uri>? _deepLinkSubscription;
  StreamSubscription? profileListener;
  StreamSubscription? contactRequestsListener;
  StreamSubscription? contactsListener;
  StreamSubscription? chatsListener;
  StreamSubscription? foregroundMessageListener;
  Admin? admin;
  Timer? _resetDebounceTimer;

  @override
  void initState() {
    super.initState();

    // Register lifecycle observer for badge management
    WidgetsBinding.instance.addObserver(this);

    _checkNotifications();

    initializeFcmToken();
    _setupFcmTokenListener();
    _setupForegroundMessageListener();
    _checkBiometric();

    authListener = Auth.authSubject.stream.listen((shouldFire) async {
      _authFlow();
    });

    resetConnectionListener = ChatSocket.resetConnectionSubject.stream.listen(
      (shouldFire) async {
        // Debounce rapid reconnection requests to prevent connection storms
        _resetDebounceTimer?.cancel();
        _resetDebounceTimer = Timer(const Duration(milliseconds: 500), () {
          ChatSocket.resetConnection();
        });
      },
    );

    // Listen for account blocking events
    blockedListener = Auth.blockedSubject.stream.listen((message) {
      if (message != null && mounted) {
        // Show dialog informing user they've been blocked
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
              title: const Text('Account Blocked'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        });
      }
    });

    _authFlow();

    // Initialize deep link handling
    _initDeepLinks();

    if (Admin.isAvailable()) {
      // Keep a reference until no longer needed or manually closed.
      admin = Admin(ObxInit.obx.store);
    }
  }

  @override
  void dispose() {
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    userReloadTimer?.cancel();
    ioConnectionTimer?.cancel();
    _resetDebounceTimer?.cancel();
    _deepLinkSubscription?.cancel();
    authListener.cancel();
    resetConnectionListener.cancel();
    blockedListener.cancel();
    foregroundMessageListener?.cancel();
    cancelListeners();
    ChatSocket.disconnectWS();
    admin?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Clear badge when app comes to foreground
      AppBadgePlus.updateBadge(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isAuthCheckComplete || isBiometricLocked) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 1200),
                tween: Tween(begin: 0.55, end: 1.0),
                curve: Curves.easeInOut,
                builder: (context, scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: 0.9 + (0.1 * scale),
                      child: SvgPicture.asset(
                        logoTheme,
                        width: 150,
                        height: 150,
                      ),
                    ),
                  );
                },
                onEnd: () {
                  // Seamless pulse restart
                  if (!biometricAuthFailed) setState(() {});
                },
              ),
              if (biometricAuthFailed) ...[
                const SizedBox(height: 40),
                ElevatedButton.icon(
                  onPressed: () => _checkBiometric(),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: user == null
          ? tokenAndUserNotLoaded
              ? isOtpActiveAndNoToken
                  ? const OtpScreen(
                      isLogin: true,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Center(child: SvgPicture.asset(logoTheme, width: 150)),
                      ],
                    )
              : const SignInScreen()
          : isOtpActiveAndNoToken
              ? const OtpScreen(
                  isLogin: true,
                )
              : !user!.emailVerified
                  ? const VerificationScreen()
                  : const MainScreen(),
    );
  }

  /// Initializes FCM token following Firebase best practices for iOS SDK 10.4.0+
  /// On iOS: waits for APNS token before requesting FCM token
  /// Then sends the token to the server
  void initializeFcmToken() async {
    final messaging = FirebaseMessaging.instance;

    // Request permission first
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: true,
      sound: true,
    );

    String? fcmToken;

    if (Platform.isIOS) {
      // For iOS SDK 10.4.0+, wait for APNS token before making FCM API calls
      String? apnsToken;
      for (int attempt = 1; attempt <= 5 && apnsToken == null; attempt++) {
        apnsToken = await messaging.getAPNSToken();
        if (apnsToken != null) {
          break;
        }
        await Future.delayed(Duration(seconds: attempt * 2));
      }

      if (apnsToken != null) {
        // APNS token is available, safe to make FCM API calls
        fcmToken = await messaging.getToken();
      } else {}
    } else {
      // Android - get FCM token directly
      fcmToken = await messaging.getToken();
    }

    // Store FCM token in Auth for later use
    if (fcmToken != null) {
      await Auth.setFcmToken(newFcmToken: fcmToken);
    }

    // Send token to server if we have one and are connected
    if (fcmToken != null &&
        ChatSocket.key != null &&
        ChatSocket.isConnected == true) {
      AppHttpClient.message(
        channel: SocketChannelTypes.general,
        type: GeneralEventTypes.updateFcmToken,
        payload: {
          'fcmToken': fcmToken,
        },
      );
    }
  }

  void _setupFcmTokenListener() {
    fcmTokenListener =
        FirebaseMessaging.instance.onTokenRefresh.listen((newFcmToken) async {
      // Store in Auth
      await Auth.setFcmToken(newFcmToken: newFcmToken);

      // Send to server if connected
      if (ChatSocket.key != null && ChatSocket.isConnected == true) {
        AppHttpClient.message(
          channel: SocketChannelTypes.general,
          type: GeneralEventTypes.updateFcmToken,
          payload: {
            'fcmToken': newFcmToken,
          },
        );
      }
    });
  }

  void _setupForegroundMessageListener() {
    // Listen for messages when app is in foreground
    foregroundMessageListener =
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Clear badge immediately since user is already using the app
      AppBadgePlus.updateBadge(0);
    });
  }

  Future<void> _checkBiometric() async {
    final token = await Auth.getToken;
    if (token == null) return;

    final biometricService = ref.read(biometricServiceProvider);
    final enabled = await biometricService.isBiometricEnabled();
    if (enabled) {
      if (mounted) {
        setState(() {
          isBiometricLocked = true;
          biometricAuthFailed = false;
        });
      }
      final authenticated = await biometricService.authenticate();
      if (authenticated) {
        if (mounted) {
          setState(() {
            isBiometricLocked = false;
            biometricAuthFailed = false;
          });
        }
      } else {
        // Authentication failed or was cancelled - show retry button
        if (mounted) {
          setState(() => biometricAuthFailed = true);
        }
      }
    }
  }

  void _authFlow() async {
    try {
      final String? token = await Auth.getToken;
      if (token != null) {
        if (Auth.getUser == null) {
          setState(() {
            tokenAndUserNotLoaded = true;
            isAuthCheckComplete = true;
          });
        } else if (user == null) {
          setState(() {
            tokenAndUserNotLoaded = false;
            user = Auth.getUser;
            isAuthCheckComplete = true;
          });
          Future.delayed(Duration.zero, () {
            _syncIsarToRiverpod();
            _setWatchers();
            // Process any pending invite token stored before login
            final pendingToken = ref.read(pendingInviteTokenProvider);
            if (pendingToken != null) {
              ref.read(pendingInviteTokenProvider.notifier).clear();
              _handleJoinChat(pendingToken);
            }
          });
        } else {
          setState(() {
            user = Auth.getUser;
            isAuthCheckComplete = true;
          });
        }
        _connectIO(token);

        // Handle OTP state
        final bool otpActive = await Auth.getIsOtpActive;
        final String? otpToken = await Auth.getOtpToken;
        setState(() {
          isOtpActiveAndNoToken = otpActive && otpToken == null;
        });
      } else {
        setState(() {
          user = null;
          isAuthCheckComplete = true;
        });
      }
    } catch (e) {
      setState(() {
        user = null;
        isAuthCheckComplete = true;
      });
    }
  }

  void _checkNotifications() async {
    void onDidReceiveNotificationResponse(
        NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
      if (payload != null) {
        notificationEventsService.handleNotification(
            context, json.decode(payload));
      }
    }

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        FlutterLocalNotificationsPlugin();

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    bool? areNotifsEnabled = await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    if (areNotifsEnabled != true) {
      flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.requestNotificationsPermission();
    }

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
            requestSoundPermission: true,
            requestBadgePermission: true,
            requestAlertPermission: true);

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    flutterLocalNotificationsPlugin.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
  }

  void _syncIsarToRiverpod() async {
    //profile
    final profile = ObxInit.obx.profiles.getAll().firstOrNull;
    if (profile != null) {
      ref.read(profileProvider.notifier).setProfile(profile);
    }

    //contactRequests
    final contactRequests = ObxInit.obx.contactRequests.getAll();
    if (contactRequests.isNotEmpty) {
      ref.read(receivedContactRequestsProvider.notifier).setReceivedRequests(
          contactRequests
              .where((element) =>
                  element.recipientEmail?.toLowerCase() ==
                  user!.email.toLowerCase())
              .toList());
      ref.read(sentContactRequestsProvider.notifier).setSentRequests(
          contactRequests
              .where((element) => element.authorId == user!.uid)
              .toList());
    }

    //contacts
    final contacts = ObxInit.obx.contacts.getAll();
    if (contacts.isNotEmpty) {
      ref.read(contactsProvider.notifier).setContacts(contacts);
    }

    //chats
    final chats = ObxInit.obx.chats.getAll();

    if (chats.isNotEmpty) {
      ChatState.setChats(chats);
    }
  }

  void cancelListeners() {
    profileListener?.cancel();
    contactRequestsListener?.cancel();
    contactsListener?.cancel();
    chatsListener?.cancel();
  }

  void _setWatchers() async {
    cancelListeners();
    //profile
    profileListener = ObxInit.obx.profiles
        .query()
        .watch()
        .map((query) => query.find())
        .listen((profiles) {
      if (profiles.isNotEmpty) {
        ref.read(profileProvider.notifier).setProfile(profiles.first);
      }
    });
    //contactRequests
    contactRequestsListener = ObxInit.obx.contactRequests
        .query()
        .watch()
        .map((query) => query.find())
        .listen((contactRequests) {
      ref.read(receivedContactRequestsProvider.notifier).setReceivedRequests(
          contactRequests
              .where((element) =>
                  element.recipientEmail?.toLowerCase() ==
                  user!.email.toLowerCase())
              .toList());
      ref.read(sentContactRequestsProvider.notifier).setSentRequests(
          contactRequests
              .where((element) => element.authorId == user!.uid)
              .toList());
    });
    //contacts
    contactsListener = ObxInit.obx.contacts
        .query()
        .watch()
        .map((query) => query.find())
        .listen((contacts) {
      ref.read(contactsProvider.notifier).setContacts(contacts);
    });
    //chats
    chatsListener = ObxInit.obx.chats
        .query()
        .watch()
        .map((query) => query.find())
        .listen((chats) {
      ChatState.setChats(chats);
    });
    //messages
  }

  _connectIO(token) {
    if (ChatSocket.socket == null && Auth.token != null) {
      ChatSocket.connectWS();
    }
    ioConnectionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (ChatSocket.socket == null && Auth.token != null) {
          ChatSocket.connectWS();
        }
      },
    );
  }

  /// Initialize deep link handling for both cold and warm starts
  void _initDeepLinks() async {
    // Handle cold start — app was launched from a deep link

    final initialUri = await AppLinkService.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // Handle warm start — app is already running and receives a deep link
    _deepLinkSubscription = AppLinkService.onLinkStream.listen(
      (uri) => _handleDeepLink(uri),
    );
  }

  /// Process an incoming deep link URI
  void _handleDeepLink(Uri uri) {
    // 1. Check for Contact Add Link
    final contactEmail = AppLinkService.parseContactEmail(uri);
    if (contactEmail != null) {
      final senderEmail = contactEmail;
      final currentUserEmail = Auth.getUser?.email ?? 'someone';
      final message =
          "Hi! It's $currentUserEmail. I'd like to add you as a contact on EverCrypted.";

      ref
          .read(pendingContactLinkProvider.notifier)
          .set(PendingContactLink(email: senderEmail, message: message));

      if (user != null && !isBiometricLocked) {
        ref.read(navigationProvider.notifier).navigateToContacts();
      }
      return;
    }

    // 2. Check for Chat Join Link
    final inviteToken = AppLinkService.parseInviteToken(uri);
    if (inviteToken != null) {
      _handleJoinChat(inviteToken);
      return;
    }
  }

  Future<void> _handleJoinChat(String token) async {
    // Requires authentication — store token for after login
    if (user == null || isBiometricLocked) {
      ref.read(pendingInviteTokenProvider.notifier).set(token);

      return;
    }

    // Check subscription
    if (Auth.user?.activated != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Active subscription required to join via invite link'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (c) => const Center(child: CircularProgressIndicator()),
      );

      final ChatService chatService = ChatService();
      final Chat chat = await chatService.joinChatViaInvite(token: token);

      // Dismiss loading
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Joined "${chat.name ?? "Group Chat"}"'),
            backgroundColor: primaryColor,
          ),
        );
        // Navigate to the chats tab and open the chat
        ref.read(navigationProvider.notifier).navigateToChats();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MessagesScreen(chat: chat),
          ),
        );
      }
    } catch (e) {
      // Dismiss loading
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      if (mounted) {
        String errorMessage = 'Failed to join chat';
        if (e.toString().contains('already a member')) {
          errorMessage = 'You are already a member of this chat';
        } else if (e.toString().contains('subscription')) {
          errorMessage = 'Active subscription required';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
