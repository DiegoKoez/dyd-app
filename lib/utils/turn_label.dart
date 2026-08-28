import '../services/game_session.dart';

/// Resolves the display name for whoever's turn it currently is (a player
/// or a monster instance), given the shared [GameSession] state.
String turnLabel(GameSession session) {
  final id = session.currentTurnId;
  if (id == null) return 'Sin turno activo';
  if (id == session.myPlayerId) return 'Tu turno';
  final players = session.players.where((p) => p.id == id);
  if (players.isNotEmpty) return '${players.first.name} (jugador)';
  final monsters = session.monsters.where((m) => m.instanceId == id);
  if (monsters.isNotEmpty) return '${monsters.first.name} (monstruo)';
  return 'Desconocido';
}
