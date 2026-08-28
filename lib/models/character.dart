import 'ability.dart';
import 'ability_scores.dart';
import 'character_class.dart';
import 'race.dart';
import '../data/races_data.dart';
import '../data/classes_data.dart';

/// A fully built player character, ready to join a session.
class Character {
  final String name;
  final Race race;
  final CharacterClass characterClass;
  final String hairStyle;
  final String hairColor;
  final int heightCm;
  final AbilityScores abilityScores;
  final int maxHp;
  final int armorClass;
  final String gender;
  final String? photoBase64;

  const Character({
    required this.name,
    required this.race,
    required this.characterClass,
    required this.hairStyle,
    required this.hairColor,
    required this.heightCm,
    required this.abilityScores,
    required this.maxHp,
    required this.armorClass,
    this.gender = 'masculino',
    this.photoBase64,
  });

  Character copyWith({
    String? name,
    Race? race,
    CharacterClass? characterClass,
    String? hairStyle,
    String? hairColor,
    int? heightCm,
    AbilityScores? abilityScores,
    int? maxHp,
    int? armorClass,
    String? gender,
    String? photoBase64,
  }) => Character(
           name: name ?? this.name,
           race: race ?? this.race,
           characterClass: characterClass ?? this.characterClass,
           hairStyle: hairStyle ?? this.hairStyle,
           hairColor: hairColor ?? this.hairColor,
           heightCm: heightCm ?? this.heightCm,
           abilityScores: abilityScores ?? this.abilityScores,
           maxHp: maxHp ?? this.maxHp,
           armorClass: armorClass ?? this.armorClass,
           gender: gender ?? this.gender,
           photoBase64: photoBase64 ?? this.photoBase64,
         );

  String get hitDiceLabel => characterClass.hitDiceLabel;

  List<String> get specialties => characterClass.specialties;

  factory Character.fromJson(Map<String, dynamic> json) {
    final raceName = json['race'] as String? ?? '';
    final className = json['characterClass'] as String? ?? '';
    final race = kRaces.firstWhere((r) => r.name == raceName, orElse: () => kRaces.first);
    final characterClass = kClasses.firstWhere((c) => c.name == className, orElse: () => kClasses.first);

    final abilityScoresJson = json['abilityScores'] as Map<String, dynamic>? ?? {};
    final abilityScores = <Ability, int>{};
    for (final entry in abilityScoresJson.entries) {
      final ability = Ability.values.firstWhere((a) => a.name == entry.key, orElse: () => Ability.fuerza);
      abilityScores[ability] = (entry.value as num).toInt();
    }

    return Character(
      name: json['name'] as String? ?? 'Sin nombre',
      race: race,
      characterClass: characterClass,
      hairStyle: json['hairStyle'] as String? ?? '',
      hairColor: json['hairColor'] as String? ?? '',
      heightCm: (json['heightCm'] as num?)?.toInt() ?? 170,
      abilityScores: AbilityScores(abilityScores),
      maxHp: (json['maxHp'] as num?)?.toInt() ?? 10,
      armorClass: (json['armorClass'] as num?)?.toInt() ?? 10,
      gender: json['gender'] as String? ?? 'masculino',
      photoBase64: json['photoBase64'] as String?,
    );
  }

  /// Serializes the display-relevant fields to send over the network.
  Map<String, dynamic> toJson() => {
        'name': name,
        'race': race.name,
        'characterClass': characterClass.name,
        'hairStyle': hairStyle,
        'hairColor': hairColor,
        'heightCm': heightCm,
        'abilityScores': {
          for (final ability in Ability.values) ability.name: abilityScores.score(ability),
        },
        'maxHp': maxHp,
        'currentHp': maxHp,
        'armorClass': armorClass,
        'hitDiceLabel': hitDiceLabel,
        'specialties': specialties,
        'photoBase64': photoBase64,
        'gender': gender,
      };

  /// Builds a character, assigning the standard array by class priority,
  /// applying racial bonuses, and deriving HP/AC.
  factory Character.create({
    required String name,
    required Race race,
    required CharacterClass characterClass,
    required String hairStyle,
    required String hairColor,
    required int heightCm,
  }) {
    final baseScores = <Ability, int>{};
    for (var i = 0; i < characterClass.abilityPriority.length; i++) {
      baseScores[characterClass.abilityPriority[i]] = kStandardArray[i];
    }

    final finalScores =
        AbilityScores(baseScores).withBonuses(race.abilityBonuses);

    final conModifier = finalScores.modifier(Ability.constitucion);
    final maxHp = characterClass.hitDie + conModifier < 1
        ? 1
        : characterClass.hitDie + conModifier;

    final dexModifier = finalScores.modifier(Ability.destreza);
    final armorClass = 10 + dexModifier + characterClass.armorBonus;

    return Character(
      name: name,
      race: race,
      characterClass: characterClass,
      hairStyle: hairStyle,
      hairColor: hairColor,
      heightCm: heightCm,
      abilityScores: finalScores,
      maxHp: maxHp,
      armorClass: armorClass,
    );
  }
}
