import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppState {
  bool shouldOtpLogin;

  AppState({this.shouldOtpLogin = false});

  AppState copyWith({
    bool? shouldOtpLogin,
  }) {
    return AppState(
      shouldOtpLogin: shouldOtpLogin ?? this.shouldOtpLogin,
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
}

final appStateProvider =
    StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  return AppStateNotifier();
});
