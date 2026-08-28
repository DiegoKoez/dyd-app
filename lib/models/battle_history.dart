import 'character.dart';
import 'item.dart';
import 'monster.dart';
import 'player_info.dart';

/// Historial de una batalla individual
class BattleHistory {
  final String id;
  final DateTime date;
  final String result; // 'victory', 'defeat', 'fled'
  final Character characterAtStart;
  final List<Map<String, dynamic>> monstersData;
  final List<Map<String, dynamic>> alliesData;
  final int? damageReceived;
  final int? damageDealt;
  final String? notes; // Notas del DM o jugador

  const BattleHistory({
    required this.id,
    required this.date,
    required this.result,
    required this.characterAtStart,
    required this.monstersData,
    required this.alliesData,
    this.damageReceived,
    this.damageDealt,
    this.notes,
  });

  factory BattleHistory.fromJson(Map<String, dynamic> json) {
    return BattleHistory(
      id: json['id'] as String,
      date: DateTime.parse(json['date']),
      result: json['result'] as String,
      characterAtStart: Character.fromJson(Map<String, dynamic>.from(json['characterAtStart'] as Map)),
      monstersData: (json['monsters'] as List?)?.map((m) => Map<String, dynamic>.from(m as Map)).toList() ?? [],
      alliesData: (json['allies'] as List?)?.map((a) => Map<String, dynamic>.from(a as Map)).toList() ?? [],
      damageReceived: json['damageReceived'] as int?,
      damageDealt: json['damageDealt'] as int?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'result': result,
        'characterAtStart': characterAtStart.toJson(),
        'monsters': monstersData,
        'allies': alliesData,
        'damageReceived': damageReceived,
        'damageDealt': damageDealt,
        'notes': notes,
      };
}
