import 'package:flutter/material.dart';
import '../../../models/ability.dart';
import '../../../models/character.dart';
import '../../../widgets/stat_row.dart';

class SummaryStep extends StatelessWidget {
  final Character character;
  final VoidCallback onConfirm;

  const SummaryStep({super.key, required this.character, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(character.name, style: theme.textTheme.headlineSmall),
        Text('${character.race.name} · ${character.characterClass.name}',
            style: theme.textTheme.titleMedium),
        Text(
          '${character.hairStyle}, pelo ${character.hairColor.toLowerCase()} · ${character.heightCm} cm · ${character.gender}',
          style: theme.textTheme.bodyMedium,
        ),
        const Divider(height: 32),
        Text('Estadísticas', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        for (final ability in Ability.values)
          StatRow(
            ability: ability,
            score: character.abilityScores.score(ability),
            modifier: character.abilityScores.modifier(ability),
          ),
        const Divider(height: 32),
        Text('Vida y especialidades', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        _InfoLine(label: 'Puntos de Vida Máximos', value: '${character.maxHp}'),
        _InfoLine(label: 'Dados de Vida', value: character.hitDiceLabel),
        _InfoLine(label: 'Clase de Armadura (AC)', value: '${character.armorClass}'),
        const SizedBox(height: 8),
        Text('Especializaciones / Pasiones', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              character.specialties.map((s) => Chip(label: Text(s))).toList(),
        ),
        const SizedBox(height: 32),
        FilledButton.icon(
          onPressed: onConfirm,
          icon: const Icon(Icons.check),
          label: const Text('Crear personaje'),
        ),
      ],
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
