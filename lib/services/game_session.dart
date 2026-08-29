import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/classes_data.dart';
import '../data/monsters_data.dart';
import '../data/races_data.dart';
import '../models/battle_monster.dart';
import '../models/character.dart';
import '../models/character_class.dart';
import '../models/item.dart';
import '../services/server_prefs.dart';
import '../models/monster.dart';
import '../models/player_info.dart';
import '../models/race.dart';
import '../models/achievements.dart';
import '../models/battle_history.dart';
import '../utils/storage_service.dart';
import 'socket_service.dart';

/// Central real-time state shared by every DM/player screen. Holds the
/// connection to the server and the live room/battle state.
class GameSession extends ChangeNotifier {
  final SocketService _socketService = SocketService();

  String serverUrl = '';
  bool connected = false;
  String? roomCode;
  bool isDm = false;
  String? myPlayerId;

  Character? myCharacter;
  int? myCurrentHp;

  List<PlayerInfo> players = [];
  List<BattleMonster> monsters = [];
  List<Monster> customMonsters = [];
  List<Race> customRaces = [];
  List<CharacterClass> customClasses = [];
  List<String> turnOrder = [];
  String? currentTurnId;
  bool battleStarted = false;
  String? battleStartError;

  List<GameItem> myInventory = [];
  List<GameItem> myWeapons = [];
  String? lastPhotoBase64;

  /// Set while this player is waiting for the DM to approve/reject using
  /// this item id.
  String? pendingItemUseId;

  /// Pending "use item" requests the DM must approve or reject.
  List<ItemUseRequest> itemUseRequests = [];

  GameItem? lastReceivedItem;
  GameItem? lastReceivedWeapon;

  String? lastNotificationMessage;
  DateTime? _lastNotificationTime;

  String? lastBattleMessage;
  int? lastBattleEffectValue;
  bool? lastBattleEffectIsDamage;
  DateTime? _lastBattleMessageTime;
  
  /// Historial de batallas del jugador
  List<BattleHistory> battlesHistory = [];
  
  /// Achievements del jugador
  PlayerAchievements achievements = PlayerAchievements();

  final List<String> _pendingNotifications = [];
  final List<Map<String, dynamic>> _pendingBattleEffects = [];
  GameItem? _pendingWeapon;
  GameItem? _pendingItem;

  bool get isMyTurn => currentTurnId != null && currentTurnId == myPlayerId;

