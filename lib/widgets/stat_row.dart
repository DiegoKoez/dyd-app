import 'package:flutter/material.dart';
import '../models/ability.dart';

/// Displays one ability score with its modifier, e.g. "Fuerza 15 (+2)".
class StatRow extends StatelessWidget {
  final Ability ability;
  final int score;
  final int modifier;

  const StatRow({
    super.key,
    required this.ability,
    required this.score,
    required this.modifier,
  });

  @override
  Widget build(BuildContext context) {
    final sign = modifier >= 0 ? '+' : '';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(ability.label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text('$score', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Text('($sign$modifier)', style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
