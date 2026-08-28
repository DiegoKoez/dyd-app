import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ability.dart';
import '../../models/character_class.dart';
import '../../services/game_session.dart';

const List<int> kHitDiceOptions = [4, 6, 8, 10, 12, 14, 20];

/// Dialog that lets the player create a custom class with a name, description,
/// hit die, armor bonus, saving throws, and specialties.
Future<CharacterClass?> showClassCreationDialog(
  BuildContext context,
  List<CharacterClass> existingClasses,
) {
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  int selectedHitDie = 8;
  int armorBonus = 0;
  final Set<Ability> savingThrows = {};
  final specialtiesController = TextEditingController();

  return showDialog<CharacterClass>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final List<DropdownMenuEntry<int>> diceEntries = kHitDiceOptions
            .map((d) => DropdownMenuEntry(value: d, label: 'd$d'))
            .toList();

        return AlertDialog(
          title: const Text('Crear clase personalizada'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la clase',
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
                DropdownMenu<int>(
                  initialSelection: selectedHitDie,
                  label: const Text('Dado de golpe'),
                  dropdownMenuEntries: diceEntries,
                  onSelected: (v) => setState(() => selectedHitDie = v ?? 8),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: '0',
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Bono de armadura (AC)',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: 0, 2, 4, 6',
                  ),
                  onChanged: (v) {
                    final val = int.tryParse(v.trim()) ?? 0;
                    setState(() => armorBonus = val);
                  },
                ),
                const SizedBox(height: 16),
                Text('Tiradas salvación',
                    style: Theme.of(context).textTheme.titleSmall),
                Wrap(
                  spacing: 6,
                  children: Ability.values
                      .map((a) => FilterChip(
                            label: Text(a.abbreviation),
                            selected: savingThrows.contains(a),
                            onSelected: (checked) {
                              setState(() {
                                if (checked) {
                                  savingThrows.add(a);
                                } else {
                                  savingThrows.remove(a);
                                }
                              });
                            },
                            visualDensity: VisualDensity.compact,
                          ))
                      .toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: specialtiesController,
                  decoration: const InputDecoration(
                    labelText: 'Especialidades (separadas por coma)',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Atletismo, Intuición',
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
                final charClass = CharacterClass(
                  id: id,
                  name: name,
                  description: descriptionController.text.trim(),
                  hitDie: selectedHitDie,
                  abilityPriority: Ability.values.toList(),
                  armorBonus: armorBonus,
                  savingThrows: savingThrows.toList(),
                  specialties: specialtiesController.text
                      .trim()
                      .split(',')
                      .map((e) => e.trim())
                      .where((e) => e.isNotEmpty)
                      .toList(),
                );
                session.addCustomClass(charClass);
                Navigator.of(context).pop(charClass);
              },
              child: const Text('Crear'),
            ),
          ],
        );
      },
    ),
  );
}
