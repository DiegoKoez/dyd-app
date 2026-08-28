import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../services/game_session.dart';

Future<String?> _showTargetDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('¿En quién usar el objeto?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop('self'),
          child: const Text('En mí mismo'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop('player'),
          child: const Text('En aliado'),
        ),
      ],
    ),
  );
}

Future<String?> _showAllyPicker(BuildContext context, GameSession session) {
  final allies = session.players.where((p) => p.id != session.myPlayerId).toList();
  if (allies.isEmpty) {
    return Future.value('self');
  }
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Selecciona un aliado'),
      children: [
        for (final ally in allies)
          SimpleDialogOption(
            onPressed: () => Navigator.of(context).pop(ally.id),
            child: Text(ally.name),
          ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop('self'),
          child: const Text('Cancelar'),
        ),
      ],
    ),
  );
}

/// Shows the current player's inventory (bag), usable both while waiting
/// in the lobby and during battle.
class InventoryView extends StatelessWidget {
  const InventoryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameSession>(
      builder: (context, session, _) {
        if (session.myInventory.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.backpack_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'Tu mochila está vacía.\nEl Dungeon Master te dará objetos durante la partida.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final item in session.myInventory)
              Card(
                child: ListTile(
                  leading: Icon(iconForEffect(item.effect)),
                  title: Text(item.name),
                  subtitle: Text(
                    item.damageDice == null
                        ? item.description
                        : '${item.description} · ${item.damageDice}',
                  ),
                  trailing: session.pendingItemUseId == item.id
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : TextButton(
                          onPressed: () async {
                            final session = Provider.of<GameSession>(context, listen: false);
                            final targetType = await _showTargetDialog(context);
                            if (targetType == null) return;
                            if (targetType == 'self') {
                              session.useItem(item);
                            } else {
                              final targetId = await _showAllyPicker(context, session);
                              if (targetId == null) return;
                              session.useItem(item, targetType: 'player', targetId: targetId);
                            }
                          },
                          child: const Text('Usar'),
                        ),
                ),
              ),
          ],
        );
      },
    );
  }
}
