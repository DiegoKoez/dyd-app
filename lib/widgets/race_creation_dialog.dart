import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ability.dart';
import '../../models/race.dart';
import '../../services/game_session.dart';

/// Dialog that lets the player create a custom race with a name, description,
/// ability bonuses, and trait text. Returns the created [Race] or null.
Future<Race?> showRaceCreationDialog(
  BuildContext context,
  List<Race> existingRaces,
) {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  final Map<Ability, int> bonuses = {for (final a in Ability.values) a: 0};
  final traitsController = TextEditingController();

  return showDialog<Race>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Crear raza personalizada'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre de la raza',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Text('Bonificaciones de habilidad',
                  style: Theme.of(context).textTheme.titleSmall),
              for (final ability in Ability.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 90,
                        child: Text(ability.label,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Expanded(
                        child: TextFormField(
                          initialValue: '0',
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: '+X',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (v) {
                            final val = int.tryParse(v.trim()) ?? 0;
                            setState(() => bonuses[ability] = val);
                          },
                        ),
                      ),
                      Text(
                        ability.abbreviation,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              TextField(
                controller: traitsController,
                decoration: const InputDecoration(
                  labelText: 'Rasgos (separados por coma)',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: Visión en la oscuridad, Resistencia al fuego',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final session = context.read<GameSession>();
              final id = 'custom_${DateTime.now().millisecondsSinceEpoch}';
              final race = Race(
                id: id,
                name: name,
                description: descriptionController.text.trim(),
                abilityBonuses: bonuses,
                traits: traitsController.text
                    .trim()
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList(),
              );
              session.addCustomRace(race);
              Navigator.of(context).pop(race);
            },
            child: const Text('Crear'),
          ),
        ],
      ),
    ),
  );
}
