import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:network_info_plus/network_info_plus.dart';

class ServerDiscovery {
  static const _defaultPort = 8080;
  static const _scanTimeout = Duration(milliseconds: 1500);
  static const _maxConcurrency = 10;
  static const _pathsToTry = ['/health', '/ip', '/'];

  Stream<DiscoveredServer> discover({int port = _defaultPort}) async* {
    // Primero verificar localhost (misma PC)
    final localhostServer = await _checkServer('127.0.0.1', port);
    if (localhostServer != null) {
      yield localhostServer;
      return;
    }
    
    // Luego verificar IP local
    try {
      final localIp = await _getLocalIp();
      if (localIp != null && localIp != '127.0.0.1') {
        final localServer = await _checkServer(localIp, port);
        if (localServer != null) {
          yield localServer;
          return;
        }
      }
    } catch (_) {}
    
    // Finalmente escanear la subred
    final subnet = await _localSubnet();
    if (subnet == null) {
      yield DiscoveredServer(
        ip: 'unknown',
        port: port,
        url: '',
      );
      return;
    }

    final futures = <Future<DiscoveredServer?>>[];
    for (var i = 1; i < 255; i++) {
      final ip = '$subnet.$i';
      if (ip == '127.0.0.1') continue; // Ya verificado
      futures.add(_checkServer(ip, port));
    }

    for (final batch in _batched(futures, _maxConcurrency)) {
      for (final future in batch) {
        final result = await future;
        if (result != null) yield result;
      }
    }
  }
  
  Future<String?> _getLocalIp() async {
    try {
      final interfaces = await NetworkInfo().getWifiIP();
      if (interfaces != null && interfaces.isNotEmpty) {
        return interfaces;
      }
    } catch (_) {}
    
    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      final localIp = socket.address.address;
      socket.destroy();
      return localIp;
    } catch (_) {}
    
    return null;
  }

  /// Descubre servidores y obtiene información de salas disponibles
  Future<List<DiscoveredServer>> discoverWithRooms({int port = _defaultPort}) async {
    final results = <DiscoveredServer>[];
    final subnet = await _localSubnet();
    
    if (subnet != null) {
      // Buscar servidores que respondan a /search-rooms
      for (var i = 1; i < 255; i++) {
        final ip = '$subnet.$i';
        try {
          final url = Uri.parse('http://$ip:$port/search-rooms');
          final response = await http.get(url).timeout(const Duration(seconds: 2));
          if (response.statusCode == 200) {
            final body = response.body;
            // Parsear el JSON para obtener IP y salas
            final parsed = jsonDecode(body) as Map<String, dynamic>;
            final roomsList = parsed['rooms'] as List? ?? [];
            final serverIp = parsed['server']['ip'] as String? ?? ip;
            
            // Convertir List<dynamic> a List<Map<String, dynamic>>
            final rooms = roomsList.map((room) {
              if (room is Map) return room;
              return {};
            }).cast<Map<String, dynamic>>();
            
            results.add(DiscoveredServer(
              ip: serverIp,
              port: port,
              url: 'http://$serverIp:$port',
              rooms: rooms.isNotEmpty ? rooms : null,
            ));
          }
        } catch (_) {}
      }
    }
    
    return results;
  }

  Future<String?> _localSubnet() async {
    try {
      final interfaces = await NetworkInfo().getWifiIP();
      if (interfaces != null && interfaces.isNotEmpty) {
        final parts = interfaces.split('.');
        if (parts.length == 4) {
          return '${parts[0]}.${parts[1]}.${parts[2]}';
        }
      }
    } catch (_) {}

    try {
      final socket = await Socket.connect('8.8.8.8', 53, timeout: const Duration(seconds: 2));
      final localIp = socket.address.address;
      socket.destroy();
      final parts = localIp.split('.');
      if (parts.length == 4) {
        return '${parts[0]}.${parts[1]}.${parts[2]}';
      }
    } catch (_) {}

    return null;
  }

  Future<DiscoveredServer?> _checkServer(String ip, int port) async {
    for (final path in _pathsToTry) {
      try {
        final url = Uri.parse('http://$ip:$port$path');
        final response = await http.get(url).timeout(_scanTimeout);
        if (response.statusCode == 200) {
          final body = response.body.trim();
          if (path == '/health' && body.contains('ok')) {
            return DiscoveredServer(ip: ip, port: port, url: 'http://$ip:$port');
          } else if (path == '/ip' && body.contains('ip')) {
            return DiscoveredServer(ip: ip, port: port, url: 'http://$ip:$port');
          } else if (path == '/' && body.isNotEmpty) {
            return DiscoveredServer(ip: ip, port: port, url: 'http://$ip:$port');
          }
        }
      } catch (_) {}
    }
    return null;
  }

  Iterable<List<Future<DiscoveredServer?>>> _batched(
    List<Future<DiscoveredServer?>> futures,
    int batchSize,
  ) sync* {
    for (var i = 0; i < futures.length; i += batchSize) {
      final end = i + batchSize > futures.length ? futures.length : i + batchSize;
      yield futures.sublist(i, end);
    }
  }
}

class DiscoveredServer {
  final String ip;
  final int port;
  final String url;
  final Iterable<Map<String, dynamic>>? rooms;

  const DiscoveredServer({
    required this.ip,
    required this.port,
    required this.url,
    this.rooms,
  });

  /// Obtiene un código de sala de las salas disponibles
  String? get firstRoomCode {
    if (rooms == null || !rooms!.any((r) => r is Map<String, dynamic>)) return null;
    for (final room in rooms ?? []) {
      if (room is Map<String, dynamic> && room.containsKey('code')) {
        return room['code'] as String?;
      }
    }
    return null;
  }

  /// Verifica si hay salas disponibles
  bool get hasRooms => rooms != null && rooms!.isNotEmpty;
}
