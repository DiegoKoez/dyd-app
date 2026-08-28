import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Singleton para StorageService
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _keyBattlesHistory = 'battles_history';
  static const String _keyAchievements = 'achievements';
  static const String _keyCharacter = 'character';
  static const String _keyPlayerId = 'player_id';

  /// Guardar historial de batallas
  Future<void> saveBattlesHistory(List<dynamic> battles) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyBattlesHistory, jsonEncode(battles));
  }

  /// Obtener historial de batallas
  Future<List<dynamic>> getBattlesHistory() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_keyBattlesHistory);
    if (json == null) return [];
    return jsonDecode(json) as List<dynamic>;
  }

  /// Añadir batalla al historial
  Future<void> addBattleToHistory(Map<String, dynamic> battle) async {
    final battles = await getBattlesHistory();
    battles.insert(0, battle);
    // Mantener solo las últimas 50 batallas
    if (battles.length > 50) {
      battles.removeRange(50, battles.length);
    }
    await saveBattlesHistory(battles);
  }

  /// Limpiar historial de batallas
  Future<void> clearBattlesHistory() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyBattlesHistory);
  }

  /// Guardar achievements
  Future<void> saveAchievements(Map<String, dynamic> achievements) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyAchievements, jsonEncode(achievements));
  }

  /// Obtener achievements
  Future<Map<String, dynamic>?> getAchievements() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_keyAchievements);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Guardar personaje
  Future<void> saveCharacter(Map<String, dynamic> character) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyCharacter, jsonEncode(character));
  }

  /// Obtener personaje
  Future<Map<String, dynamic>?> getCharacter() async {
    final prefs = await _getPrefs();
    final json = prefs.getString(_keyCharacter);
    if (json == null) return null;
    return jsonDecode(json) as Map<String, dynamic>;
  }

  /// Guardar player ID
  Future<void> savePlayerId(String playerId) async {
    final prefs = await _getPrefs();
    await prefs.setString(_keyPlayerId, playerId);
  }

  /// Obtener player ID
  Future<String?> getPlayerId() async {
    final prefs = await _getPrefs();
    return prefs.getString(_keyPlayerId);
  }

  /// Eliminar player ID
  Future<void> removePlayerId() async {
    final prefs = await _getPrefs();
    await prefs.remove(_keyPlayerId);
  }

  /// Limpiar todos los datos
  Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.clear();
  }

  /// Detectar si estamos en web
  bool get isWeb => kIsWeb;

  /// Obtener SharedPreferences (o localStorage simulado para web)
  Future<SharedPreferences> _getPrefs() async {
    // En web, usar localStorage (simulado)
    if (isWeb) {
      // Para web, usaremos SharedPreferences que tiene soporte básico
      // En el futuro, podríamos implementar un wrapper para localStorage
      return await SharedPreferences.getInstance();
    }
    return await SharedPreferences.getInstance();
  }
}
