import 'dart:async';

import 'package:evercrypted/core/entities/message/message_isar.dart';
import 'package:evercrypted/core/entities/profile/profile_model.dart';
import 'package:evercrypted/core/offline/action_queue/action_queue.dart';
import 'package:evercrypted/screens/auth/forgot_password_screen.dart';
import 'package:evercrypted/screens/auth/sign_in_screen.dart';
import 'package:evercrypted/screens/auth/sign_up_screen.dart';
import 'package:evercrypted/screens/auth/signin_or_signup_screen.dart';
import 'package:evercrypted/screens/auth/verification_screen.dart';
import 'package:evercrypted/screens/contacts/add_new_contact_screen.dart';
import 'package:evercrypted/screens/contacts/contacts_screen.dart';
import 'package:evercrypted/screens/mainpage.dart';
import 'package:evercrypted/core/entities/profile/profile_riverpod.dart';
import 'package:evercrypted/theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path_provider/path_provider.dart';
import 'core/entities/contact-request/contact_request_model.dart';
import 'core/entities/contact-request/contact_request_riverpod.dart';
import 'core/entities/contact/contact_model.dart';
import 'core/socket/chat_socket.dart';
import 'core/entities/profile/profile_service.dart';
import 'core/http.dart';
import 'core/interceptors/auth_interceptor.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
    ActionQueueSchema
  ], directory: dir.path);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        },
      ),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  AuthGateState createState() => AuthGateState();
}

class AuthGateState extends ConsumerState<AuthGate> {
  User? user;
  Timer? userReloadTimer;
  Timer? ioConnectionTimer;
  final ProfileService profileService = ProfileService();

  @override
  void initState() {
    super.initState();
    FirebaseAuth.instance.authStateChanges().listen((User? fbUser) {
      if (fbUser != null) {
        setState(() {
          user = fbUser;
        });
        _checkIfUserEmailIsVerified(fbUser);
        _syncIsarToRiverpod();
        _setIsarWatchers(fbUser);
      } else {
        setState(() {
          user = null;
        });
      }
    });
  }

  @override
  void dispose() {
    userReloadTimer?.cancel();
    ioConnectionTimer?.cancel();
    ChatSocket.instance.disconnectWS();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: user == null
          ? const SignInScreen()
          : !user!.emailVerified
              ? const VerificationScreen()
              : const MainWidget(),
    );
  }

  void _syncIsarToRiverpod() {
    final isar = Isar.getInstance();
    final profile = isar?.profiles.where().build().findFirstSync();
    if (profile != null) ref.read(profileProvider.notifier).setProfile(profile);

    final contactRequests = isar?.contactRequests.where().build().findAllSync();
    if (contactRequests != null) {
      print(contactRequests.map((ContactRequest e) => e.toJson()));
      ref.read(receivedRequestsProvider.notifier).setReceivedRequests(
          contactRequests
              .where((element) =>
                  element.recipientEmail ==
                  FirebaseAuth.instance.currentUser?.email)
              .toList());
      ref.read(sentRequestsProvider.notifier).setSentRequests(contactRequests
          .where((element) =>
              element.authorId == FirebaseAuth.instance.currentUser?.uid)
          .toList());
    }
  }

  void _setIsarWatchers(User user) {
    final isar = Isar.getInstance();

    isar?.profiles.where().build().watch().listen((profiles) {
      if (profiles.isNotEmpty) {
        ref.read(profileProvider.notifier).setProfile(profiles.first);
      }
    });

    isar?.contactRequests.where().build().watch().listen((contactRequests) {
      ref.read(receivedRequestsProvider.notifier).setReceivedRequests(
          contactRequests
              .where((element) =>
                  element.recipientEmail ==
                  FirebaseAuth.instance.currentUser?.email)
              .toList());
      ref.read(sentRequestsProvider.notifier).setSentRequests(contactRequests
          .where((element) =>
              element.authorId == FirebaseAuth.instance.currentUser?.uid)
          .toList());
    });

    // isar.contacts.where().build().watch().listen((contacts) {
    //   ref.read(contactsProvider.notifier).setContacts(contacts);
    // });
  }

  _getTokenAndAddAuthInterceptor(User user) {
    user.getIdTokenResult().then((value) {
      if (value.claims?['email_verified']) {
        addAuthInterceptor(value.token!);
        _checkProfileExists(value.token!);
      }
    });
  }

  _checkProfileExists(String token) {
    profileService.checkProfileExists(token).then((_) {
      _connectIO(token);
    }).catchError((error) {
      _checkProfileExists(token);
    });
  }

  _connectIO(token) {
    ChatSocket.instance.connectWS(token, ref);
    ioConnectionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (ChatSocket.instance.socket == null) {
          ChatSocket.instance.connectWS(token, ref);
        } else if (ChatSocket.instance.socket?.connected != true) {
          ChatSocket.instance.socket?.connect();
        }
      },
    );
  }

  _checkIfUserEmailIsVerified(fbUser) {
    if (!fbUser.emailVerified) {
      userReloadTimer = Timer.periodic(
        const Duration(seconds: 5),
        (timer) {
          FirebaseAuth.instance.currentUser?.reload().then((value) {
            setState(() {
              user = FirebaseAuth.instance.currentUser;
            });
            if (user?.emailVerified ?? false) {
              userReloadTimer?.cancel();
              _getTokenAndAddAuthInterceptor(user!);
            }
          });
        },
      );
    } else {
      _getTokenAndAddAuthInterceptor(user!);
      userReloadTimer?.cancel();
    }
  }
}
