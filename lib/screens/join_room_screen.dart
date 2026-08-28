import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_session.dart';
import '../services/socket_service.dart';
import 'character_creation/character_creation_flow.dart';
import 'player/player_battle_screen.dart';

class JoinRoomScreen extends StatefulWidget {
  const JoinRoomScreen({super.key});

  @override
  State<JoinRoomScreen> createState() => _JoinRoomScreenState();
}

class _JoinRoomScreenState extends State<JoinRoomScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  bool _loading = false;
  String? _error;
  final SocketService _socketService = SocketService();

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  bool get _canJoin =>
      _codeController.text.trim().isNotEmpty &&
      _nameController.text.trim().isNotEmpty &&
      !_loading;

  Future<void> _join() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final session = context.read<GameSession>();
    final rawServerUrl = session.serverUrl;
    if (rawServerUrl.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'Falta la URL del servidor. Volvé a Home y configurala.';
      });
      return;
    }

    try {
      await session.connect(rawServerUrl).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('No se pudo conectar al servidor en $rawServerUrl'),
      );

      await Future.delayed(const Duration(milliseconds: 500));

      final error = await session.joinRoom(
        _codeController.text.trim().toUpperCase(),
        _nameController.text.trim(),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('El servidor no respondió al intentar unirse'),
      );
      if (!mounted) return;
      if (error != null) {
        setState(() {
          _loading = false;
          _error = error;
        });
        return;
      }
      session.startCustomizing();
      if (session.battleStarted && session.myCharacter != null) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PlayerBattleScreen()),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CharacterCreationFlow()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'No se pudo unir: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Unirse a sala')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Ingresa el código de la sala',
                    style: theme.textTheme.titleLarge),
                const SizedBox(height: 24),
                TextField(
                  controller: _codeController,
                  textAlign: TextAlign.center,
                  textCapitalization: TextCapitalization.characters,
                  style: theme.textTheme.headlineSmall,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tu nombre',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(color: theme.colorScheme.error),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 8),
                Consumer<GameSession>(
                  builder: (context, session, _) => Text(
                    'Servidor: ${session.serverUrl}',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 32),
                FilledButton.icon(
                  onPressed: _canJoin ? _join : null,
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.login),
                  label: const Text('Unirse'),
                  style:
                      FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
