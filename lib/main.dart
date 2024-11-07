import 'dart:async';
import 'dart:convert';
// import 'dart:io' show Platform;

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/objectbox.dart';
import 'package:evercrypted/core/notifications/notification_events_service.dart';
import 'package:evercrypted/core/socket/event_types/general_event_types.dart';
import 'package:evercrypted/core/socket/socket_channels.dart';
import 'package:evercrypted/objectbox.g.dart';
// import 'package:evercrypted/screens/auth/change_password_screen.dart';
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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:rhttp/rhttp.dart';
import 'core/entities/contact-request/contact_request_riverpod.dart';
import 'core/entities/contact/contact_riverpod.dart';
import 'core/socket/socket.dart';
import 'core/entities/profile/profile_service.dart';
import 'core/http.dart';
import 'firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

late ObjectBox obx;

// @pragma('vm:entry-point')
// Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
//   // If you're going to use other Firebase services in the background, such as Firestore,
//   // make sure you call `initializeApp` before using other Firebase services.
//   await Firebase.initializeApp();

//   print("Handling a background message: ${message.messageId}");
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);s

  await FirebaseMessaging.instance.requestPermission(provisional: true);

  if (await Auth.appKeyFromStorage == null) {
    await Auth.setAppKey();
  }

  await Auth.getAppKey;

  obx = await ObjectBox.create();

  await Rhttp.init();
  await HttpClient.initialize();
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://e8035b86b950aadbfb29164b99cc0a2e@o4508054021210112.ingest.de.sentry.io/4508077446529104';
      // Set tracesSampleRate to 1.0 to capture 100% of transactions for tracing.
      // We recommend adjusting this value in production.
      options.tracesSampleRate = 1.0;
      // The sampling rate for profiling is relative to tracesSampleRate
      // Setting to 1.0 will profile 100% of sampled transactions:
      options.profilesSampleRate = 1.0;
      options.debug = true;
      options.diagnosticLevel = SentryLevel.error;
    },
    appRunner: () => runApp(const ProviderScope(child: MyApp())),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OverlaySupport.global(
      child: MaterialApp(
        title: 'EverCrypted',
        theme: lightThemeData(context),
        darkTheme: darkThemeData(context),
        home: const AuthGate(),
        routes: {
          SigninOrSignupScreen.routeName: (ctx) => const SigninOrSignupScreen(),
          SignUpScreen.routeName: (ctx) => const SignUpScreen(),
          SignInScreen.routeName: (ctx) => const SignInScreen(),
          // ChangePasswordScreen.routeName: (ctx) => const ChangePasswordScreen(),
          ContactsScreen.routeName: (ctx) => const ContactsScreen(),
          AddNewContactScreen.routeName: (ctx) => const AddNewContactScreen(),
          OtpScreen.routeName: (ctx) => const OtpScreen(),
          MainScreen.routeName: (ctx) => const MainScreen(),
        },
      ),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  AuthGateState createState() => AuthGateState();
}

class AuthGateState extends ConsumerState<AuthGate> {
  AuthUser? user;
  Timer? userReloadTimer;
  Timer? ioConnectionTimer;
  final ProfileService profileService = ProfileService();
  final NotificationEventsService notificationEventsService =
      NotificationEventsService();

  bool isOtpActiveAndNoToken = false;
  bool tokenAndUserNotLoaded = false;

  late StreamSubscription authListener;
  late StreamSubscription resetConnectionListener;
  late StreamSubscription fcmTokenListener;
  StreamSubscription? profileListener;
  StreamSubscription? contactRequestsListener;
  StreamSubscription? contactsListener;
  StreamSubscription? chatsListener;
  Admin? admin;

