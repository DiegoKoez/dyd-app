import 'ability.dart';

/// Standard array used to distribute base ability scores by class priority.
const List<int> kStandardArray = [15, 14, 13, 12, 10, 8];

/// Holds the six ability scores of a character and derives modifiers.
class AbilityScores {
  final Map<Ability, int> scores;

  const AbilityScores(this.scores);

  int score(Ability ability) => scores[ability] ?? 10;

  int modifier(Ability ability) => ((score(ability) - 10) / 2).floor();

  /// Returns a new [AbilityScores] with the given bonuses added on top.
  AbilityScores withBonuses(Map<Ability, int> bonuses) {
    final merged = {...scores};
    bonuses.forEach((ability, bonus) {
      merged[ability] = (merged[ability] ?? 10) + bonus;
    });
    return AbilityScores(merged);
  }
}
