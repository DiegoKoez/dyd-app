import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/game_session.dart';
import '../../models/player_info.dart';
import '../../widgets/dm_player_editor.dart';
import 'dm_lobby_screen.dart';
import 'give_item_sheet.dart';
import 'weapon_assignment_screen.dart';

class DmOptionsScreen extends StatefulWidget {
  final String roomCode;

  const DmOptionsScreen({super.key, required this.roomCode});

  @override
  State<DmOptionsScreen> createState() => _DmOptionsScreenState();
}

class _DmOptionsScreenState extends State<DmOptionsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Sala ${widget.roomCode}')),
      body: Consumer<GameSession>(
        builder: (context, session, _) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Opciones del Dungeon Master',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
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
                      for (final PlayerInfo player in session.players)
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
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DmLobbyScreen(roomCode: widget.roomCode),
                ),
              ),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar batalla'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => WeaponAssignmentScreen(roomCode: widget.roomCode),
                ),
              ),
              icon: const Icon(Icons.change_history),
              label: const Text('Asignar armas'),
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
            const SizedBox(height: 16),
            if (session.players.any((p) => p.hasCharacter))
              FilledButton.icon(
                onPressed: () => showPlayerEditor(context, session),
                icon: const Icon(Icons.manage_accounts),
                label: const Text('Editar estadísticas jugadores'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                final session = context.read<GameSession>();
                final result = await showGiveItemSheet(context);
                if (result == null || !mounted) return;
                session.giveItem(result.playerId, result.item);
              },
              icon: const Icon(Icons.card_giftcard),
              label: const Text('Dar objetos'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            ),
          ],
        ),
      ),
    );
  }
}