  /// Conecta al servidor URL proporcionado.
  /// Devuelve true si la conexión fue exitosa, false si falló o timeout.
  Future<bool> connect(String url) async {
    print('[GameSession] Connecting to: $url');
    try {
      await _socketService.connect(url);
      serverUrl = url;
      connected = true;
      print('[socket] connected to $url');
      _registerListeners();
      await restoreCharacterAfterReconnect();
      
      // Intentar reconectar a la sala si teníamos una sesión
      if (myPlayerId != null && roomCode != null && roomCode!.isNotEmpty) {
        _socketService.emit('player:reconnect', {
          'playerId': myPlayerId,
          'roomCode': roomCode,
        });
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      print('[socket] Connection failed: $e');
      connected = false;
      return false;
    }
  }

  /// Intenta conectar al servidor si no está conectado.
  /// Método optimizado para UI: solo conecta si es necesario,
  /// devuelve inmediatamente si ya está conectado.
  Future<bool> connectOrRefresh(String url) async {
    if (connected && _socketService.isConnected) {
      print('[GameSession] Already connected, skipping connection');
      return true;
    }
    return connect(url);
  }

  Future<void> restoreCharacterAfterReconnect() async {
    if (myCharacter != null) return;
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_character');
    if (saved == null) return;
    try {
      final character = Character.fromJson(Map<String, dynamic>.from(jsonDecode(saved)));
      sendCharacter(character);
    } catch (_) {}
  }

  void reconnect() {
    if (serverUrl.isEmpty) return;
    _socketService.connect(serverUrl);
    _registerListeners();
  }

  List<Monster> get allAvailableMonsters {
    final overriddenIds = customMonsters.map((m) => m.id).toSet();
    final result = <Monster>[
      for (final m in kMonsters)
        if (!overriddenIds.contains(m.id)) m,
    ];
    result.addAll(customMonsters);
    return result;
  }

  List<Race> get allAvailableRaces => [...kRaces, ...customRaces];

  List<CharacterClass> get allAvailableClasses => [...kClasses, ...customClasses];

  void startCustomizing() {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('player:customizing', {'code': code});
  }

  void addCustomMonster(Monster monster) {
    customMonsters = [...customMonsters, monster];
    notifyListeners();
  }

  void addCustomRace(Race race) {
    customRaces = [...customRaces, race];
    notifyListeners();
  }

  void addCustomClass(CharacterClass charClass) {
    customClasses = [...customClasses, charClass];
    notifyListeners();
  }

  void updateCustomMonster(String id, Monster updated) {
    customMonsters = [
      for (final m in customMonsters)
        if (m.id == id) updated else m,
    ];
    notifyListeners();
  }

  void removeCustomMonster(String id) {
    customMonsters = customMonsters.where((m) => m.id != id).toList();
    notifyListeners();
  }

  void _registerListeners() {
    _socketService.on('room:playersUpdated', (data) {
      players = (data as List)
          .map((e) => PlayerInfo.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    });

    _socketService.on('battle:started', (data) {
      print('[battle] event arrived data=$data');
      try {
        final map = Map<String, dynamic>.from(data as Map);
        _applyMonsters(map['monsters']);
        _applyPlayers(map['players']);
        final rawTurnOrder = map['turnOrder'];
        turnOrder = rawTurnOrder is List
            ? rawTurnOrder.map((e) => e.toString()).toList()
            : [];
        currentTurnId = map['currentTurnId'] as String?;
        battleStarted = true;
        battleStartError = null;
        myCurrentHp ??= myCharacter?.maxHp;
        print('[battle] battleStarted=true notifyListeners');
        notifyListeners();
      } catch (e, st) {
        print('[battle] error=$e st=$st');
        battleStartError = 'Error al iniciar batalla: $e';
        notifyListeners();
      }
    });

    _socketService.on('battle:turnChanged', (data) {
      print('[battle] turnChanged arrived data=$data');
      try {
        final map = Map<String, dynamic>.from(data as Map);
        currentTurnId = map['currentTurnId'] as String?;
        print('[battle] currentTurnId updated to: $currentTurnId');
        notifyListeners();
      } catch (e) {
        print('[battle] turnChanged error=$e');
      }
    });

    _socketService.on('battle:update', (data) {
      try {
        print('[battle] battle:update arrived data=$data');
        final map = Map<String, dynamic>.from(data as Map);
        final previousHp = myCurrentHp;
        _applyMonsters(map['monsters']);
        _applyPlayers(map['players']);

        if (previousHp != null && myCurrentHp != null && previousHp != myCurrentHp) {
          if (myCurrentHp! < previousHp!) {
            lastNotificationMessage = 'Recibiste ${previousHp! - myCurrentHp!} de daño';
          } else {
            lastNotificationMessage = 'Te curaste ${myCurrentHp! - previousHp!} puntos';
          }
          _lastNotificationTime = DateTime.now();
        }

        notifyListeners();
      } catch (e, st) {
        print('[battle] battle:update error=$e st=$st');
      }
    });

    _socketService.on('battle:effect', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final targetType = map['targetType'] as String? ?? '';
      final targetId = map['targetId'] as String? ?? '';
      final targetName = map['targetName'] as String? ?? 'objetivo';
      final damage = (map['damage'] as num?)?.toInt() ?? 0;
      final isDamage = map['isDamage'] as bool? ?? true;

      final isMe = targetType == 'player' && targetId == myPlayerId;
      if (isMe) {
        lastBattleEffectValue = damage;
        lastBattleEffectIsDamage = isDamage;
      }
      lastBattleMessage = isDamage
          ? '$targetName recibió $damage de daño'
          : '$targetName fue curado $damage puntos';
      _lastBattleMessageTime = DateTime.now();
      notifyListeners();
    });

    _socketService.on('battle:turnChanged', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      currentTurnId = map['currentTurnId'] as String?;
      notifyListeners();
    });

    _socketService.on('player:skipTurn', (data) {
      // El servidor confirma que el turno fue saltado
      print('[socket] player:skipTurn received, updating turn');
      final map = Map<String, dynamic>.from(data as Map);
      // El servidor debería actualizar currentTurnId al recibir esta solicitud
      // Si el servidor ya actualizó, currentTurnId cambiará automáticamente
      // Si no, el servidor debe emitir battle:turnChanged después
      notifyListeners();
    });

    _socketService.on('weapon:received', (data) {
      print('[socket] weapon:received data=$data');
      try {
        final map = Map<String, dynamic>.from(data as Map);
        final weapon = GameItem.fromJson(map);
        lastReceivedWeapon = weapon;
        // Agregar a armas si no está ya
        final alreadyInWeapons = myWeapons.any((w) => w.id == weapon.id);
        if (!alreadyInWeapons) {
          myWeapons.add(weapon);
          print('[socket] Weapon added: ${weapon.name}');
        }
        notifyListeners();
      } catch (e) {
        print('[socket] weapon:received error=$e');
      }
    });

    _socketService.on('item:received', (data) {
      print('[socket] item:received data=$data');
      try {
        final map = Map<String, dynamic>.from(data as Map);
        final item = GameItem.fromJson(map);
        lastReceivedItem = item;
        // Agregar al inventario si no está ya
        final alreadyInInventory = myInventory.any((i) => i.id == item.id);
        if (!alreadyInInventory) {
          myInventory.add(item);
          print('[socket] Item added to inventory: ${item.name}');
        }
        notifyListeners();
      } catch (e) {
        print('[socket] item:received error=$e');
      }
    });

    _socketService.on('battle:ended', (data) {
      battleStarted = false;
      turnOrder = [];
      currentTurnId = null;
      monsters = [];
      notifyListeners();
    });

    _socketService.on('player:reconnectResponse', (data) {
      print('[GameSession] player:reconnectResponse received: $data');
      try {
        final map = Map<String, dynamic>.from(data as Map);
        if (map['success'] == true) {
          print('[GameSession] Reconnected successfully to room ${map['roomCode']}');
          connected = true;
          notifyListeners();
        } else {
          print('[GameSession] Reconnect failed: ${map['error']}');
        }
      } catch (e) {
        print('[GameSession] player:reconnectResponse error: $e');
      }
    });

    _socketService.on('battle:startError', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      battleStartError = map['message'] as String?;
      notifyListeners();
    });

