import 'dart:async';

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
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

  _checkIfUserEmailIsVerified(fbUser) {
    if (!fbUser.emailVerified) {
      userReloadTimer = Timer.periodic(
        const Duration(seconds: 5),
        (timer) {
          FirebaseAuth.instance.currentUser?.reload().then((value) {
            setState(() {
              user = FirebaseAuth.instance.currentUser;
              ref.read(profileProvider).setProfileWhenSignIn(user);
            });
            if (user!.emailVerified) {
              userReloadTimer?.cancel();
            }
          });
        },
      );
    } else {
      userReloadTimer?.cancel();
    }
  }
}
