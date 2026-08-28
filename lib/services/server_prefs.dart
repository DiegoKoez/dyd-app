import 'package:shared_preferences/shared_preferences.dart';

/// Persists the last used server address (e.g. http://192.168.1.10:3000).
class ServerPrefs {
  static const _key = 'server_url';

  static Future<String?> getSavedUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> saveUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }
}
