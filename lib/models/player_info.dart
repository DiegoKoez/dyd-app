import '../models/item.dart';

/// A connected player as seen by the Dungeon Master / game session, built
/// from the JSON the server broadcasts (id, name, character summary,
/// inventory).
class PlayerInfo {
  final String id;
  final String name;
  final Map<String, dynamic>? character;
  final List<GameItem> inventory;
  final List<GameItem> weapons;
  final bool customizing;

  const PlayerInfo({
    required this.id,
    required this.name,
    this.character,
    this.inventory = const [],
    this.weapons = const [],
    this.customizing = false,
  });

  factory PlayerInfo.fromJson(Map<String, dynamic> json) {
    final rawInventory = (json['inventory'] as List?) ?? const [];
    final rawWeapons = (json['weapons'] as List?) ?? const [];
    return PlayerInfo(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? 'Jugador',
      character: json['character'] == null
          ? null
          : Map<String, dynamic>.from(json['character'] as Map),
      inventory: rawInventory
          .map((e) => GameItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      weapons: rawWeapons
          .map((e) => GameItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      customizing: json['customizing'] as bool? ?? false,
    );
  }

  bool get hasCharacter => character != null;
  String get raceName => character?['race'] as String? ?? '';
  String get className => character?['characterClass'] as String? ?? '';
  String get photoBase64 => character?['photoBase64'] as String? ?? '';
  int get maxHp => (character?['maxHp'] as num?)?.toInt() ?? 0;
  int get currentHp => (character?['currentHp'] as num?)?.toInt() ?? maxHp;
  int get armorClass => (character?['armorClass'] as num?)?.toInt() ?? 10;
}
