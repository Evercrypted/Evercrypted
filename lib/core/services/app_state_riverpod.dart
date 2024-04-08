import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  bool isConnected;
  bool shouldOtpLogin;
  String? httpEncryptionKey;
  String? openedChatId;

  AppState(
      {this.isConnected = true,
      this.shouldOtpLogin = false,
      this.httpEncryptionKey,
      this.openedChatId});

  AppState copyWith({
    bool? isConnected,
    bool? shouldOtpLogin,
    String? httpEncryptionKey,
    String? openedChatId,
  }) {
    return AppState(
      isConnected: isConnected ?? this.isConnected,
      shouldOtpLogin: shouldOtpLogin ?? this.shouldOtpLogin,
      httpEncryptionKey: httpEncryptionKey ?? this.httpEncryptionKey,
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

  void setShouldOtpLogin(bool shouldOtpLogin) {
    if (shouldOtpLogin != state.shouldOtpLogin) {
      state = state.copyWith(shouldOtpLogin: shouldOtpLogin);
    }
  }

  void setHttpEncryptionKey(String key) {
    state = state.copyWith(httpEncryptionKey: key);
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
