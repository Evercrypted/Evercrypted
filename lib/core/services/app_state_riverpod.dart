import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  bool shouldOtpLogin;
  String? httpEncryptionKey;

  AppState({this.shouldOtpLogin = false, this.httpEncryptionKey});

  AppState copyWith({
    bool? shouldOtpLogin,
    String? httpEncryptionKey,
  }) {
    return AppState(
      shouldOtpLogin: shouldOtpLogin ?? this.shouldOtpLogin,
      httpEncryptionKey: httpEncryptionKey ?? this.httpEncryptionKey,
    );
  }
}

class AppStateNotifier extends StateNotifier<AppState> {
  // We initialize the list of todos to an empty list
  AppStateNotifier() : super(AppState());

  void setShouldOtpLogin(bool shouldOtpLogin) {
    if (shouldOtpLogin != state.shouldOtpLogin) {
      state = state.copyWith(shouldOtpLogin: shouldOtpLogin);
    }
  }

  void setHttpEncryptionKey(String key) {
    state = state.copyWith(httpEncryptionKey: key);
  }
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
