import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/game_session.dart';
import '../../../models/character_class.dart';
import '../../../widgets/selectable_card.dart';
import '../../../widgets/class_creation_dialog.dart';

class ClassStep extends StatelessWidget {
  final CharacterClass? selected;
  final ValueChanged<CharacterClass> onSelected;

  const ClassStep({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final allClasses = context.watch<GameSession>().allAvailableClasses;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Elige la clase de tu personaje',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final characterClass in allClasses)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableCard(
              title: characterClass.name,
              subtitle: characterClass.description,
              tags: [
                'Dado de vida ${characterClass.hitDiceLabel}',
                ...characterClass.specialties,
              ],
              selected: selected?.id == characterClass.id,
              onTap: () => onSelected(characterClass),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            onPressed: () async {
              final session = context.read<GameSession>();
              final result = await showClassCreationDialog(context, allClasses);
              if (result == null || !context.mounted) return;
              session.addCustomClass(result);
              onSelected(result);
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear clase personalizada'),
          ),
        ),
      ],
    );
  }
}
