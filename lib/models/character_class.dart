import 'ability.dart';

/// A playable class, defining hit points, armor, saves and specialties.
class CharacterClass {
  final String id;
  final String name;
  final String description;

  /// Die used for hit points (e.g. 10 -> d10).
  final int hitDie;

  /// Ability priority order used to assign the standard array, from most to
  /// least important for this class.
  final List<Ability> abilityPriority;

  /// Flat bonus to armor class representing this class's typical starting
  /// gear (light/medium/heavy armor and shields).
  final int armorBonus;

  final List<Ability> savingThrows;

  /// Especializaciones / pasiones del personaje.
  final List<String> specialties;

  const CharacterClass({
    required this.id,
    required this.name,
    required this.description,
    required this.hitDie,
    required this.abilityPriority,
    required this.armorBonus,
    required this.savingThrows,
    required this.specialties,
  });

  String get hitDiceLabel => '1d$hitDie';
}
