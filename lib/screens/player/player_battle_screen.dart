import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/character.dart';
import '../../models/item.dart';
import '../../services/game_session.dart';
import '../../utils/avatar_assets.dart';
import '../../widgets/defeated_avatar.dart';
import '../../widgets/inventory_view.dart';
import '../../widgets/weapon_received_dialog.dart';
import '../../widgets/item_received_dialog.dart';

class PlayerBattleScreen extends StatefulWidget {
  const PlayerBattleScreen({super.key});

  @override
  State<PlayerBattleScreen> createState() => _PlayerBattleScreenState();
}

class _PlayerBattleScreenState extends State<PlayerBattleScreen> {
  int _tab = 0;
  bool _wasMyTurn = false;
  bool _turnAlertShown = false;
  bool _skippedTurn = false;
  int? _damageTaken;
  bool _showDamageFlash = false;
  int? _healTaken;
  bool _showHealFlash = false;
  OverlayEntry? _effectOverlay;
  bool _battleStartedFromThisSession = false;
  late final GameSession _session;
  
  // Alerta de peligro con countdown
  bool _showDangerAlert = false;
  int _dangerCountdown = 0;
  DateTime? _dangerTime;

  @override
  void initState() {
    super.initState();
    _session = context.read<GameSession>();
    _session.addListener(_onSessionChanged);
    
    // Verificar popups pendientes al entrar a la pantalla
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPendingPopups();
    });
  }

  void _showBattleEffectOverlay(int value, bool isDamage) {
    _effectOverlay?.remove();
    _effectOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: 120,
        left: 0,
        right: 0,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1200),
            builder: (context, value, child) {
              // Agregar escala dramática para daño
              final scale = isDamage
                  ? Tween(begin: 0.5, end: 1.0).transform(value)
                  : 1.0;

              return Transform.translate(
                offset: Offset(0, -30 * value),
                child: Transform.scale(
                  scale: scale,
                  child: Opacity(
                    opacity: 1 - value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDamage ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDamage
                            ? [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.8),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        '${isDamage ? "-" : "+"}$value',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          shadows: const [
                            Shadow(color: Colors.black45, offset: Offset(1, 1), blurRadius: 2),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_effectOverlay!);

    // Agregar haptic feedback cuando se recibe daño
    if (isDamage) {
      HapticFeedback.mediumImpact();
    }

    Future.delayed(const Duration(milliseconds: 2000), () {
      _effectOverlay?.remove();
      _effectOverlay = null;
    });
  }

  // Verificar popups pendientes al entrar a la pantalla
  void _checkPendingPopups() {
    // Verificar arma
    if (_session.lastReceivedWeapon != null && mounted) {
      showWeaponReceivedDialog(context, _session.lastReceivedWeapon!).then((_) {
        if (mounted) {
          _session.clearReceivedWeapon();
        }
      });
    }

    // Verificar objeto
    if (_session.lastReceivedItem != null && mounted) {
      showItemReceivedDialog(context, _session.lastReceivedItem!).then((_) {
        if (mounted) {
          _session.clearReceivedItem();
        }
      });
    }
  }

  // Mostrar notificación cuando comienza la batalla
  void _showBattleStartedNotification() {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.sports_martial_arts, size: 64, color: Colors.deepPurple),
        title: const Text('¡Batalla Iniciada!'),
        content: const Text(
          'La batalla ha comenzado. Prepárate para combatir.',
          textAlign: TextAlign.center,
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Comenzar'),
          ),
        ],
      ),
    );
  }

  // Notificación mejorada de turno con opción de saltar
  void _showTurnNotification({required bool skipTurn}) {
    HapticFeedback.vibrate();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.visibility, size: 48, color: Colors.deepPurple),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('¡Es tu turno!', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    context.read<GameSession>().myCharacter?.name ?? 'Jugador',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Decide qué hacer en este turno.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Puedes continuar con tu acción o saltar este turno si deseas esperar al siguiente jugador.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () {
              // Saltar turno - notificar al servidor que el jugador pasa el turno
              _skipTurn();
              Navigator.of(context).pop();
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
            ),
            child: const Text('Saltar turno'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  // Método para saltar turno
  void _skipTurn() {
    final session = context.read<GameSession>();
    final code = session.roomCode;
    if (code != null) {
      // Usar el método de GameSession en lugar de llamar directamente al socket
      session.skipTurn();
    }
    // Marcar que saltamos turno para evitar notificaciones duplicadas
    setState(() {
      _skippedTurn = true;
    });
  }

  // Verificar si el jugador está en peligro y mostrar alerta
  void _checkDangerAlert() {
    final session = context.select((GameSession s) => s);
    final character = session.myCharacter;
    final myHp = session.myCurrentHp ?? character?.maxHp ?? 0;
    final maxHp = character?.maxHp ?? 1;
    final myHpPercent = maxHp > 0 ? myHp / maxHp : 0;
    
    final isCritical = myHpPercent <= 0.25;
    final isCriticalDanger = myHpPercent <= 0.10;
    
    // Si el jugador entra en peligro
    if (isCritical && !_showDangerAlert) {
      setState(() {
        _showDangerAlert = true;
        _dangerTime = DateTime.now();
        _dangerCountdown = 3; // 3 segundos
      });
      // Iniciar countdown
      _startDangerCountdown();
    }
    
    // Si el jugador sale del peligro
    if (!_showDangerAlert && _showDangerAlert) {
      setState(() {
        _showDangerAlert = false;
        _dangerCountdown = 0;
        _dangerTime = null;
      });
    }
  }

  // Iniciar countdown de peligro
  void _startDangerCountdown() {
    if (!_showDangerAlert || !mounted) return;
    
    _dangerCountdown = 3;
    
    Future.delayed(const Duration(seconds: 1), () {
      if (_showDangerAlert && mounted) {
        setState(() => _dangerCountdown--);
        _startDangerCountdown();
      }
    });
    
    Future.delayed(const Duration(seconds: 2), () {
      if (_showDangerAlert && mounted) {
        setState(() => _dangerCountdown--);
        _startDangerCountdown();
      }
    });
    
    Future.delayed(const Duration(seconds: 3), () {
      if (_showDangerAlert && mounted) {
        setState(() => _dangerCountdown = 0);
        _startDangerCountdown();
      }
    });
  }

  @override
  void dispose() {
    _effectOverlay?.remove();
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  void _onSessionChanged() {
    if (mounted) {
      setState(() {});
    }
    if (!_session.battleStarted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      });
      return;
    }

    // Verificar si la batalla comenzó por primera vez en esta sesión
    if (_session.battleStarted && !_battleStartedFromThisSession) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _showBattleStartedNotification();
          _battleStartedFromThisSession = true;
        }
      });
    }

    final effectValue = _session.lastBattleEffectValue;
    final isDamage = _session.lastBattleEffectIsDamage;
    if (effectValue != null && isDamage != null) {
      if (isDamage) {
        setState(() {
          _damageTaken = effectValue;
          _showDamageFlash = true;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _showDamageFlash = false);
        });
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _damageTaken = null);
        });
      } else {
        setState(() {
          _healTaken = effectValue;
          _showHealFlash = true;
        });
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) setState(() => _showHealFlash = false);
        });
        Future.delayed(const Duration(milliseconds: 1400), () {
          if (mounted) setState(() => _healTaken = null);
        });
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showBattleEffectOverlay(effectValue, isDamage);
      });
      _session.clearBattleEffects();
    }
    
    // Verificar alerta de peligro para el jugador
    _checkDangerAlert();
  }

  // Notificación original de turno
  void _notifyTurnStart() {
    // Mostrar notificación mejorada con opción de saltar turno
    _showTurnNotification(skipTurn: true);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !context.select((GameSession s) => s.battleStarted),
      child: Consumer<GameSession>(
        builder: (context, session, _) {
          final theme = Theme.of(context);
          final character = session.myCharacter;
          final myHp = session.myCurrentHp ?? character?.maxHp ?? 0;
          final maxHp = character?.maxHp ?? 1;
          final isMyTurn = session.isMyTurn;
          
          // Calcular porcentajes de HP para alertas
          final myHpPercent = maxHp > 0 ? myHp / maxHp : 0;
          final isMyCritical = myHpPercent <= 0.25; // 25% o menos
          final isMyCriticalDanger = myHpPercent <= 0.10; // 10% o menos
          
          // Alertas para otros jugadores
          final List<_DangerAlert> _alerts = [];
          for (final p in session.players) {
            if (p.id == session.myPlayerId) continue;
            final hpPercent = p.maxHp > 0 ? p.currentHp / p.maxHp : 0;
            if (hpPercent <= 0.25) {
              _alerts.add(_DangerAlert(p.name, p.currentHp, p.maxHp, 'warning'));
            } else if (hpPercent <= 0.10) {
              _alerts.add(_DangerAlert(p.name, p.currentHp, p.maxHp, 'danger'));
            }
          }
          
          // Alerta para mis enemigos
          final List<_DangerAlert> _enemyAlerts = [];
          for (final m in session.monsters) {
            final hpPercent = m.maxHp > 0 ? m.currentHp / m.maxHp : 0;
            if (hpPercent <= 0.25) {
              _enemyAlerts.add(_DangerAlert(m.name, m.currentHp, m.maxHp, 'warning'));
            } else if (hpPercent <= 0.10) {
              _enemyAlerts.add(_DangerAlert(m.name, m.currentHp, m.maxHp, 'danger'));
            }
          }

          // Detectar cambios de turno
          if (isMyTurn && !_wasMyTurn && _tab == 0 && !_skippedTurn) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _notifyTurnStart();
              }
            });
          }
          if (!isMyTurn && _wasMyTurn) {
            // Jugador no saltó turno, sigue el flujo normal
            _turnAlertShown = false;
            _skippedTurn = false;
          }
          _wasMyTurn = isMyTurn;

          // Detectar cuando el turno anterior fue saltado
          if (_skippedTurn && isMyTurn && !_turnAlertShown) {
            // El jugador saltó su turno anterior, mostrar notificación de nuevo turno
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _showTurnNotification(skipTurn: false);
              }
            });
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(character?.name ?? 'Combate'),
            ),
            body: _tab == 0
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (character != null) ...[
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // Alerta de peligro para el jugador
                            if (isMyCritical)
                              Positioned(
                                top: -20,
                                right: 10,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: isMyCriticalDanger
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isMyCriticalDanger
                                          ? theme.colorScheme.error
                                          : Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isMyCriticalDanger
                                            ? Icons.error_outline
                                            : Icons.warning,
                                        size: 16,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        isMyCriticalDanger ? '¡CRÍTICO!' : '¡PELIGRO!',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            // Countdown timer popup
                            if (_showDangerAlert && _dangerCountdown > 0)
                              Positioned(
                                top: 100,
                                right: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.error.withOpacity(0.5),
                                        blurRadius: 16,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.timer, color: Colors.orange),
                                      const SizedBox(width: 8),
                                      Text(
                                        '¡${_dangerCountdown}s! ¡PELIGRO!',
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          color: theme.colorScheme.error,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 480),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _showDamageFlash
                                          ? theme.colorScheme.error
                                          : (_showHealFlash
                                              ? Colors.green
                                              : (isMyTurn ? theme.colorScheme.primary : Colors.transparent)),
                                      width: 4,
                                    ),
                                    boxShadow: [
                                      if (isMyTurn && !_showDamageFlash && !_showHealFlash)
                                        BoxShadow(
                                          color: theme.colorScheme.primary.withOpacity(0.5),
                                          blurRadius: 20,
                                          spreadRadius: 2,
                                        ),
                                      if (_showDamageFlash)
                                        BoxShadow(
                                          color: theme.colorScheme.error.withOpacity(0.8),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                      if (_showHealFlash)
                                        BoxShadow(
                                          color: Colors.green.withOpacity(0.8),
                                          blurRadius: 24,
                                          spreadRadius: 4,
                                        ),
                                    ],
                                  ),
                                  child: Card(
                                    color: theme.colorScheme.primaryContainer,
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          DefeatedAvatar(
                                            photoBase64: character.photoBase64,
                                            isDefeated: myHp <= 0,
                                            defaultIcon: Icons.person,
                                            radius: 36,
                                            assetPath: character.photoBase64 == null || character.photoBase64!.isEmpty
                                                ? raceDefaultAsset(character)
                                                : null,
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(character.name, style: theme.textTheme.titleMedium),
                                                if (character.race.name.isNotEmpty)
                                                  Text(
                                                    character.race.name,
                                                    style: theme.textTheme.bodySmall,
                                                  ),
                                                const SizedBox(height: 8),
                                                LinearProgressIndicator(
                                                  value: maxHp == 0 ? 0 : myHp / maxHp,
                                                  minHeight: 10,
                                                ),
                                                const SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Icon(Icons.favorite, size: 18, color: theme.colorScheme.error),
                                                    const SizedBox(width: 6),
                                                    Text('HP $myHp / $maxHp', style: theme.textTheme.bodySmall),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (_showDamageFlash && _damageTaken != null)
                              Positioned(
                                top: -10,
                                right: 20,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 600),
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, -30 * value),
                                      child: Opacity(
                                        opacity: 1 - value,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.error,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '-${_damageTaken!}',
                                            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onError),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            if (_showHealFlash && _healTaken != null)
                              Positioned(
                                top: -10,
                                right: 20,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 600),
                                  builder: (context, value, child) {
                                    return Transform.translate(
                                      offset: Offset(0, -30 * value),
                                      child: Opacity(
                                        opacity: 1 - value,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: Colors.green,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            '+${_healTaken!}',
                                            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      Text('Aliados', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (session.players.isEmpty)
                        const Text('No hay otros jugadores conectados.')
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                               for (final p in session.players)
                                 if (p.id != session.myPlayerId)
                                   Padding(
                                     padding: const EdgeInsets.only(right: 12),
                                     child: _BattleTile(
                                       photoBase64: p.photoBase64,
                                       isDefeated: p.currentHp <= 0,
                                       name: p.name,
                                       hp: p.currentHp,
                                       maxHp: p.maxHp,
                                       subtitle: p.hasCharacter ? '${p.raceName} · ${p.className}' : 'Sin personaje',
                                       avatarColor: theme.colorScheme.secondaryContainer,
                                       hpColor: theme.colorScheme.error,
                                       assetPath: p.photoBase64.isEmpty
                                           ? (p.character != null
                                               ? raceDefaultAsset(Character.fromJson(Map<String, dynamic>.from(p.character!)))
                                               : null)
                                           : null,
                                       weapons: p.weapons,
                                       dangerAlert: _alerts.where((a) => a.name == p.name).firstWhere((e) => e.name == p.name, orElse: () => _DangerAlert('', 0, 0, '')),
                                     ),
                                   ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Text('Enemigos', style: theme.textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (session.monsters.isEmpty)
                        const Text('No hay enemigos en la sala.')
                      else
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final m in session.monsters)
                                Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: _BattleTile(
                                    photoBase64: m.photoBase64,
                                    isDefeated: m.isDefeated,
                                    name: m.name,
                                    hp: m.currentHp,
                                    maxHp: m.maxHp,
                                    subtitle: 'AC ${m.armorClass}',
                                    avatarColor: theme.colorScheme.errorContainer,
                                    hpColor: theme.colorScheme.error,
                                    assetPath: m.photoBase64 == null || m.photoBase64!.isEmpty
                                        ? monsterAsset(m)
                                        : null,
                                    dangerAlert: _enemyAlerts.where((a) => a.name == m.name).firstWhere((e) => e.name == m.name, orElse: () => _DangerAlert('', 0, 0, '')),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 80),
                    ],
                  )
                : const InventoryView(),
            bottomNavigationBar: NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: (i) {
                setState(() => _tab = i);
              },
              destinations: const [
                NavigationDestination(icon: Icon(Icons.sports_martial_arts), label: 'Combate'),
                NavigationDestination(icon: Icon(Icons.backpack), label: 'Mochila'),
              ],
            ),
            floatingActionButton: _tab == 0 && isMyTurn
                ? _buildTurnActionButtons(context, session)
                : (_tab == 0
                    ? FloatingActionButton(
                        onPressed: () => setState(() => _tab = 1),
                        tooltip: 'Abrir mochila',
                        child: const Icon(Icons.backpack),
                      )
                    : null),
          );
        },
      ),
    );
  }

  Widget _buildTurnActionButtons(BuildContext context, GameSession session) {
    return FloatingActionButton.extended(
      heroTag: 'end_turn',
      onPressed: () {
        session.endTurn();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Turno finalizado'), duration: Duration(seconds: 1)),
        );
      },
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
      tooltip: 'Siguiente turno',
      icon: const Icon(Icons.arrow_forward),
      label: const Text('Siguiente turno'),
    );
  }
}

