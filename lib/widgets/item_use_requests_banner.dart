import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../services/game_session.dart';

Future<int?> _showEffectValueDialog(BuildContext context, ItemUseRequest request) {
  final controller = TextEditingController();
  return showDialog<int>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('${request.playerName} quiere usar ${request.item.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Objetivo: ${request.targetName}'),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Valor del efecto (cura/daño)',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Rechazar'),
        ),
        FilledButton(
          onPressed: () {
            final raw = controller.text.trim();
            final value = raw.isEmpty ? 0 : (int.tryParse(raw) ?? 0);
            Navigator.of(context).pop(value);
          },
          child: const Text('Aceptar'),
        ),
      ],
    ),
  );
}

/// Shown to the DM whenever a player asks to use an item from their
/// inventory; lets the DM accept (item is consumed) or reject (item stays).
class ItemUseRequestsBanner extends StatelessWidget {
  const ItemUseRequestsBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameSession>(
      builder: (context, session, _) {
        if (session.itemUseRequests.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            for (final request in session.itemUseRequests)
              Card(
                color: Theme.of(context).colorScheme.tertiaryContainer,
                child: ListTile(
                  leading: Icon(iconForEffect(request.item.effect)),
                  title: Text('${request.playerName} quiere usar ${request.item.name}'),
                  subtitle: Text('Objetivo: ${request.targetName}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        tooltip: 'Aceptar',
                        onPressed: () async {
                          final value = await _showEffectValueDialog(context, request);
                          if (value == null) return;
                          session.resolveItemUse(request, true, effectValue: value);
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        tooltip: 'Rechazar',
                        onPressed: () => session.resolveItemUse(request, false),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
