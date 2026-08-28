import 'ability.dart';

/// A playable race/lineage with its ability bonuses, narrative traits,
/// default avatar metadata and gender options.
class Race {
  final String id;
  final String name;
  final String description;
  final Map<Ability, int> abilityBonuses;
  final List<String> traits;
  final List<String> genders;
  final String avatarAsset;

  const Race({
    required this.id,
    required this.name,
    required this.description,
    required this.abilityBonuses,
    required this.traits,
    this.genders = const ['masculino', 'femenino', 'otro'],
    this.avatarAsset = 'assets/avatars/race_human.png',
  });

  String get bonusSummary => abilityBonuses.entries
      .map((e) => '+${e.value} ${e.key.abbreviation}')
      .join('  ');
}
