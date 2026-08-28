import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item.dart';
import '../services/game_session.dart';

/// Shown to a player whenever the DM assigns them a weapon, so they know
/// what was granted (name, damage dice) and can dismiss it to continue.
Future<void> showWeaponReceivedDialog(BuildContext context, GameItem weapon) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      icon: weapon.imageBase64 != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                base64Decode(weapon.imageBase64!),
                width: 56,
                height: 56,
                fit: BoxFit.cover,
              ),
            )
          : Text(weapon.icon ?? emojiForItemName(weapon.name), style: const TextStyle(fontSize: 56)),
      title: const Text('Has recibido un arma'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            weapon.name,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            weapon.description,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Ya la tienes en tu inventario (pestaña Mochila) y en tu ficha de Personaje.',
            textAlign: TextAlign.center,
            style: TextStyle(fontStyle: FontStyle.italic),
          ),
          if (weapon.damageDice != null) ...[
            const SizedBox(height: 8),
            Text(
              'Daño: ${weapon.damageDice}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () {
            final session = context.read<GameSession>();
            session.clearReceivedWeapon();
            Navigator.of(context).pop();
          },
          child: const Text('Continuar'),
        ),
      ],
    ),
  );
}
