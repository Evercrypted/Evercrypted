import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:evercrypted/core/auth.dart';
import 'package:evercrypted/core/cryptography/fernet.dart';
import 'package:evercrypted/core/entities/chat/chat_model.dart';
import 'package:evercrypted/core/entities/chat/chat_riverpod.dart';
import 'package:evercrypted/core/entities/message/message_isar.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/notifications/notification.dart';
import 'package:evercrypted/core/notifications/notification_events_service.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue.dart';
import 'package:evercrypted/screens/auth/forgot_password_screen.dart';
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
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:isar/isar.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rhttp/rhttp.dart';
import 'core/entities/contact-request/contact_request_model.dart';
import 'core/entities/contact-request/contact_request_riverpod.dart';
import 'core/entities/contact/contact_model.dart';
import 'core/entities/contact/contact_riverpod.dart';
import 'core/socket/socket.dart';
import 'core/entities/profile/profile_service.dart';
import 'core/http.dart';
import 'firebase_options.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  if (await Auth.appKeyFromStorage == null) {
    await Auth.setAppKey();
  }

  final dir = await getApplicationDocumentsDirectory();
  await Isar.open([
    ProfileSchema,
    ContactRequestSchema,
    ContactSchema,
    MessageSchema,
    ActionQueueSchema,
    ChatSchema
  ], directory: dir.path);

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
          ForgotPasswordScreen.routeName: (ctx) => const ForgotPasswordScreen(),
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
  StreamSubscription? isarProfileListener;
  StreamSubscription? isarContactRequestsListener;
  StreamSubscription? isarContactsListener;
  StreamSubscription? isarChatsListener;

  @override
  void initState() {
    super.initState();

    _checkNotifications();

    authListener = Auth.authSubject.stream.listen((shouldFire) async {
      _authFlow();
    });

    resetConnectionListener = ChatSocket.resetConnectionSubject.stream.listen(
      (shouldFire) async {
        ChatSocket.resetConnection();
      },
    );

    _authFlow();
  }

  @override
  void dispose() {
    userReloadTimer?.cancel();
    ioConnectionTimer?.cancel();
    authListener.cancel();
    resetConnectionListener.cancel();
    cancelIsarListeners();
    ChatSocket.disconnectWS();
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
          _setIsarWatchers();
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
        AndroidInitializationSettings('app_icon');

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
    final isar = Isar.getInstance();

    final String appKey = await Auth.getAppKey;

    //profile
    final profile = isar?.profiles.where().build().findFirstSync();
    if (profile != null) {
      ref.read(profileProvider.notifier).setProfile(profile.copyWith(
          email: fernetDecrypt(profile.email, appKey),
          name: fernetDecrypt(profile.name, appKey)));
    }

    //contactRequests
    final contactRequests = isar?.contactRequests.where().build().findAllSync();
    if (contactRequests != null) {
      ref
          .read(receivedRequestsProvider.notifier)
          .setReceivedRequests(contactRequests
              .where((element) =>
                  fernetDecrypt(element.recipientEmail, appKey) == user!.email)
              .map((c) {
            return c.copyWith(
                authorEmail: fernetDecrypt(c.authorEmail, appKey),
                recipientEmail: fernetDecrypt(c.recipientEmail, appKey),
                message: fernetDecrypt(c.message, appKey));
          }).toList());
      ref.read(sentRequestsProvider.notifier).setSentRequests(contactRequests
              .where((element) =>
                  fernetDecrypt(element.authorId, appKey) == user!.uid)
              .map((c) {
            return c.copyWith(
                authorEmail: fernetDecrypt(c.authorEmail, appKey),
                recipientEmail: fernetDecrypt(c.recipientEmail, appKey),
                message: fernetDecrypt(c.message, appKey));
          }).toList());
    }

    //contacts
    final contacts = isar?.contacts.where().build().findAllSync();
    if (contacts != null) {
      ref.read(contactsProvider.notifier).setContacts(contacts.map((c) {
            return c.copyWith(
                email: fernetDecrypt(c.email, appKey),
                name: fernetDecrypt(c.name, appKey));
          }).toList());
    }

    //chats
    final chats = isar?.chats.where().build().findAllSync();

    if (chats != null) {
      ref.read(chatsProvider.notifier).setChats(chats.map((c) {
            c.participants = c.participants.map((p) {
              return p.copyWith(
                  email: fernetDecrypt(p.email, appKey),
                  name: fernetDecrypt(p.name, appKey));
            }).toList();
            return c;
          }).toList());
    }
  }

  void cancelIsarListeners() {
    isarProfileListener?.cancel();
    isarContactRequestsListener?.cancel();
    isarContactsListener?.cancel();
    isarChatsListener?.cancel();
  }

  void _setIsarWatchers() async {
    final isar = Isar.getInstance();

    cancelIsarListeners();

    final String appKey = await Auth.getAppKey;

    //profile
    isarProfileListener =
        isar?.profiles.where().build().watch().listen((profiles) {
      if (profiles.isNotEmpty) {
        ref.read(profileProvider.notifier).setProfile(profiles.first.copyWith(
            email: fernetDecrypt(profiles.first.email, appKey),
            name: fernetDecrypt(profiles.first.name, appKey)));
      }
    });
    //contactRequests
    isarContactRequestsListener =
        isar?.contactRequests.where().build().watch().listen((contactRequests) {
      ref.read(receivedRequestsProvider.notifier).setReceivedRequests(
              contactRequests
                  .where((element) => element.recipientEmail == user!.email)
                  .map((c) {
            return c.copyWith(
                authorEmail: fernetDecrypt(c.authorEmail, appKey),
                recipientEmail: fernetDecrypt(c.recipientEmail, appKey),
                message: fernetDecrypt(c.message, appKey));
          }).toList());
      ref.read(sentRequestsProvider.notifier).setSentRequests(contactRequests
              .where((element) => element.authorId == user!.uid)
              .map((c) {
            return c.copyWith(
                authorEmail: fernetDecrypt(c.authorEmail, appKey),
                recipientEmail: fernetDecrypt(c.recipientEmail, appKey),
                message: fernetDecrypt(c.message, appKey));
          }).toList());
    });
    //contacts
    isarContactsListener =
        isar?.contacts.where().build().watch().listen((contacts) {
      ref.read(contactsProvider.notifier).setContacts(contacts.map((c) {
            return c.copyWith(
                email: fernetDecrypt(c.email, appKey),
                name: fernetDecrypt(c.name, appKey));
          }).toList());
    });
    //chats
    isarChatsListener = isar?.chats.where().build().watch().listen((chats) {
      final decr = chats.map((c) {
        c.participants = c.participants.map((p) {
          return p.copyWith(
              email: fernetDecrypt(p.email, appKey),
              name: fernetDecrypt(p.name, appKey));
        }).toList();
        return c;
      }).toList();
      ref.read(chatsProvider.notifier).setChats(decr);
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
