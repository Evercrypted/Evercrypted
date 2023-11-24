import 'package:animations/animations.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/entities/profile/profile_model.dart';
import '../../core/entities/profile/profile_riverpod.dart';
import '../calls/calls_history_screen.dart';
import '../chats/chats_screen.dart';
import '../contacts/contacts_screen.dart';
import '../profile/profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});
  static const routeName = '/main';

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends ConsumerState<MainScreen> {
  int pageIndex = 0;

  List<Widget> pageList = <Widget>[
    const ChatsScreen(),
    const CallsHistoryScreen(),
    const ContactsScreen(),
    ProfileScreen(),
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
                  final Profile? profile = ref.read(profileProvider);
                  if (profile?.avatar?.pic != null) {
                    return CircleAvatar(
                        backgroundColor: secondaryColor,
                        radius: 14,
                        backgroundImage: NetworkImage(profile!.avatar!.pic!));
                  } else {
                    return Container(
                      height: 46,
                      width: 46,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.green,
                      ),
                      alignment: Alignment.center,
                      child: profile?.avatar?.icon != null
                          ? Text(
                              profile!.avatar!.icon!,
                              style:
                                  const TextStyle(fontFamily: 'MaterialIcons'),
                            )
                          : null,
                    );
                  }
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
