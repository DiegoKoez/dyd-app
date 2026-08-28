import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

/// Persists the last used server address (e.g. http://192.168.1.10:3000).
class ServerPrefs {
  static const _key = 'server_url';
  static const _roomCodeKey = 'room_code';
  static const _playerIdKey = 'player_id';
  static const _playerNameKey = 'player_name';
  static const _isDmKey = 'is_dm';

  static Future<String?> getSavedUrl() async {
    if (kIsWeb) {
      return html.window.localStorage[_key];
    }
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key);
  }

  static Future<void> saveUrl(String url) async {
    if (kIsWeb) {
      html.window.localStorage[_key] = url;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, url);
  }

  static Future<void> saveSession({
    required String roomCode,
    required String playerId,
    String? playerName,
    bool isDm = false,
  }) async {
    if (kIsWeb) {
      html.window.localStorage[_roomCodeKey] = roomCode;
      html.window.localStorage[_playerIdKey] = playerId;
      if (playerName != null) {
        html.window.localStorage[_playerNameKey] = playerName;
      }
      html.window.localStorage[_isDmKey] = isDm.toString();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roomCodeKey, roomCode);
    await prefs.setString(_playerIdKey, playerId);
    if (playerName != null) {
      await prefs.setString(_playerNameKey, playerName);
    }
    await prefs.setBool(_isDmKey, isDm);
  }

  static Future<Map<String, dynamic>?> getSavedSession() async {
    if (kIsWeb) {
      final roomCode = html.window.localStorage[_roomCodeKey];
      final playerId = html.window.localStorage[_playerIdKey];
      if (roomCode != null && playerId != null) {
        return {
          'roomCode': roomCode,
          'playerId': playerId,
          'playerName': html.window.localStorage[_playerNameKey],
          'isDm': html.window.localStorage[_isDmKey] == 'true',
        };
      }
      return null;
    }
    final prefs = await SharedPreferences.getInstance();
    final roomCode = prefs.getString(_roomCodeKey);
    final playerId = prefs.getString(_playerIdKey);
    if (roomCode != null && playerId != null) {
      return {
        'roomCode': roomCode,
        'playerId': playerId,
        'playerName': prefs.getString(_playerNameKey),
        'isDm': prefs.getBool(_isDmKey) ?? false,
      };
    }
    return null;
  }

  static Future<void> clearSession() async {
    if (kIsWeb) {
      html.window.localStorage.remove(_roomCodeKey);
      html.window.localStorage.remove(_playerIdKey);
      html.window.localStorage.remove(_playerNameKey);
      html.window.localStorage.remove(_isDmKey);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roomCodeKey);
    await prefs.remove(_playerIdKey);
    await prefs.remove(_playerNameKey);
    await prefs.remove(_isDmKey);
  }
}
