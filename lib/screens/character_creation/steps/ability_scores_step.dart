import 'package:flutter/material.dart';
import '../../../models/ability.dart';
import '../../../models/ability_scores.dart';

/// Step where the player manually assigns their six ability scores.
/// Bonuses from race are applied on top of the entered values.
class AbilityScoresStep extends StatelessWidget {
  final Map<Ability, int> scores;
  final ValueChanged<Ability> onIncrement;
  final ValueChanged<Ability> onDecrement;
  final AbilityScores baseScores;
  final Map<Ability, int> raceBonuses;

  const AbilityScoresStep({
    super.key,
    required this.scores,
    required this.onIncrement,
    required this.onDecrement,
    required this.baseScores,
    required this.raceBonuses,
  });

  static int _modifier(int total) => ((total - 10) / 2).floor();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Estadísticas de característica',
          style: theme.textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Asigna puntos a cada estadística. Los bonos de raza se aplican automáticamente.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        for (final ability in Ability.values)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(ability.label,
                          style: theme.textTheme.titleMedium),
                      Text(ability.abbreviation,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(color: theme.colorScheme.secondary)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: () => onDecrement(ability),
                        child: const Icon(Icons.remove),
                      ),
                      Text(
                        '${scores[ability] ?? 10}',
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => onIncrement(ability),
                        child: const Icon(Icons.add),
                      ),
                    ],
                  ),
                  if ((raceBonuses[ability] ?? 0) != 0)
                    Text(
                      'Bono de raza: ${raceBonuses[ability]! > 0 ? '+' : ''}${raceBonuses[ability]}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: Colors.green),
                    ),
                  Builder(builder: (_) {
                    final base = scores[ability] ?? 10;
                    final bonus = raceBonuses[ability] ?? 0;
                    final total = base + bonus;
                    final mod = _modifier(total);
                    return Text(
                      'Total: $total (mod $mod)',
                      style: theme.textTheme.bodySmall,
                    );
                  }),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
