class NotificationHelper {
  static String buildNotificationBody(String specificText, bool useGeneric) {
    if (useGeneric) {
      return "You have a health reminder. Open the app for details.";
    } else {
      return specificText;
    }
  }

  static String buildNotificationTitle(bool useGeneric, String specificTitle) {
    if (useGeneric) {
      return "Health reminder";
    } else {
      return specificTitle;
    }
  }
}
