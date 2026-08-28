import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../models/race.dart';
import '../../../services/game_session.dart';
import '../../../widgets/selectable_card.dart';
import '../../../widgets/race_creation_dialog.dart';

class RaceStep extends StatelessWidget {
  final Race? selected;
  final ValueChanged<Race> onSelected;

  const RaceStep({super.key, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final allRaces = context.watch<GameSession>().allAvailableRaces;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Elige la raza de tu personaje',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final race in allRaces)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SelectableCard(
              title: race.name,
              subtitle: race.description,
              tags: [race.bonusSummary, ...race.traits],
              selected: selected?.id == race.id,
              onTap: () => onSelected(race),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: TextButton.icon(
            onPressed: () async {
              final session = context.read<GameSession>();
              final result = await showRaceCreationDialog(context, allRaces);
              if (result == null || !context.mounted) return;
              session.addCustomRace(result);
              onSelected(result);
            },
            icon: const Icon(Icons.add),
            label: const Text('Crear raza personalizada'),
          ),
        ),
      ],
    );
  }
}
