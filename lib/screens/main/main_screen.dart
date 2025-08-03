import 'package:animations/animations.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:evercrypted/core/evercrypted-keyboard/evercrypted_keyboard_riverpod.dart';
import 'package:evercrypted/core/navigation/navigation_state.dart';
import 'package:evercrypted/main.dart';
import 'package:evercrypted/screens/main/contacts_tab_icon.dart';
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
    ref.read(keyboardProvider.notifier).close();
    setState(() {
      pageIndex = i;
    });

    // Update navigation provider when tab is manually changed
    switch (i) {
      case 0:
        ref.read(navigationProvider.notifier).navigateToChats();
        break;
      case 1:
        ref.read(navigationProvider.notifier).navigateToContacts();
        break;
      case 2:
        ref.read(navigationProvider.notifier).navigateToProfile();
        break;
    }
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

    // Set initial navigation state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      switch (pageIndex) {
        case 0:
          ref.read(navigationProvider.notifier).navigateToChats();
          break;
        case 1:
          ref.read(navigationProvider.notifier).navigateToContacts();
          break;
        case 2:
          ref.read(navigationProvider.notifier).navigateToProfile();
          break;
      }
    });
  }

  void checkOnPermissions() async {
    await [
      Permission.storage,
    ].request();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to navigation provider and sync pageIndex
    ref.listen<NavigationState>(navigationProvider, (previous, next) {
      final newIndex = ref.read(navigationProvider.notifier).currentIndex;
      if (newIndex != pageIndex) {
        setState(() {
          pageIndex = newIndex;
        });
      }
    });

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
                      key: ValueKey(
                          pageIndex), // Force rebuild when index changes
                      style: TabStyle.react,
                      backgroundColor: primaryColor,
                      initialActiveIndex: pageIndex,
                      items: [
                        TabItem(icon: Icons.messenger, title: 'Chats'),
                        TabItem(
                          icon: ContactsTabIcon(active: false),
                          activeIcon: ContactsTabIcon(active: true),
                          title: 'Contacts',
                        ),
                        TabItem(icon: Icons.manage_accounts, title: 'Settings'),
                      ],
                      onTap: tabChangeHandler,
                    );
            }));
  }
}