  @override
  void initState() {
    super.initState();

    _checkNotifications();

    requestFcmPermissions();

    fcmTokenListener =
        FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      ChatSocket.emitWAck(
          SocketChannelTypes.general, GeneralEventTypes.updateFcmToken, {
        'fcmToken': fcmToken,
      }).then((resp) {});
    });

    authListener = Auth.authSubject.stream.listen((shouldFire) async {
      _authFlow();
    });

    resetConnectionListener = ChatSocket.resetConnectionSubject.stream.listen(
      (shouldFire) async {
        ChatSocket.resetConnection();
      },
    );

    _authFlow();

    if (Admin.isAvailable()) {
      // Keep a reference until no longer needed or manually closed.
      admin = Admin(obx.store);
    }
  }

  @override
  void dispose() {
    userReloadTimer?.cancel();
    ioConnectionTimer?.cancel();
    authListener.cancel();
    resetConnectionListener.cancel();
    cancelListeners();
    ChatSocket.disconnectWS();
    admin?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

  void requestFcmPermissions() async {
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
  }

  void _authFlow() async {
    final String? token = await Auth.getToken;
    if (token != null) {
      if (Auth.getUser == null) {
        tokenAndUserNotLoaded = true;
      } else if (user == null) {
        setState(() {
          tokenAndUserNotLoaded = false;
        });
        Future.delayed(Duration.zero, () {
          _syncIsarToRiverpod();
          _setWatchers();
        });
      }
      setState(() {
        user = Auth.getUser;
      });
      _connectIO(token);
      HttpClient.addAuth(token);
      final bool otpActive = await Auth.getIsOtpActive;
      final String? otpToken = await Auth.getOtpToken;
      setState(() {
        isOtpActiveAndNoToken = otpActive && otpToken == null;
      });
    } else {
      setState(() {
        user = null;
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

    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    debugPrint(
        'afterlaunch payload: ${notificationAppLaunchDetails.toString()}');
  }

  void _syncIsarToRiverpod() async {
    //profile
    final profile = obx.profiles.getAll().firstOrNull;
    if (profile != null) {
      ref.read(profileProvider.notifier).setProfile(profile);
    }

    //contactRequests
    final contactRequests = obx.contactRequests.getAll();
    if (contactRequests.isNotEmpty) {
      ref.read(receivedRequestsProvider.notifier).setReceivedRequests(
          contactRequests
              .where((element) => element.recipientEmail == user!.email)
              .toList());
      ref.read(sentRequestsProvider.notifier).setSentRequests(contactRequests
          .where((element) => element.authorId == user!.uid)
          .toList());
    }

    //contacts
    final contacts = obx.contacts.getAll();
    if (contacts.isNotEmpty) {
      ref.read(contactsProvider.notifier).setContacts(contacts);
    }

    //chats
    final chats = obx.chats.getAll();

    if (chats.isNotEmpty) {
      ref.read(chatsProvider.notifier).setChats(chats);
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
    profileListener = obx.profiles
        .query()
        .watch()
        .map((query) => query.find())
        .listen((profiles) {
      if (profiles.isNotEmpty) {
        ref.read(profileProvider.notifier).setProfile(profiles.first);
      }
    });
    //contactRequests
    contactRequestsListener = obx.contactRequests
        .query()
        .watch()
        .map((query) => query.find())
        .listen((contactRequests) {
      ref.read(receivedRequestsProvider.notifier).setReceivedRequests(
          contactRequests
              .where((element) => element.recipientEmail == user!.email)
              .toList());
      ref.read(sentRequestsProvider.notifier).setSentRequests(contactRequests
          .where((element) => element.authorId == user!.uid)
          .toList());
    });
    //contacts
    contactsListener = obx.contacts
        .query()
        .watch()
        .map((query) => query.find())
        .listen((contacts) {
      print('contacts: ${contacts.map((e) => e.toJson()).toList()}');
      ref.read(contactsProvider.notifier).setContacts(contacts);
    });
    //chats
    chatsListener =
        obx.chats.query().watch().map((query) => query.find()).listen((chats) {
      ref.read(chatsProvider.notifier).setChats(chats);
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
}
