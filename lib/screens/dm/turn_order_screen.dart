import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/monster.dart';
import '../../services/game_session.dart';
import 'dm_battle_screen.dart';

/// Wrapper that returns to the previous screen (the DM lobby) automatically
/// when the DM ends the battle, so the DM is never stuck on the battle view.
class _DmBattleScreenExitGuard extends StatefulWidget {
  const _DmBattleScreenExitGuard({super.key});

  @override
  State<_DmBattleScreenExitGuard> createState() =>
      _DmBattleScreenExitGuardState();
}

class _DmBattleScreenExitGuardState extends State<_DmBattleScreenExitGuard> {
  GameSession? _session;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _session = context.read<GameSession>();
      _session?.addListener(_onSessionChanged);
      _checkAndPop();
    });
  }

  void _onSessionChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAndPop());
  }

  void _checkAndPop() {
    final session = _session;
    if (session == null) return;
    if (session.battleStarted) return;
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _session?.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const DmBattleScreen();
  }
}

class _TurnEntry {
  final String type; // 'player' or 'monster'
  final String label;
  final String subtitle;
  final String? playerId;
  final int? monsterIndex;

  _TurnEntry.player(String id, String name)
      : type = 'player',
        label = name,
        subtitle = 'Jugador',
        playerId = id,
        monsterIndex = null;

  _TurnEntry.monster(int index, String name)
      : type = 'monster',
        label = name,
        subtitle = 'Monstruo',
        playerId = null,
        monsterIndex = index;
}

/// Lets the Dungeon Master decide the exact turn order (who goes first
/// through last) mixing players and the selected monsters, before starting
/// the battle.
class TurnOrderScreen extends StatefulWidget {
  final List<Monster> selectedMonsters;

  const TurnOrderScreen({super.key, required this.selectedMonsters});

  @override
  State<TurnOrderScreen> createState() => _TurnOrderScreenState();
}

class _TurnOrderScreenState extends State<TurnOrderScreen> {
  late List<_TurnEntry> _entries;
  bool _startingBattle = false;

  @override
  void initState() {
    super.initState();
    final session = context.read<GameSession>();
    _entries = [
      for (final player in session.players) _TurnEntry.player(player.id, player.name),
      for (var i = 0; i < widget.selectedMonsters.length; i++)
        _TurnEntry.monster(i, widget.selectedMonsters[i].name),
    ];
  }

  Future<void> _startBattle() async {
    setState(() => _startingBattle = true);
    final session = context.read<GameSession>();
    final turnOrder = [
      for (final entry in _entries)
        entry.type == 'player'
            ? {'type': 'player', 'id': entry.playerId}
            : {'type': 'monster', 'index': entry.monsterIndex},
    ];
    final error = await session.startBattle(widget.selectedMonsters, turnOrder: turnOrder);
    if (!mounted) return;
    final finalError = error ?? session.battleStartError;
    if (finalError != null) {
      setState(() => _startingBattle = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            finalError,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const _DmBattleScreenExitGuard()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ordenar turnos')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Arrastra para decidir quién actúa primero y quién último.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: _entries.isEmpty
                ? const Center(child: Text('No hay jugadores ni monstruos.'))
                : ReorderableListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _entries.length,
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        if (newIndex > oldIndex) newIndex -= 1;
                        final entry = _entries.removeAt(oldIndex);
                        _entries.insert(newIndex, entry);
                      });
                    },
                    itemBuilder: (context, index) {
                      final entry = _entries[index];
                      return Card(
                        key: ValueKey('${entry.type}-${entry.playerId}-${entry.monsterIndex}-$index'),
                        child: ListTile(
                          leading: CircleAvatar(child: Text('${index + 1}')),
                          title: Text(entry.label),
                          subtitle: Text(entry.subtitle),
                          trailing: Icon(
                            entry.type == 'player' ? Icons.person : Icons.pets,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: _entries.isEmpty || _startingBattle
                    ? null
                    : () async {
                        await _startBattle();
                      },
                icon: _startingBattle
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(_startingBattle ? 'Iniciando...' : 'Iniciar partida'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          ),
        ),
      ),
    );
  }
}
