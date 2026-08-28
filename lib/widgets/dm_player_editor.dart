import 'package:flutter/material.dart';
import '../models/ability.dart';
import '../models/character_class.dart';
import '../models/player_info.dart';
import '../models/race.dart';
import '../services/game_session.dart';

/// Opens a two-step dialog: first a player list, then an editor for the
/// selected player's stats.  Designed to be called from any DM screen.
void showPlayerEditor(BuildContext ctx, GameSession session) {
  showDialog(
    context: ctx,
    builder: (listCtx) => AlertDialog(
      title: const Text('Selecciona un jugador para editar'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: session.players.where((p) => p.hasCharacter).length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final player = session.players.where((p) => p.hasCharacter).elementAt(index);
            return ListTile(
              leading: const Icon(Icons.person),
              title: Text(player.name),
              subtitle: Text('${player.raceName} · ${player.className}'),
              onTap: () {
                Navigator.of(listCtx).pop();
                _showEditor(ctx, session, player);
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(listCtx).pop(), child: const Text('Cancelar')),
      ],
    ),
  );
}

void _showEditor(BuildContext ctx, GameSession session, PlayerInfo player) {
  final char = player.character;
  if (char == null) return;

  final nameController = TextEditingController(text: player.name);
  final hpController = TextEditingController(text: char['maxHp']?.toString() ?? '0');
  final acController = TextEditingController(text: char['armorClass']?.toString() ?? '10');
  final currentHpController = TextEditingController(text: char['currentHp']?.toString() ?? char['maxHp']?.toString() ?? '0');

  final abilityControllers = <Ability, TextEditingController>{};
  final scores = char['abilityScores'] as Map<String, dynamic>? ?? {};
  for (final a in Ability.values) {
    abilityControllers[a] = TextEditingController(
        text: (scores[a.name] as num?)?.toInt().toString() ?? '10');
  }

  Race? selectedRace = session.allAvailableRaces
      .firstWhere((r) => r.name == player.raceName, orElse: () => session.allAvailableRaces.first);
  CharacterClass? selectedClass = session.allAvailableClasses
      .firstWhere((c) => c.name == player.className, orElse: () => session.allAvailableClasses.first);

  showDialog(
    context: ctx,
    builder: (dialogCtx) => StatefulBuilder(
      builder: (dialogCtx, setState) {
        final races = session.allAvailableRaces;
        final classes = session.allAvailableClasses;
        return AlertDialog(
          title: Text('Editar: ${player.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<Race>(
                    value: selectedRace,
                    items: races.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
                    onChanged: (r) => setState(() => selectedRace = r),
                    decoration: const InputDecoration(labelText: 'Raza', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<CharacterClass>(
                    value: selectedClass,
                    items: classes.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                    onChanged: (c) => setState(() => selectedClass = c),
                    decoration: const InputDecoration(labelText: 'Clase', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hpController,
                    decoration: const InputDecoration(labelText: 'HP Máximo', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: currentHpController,
                    decoration: const InputDecoration(labelText: 'HP Actual', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: acController,
                    decoration: const InputDecoration(labelText: 'Clase de Armadura (AC)', border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  Text('Tiradas de característica', style: Theme.of(ctx).textTheme.titleSmall),
                  for (final a in Ability.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(child: Text(a.label, style: Theme.of(ctx).textTheme.bodySmall)),
                          SizedBox(
                            width: 60,
                            child: TextField(
                              controller: abilityControllers[a],
                              decoration: const InputDecoration(hintText: '10', isDense: true),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogCtx).pop(), child: const Text('Cancelar')),
            OutlinedButton.icon(
              onPressed: () {
                final maxHp = int.tryParse(hpController.text.trim()) ?? (char['maxHp'] as num?)?.toInt() ?? 0;
                currentHpController.text = maxHp.toString();
                setState(() {});
              },
              icon: const Icon(Icons.healing),
              label: const Text('Curar al máximo'),
            ),
            FilledButton(
              onPressed: () {
                final newName = nameController.text.trim().isEmpty ? player.name : nameController.text.trim();
                final newMaxHp = int.tryParse(hpController.text.trim()) ?? (char['maxHp'] as num?)?.toInt() ?? 0;
                final newCurrentHp = int.tryParse(currentHpController.text.trim()) ?? (char['currentHp'] as num?)?.toInt() ?? newMaxHp;
                final newAc = int.tryParse(acController.text.trim()) ?? (char['armorClass'] as num?)?.toInt() ?? 10;
                final updatedScores = <String, int>{};
                for (final a in Ability.values) {
                  final v = int.tryParse(abilityControllers[a]!.text.trim());
                  updatedScores[a.name] = v ?? (scores[a.name] as num?)?.toInt() ?? 10;
                }

                session.updatePlayer(player.id, {
                  'name': newName,
                  'character': {
                    'name': newName,
                    'race': selectedRace?.name ?? (char['race'] as String? ?? ''),
                    'characterClass': selectedClass?.name ?? (char['characterClass'] as String? ?? ''),
                    'maxHp': newMaxHp,
                    'currentHp': newCurrentHp,
                    'armorClass': newAc,
                    'abilityScores': updatedScores,
                  },
                });

                Navigator.of(dialogCtx).pop();
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Personaje actualizado')),
                  );
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    ),
  );
}
