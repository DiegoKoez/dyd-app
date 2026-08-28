import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/player_info.dart';
import '../../models/character.dart';
import '../../models/battle_monster.dart';
import '../../models/item.dart';
import '../../services/game_session.dart';
import '../../utils/turn_label.dart';
import '../../widgets/item_use_requests_banner.dart';
import '../../widgets/dm_player_editor.dart';
import '../../widgets/defeated_avatar.dart';
import '../../widgets/image_search_dialog.dart';
import '../../utils/avatar_assets.dart';
import '../../data/weapons_data.dart';
import 'give_item_sheet.dart';

/// The Dungeon Master's live combat control: manual damage, turn management,
/// giving items, and sharing photos with the group.
class DmBattleScreen extends StatelessWidget {
  const DmBattleScreen({super.key});

  Future<void> _applyDamageToPlayer(BuildContext context, GameSession session) async {
    if (session.players.isEmpty) return;
    final player = await showDialog<PlayerInfo>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Selecciona un jugador'),
        children: [
          for (final p in session.players)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(p),
              child: Text(p.name),
            ),
        ],
      ),
    );
    if (player == null) return;

    final damage = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _DamageInputDialog(playerName: player.name),
    );
    if (damage == null || damage <= 0) return;

    session.manualDamage('player', player.id, damage);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${player.name} recibió $damage de daño')),
    );
  }

  Future<void> _applyDamageToEnemy(BuildContext context, GameSession session) async {
    if (session.monsters.isEmpty) return;
    final monster = await showDialog<BattleMonster>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: const Text('Selecciona un enemigo'),
        children: [
          for (final m in session.monsters)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(m),
              child: Text(m.name),
            ),
        ],
      ),
    );
    if (monster == null) return;

    final damage = await showDialog<int>(
      context: context,
      builder: (dialogContext) => _DamageInputDialog(playerName: monster.name),
    );
    if (damage == null || damage <= 0) return;

    session.manualDamage('monster', monster.instanceId, damage);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${monster.name} recibió $damage de daño')),
    );
  }

  Widget _buildDamageAnimation(int damage) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, -20 * value),
          child: Opacity(
            opacity: 1 - value,
            child: Text(
              '-$damage',
              style: TextStyle(
                fontSize: 24,
                color: Colors.red,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: const Offset(1, 1),
                    blurRadius: 2,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _giveItem(
      BuildContext context, GameSession session, PlayerInfo player) async {
    final result = await showGiveItemSheet(context, preselectedPlayerId: player.id);
    if (result == null) return;
    session.giveItem(result.playerId, result.item);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.item.name} entregado a ${player.name}')),
    );
  }

  Future<void> _sharePhoto(BuildContext context, GameSession session) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    session.sharePhoto(base64Encode(bytes));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto enviada al grupo')),
    );
  }

  Future<void> _setMonsterPhoto(BuildContext context, GameSession session, String instanceId) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    session.setMonsterPhoto(instanceId, base64Encode(bytes));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Foto del monstruo actualizada')),
    );
  }

  Future<void> _assignWeapon(BuildContext context, GameSession session, PlayerInfo player) async {
    String? weaponType = 'fuego';
    final selected = await showDialog<GameItem?>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Dar arma a ${player.name}'),
          content: SizedBox(
            width: 360,
            height: 400,
            child: ListView(
              children: [
                const Text('Tipo de arma', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: weaponType,
                  decoration: InputDecoration(
                    prefixIcon: Icon(_weaponTypeIcon(weaponType)),
                    labelText: 'Selecciona el tipo',
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'fuego', child: Text('Espada / Fuego')),
                    DropdownMenuItem(value: 'hielo', child: Text('Hielo / Bastón')),
                    DropdownMenuItem(value: 'veneno', child: Text('Veneno / Daga')),
                    DropdownMenuItem(value: 'otro', child: Text('Otro...')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => weaponType = value);
                  },
                ),
                const SizedBox(height: 16),
                if (weaponType != 'otro')
                  ...kWeapons.where((w) => w.effect == weaponType).map((weapon) {
                    return ListTile(
                      leading: Text(weapon.icon ?? emojiForItemName(weapon.name), style: const TextStyle(fontSize: 28)),
                      title: Text(weapon.name),
                      subtitle: Text(weapon.damageDice ?? weapon.description),
                      onTap: () => Navigator.of(ctx).pop(weapon),
                    );
                  }).toList(),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Otro...'),
                  subtitle: const Text('Ingresar arma personalizada'),
                  onTap: () => Navigator.of(ctx).pop(null),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    GameItem? weapon = selected;
    if (weapon == null) {
      final nameController = TextEditingController();
      final diceController = TextEditingController(text: '1d8');
      String? customIcon;
      String? customImageBase64;
      final custom = await showDialog<GameItem>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Arma personalizada para ${player.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre del arma',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: diceController,
                  decoration: const InputDecoration(
                    labelText: 'Dados de daño',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: 1d8, 2d6',
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (customImageBase64 != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 12.0),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundImage: MemoryImage(base64Decode(customImageBase64!)),
                        ),
                      ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final base64 = await showImageSearchDialog(context, nameController.text.trim());
                          if (base64 != null && context.mounted) {
                            setState(() => customImageBase64 = base64);
                          }
                        },
                        icon: const Icon(Icons.image),
                        label: Text(customImageBase64 == null ? 'Agregar imagen' : 'Cambiar imagen'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ListTile(
                  leading: Text(customIcon ?? '🎁', style: const TextStyle(fontSize: 28)),
                  title: const Text('Icono del arma'),
                  subtitle: Text(customIcon == null ? 'Toca para seleccionar' : 'Icono seleccionado'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () async {
                    final picked = await showDialog<String>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Selecciona un icono'),
                        content: SizedBox(
                          width: 360,
                          child: GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 5,
                              mainAxisSpacing: 8,
                              crossAxisSpacing: 8,
                            ),
                            itemCount: kWeaponIcons.length,
                            itemBuilder: (ctx, index) {
                              final option = kWeaponIcons[index];
                              final isSelected = customIcon == option['emoji'];
                              return InkWell(
                                onTap: () => Navigator.of(ctx).pop(option['emoji']),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: isSelected
                                          ? Theme.of(context).colorScheme.primary
                                          : Colors.transparent,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: Text(
                                      option['emoji']!,
                                      style: const TextStyle(fontSize: 28),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                    if (picked != null) {
                      setState(() => customIcon = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () {
                  if (nameController.text.trim().isEmpty) return;
                  Navigator.of(ctx).pop(GameItem(
                    id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
                    name: nameController.text.trim(),
                    description: 'Arma personalizada.',
                    effect: weaponType ?? 'fuego',
                    damageDice: diceController.text.trim(),
                    icon: customIcon,
                    imageBase64: customImageBase64,
                  ));
                },
                child: const Text('Dar'),
              ),
            ],
          ),
        ),
      );
      if (custom == null || !context.mounted) return;
      weapon = custom;
    }

    final error = await session.assignWeapon(
      playerId: player.id,
      weaponName: weapon.name,
      dice: weapon.damageDice ?? '1d8',
      icon: weapon.icon,
      imageBase64: weapon.imageBase64,
    );
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error, style: TextStyle(color: Theme.of(context).colorScheme.onError))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Arma entregada a ${player.name}')),
      );
    }
  }

  IconData _weaponTypeIcon(String? type) {
    switch (type) {
      case 'fuego':
        return Icons.local_fire_department;
      case 'hielo':
        return Icons.ac_unit;
      case 'veneno':
        return Icons.science;
      default:
        return Icons.category;
    }
  }

Future<void> _editEntityHp(
    BuildContext context,
    GameSession session,
    String targetType,
    String targetId,
    String targetName,
    int currentHp,
    int maxHp,
  ) async {
    final controller = TextEditingController(text: currentHp.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar HP: $targetName'),
        content: TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'HP actual',
            border: const OutlineInputBorder(),
            helperText: 'Máximo: $maxHp',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = int.tryParse(controller.text.trim());
              if (val == null || val < 0) return;
              Navigator.of(ctx).pop(val);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    if (result == null || !context.mounted) return;
    session.setEntityHp(targetType, targetId, result);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameSession>(
      builder: (context, session, _) {
        final theme = Theme.of(context);

        if (session.battleStartError != null && !session.battleStarted) {
          return Scaffold(
            appBar: AppBar(title: Text('Sala ${session.roomCode}')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  session.battleStartError!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Sala ${session.roomCode}'),
            actions: [
               if (session.players.any((p) => p.hasCharacter))
                IconButton(
                  onPressed: () => showPlayerEditor(context, session),
                  icon: const Icon(Icons.manage_accounts),
                  tooltip: 'Editar estadísticas de jugadores',
                ),
              IconButton(
                onPressed: () => _sharePhoto(context, session),
                icon: const Icon(Icons.photo_camera),
                tooltip: 'Compartir foto',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const ItemUseRequestsBanner(),
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.hourglass_bottom),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Turno: ${turnLabel(session)}')),
                      if (session.currentTurnId != null)
                        TextButton(
                          onPressed: session.endTurn,
                          child: const Text('Saltar turno'),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (session.currentTurnId != null && session.players.any((p) => p.id == session.currentTurnId))
                FilledButton.icon(
                  onPressed: () => _applyDamageToEnemy(context, session),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Daño Enemigo'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                )
              else if (session.currentTurnId != null && session.monsters.any((m) => m.instanceId == session.currentTurnId))
                FilledButton.icon(
                  onPressed: () => _applyDamageToPlayer(context, session),
                  icon: const Icon(Icons.flash_on),
                  label: const Text('Daño Jugador'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  session.endBattle();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Batalla finalizada')),
                  );
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.stop),
                label: const Text('Finalizar batalla'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 24),
              Text('Jugadores', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (session.players.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('Aún no se ha unido ningún jugador.'),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final player in session.players)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _DmBattlePlayerTile(
                            player: player,
                            onEditHp: () => _editEntityHp(
                              context,
                              session,
                              'player',
                              player.id,
                              player.name,
                              player.currentHp,
                              player.maxHp,
                            ),
                            onAssignWeapon: () => _assignWeapon(context, session, player),
                            onGiveItem: () => _giveItem(context, session, player),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Text('Enemigos', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              if (session.monsters.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text('No hay enemigos en la partida.'),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final m in session.monsters)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _DmBattleMonsterTile(
                            monster: m,
                            onEditHp: () => _editEntityHp(
                              context,
                              session,
                              'monster',
                              m.instanceId,
                              m.name,
                              m.currentHp,
                              m.maxHp,
                            ),
                            onChangePhoto: () => _setMonsterPhoto(context, session, m.instanceId),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _DmBattlePlayerTile extends StatelessWidget {
  const _DmBattlePlayerTile({
    required this.player,
    required this.onEditHp,
    required this.onAssignWeapon,
    required this.onGiveItem,
  });

  final PlayerInfo player;
  final VoidCallback onEditHp;
  final VoidCallback onAssignWeapon;
  final VoidCallback onGiveItem;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 120,
      child: Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              DefeatedAvatar(
                photoBase64: player.photoBase64,
                isDefeated: player.currentHp <= 0,
                defaultIcon: Icons.person,
                radius: 28,
                assetPath: player.photoBase64.isEmpty
                    ? (player.character != null
                        ? raceDefaultAsset(Character.fromJson(Map<String, dynamic>.from(player.character!)))
                        : null)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                player.name,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (player.hasCharacter)
                Text('${player.raceName} · ${player.className}', style: theme.textTheme.bodySmall),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: player.maxHp == 0 ? 0 : player.currentHp / player.maxHp,
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 14, color: theme.colorScheme.error),
                  const SizedBox(width: 4),
                  Text('HP ${player.currentHp}/${player.maxHp}', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.favorite, size: 18), onPressed: onEditHp, tooltip: 'Editar HP'),
                  IconButton(icon: const Icon(Icons.shield_outlined, size: 18), onPressed: onAssignWeapon, tooltip: 'Arma'),
                  IconButton(icon: const Icon(Icons.card_giftcard, size: 18), onPressed: onGiveItem, tooltip: 'Objeto'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DmBattleMonsterTile extends StatelessWidget {
  const _DmBattleMonsterTile({
    required this.monster,
    required this.onEditHp,
    required this.onChangePhoto,
  });

  final BattleMonster monster;
  final VoidCallback onEditHp;
  final VoidCallback onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 120,
      child: Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              DefeatedAvatar(
                photoBase64: monster.photoBase64,
                isDefeated: monster.isDefeated,
                defaultIcon: Icons.pets,
                radius: 28,
                assetPath: monster.photoBase64 == null || monster.photoBase64!.isEmpty
                    ? monsterAsset(monster)
                    : null,
              ),
              const SizedBox(height: 8),
              Text(
                monster.name,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: monster.maxHp == 0 ? 0 : monster.currentHp / monster.maxHp,
                minHeight: 6,
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 14, color: theme.colorScheme.error),
                  const SizedBox(width: 4),
                  Text('HP ${monster.currentHp}/${monster.maxHp}', style: theme.textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(icon: const Icon(Icons.favorite, size: 18), onPressed: onEditHp, tooltip: 'Editar HP'),
                  IconButton(icon: const Icon(Icons.photo_camera, size: 18), onPressed: onChangePhoto, tooltip: 'Foto'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DamageInputDialog extends StatefulWidget {
  final String playerName;

  const _DamageInputDialog({required this.playerName});

  @override
  State<_DamageInputDialog> createState() => _DamageInputDialogState();
}

class _DamageInputDialogState extends State<_DamageInputDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Daño para ${widget.playerName}'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(
          labelText: 'Cantidad de daño',
          border: OutlineInputBorder(),
        ),
        autofocus: true,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            final value = int.tryParse(_controller.text.trim());
            if (value == null || value <= 0) return;
            Navigator.of(context).pop(value);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
