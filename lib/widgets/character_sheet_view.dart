import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/ability.dart';
import '../models/character.dart';
import '../models/item.dart';
import 'stat_row.dart';

/// Read-only character sheet content, reusable inside any Scaffold.
/// If [onEditPhoto] is provided, shows a button to change the character's
/// photo.
class CharacterSheetView extends StatelessWidget {
  final Character character;
  final int? currentHp;
  final VoidCallback? onEditPhoto;
  final List<GameItem>? weapons;

  const CharacterSheetView({
    super.key,
    required this.character,
    this.currentHp,
    this.onEditPhoto,
    this.weapons,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Stack(
            children: [
              CircleAvatar(
                radius: 48,
                backgroundImage: character.photoBase64 != null && character.photoBase64!.isNotEmpty
                    ? MemoryImage(base64Decode(character.photoBase64!))
                    : null,
                child: character.photoBase64 == null || character.photoBase64!.isEmpty
                    ? const Icon(Icons.person, size: 48)
                    : null,
              ),
              if (onEditPhoto != null)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: theme.colorScheme.primary,
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      padding: EdgeInsets.zero,
                      onPressed: onEditPhoto,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
         Center(
           child: Text(
             '${character.race.name} · ${character.characterClass.name}',
             style: theme.textTheme.titleLarge,
           ),
         ),
        Center(
          child: Text(
            '${character.hairStyle}, pelo ${character.hairColor.toLowerCase()} · ${character.heightCm} cm',
            style: theme.textTheme.bodyMedium,
          ),
        ),
        const Divider(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BigStat(label: 'Vida', value: '${currentHp ?? character.maxHp}/${character.maxHp}', icon: Icons.favorite),
            _BigStat(label: 'AC', value: '${character.armorClass}', icon: Icons.shield),
            _BigStat(label: 'Dados', value: character.hitDiceLabel, icon: Icons.casino),
          ],
        ),
        const Divider(height: 32),
        Text('Estadísticas', style: theme.textTheme.titleMedium),
        for (final ability in Ability.values)
          StatRow(
            ability: ability,
            score: character.abilityScores.score(ability),
            modifier: character.abilityScores.modifier(ability),
          ),
        const Divider(height: 32),
        Text('Especializaciones / Pasiones', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: character.specialties.map((s) => Chip(label: Text(s))).toList(),
        ),
        const SizedBox(height: 24),
        Text('Rasgos de raza', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: character.race.traits.map((t) => Chip(label: Text(t))).toList(),
        ),
        if (weapons != null && weapons!.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Armas', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          for (final weapon in weapons!)
            Card(
              child: ListTile(
                leading: weapon.icon != null
                    ? Text(weapon.icon!, style: const TextStyle(fontSize: 28))
                    : Icon(iconForEffect(weapon.effect)),
                title: Text(weapon.name),
                subtitle: Text(weapon.description),
              ),
            ),
        ],
      ],
    );
  }
}

class _BigStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _BigStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 28),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}
