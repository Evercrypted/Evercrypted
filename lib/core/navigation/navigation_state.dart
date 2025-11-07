import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'navigation_state.g.dart';

enum MainNavigationTab { chats, contacts, profile }

class NavigationState {
  final MainNavigationTab currentTab;

  const NavigationState({
    required this.currentTab,
  });

  NavigationState copyWith({
    MainNavigationTab? currentTab,
  }) {
    return NavigationState(
      currentTab: currentTab ?? this.currentTab,
    );
  }
}

@riverpod
class Navigation extends _$Navigation {
  @override
  NavigationState build() =>
      const NavigationState(currentTab: MainNavigationTab.chats);

  void setCurrentTab(MainNavigationTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void navigateToChats() {
    state = state.copyWith(currentTab: MainNavigationTab.chats);
  }

  void navigateToContacts() {
    state = state.copyWith(currentTab: MainNavigationTab.contacts);
  }

  void navigateToProfile() {
    state = state.copyWith(currentTab: MainNavigationTab.profile);
  }

  int get currentIndex {
    switch (state.currentTab) {
      case MainNavigationTab.chats:
        return 0;
      case MainNavigationTab.contacts:
        return 1;
      case MainNavigationTab.profile:
        return 2;
    }
  }
}
