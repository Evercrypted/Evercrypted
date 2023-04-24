import 'dart:async';

import 'package:dio_smart_retry/dio_smart_retry.dart';
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
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import 'core/chat_socket.dart';
import 'core/entities/profile/profile_service.dart';
import 'core/http.dart';
import 'core/interceptors/auth_interceptor.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  dio
    ..options.baseUrl = 'http://localhost:3000'
    // ..interceptors.add(CertificatePinningInterceptor(
    //     allowedSHAFingerprints: allowedSHAFingerprints))
    ..interceptors.add(PrettyDioLogger())
    ..interceptors.add(RetryInterceptor(
      dio: dio,
      logPrint: print, // specify log function (optional)
      retries: 3, // retry count (optional)
      retryDelays: const [
        // set delays between retries (optional)
        Duration(seconds: 1), // wait 1 sec before first retry
        Duration(seconds: 2), // wait 2 sec before second retry
        Duration(seconds: 3), // wait 3 sec before third retry
      ],
    ));
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'EverCrypted',
        theme: lightThemeData(context),
        darkTheme: darkThemeData(context),
        home: const AuthGate(),
        routes: {
          SigninOrSignupScreen.routeName: (ctx) => SigninOrSignupScreen(),
          SignUpScreen.routeName: (ctx) => const SignUpScreen(),
          SignInScreen.routeName: (ctx) => const SignInScreen(),
          ForgotPasswordScreen.routeName: (ctx) => const ForgotPasswordScreen(),
          ContactsScreen.routeName: (ctx) => ContactsScreen(),
          AddNewContactScreen.routeName: (ctx) => const AddNewContactScreen(),
        });
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
              ? VerificationScreen()
              : const MainWidget(),
    );
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
    ChatSocket.instance.connectWS(token);
    ioConnectionTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) {
        if (ChatSocket.instance.socket == null) {
          ChatSocket.instance.connectWS(token);
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
              ref
                  .read(profileProvider)
                  .setProfileWhenSignIn(user, justVerified: true);
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
      ref.read(profileProvider).setProfileWhenSignIn(fbUser);
      userReloadTimer?.cancel();
    }
  }
}
