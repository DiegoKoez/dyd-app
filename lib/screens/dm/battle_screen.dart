import 'package:flutter/material.dart';
import '../../models/monster.dart';

/// Placeholder for the future turn-based combat screen (split view
/// personaje vs. monstruo, 3 acciones + 2 movimientos por turno).
class BattleScreen extends StatelessWidget {
  final List<Monster> monsters;

  const BattleScreen({super.key, required this.monsters});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Combate')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Icon(Icons.construction, size: 48, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            'La pantalla de combate por turnos se construirá en la próxima iteración.',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Text('Encuentro preparado', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          for (final monster in monsters)
            Card(
              child: ListTile(
                leading: const Icon(Icons.pets),
                title: Text(monster.name),
                subtitle: Text(
                    'HP ${monster.maxHp} · AC ${monster.armorClass} · ${monster.attackName} (${monster.damageDice})'),
              ),
            ),
        ],
      ),
    );
  }
}
