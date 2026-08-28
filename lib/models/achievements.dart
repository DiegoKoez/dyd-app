import 'dart:convert';

/// Achievements disponibles en el juego
class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final int points; // Puntos de experiencia por achievement
  final bool unlocked;
  final Map<String, dynamic> conditions; // Condiciones para desbloquear

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.points,
    this.unlocked = false,
    required this.conditions,
  });

  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    int? points,
    bool? unlocked,
    Map<String, dynamic>? conditions,
  }) => Achievement(
           id: id ?? this.id,
           name: name ?? this.name,
           description: description ?? this.description,
           icon: icon ?? this.icon,
           points: points ?? this.points,
           unlocked: unlocked ?? this.unlocked,
           conditions: conditions ?? this.conditions,
         );
}

/// List de todos los achievements disponibles
class AchievementsData {
  static const List<Achievement> all = [
    // Primeros pasos
    Achievement(
      id: 'first_battle',
      name: 'Primer Combate',
      description: 'Gana tu primera batalla',
      icon: 'sports_martial_arts',
      points: 10,
      conditions: {'battles_won': 1},
    ),
    Achievement(
      id: 'first_kill',
      name: 'Primera Sangre',
      description: 'Derrota a tu primer monstruo',
      icon: 'pets',
      points: 15,
      conditions: {'kills': 1},
    ),
    
    // Niveles
    Achievement(
      id: 'level_5',
      name: 'Aprendiz',
      description: 'Llega al nivel 5',
      icon: 'emoji_events',
      points: 25,
      conditions: {'level': 5},
    ),
    Achievement(
      id: 'level_10',
      name: 'Guerero',
      description: 'Llega al nivel 10',
      icon: 'person',
      points: 50,
      conditions: {'level': 10},
    ),
    Achievement(
      id: 'level_20',
      name: 'Veterano',
      description: 'Llega al nivel 20',
      icon: 'badge',
      points: 100,
      conditions: {'level': 20},
    ),
    Achievement(
      id: 'level_50',
      name: 'Legendario',
      description: 'Llega al nivel 50',
      icon: 'trophy',
      points: 500,
      conditions: {'level': 50},
    ),
    
    // Batallas
    Achievement(
      id: 'ten_battles',
      name: 'Deca-Batallador',
      description: 'Participa en 10 batallas',
      icon: 'group',
      points: 30,
      conditions: {'battles': 10},
    ),
    Achievement(
      id: 'hundred_battles',
      name: 'Centuria',
      description: 'Participa en 100 batallas',
      icon: 'groups',
      points: 200,
      conditions: {'battles': 100},
    ),
    
    // Daño recibido
    Achievement(
      id: 'tank',
      name: 'Tanque',
      description: 'Sobrevive a un daño de 100 puntos en una sola batalla',
      icon: 'shield',
      points: 40,
      conditions: {'max_damage_taken': 100},
    ),
    
    // Dañodealido
    Achievement(
      id: 'slayer',
      name: 'Matador',
      description: 'Inflige un daño total de 500 puntos en una sola batalla',
      icon: 'flash_on',
      points: 40,
      conditions: {'total_damage_dealt': 500},
    ),
    
    // Monster específicos
    Achievement(
      id: 'dragon_slayer',
      name: 'Cazador de Dragones',
      description: 'Derrota a un Dragón',
      icon: 'dragons',
      points: 100,
      conditions: {'monster_type': 'dragon'},
    ),
    Achievement(
      id: 'boss_slayer',
      name: 'Boss Slayer',
      description: 'Derrota a un Boss',
      icon: 'bolt',
      points: 150,
      conditions: {'monster_type': 'boss'},
    ),
    
    // Items
    Achievement(
      id: 'collector',
      name: 'Coleccionista',
      description: 'Encuentra 50 objetos diferentes',
      icon: 'inventory_2',
      points: 60,
      conditions: {'items_collected': 50},
    ),
    
    // Quests
    Achievement(
      id: 'quest_master',
      name: 'Maestro de Quests',
      description: 'Completa 10 quests',
      icon: 'local_cafe',
      points: 80,
      conditions: {'quests_completed': 10},
    ),
    
    // Social
    Achievement(
      id: 'leader',
      name: 'Líder',
      description: 'Crea 5 salas de batalla',
      icon: 'leaderboard',
      points: 50,
      conditions: {'rooms_created': 5},
    ),
    Achievement(
      id: 'popular',
      name: 'Popular',
      description: 'Tienes 10 jugadores en tus salas',
      icon: 'people',
      points: 75,
      conditions: {'max_players_in_room': 10},
    ),
  ];
}

/// Estado de achievements del jugador
class PlayerAchievements {
  final Map<String, Achievement> unlocked;
  final Map<String, int> progress; // Progress por achievement ID

  PlayerAchievements({
    this.unlocked = const {},
    this.progress = const {},
  });

  factory PlayerAchievements.fromJson(Map<String, dynamic> json) {
    final unlocked = <String, Achievement>{};
    final progress = <String, int>{};
    
    for (final id in AchievementsData.all.map((a) => a.id)) {
      if (json[id] == true) {
        unlocked[id] = Achievement(
          id: id,
          name: AchievementsData.all.where((a) => a.id == id).first.name,
          description: AchievementsData.all.where((a) => a.id == id).first.description,
          icon: AchievementsData.all.where((a) => a.id == id).first.icon,
          points: AchievementsData.all.where((a) => a.id == id).first.points,
          unlocked: true,
          conditions: AchievementsData.all.where((a) => a.id == id).first.conditions,
        );
      }
      progress[id] = json[id] as int? ?? 0;
    }
    
    return PlayerAchievements(
      unlocked: unlocked,
      progress: progress,
    );
  }

  Map<String, dynamic> toJson() => {
        'unlocked': unlocked.map((k, v) => MapEntry(k, {'id': v.id})),
        'progress': progress,
      };

  /// Verificar si un achievement está desbloqueado
  bool isUnlocked(String id) => unlocked.containsKey(id);

  /// Desbloquear achievement
  void unlock(String id) {
    final achievement = AchievementsData.all.firstWhere((a) => a.id == id, orElse: () => throw ArgumentError('Achievement no encontrado'));
    unlocked[id] = achievement.copyWith(unlocked: true);
  }

  /// Actualizar progreso
  void updateProgress(String id, int value) {
    progress[id] = value;
    _checkAchievements();
  }

  /// Calcular puntos totales
  int get totalPoints => unlocked.values.fold(0, (sum, a) => sum + a.points);

  /// Calcular nivel basado en puntos
  int get currentLevel => (totalPoints / 100).toInt() + 1;

  void _checkAchievements() {
    // Verificar achievements basados en progreso
    for (final entry in progress.entries) {
      final id = entry.key;
      final value = entry.value;
      final achievement = AchievementsData.all.firstWhere((a) => a.id == id, orElse: () => throw ArgumentError('Achievement no encontrado'));
      
      // Verificar condiciones (simplificado)
      // Aquí deberías implementar la lógica real de verificación
    }
  }
}
