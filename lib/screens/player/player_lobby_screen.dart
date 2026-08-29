import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../services/game_session.dart';
import '../../services/navigator_key.dart';
import '../../widgets/character_sheet_view.dart';
import '../../widgets/inventory_view.dart';
import 'player_battle_screen.dart';

class PlayerLobbyScreen extends StatefulWidget {
  final Character character;

  const PlayerLobbyScreen({super.key, required this.character});

  @override
  State<PlayerLobbyScreen> createState() => _PlayerLobbyScreenState();
}

class _PlayerLobbyScreenState extends State<PlayerLobbyScreen> {
  int _tab = 0;
  bool _battlePushed = false;
  late final GameSession _session;

  @override
  void initState() {
    super.initState();
    _session = context.read<GameSession>();
    _session.myCharacter = widget.character;
    _session.myCurrentHp ??= widget.character.maxHp;
    _session.sendCharacter(widget.character);
    _session.addListener(_onSessionChanged);
    
    // Listener para cuando la página vuelve a estar visible (después de minimizar)
    _setupVisibilityListener();
    
    if (_session.battleStarted && !_battlePushed) {
      _battlePushed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => const PlayerBattleScreen()),
          );
        }
      });
    }
  }

  void _setupVisibilityListener() {
    // Cuando la página vuelve a estar visible, verificar si hay una batalla en curso
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _session.battleStarted && !_battlePushed) {
        _battlePushed = true;
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const PlayerBattleScreen()),
        );
      }
    });
    
    // Verificar periódicamente si la batalla comenzó (cada 2 segundos)
    _startBattleCheckTimer();
  }

  Timer? _battleCheckTimer;
  
  void _startBattleCheckTimer() {
    _battleCheckTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted && _session.battleStarted && !_battlePushed) {
        _battlePushed = true;
        _battleCheckTimer?.cancel();
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const PlayerBattleScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _battleCheckTimer?.cancel();
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (_session.battleStarted && !_battlePushed) {
      _battlePushed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && navigatorKey.currentState != null) {
          navigatorKey.currentState!.push(
            MaterialPageRoute(builder: (_) => const PlayerBattleScreen()),
          );
        }
      });
    } else if (!_session.battleStarted && _battlePushed) {
      _battlePushed = false;
    }
  }

  void _editPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();
    final session = context.read<GameSession>();
    final currentChar = session.myCharacter ?? widget.character;
    final updated = currentChar.copyWith(photoBase64: base64Encode(bytes));
    session.myCharacter = updated;  // Actualizar en la sesión
    session.sendCharacter(updated);
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Consumer<GameSession>(
        builder: (context, session, _) {
          return Scaffold(
            appBar: AppBar(
              title: Text(widget.character.name),
            ),
              body: Column(
                children: [
                  Container(
                    width: double.infinity,
                    color: Theme.of(context).colorScheme.primaryContainer,
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        const Icon(Icons.hourglass_top),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            session.battleStarted
                                ? '¡La batalla ha comenzado!'
                                : 'Esperando a que el Dungeon Master inicie la partida...',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _tab == 0
                        ? CharacterSheetView(
                            character: session.myCharacter ?? widget.character,
                            currentHp: session.myCurrentHp,
                            onEditPhoto: _editPhoto,
                            weapons: session.myWeapons,
                          )
                        : const InventoryView(),
                  ),
                ],
              ),
              bottomNavigationBar: NavigationBar(
                selectedIndex: _tab,
                onDestinationSelected: (i) => setState(() => _tab = i),
                destinations: const [
                  NavigationDestination(icon: Icon(Icons.person), label: 'Personaje'),
                  NavigationDestination(icon: Icon(Icons.backpack), label: 'Mochila'),
                ],
              ),
            );
          },
      ),
    );
  }
}
