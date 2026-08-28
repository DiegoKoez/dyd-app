import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/monster.dart';
import '../../services/game_session.dart';
import '../../widgets/item_use_requests_banner.dart';
import '../home_screen.dart';
import 'monster_management_screen.dart';
import 'turn_order_screen.dart';

/// Room the Dungeon Master sees after creating a session: participants,
/// bestiary management, and the button to start the game once ready.
class DmLobbyScreen extends StatefulWidget {
  final String roomCode;

  const DmLobbyScreen({super.key, required this.roomCode});

  @override
  State<DmLobbyScreen> createState() => _DmLobbyScreenState();
}

class _DmLobbyScreenState extends State<DmLobbyScreen> {
  final Map<String, int> _selectedMonsterQuantities = {};

  int _getQuantity(String monsterId) => _selectedMonsterQuantities[monsterId] ?? 1;

  void _setQuantity(String monsterId, int quantity) {
    setState(() {
      if (quantity <= 0) {
        _selectedMonsterQuantities.remove(monsterId);
      } else {
        _selectedMonsterQuantities[monsterId] = quantity;
      }
    });
  }

  bool _isSelected(String monsterId) => _selectedMonsterQuantities.containsKey(monsterId);

  void _toggleMonster(Monster monster) {
    setState(() {
      if (_isSelected(monster.id)) {
        _selectedMonsterQuantities.remove(monster.id);
      } else {
        _selectedMonsterQuantities[monster.id] = 1;
      }
    });
  }

  Future<void> _editMonster(BuildContext context, Monster monster) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MonsterManagementScreen(
          editMonster: monster,
        ),
      ),
    );
  }

  void _startBattle(BuildContext context) {
    final session = context.read<GameSession>();
    session.battleStartError = null;
    final customizingPlayers =
        session.players.where((p) => p.customizing).toList();
    if (customizingPlayers.isNotEmpty) {
      final names = customizingPlayers.map((p) => p.name).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'El jugador $names aún no termina de personalizar',
            style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        ),
      );
      return;
    }
    final playersWithoutCharacter =
        session.players.where((p) => !p.hasCharacter).toList();
    if (playersWithoutCharacter.isNotEmpty) {
      final names = playersWithoutCharacter.map((p) => p.name).join(', ');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jugadores sin personaje: $names')),
      );
      return;
    }
    final available = session.allAvailableMonsters;
    final monstersToSend = [
      for (final entry in _selectedMonsterQuantities.entries)
        available.firstWhere((m) => m.id == entry.key, orElse: () => Monster(
          id: entry.key,
          name: 'Monstruo',
          description: '',
          maxHp: 10,
          armorClass: 10,
          attackName: '',
          damageDice: '1d6',
        )).copyWith(quantity: entry.value),
    ];
    if (monstersToSend.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos un enemigo')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TurnOrderScreen(selectedMonsters: monstersToSend),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Sala ${widget.roomCode}'),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              tooltip: 'Salir de la sala',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    title: const Text('¿Salir de la sala?'),
                    content: const Text('No podrás volver a entrar hasta que se cree una nueva sala.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const HomeScreen()),
                            (route) => false,
                          );
                        },
                        child: const Text('Salir'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<GameSession>(
          builder: (context, session, _) {
            if (session.battleStartError != null) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(session.battleStartError!),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                  session.battleStartError = null;
                }
              });
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const ItemUseRequestsBanner(),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.group),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Jugadores conectados: ${session.players.length}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (session.players.isEmpty)
                          const Text('Ninguno aún. Comparte el código.')
                        else
                          for (final player in session.players)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                '• ${player.name}${player.hasCharacter ? ' (${player.raceName} ${player.className})' : player.customizing ? ' (personalizando)' : ' (sin personaje)'}',
                              ),
                            ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text('Bestiario', style: theme.textTheme.titleLarge),
                Text(
                  'Prepara los monstruos y enemigos que usarás en la partida. Toca el icono de lápiz para personalizar o agregar una foto a cada enemigo.',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const MonsterManagementScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.pets),
                        label: const Text('Administrar enemigos'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final monster in session.allAvailableMonsters)
                  Card(
                    child: CheckboxListTile(
                      value: _isSelected(monster.id),
                      onChanged: (_) => _toggleMonster(monster),
                      title: Row(
                        children: [
                          if (monster.photoBase64 != null)
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: MemoryImage(base64Decode(monster.photoBase64!)),
                            )
                          else
                            const CircleAvatar(radius: 16, child: Icon(Icons.pets)),
                          const SizedBox(width: 8),
                          Expanded(child: Text(monster.name)),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${monster.description}\nHP ${monster.maxHp} · AC ${monster.armorClass} · ${monster.attackName} (${monster.damageDice})',
                          ),
                          if (_isSelected(monster.id)) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text('Cantidad:', style: TextStyle(fontSize: 12)),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: () => _setQuantity(monster.id, _getQuantity(monster.id) - 1),
                                ),
                                Text(
                                  '${_getQuantity(monster.id)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () => _setQuantity(monster.id, _getQuantity(monster.id) + 1),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      isThreeLine: true,
                      secondary: IconButton(
                        icon: const Icon(Icons.edit),
                        tooltip: 'Editar enemigo',
                        onPressed: () => _editMonster(context, monster),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MonsterManagementScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear enemigo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _selectedMonsterQuantities.isEmpty ? null : () => _startBattle(context),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(_selectedMonsterQuantities.isEmpty
                        ? 'Iniciar partida'
                        : 'Iniciar partida (${_selectedMonsterQuantities.values.fold(0, (a, b) => a + b)} monstruos)'),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
