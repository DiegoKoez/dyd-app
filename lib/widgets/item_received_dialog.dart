import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../services/game_session.dart';

Future<void> showItemReceivedDialog(BuildContext context, GameItem item) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: item.imageBase64 != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                base64Decode(item.imageBase64!),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          : Text(emojiForItemName(item.name), style: const TextStyle(fontSize: 56)),
      title: const Text('Haz obtenido un objeto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            item.description,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ya lo tienes en tu inventario (pestaña Mochila).',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          if (item.damageDice != null) ...[
            const SizedBox(height: 8),
            Text(
              item.damageDice!,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () {
            final session = context.read<GameSession>();
            session.clearReceivedItem();
            Navigator.of(context).pop();
          },
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}
