import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  bool isConnected;
  String? openedChatId;

  AppState({this.isConnected = true, this.openedChatId});

  AppState copyWith({
    bool? isConnected,
    bool? shouldOtpLogin,
    String? openedChatId,
  }) {
    return AppState(
      isConnected: isConnected ?? this.isConnected,
      openedChatId: openedChatId,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  // We initialize the list of todos to an empty list
  AppStateNotifier() : super(AppState());

  void setIsConnected(bool isConnected) {
    if (isConnected != state.isConnected) {
      state = state.copyWith(isConnected: isConnected);
    }
  }

  void setOpenedChatId(String? chatId) {
    if (chatId == null) {
      Future.delayed(Duration.zero, () {
        state = state.copyWith(openedChatId: null);
      });
    } else {
      state = state.copyWith(openedChatId: chatId);
    }
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
