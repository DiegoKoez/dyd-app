import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/items_data.dart';
import '../../models/item.dart';
import '../../services/game_session.dart';
import '../../widgets/image_search_dialog.dart';
import 'create_item_dialog.dart';

/// Bottom sheet letting the DM pick an item and optionally a player to give
/// it to. If [preselectedPlayerId] is provided, the player picker is skipped
/// and the item is given directly to that player.
Future<({GameItem item, String playerId})?> showGiveItemSheet(
  BuildContext context, {
  String? preselectedPlayerId,
}) {
  return showModalBottomSheet<({GameItem item, String playerId})>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => _GiveItemFlow(
      preselectedPlayerId: preselectedPlayerId,
    ),
  );
}

class _GiveItemFlow extends StatefulWidget {
  final String? preselectedPlayerId;

  const _GiveItemFlow({this.preselectedPlayerId});

  @override
  State<_GiveItemFlow> createState() => _GiveItemFlowState();
}

class _GiveItemFlowState extends State<_GiveItemFlow> {
  GameItem? _selectedItem;
  String? _pendingImageBase64;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_selectedItem == null) {
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Dar objeto', style: theme.textTheme.titleLarge),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.casino),
            title: const Text('Objeto aleatorio'),
            subtitle: const Text('Elige uno al azar del catálogo'),
            onTap: () {
              final randomItem = kItems[Random().nextInt(kItems.length)];
              _selectItem(randomItem);
            },
          ),
          ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Crear objeto personalizado'),
            subtitle: const Text('Agrega nombre, efecto y estadísticas propias'),
            onTap: () async {
              final item = await showCreateItemDialog(context);
              if (item == null || !mounted) return;
              _selectItem(item);
            },
          ),
          const Divider(),
          for (final item in kItems)
            ListTile(
              leading: Icon(iconForEffect(item.effect)),
              title: Text(item.name),
              subtitle: Text(
                item.damageDice == null
                    ? item.description
                    : '${item.description} · ${item.damageDice}',
              ),
              onTap: () => _selectItem(item),
            ),
        ],
      );
    }

    if (widget.preselectedPlayerId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.of(context).pop((
          item: _selectedItem!,
          playerId: widget.preselectedPlayerId!,
        ));
      });
      return const SizedBox.shrink();
    }

    final session = context.read<GameSession>();
    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Selecciona un jugador', style: theme.textTheme.titleLarge),
        ),
        const SizedBox(height: 8),
        ListTile(
          leading: Icon(iconForEffect(_selectedItem!.effect)),
          title: Text(_selectedItem!.name),
          subtitle: Text(_selectedItem!.description),
        ),
        Row(
          children: [
            if (_pendingImageBase64 != null)
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 12.0),
                child: CircleAvatar(
                  radius: 24,
                  backgroundImage: MemoryImage(base64Decode(_pendingImageBase64!)),
                ),
              ),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () async {
                  // Determinar si es arma u objeto basado en el efecto
                  final isWeapon = ['fuego', 'hielo', 'veneno', 'otro'].contains(_selectedItem!.effect);
                  final base64 = await showImageSearchDialog(context, _selectedItem!.name, isWeapon: isWeapon);
                  if (base64 != null && mounted) {
                    setState(() => _pendingImageBase64 = base64);
                  }
                },
                icon: const Icon(Icons.image),
                label: Text(_pendingImageBase64 == null ? 'Agregar imagen' : 'Cambiar imagen'),
              ),
            ),
          ],
        ),
        const Divider(),
        for (final player in session.players)
          ListTile(
            leading: const Icon(Icons.person),
            title: Text(player.name),
            subtitle: Text(
              player.hasCharacter
                  ? '${player.raceName} ${player.className}'
                  : 'Sin personaje',
            ),
            onTap: () {
              final item = _selectedItem!.copyWith(imageBase64: _pendingImageBase64);
              Navigator.of(context).pop((item: item, playerId: player.id));
            },
          ),
      ],
    );
  }

  void _selectItem(GameItem item) {
    setState(() {
      _selectedItem = item;
      _pendingImageBase64 = null;
    });
  }
}