/// Clase auxiliar para alertas de peligro
class _DangerAlert {
  final String name;
  final int currentHp;
  final int maxHp;
  final String level; // 'warning' (25%) o 'danger' (10%)

  const _DangerAlert(this.name, this.currentHp, this.maxHp, this.level);
}

/// Clase auxiliar para los tiles de batalla
class _BattleTile extends StatelessWidget {
  const _BattleTile({
    required this.photoBase64,
    required this.isDefeated,
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.subtitle,
    required this.avatarColor,
    required this.hpColor,
    this.assetPath,
    this.weapons = const [],
    this.dangerAlert,
  });

  final String? photoBase64;
  final bool isDefeated;
  final String name;
  final int hp;
  final int maxHp;
  final String subtitle;
  final Color avatarColor;
  final Color hpColor;
  final String? assetPath;
  final List<GameItem> weapons;
  final _DangerAlert? dangerAlert;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 110,
      child: Card(
        color: avatarColor,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              DefeatedAvatar(
                photoBase64: photoBase64,
                isDefeated: isDefeated,
                defaultIcon: Icons.person,
                radius: 26,
                assetPath: assetPath,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: theme.textTheme.titleSmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: maxHp == 0 ? 0 : hp / maxHp,
                minHeight: 6,
                color: hpColor.withOpacity(0.8),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 14, color: hpColor),
                  const SizedBox(width: 4),
                  Text('HP $hp/$maxHp', style: theme.textTheme.bodySmall),
                ],
              ),
              // Mostrar alerta de peligro
              if (dangerAlert != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: dangerAlert!.level == 'danger'
                        ? theme.colorScheme.error
                        : theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        dangerAlert!.level == 'danger'
                            ? Icons.warning_amber_rounded
                            : Icons.warning,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dangerAlert!.level == 'danger' ? 'CRÍTICO' : 'PELIGRO',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (weapons.isNotEmpty) ...[
                const SizedBox(height: 6),
                const Icon(Icons.shield, size: 14, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  weapons.map((w) => w.name).join(', '),
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