    _socketService.on('inventory:updated', (data) {
      myInventory = (data as List)
          .map((e) => GameItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      notifyListeners();
    });

    _socketService.on('photo:shared', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      lastPhotoBase64 = map['imageBase64'] as String?;
      notifyListeners();
    });

    _socketService.on('item:useRequested', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      itemUseRequests = [
        ...itemUseRequests,
        ItemUseRequest(
          playerId: map['playerId'] as String,
          playerName: map['playerName'] as String,
          item: GameItem.fromJson(Map<String, dynamic>.from(map['item'] as Map)),
          targetType: map['targetType'] as String? ?? 'self',
          targetId: map['targetId'] as String?,
          targetName: map['targetName'] as String? ?? 'sí mismo',
        ),
      ];
      notifyListeners();
    });

    _socketService.on('item:useResolved', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final itemId = map['itemId'] as String;
      if (pendingItemUseId == itemId) pendingItemUseId = null;
      notifyListeners();
    });

    _socketService.on('item:useResult', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final itemName = map['itemName'] as String? ?? 'objeto';
      final targetType = map['targetType'] as String? ?? 'self';
      final targetName = map['targetName'] as String? ?? 'sí mismo';
      final approved = map['approved'] as bool? ?? false;

      if (approved) {
        if (targetType == 'self') {
          lastNotificationMessage = 'Se utilizó "$itemName"';
        } else {
          lastNotificationMessage = 'Enviaste "$itemName" a $targetName';
        }
      } else {
        lastNotificationMessage = 'No se pudo usar "$itemName"';
      }
      _lastNotificationTime = DateTime.now();
      notifyListeners();
    });

    _socketService.on('item:usedOnYou', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      final playerName = map['playerName'] as String? ?? 'Un jugador';
      final itemName = map['itemName'] as String? ?? 'un objeto';
      lastNotificationMessage = '$playerName usó "$itemName" contigo';
      _lastNotificationTime = DateTime.now();
      notifyListeners();
    });

    _socketService.on('achievements:updated', (data) {
      final map = Map<String, dynamic>.from(data as Map);
      // Actualizar achievements del jugador
      final achievementsJson = map['achievements'] as Map<String, dynamic>? ?? {};
      if (achievementsJson.isNotEmpty) {
        // Guardar achievements en storage
        StorageService().saveAchievements(achievementsJson);
        // Actualizar achievements locales
        achievements = PlayerAchievements.fromJson(achievementsJson);
      }
      notifyListeners();
    });

    _socketService.on('weapon:assigned', (data) {
      print('[weapon] weapon:assigned arrived data=$data');
      final map = Map<String, dynamic>.from(data as Map);
      final weapon = GameItem.fromJson(map);
      myWeapons = [...myWeapons, weapon];
      lastReceivedWeapon = weapon;
      print('[weapon] weapon received name=${weapon.name} myWeapons count=${myWeapons.length}');
      notifyListeners();
    });

    _socketService.on('weapon:received', (data) {
      print('[weapon] weapon:received arrived data=$data');
      final map = Map<String, dynamic>.from(data as Map);
      final weapon = GameItem.fromJson(map);
      lastReceivedWeapon = weapon;
      print('[weapon] weapon received name=${weapon.name}');
      notifyListeners();
    });
  }

  void _applyMonsters(dynamic raw) {
    if (raw is! List) {
      monsters = [];
      return;
    }
    monsters = raw
        .map((e) => BattleMonster.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  void _applyPlayers(dynamic raw) {
    if (raw is! List) {
      players = [];
      return;
    }
    players = raw
        .map((e) => PlayerInfo.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    final mine = players.where((p) => p.id == myPlayerId);
    if (mine.isNotEmpty) {
      myCurrentHp = mine.first.currentHp;
      myWeapons = mine.first.weapons.toList();
      if (mine.first.character != null) {
        myCharacter = Character.fromJson(
          Map<String, dynamic>.from(mine.first.character as Map),
        );
      }
    }
  }

  /// Crea una nueva sala como DM.
  /// Timeout reducido a 8 segundos para mejorar la experiencia del usuario.
  Future<String> createRoom() async {
    print('[GameSession] createRoom called');
    final response = await _socketService.emitWithAck('dm:createRoom', {});
    print('[GameSession] Received response: $response');
    roomCode = response['code'] as String;
    isDm = true;
      // Guardar sesión para restaurar en web
      await ServerPrefs.saveSession(
        roomCode: roomCode!,
        playerId: myPlayerId ?? 'dm-${DateTime.now().millisecondsSinceEpoch}',
        playerName: null,
        isDm: true,
      );
    notifyListeners();
    print('[GameSession] roomCode set to: $roomCode');
    return roomCode!;
  }

  /// Returns an error message on failure, or null on success.
  Future<String?> joinRoom(String code, String playerName) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_character');
    final characterJson = saved != null ? jsonDecode(saved) as Map<String, dynamic>? : null;
    final savedPlayerId = prefs.getString('saved_player_id');
    
    // Cargar historial y achievements
    await loadBattlesHistory();
    await loadAchievements();
    
    // Asegurar que esté conectado antes de emitir
    if (!connected || !_socketService.isConnected) {
      print('[GameSession] No conectado, reconectando antes de unirse...');
      await connect(serverUrl);
    }
    
    // Generar playerId si no existe (ANTES de unirte)
    var playerId = savedPlayerId;
    if (playerId == null) {
      playerId = 'player-${DateTime.now().millisecondsSinceEpoch}-${_socketService.socketId ?? "unknown"}';
      await prefs.setString('saved_player_id', playerId);
      print('[GameSession] Generated new playerId: $playerId');
    }
    
    try {
      // Emitir evento y esperar respuesta del servidor
      final response = await _socketService.emitWithResponse(
        'player:joinRoom',
        {
          'code': code,
          'playerName': playerName,
          if (characterJson != null) 'character': characterJson,
          'playerId': playerId,
        },
        'player:joinResponse',
      );
      
      print('[GameSession] joinRoom response: $response');
      
      if (response['success'] != true) {
        return response['error'] as String? ?? 'No se pudo unir a la sala';
      }
      
      final serverPlayerId = response['playerId'] as String?;
      
      roomCode = code;
      isDm = false;
      myPlayerId = serverPlayerId ?? playerId;
      // Guardar sesión para restaurar en web
      await ServerPrefs.saveSession(
        roomCode: code,
        playerId: myPlayerId ?? playerId,
        playerName: playerName,
        isDm: false,
      );
      if (characterJson != null) {
        myCharacter = Character.fromJson(characterJson);
        myCurrentHp = myCharacter!.maxHp;
      }
      notifyListeners();
      return null;
    } catch (e) {
      print('[GameSession] joinRoom error: $e');
      return 'Error al unirse: $e';
    }
  }

  void sendCharacter(Character character) {
    myCharacter = character;
    myCurrentHp = character.maxHp;
    final code = roomCode;
    if (code != null) {
      _socketService.emit('player:setCharacter', {
        'code': code,
        'character': character.toJson(),
      });
    }
    _persistCharacter(character);
    notifyListeners();
  }

  Future<void> _persistCharacter(Character character) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_character', jsonEncode(character.toJson()));
    } catch (_) {}
  }

  Future<String?> startBattle(List<Monster> selectedMonsters,
      {List<Map<String, dynamic>>? turnOrder}) async {
    final code = roomCode;
    if (code == null) return 'Sala no encontrada';
    try {
      final response = await _socketService.emitWithAck('dm:startBattle', {
        'code': code,
        'monsters': selectedMonsters.map((m) => m.toJson()).toList(),
        if (turnOrder != null) 'turnOrder': turnOrder,
      }).timeout(
        const Duration(seconds: 3),
        onTimeout: () => {'success': true},
      );
      if (response['success'] != true) {
        battleStartError = response['error'] as String? ?? 'No se pudo iniciar la batalla';
        return battleStartError;
      }
      battleStartError = null;
      return null;
    } catch (e) {
      battleStartError = 'Error de conexión: $e';
      return battleStartError;
    }
  }

  void performAction({
    required String targetType,
    required String targetId,
    required int damage,
  }) {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('battle:action', {
      'code': code,
      'targetType': targetType,
      'targetId': targetId,
      'damage': damage,
    });
  }

  void manualDamage(String targetType, String targetId, int damage) {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('dm:manualDamage', {
      'code': code,
      'targetType': targetType,
      'targetId': targetId,
      'damage': damage,
    });
  }

  void endTurn() {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('battle:endTurn', {'code': code});
  }

  // Método para saltar turno (llamado por el cliente)
  void skipTurn() {
    final code = roomCode;
    if (code == null) return;
    print('[GameSession] skipping turn for current player');
    _socketService.emit('player:skipTurn', {
      'code': code,
    });
  }

  void setEntityHp(String targetType, String targetId, int hp) {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('dm:setEntityHp', {
      'code': code,
      'targetType': targetType,
      'targetId': targetId,
      'hp': hp,
    });
  }

  void updatePlayer(String playerId, Map<String, dynamic> updates) {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('dm:updatePlayer', {
      'code': code,
      'playerId': playerId,
      'updates': updates,
    });
  }

  void endBattle() {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('dm:endBattle', {'code': code});
  }
  
  /// Guardar batalla al historial después de que termina
  void saveBattleToHistory() {
    if (myCharacter == null) return;
    
    // Convertir monstruos a Map para guardar
    final monstersData = monsters.map((m) => {
      'instanceId': m.instanceId,
      'name': m.name,
      'currentHp': m.currentHp,
      'maxHp': m.maxHp,
      'armorClass': m.armorClass,
      'isDefeated': m.isDefeated,
    }).toList();
    
    // Convertir aliados a Map para guardar
    final alliesData = players.map((p) => {
      'id': p.id,
      'name': p.name,
      'photoBase64': p.photoBase64,
      'hasCharacter': p.hasCharacter,
      'raceName': p.raceName,
      'className': p.className,
      'maxHp': p.maxHp,
      'currentHp': p.currentHp,
      'armorClass': p.armorClass,
    }).toList();
    
    final battle = BattleHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      date: DateTime.now(),
      result: 'victory', // El DM puede cambiar esto
      characterAtStart: myCharacter!,
      monstersData: monstersData,
      alliesData: alliesData,
      damageReceived: myCurrentHp != null ? myCharacter!.maxHp - myCurrentHp! : null,
    );
    
    battlesHistory.insert(0, battle);
    // Mantener solo las últimas 50 batallas
    if (battlesHistory.length > 50) {
      battlesHistory.removeRange(50, battlesHistory.length);
    }
    
    // Guardar en storage
    StorageService().addBattleToHistory(battle.toJson());
    
    notifyListeners();
  }
  
  /// Guardar battle history en storage
  Future<void> saveBattlesHistory() async {
    // Convertir BattleHistory a Map
    final historyJson = battlesHistory.map((b) => b.toJson()).toList();
    await StorageService().saveBattlesHistory(historyJson);
  }
  
  /// Cargar battle history desde storage
  Future<void> loadBattlesHistory() async {
    final history = await StorageService().getBattlesHistory();
    if (history.isNotEmpty) {
      battlesHistory = history.map((json) {
        try {
          return BattleHistory.fromJson(Map<String, dynamic>.from(json as Map));
        } catch (e) {
          return BattleHistory(
            id: 'unknown',
            date: DateTime.now(),
            result: 'unknown',
            characterAtStart: Character.create(
              name: 'Unknown',
              race: kRaces.first,
              characterClass: kClasses.first,
              hairStyle: '',
              hairColor: '',
              heightCm: 170,
            ),
            monstersData: [],
            alliesData: [],
          );
        }
      }).toList();
    }
  }
  
  /// Actualizar achievement
  void updateAchievement(String id, int value) {
    achievements.updateProgress(id, value);
    notifyListeners();
    
    // Guardar en storage
    StorageService().saveAchievements(achievements.toJson());
  }
  
  /// Obtener achievements
  Map<String, dynamic> getAchievementsJson() {
    return achievements.toJson();
  }
  
  /// Cargar achievements desde storage
  Future<void> loadAchievements() async {
    final json = await StorageService().getAchievements();
    if (json != null) {
      achievements = PlayerAchievements.fromJson(json);
    }
  }

  void giveItem(String playerId, GameItem item) {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('dm:giveItem', {
      'code': code,
      'playerId': playerId,
      'item': item.toJson(),
    });
  }

  void sharePhoto(String imageBase64) {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('dm:sharePhoto', {
      'code': code,
      'imageBase64': imageBase64,
    });
  }

  void setMonsterPhoto(String instanceId, String imageBase64) {
    final code = roomCode;
    if (code == null) return;
    _socketService.emit('dm:setMonsterPhoto', {
      'code': code,
      'instanceId': instanceId,
      'imageBase64': imageBase64,
    });
  }

  /// Called by a player to ask the DM for permission to use an item from
  /// their inventory.
  void useItem(GameItem item, {String targetType = 'self', String? targetId}) {
    final code = roomCode;
    if (code == null) return;
    pendingItemUseId = item.id;
    notifyListeners();
    _socketService.emit('player:useItem', {
      'code': code,
      'itemId': item.id,
      'targetType': targetType,
      'targetId': targetId,
    });
  }

  /// Called by the DM to accept or reject a pending item-use request.
  void resolveItemUse(ItemUseRequest request, bool approved, {int? effectValue}) {
    final code = roomCode;
    if (code == null) return;
    itemUseRequests = itemUseRequests.where((r) => r != request).toList();
    notifyListeners();
    _socketService.emit('dm:resolveItemUse', {
      'code': code,
      'playerId': request.playerId,
      'itemId': request.item.id,
      'approved': approved,
      'effectValue': effectValue,
      'targetType': request.targetType,
      'targetId': request.targetId,
    });
  }

  Future<String?> assignWeapon({
    required String playerId,
    required String weaponName,
    required String dice,
    String? icon,
    String? imageBase64,
  }) async {
    final code = roomCode;
    if (code == null) return 'Sala no encontrada';
    try {
      final response = await _socketService.emitWithAck('dm:assignWeapon', {
        'code': code,
        'playerId': playerId,
        'weaponName': weaponName,
        'dice': dice,
        'icon': icon,
        'imageBase64': imageBase64,
      });
      if (response['success'] != true) {
        return response['error'] as String? ?? 'No se pudo asignar el arma';
      }
      return null;
    } catch (e) {
      return 'Error de conexión: $e';
    }
  }

  void clearReceivedItem() {
    lastReceivedItem = null;
    notifyListeners();
  }

  void clearReceivedWeapon() {
    lastReceivedWeapon = null;
    notifyListeners();
  }

  void clearNotification() {
    lastNotificationMessage = null;
    _lastNotificationTime = null;
    notifyListeners();
  }

  void clearBattleEffects() {
    lastBattleMessage = null;
    lastBattleEffectValue = null;
    lastBattleEffectIsDamage = null;
    _lastBattleMessageTime = null;
    notifyListeners();
  }
}

/// A pending request from a player asking to use an item; the DM must
/// approve or reject it.
class ItemUseRequest {
  final String playerId;
  final String playerName;
  final GameItem item;
  final String targetType;
  final String? targetId;
  final String targetName;

  const ItemUseRequest({
    required this.playerId,
    required this.playerName,
    required this.item,
    required this.targetType,
    this.targetId,
    required this.targetName,
  });
}
