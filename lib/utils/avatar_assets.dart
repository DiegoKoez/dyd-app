import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import '../models/character.dart';
import '../models/battle_monster.dart';

const _defaultMonsterAsset = 'assets/monsters/default_monster.png';

String? raceDefaultAsset(Character character) {
  final raceId = character.race.id;
  final gender = character.gender.toLowerCase();
  final base = 'assets/avatars/${raceId}_$gender.png';
  return base;
}

String monsterAsset(BattleMonster monster) {
  if (monster.photoBase64 != null && monster.photoBase64!.isNotEmpty) {
    return _defaultMonsterAsset;
  }
  final id = monster.id.isEmpty ? 'default' : monster.id;
  return 'assets/monsters/$id.png';
}

Future<ImageProvider> monsterImageProvider(BattleMonster monster) async {
  final asset = monsterAsset(monster);
  try {
    final bytes = await rootBundle.load(asset);
    return MemoryImage(bytes.buffer.asUint8List());
  } on Exception {
    return const AssetImage(_defaultMonsterAsset);
  }
}

Future<ImageProvider> raceAvatarProvider(Character character) async {
  final asset = raceDefaultAsset(character);
  if (asset == null) return const AssetImage('assets/avatars/default.png');
  try {
    final bytes = await rootBundle.load(asset);
    return MemoryImage(bytes.buffer.asUint8List());
  } on Exception {
    return const AssetImage('assets/avatars/default.png');
  }
}
