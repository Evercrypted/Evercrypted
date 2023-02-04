import 'package:animations/animations.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entities/profile/profile_riverpod.dart';
import '../calls/calls_history_screen.dart';
import '../chats/chats_screen.dart';
import '../contacts/contacts_screen.dart';
import '../profile/profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends ConsumerState<MainScreen> {
  int pageIndex = 0;

  List<Widget> pageList = <Widget>[
    ChatsScreen(),
    CallsHistoryScreen(),
    ContactsScreen(),
    const ProfileScreen(),
  ];

  void checkOnPermissions() async {
    await [
      Permission.location,
      Permission.storage,
    ].request();
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageTransitionSwitcher(
        transitionBuilder: (
          Widget child,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return FadeThroughTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            child: child,
          );
        },
        child: pageList[pageIndex],
      ),
      bottomNavigationBar: Consumer(builder: (context, ref, _) {
        return BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: pageIndex,
          onTap: (value) {
            setState(() {
              pageIndex = value;
            });
          },
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.messenger), label: "Chats"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.groups_rounded), label: "Groups"),
            const BottomNavigationBarItem(
                icon: Icon(Icons.people), label: "People"),
            BottomNavigationBarItem(
              icon: Consumer(
                builder: (context, ref, child) {
                  final String? profilePicRef =
                      ref.read(profileProvider).profile?.profilePicRef;
                  return CircleAvatar(
                    backgroundColor: secondaryColor,
                    radius: 14,
                    backgroundImage: profilePicRef != null
                        ? NetworkImage(profilePicRef)
                        : null,
                  );
                },
              ),
              label: "Profile",
            ),
          ],
        );
      }),
    );
  }
}
