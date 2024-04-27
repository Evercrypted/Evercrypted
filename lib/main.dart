import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:evercrypted/core/auth.dart';
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
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'core/entities/contact-request/contact_request_model.dart';
import 'core/entities/contact-request/contact_request_riverpod.dart';
import 'core/entities/contact/contact_model.dart';
import 'core/entities/contact/contact_riverpod.dart';
import 'core/socket/socket.dart';
import 'core/entities/profile/profile_service.dart';
import 'core/http.dart';
import 'core/interceptors/auth_interceptor.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initializeDio();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final dir = await getApplicationDocumentsDirectory();
  await Isar.open([
    ProfileSchema,
    ContactRequestSchema,
    ContactSchema,
    MessageSchema,
    ActionQueueSchema,
    ChatSchema
  ], directory: dir.path);

  runApp(const ProviderScope(child: MyApp()));
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
  final NotifiacationEventsService notifiacationEventsService =
      NotifiacationEventsService();

  bool isOtpActive = false;

  late StreamSubscription authListener;

  @override
  void initState() {
    super.initState();

    _checkAndroidNotifications();

    authListener = Auth.authSubject.stream.listen((shouldFire) async {
      _authFlow();
    });

    _authFlow();

    Future.delayed(Duration.zero, () {
      _syncIsarToRiverpod();
      _setIsarWatchers();
    });
  }

  @override
  void dispose() {
    userReloadTimer?.cancel();
    ioConnectionTimer?.cancel();
    authListener.cancel();
    ChatSocket.instance.disconnectWS();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: user == null
          ? const SignInScreen()
          : isOtpActive
              ? const OtpScreen(
                  isLogin: true,
                )
              : !user!.emailVerified
                  ? const VerificationScreen()
                  : const MainScreen(),
    );
  }

  void _authFlow() async {
    if (Auth.user != null) {
      setState(() {
        user = Auth.user;
      });
    }
    final String? token = await Auth.getToken;
    if (token != null) {
      addAuthInterceptor(token);
      final bool otpActive = await Auth.getIsOtpActive;
      setState(() {
        isOtpActive = otpActive;
      });
      _connectIO(token);
    } else {
      setState(() {
        user = null;
      });
    }
  }

  void _checkAndroidNotifications() async {
    void onDidReceiveNotificationResponse(
        NotificationResponse notificationResponse) async {
      final String? payload = notificationResponse.payload;
      if (payload != null) {
        notifiacationEventsService.handleNotification(
            context, json.decode(payload));
      }
    }

    // void onDidReceiveLocalNotification(
    //     int id, String? title, String? body, String? payload) async {
    //   // display a dialog with the notification details, tap ok to go to another page
    //   showDialog(
    //     context: context,
    //     builder: (BuildContext context) => CupertinoAlertDialog(
    //       title: Text(title!),
    //       content: Text(body!),
    //       actions: [
    //         CupertinoDialogAction(
    //           isDefaultAction: true,
    //           child: const Text('Ok'),
    //           onPressed: () async {},
    //         )
    //       ],
    //     ),
    //   );
    // }

    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
        LocalNotification.instance.plugin;

    // initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    if (Platform.isAndroid) {
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('app_icon');

      const InitializationSettings initializationSettings =
          InitializationSettings(android: initializationSettingsAndroid);

      flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);

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
    }

    if (Platform.isIOS) {
      const DarwinInitializationSettings initializationSettingsDarwin =
          DarwinInitializationSettings(
              requestSoundPermission: true,
              requestBadgePermission: true,
              requestAlertPermission: true);

      const InitializationSettings initializationSettings =
          InitializationSettings(iOS: initializationSettingsDarwin);

      flutterLocalNotificationsPlugin.initialize(initializationSettings,
          onDidReceiveNotificationResponse: onDidReceiveNotificationResponse);
    }

    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();
    debugPrint(
        'afterlaunch payload: ${notificationAppLaunchDetails.toString()}');
  }

  void _syncIsarToRiverpod() {
    final isar = Isar.getInstance();

    //profile
    final profile = isar?.profiles.where().build().findFirstSync();
    if (profile != null) ref.read(profileProvider.notifier).setProfile(profile);

    //contactRequests
    final contactRequests = isar?.contactRequests.where().build().findAllSync();
    if (contactRequests != null) {
      ref.read(receivedRequestsProvider.notifier).setReceivedRequests(
          contactRequests
              .where((element) => element.recipientEmail == user!.email)
              .toList());
      ref.read(sentRequestsProvider.notifier).setSentRequests(contactRequests
          .where((element) => element.authorId == user!.uid)
          .toList());
    }

    //contacts
    final contacts = isar?.contacts.where().build().findAllSync();
    if (contacts != null) {
      ref.read(contactsProvider.notifier).setContacts(contacts);
    }

    //chats
    final chats = isar?.chats.where().build().findAllSync();
    if (chats != null) {
      ref.read(chatsProvider.notifier).setChats(chats);
    }
  }

  void _setIsarWatchers() {
    final isar = Isar.getInstance();

    //profile
    isar?.profiles.where().build().watch().listen((profiles) {
      if (profiles.isNotEmpty) {
        ref.read(profileProvider.notifier).setProfile(profiles.first);
      }
    });
    //contactRequests
    isar?.contactRequests.where().build().watch().listen((contactRequests) {
      ref.read(receivedRequestsProvider.notifier).setReceivedRequests(
          contactRequests
              .where((element) => element.recipientEmail == user!.email)
              .toList());
      ref.read(sentRequestsProvider.notifier).setSentRequests(contactRequests
          .where((element) => element.authorId == user!.uid)
          .toList());
    });
    //contacts
    isar?.contacts.where().build().watch().listen((contacts) {
      ref.read(contactsProvider.notifier).setContacts(contacts);
    });
    //chats
    isar?.chats.where().build().watch().listen((chats) {
      ref.read(chatsProvider.notifier).setChats(chats);
    });
    //messages
  }

  _connectIO(token) {
    ChatSocket.instance.connectWS(token, ref);
    ioConnectionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (ChatSocket.instance.socket == null) {
          if (!isOtpActive) {
            ChatSocket.instance.connectWS(token, ref);
          }
        }
      },
    );
  }
}
