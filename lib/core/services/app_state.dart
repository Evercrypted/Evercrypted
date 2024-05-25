class AppState {
  AppState._();

  static String? openedChatId;

  static setOpenedChatId(String? chatId) {
    openedChatId = chatId;
  }
}
