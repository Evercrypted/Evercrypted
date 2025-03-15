import 'package:animations/animations.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/ui_constants.dart';
import 'package:evercrypted/widgets/connection_status_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../chats/chats_screen.dart';
import '../contacts/contacts_screen.dart';
import '../profile/profile_screen.dart';
import 'package:permission_handler/permission_handler.dart';

enum MainPageIndex { chats, contacts, profile }

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key, this.page});
  static const routeName = '/main';
  final MainPageIndex? page;

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends ConsumerState<MainScreen> {
  int pageIndex = 0;

  List<Widget> pageList = <Widget>[
    const ChatsScreen(),
    const ContactsScreen(),
    const ProfileScreen(),
  ];

  tabChangeHandler(i) {
    shouldShowKeyboard.value = false;
    setState(() {
      pageIndex = i;
    });
  }

  @override
  void initState() {
    super.initState();
    switch (widget.page) {
      case MainPageIndex.chats:
        pageIndex = 0;
        break;
      case MainPageIndex.contacts:
        pageIndex = 1;
        break;
      case MainPageIndex.profile:
        pageIndex = 2;
        break;
      default:
        pageIndex = 0;
    }
  }

  void checkOnPermissions() async {
    await [
      Permission.storage,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: const ConnectionStatusAppbar(
          title: null,
          actions: null,
        ),
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
        bottomNavigationBar: ValueListenableBuilder(
            valueListenable: shouldShowKeyboard,
            builder: (context, value, child) {
              return value
                  ? SizedBox.shrink()
                  : ConvexAppBar(
                      style: TabStyle.react,
                      backgroundColor: primaryColor,
                      items: [
                        TabItem(icon: Icons.messenger, title: 'Chats'),
                        TabItem(icon: Icons.people, title: 'Contacts'),
                        TabItem(icon: Icons.manage_accounts, title: 'Settings'),
                      ],
                      onTap: tabChangeHandler,
                    );
            }));
  }
}
