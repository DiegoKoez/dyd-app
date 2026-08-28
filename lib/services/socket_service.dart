import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  io.Socket? _socket;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 2);
  String? _lastPlayerId;
  static const _methodChannel = MethodChannel('socket_keep_alive');

  bool get isConnected => _socket?.connected ?? false;

  Future<void> _startKeepAlive() async {
    // Desactivado temporalmente - causa crashes en Android
    // if (!Platform.isAndroid) return;
    // try {
    //   await _methodChannel.invokeMethod('start');
    // } catch (_) {}
  }

  Future<void> _stopKeepAlive() async {
    // Desactivado temporalmente - causa crashes en Android
    // if (!Platform.isAndroid) return;
    // try {
    //   await _methodChannel.invokeMethod('stop');
    // } catch (_) {}
  }

  Future<String?> diagnoseServer(String serverUrl) async {
    try {
      final uri = Uri.parse(serverUrl);
      final healthUrl = Uri(
        scheme: uri.scheme,
        host: uri.host,
        port: uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80),
        path: '/health',
      ).toString();
      print('[socket] diagnostic: trying $healthUrl');
      final response = await http.get(Uri.parse(healthUrl)).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        print('[socket] diagnostic: server reachable');
        return null;
      }
      return 'El servidor respondió, pero no es válido (status ${response.statusCode}).';
    } on SocketException catch (e) {
      print('[socket] diagnostic: SocketException $e');
      return 'No se puede alcanzar el servidor (${e.message}).';
    } on TimeoutException catch (_) {
      print('[socket] diagnostic: timeout');
      return 'El servidor no respondió en 8s. Revisá IP, WiFi y firewall.';
    } catch (e) {
      print('[socket] diagnostic: error $e');
      return 'Error de diagnóstico: $e';
    }
  }

  Future<String> resolveLocalhostIfNeeded(String serverUrl) async {
    try {
      final uri = Uri.parse(serverUrl);
      final host = uri.host;
      if (host.isEmpty) return serverUrl;

      // Convertir localhost a 127.0.0.1 para evitar problemas con IPv6
      if (host == 'localhost' || host == '::1') {
        print('[socket] Converting localhost to 127.0.0.1');
        return uri.replace(host: '127.0.0.1').toString();
      }

      print('[socket] Using server URL as-is: $serverUrl');
      return serverUrl;
      
    } catch (e) {
      print('[socket] Error in resolveLocalhostIfNeeded: $e');
      return serverUrl;
    }
  }

  Future<void> connect(String serverUrl) async {
    print('[socket] ========================================');
    print('[socket] Starting connection to: $serverUrl');
    print('[socket] ========================================');

    // Limpiar URL - eliminar espacios y caracteres extra
    serverUrl = serverUrl.trim();
    serverUrl = serverUrl.replaceAll('#', '');
    serverUrl = serverUrl.replaceAll('?', '');
    print('[socket] Cleaned URL: $serverUrl');

    disconnect();
    print('[socket] Disconnected previous socket');

    final effectiveUrl = await resolveLocalhostIfNeeded(serverUrl);
    print('[socket] Effective URL (after resolveLocalhost): $effectiveUrl');
    print('[socket] Attempting to connect...');

    final completer = Completer<void>();

    // Crear socket con configuración robusta para móviles
    // socket.io por defecto soporta polling y websocket
    print('[socket] Creating socket with robust configuration');
    final socket = io.io(
      effectiveUrl,
      <String, dynamic>{
        'transports': ['polling'],
        'autoConnect': false,
        'timeout': 60000,
        'upgrade': false,
      },
    );
    _socket = socket;

    // Listener para ver qué transporte se está usando
    socket.on('connect', (data) {
      print('[socket] 🎉 onConnect event fired!');
      print('[socket] Socket ID: ${socket.id}');
    });

    socket.on('disconnect', (reason) {
      print('[socket] Disconnect event fired with reason: $reason');
    });

    socket.on('error', (data) {
      print('[socket] Error event fired: $data');
    });

    socket.onConnect((_) {
      print('[socket] ✓✓✓ CONNECTED! Socket ID: ${socket.id}');
      print('[socket] Connected at: ${DateTime.now().toIso8601String()}');
      _reconnectAttempts = 0;
      _startKeepAlive();
      if (!completer.isCompleted) {
        print('[socket] Completing connection');
        completer.complete();
      }
    });

    socket.onConnectError((error) {
      print('[socket] ✗✗✗ CONNECT ERROR: $error');
      print('[socket] Error type: ${error.runtimeType}');
      print('[socket] Error details: ${error.toString()}');

      if (!completer.isCompleted) {
        completer.completeError(Exception('Error de conexión: $error'));
      }
    });

    socket.onDisconnect((reason) {
      print('[socket] Disconnected with reason: $reason');
      _stopKeepAlive();
    });

    socket.onError((error) {
      print('[socket] Socket error: $error');
    });

    print('[socket] Calling socket.connect()...');
    socket.connect();

    print('[socket] Waiting for connection (timeout: 60s)...');

    try {
      final result = await completer.future.timeout(Duration(seconds: 60));
      print('[socket] ✅ Connection completed successfully');
      return result;
    } on TimeoutException catch (e) {
      print('[socket] ✗✗✗ CONNECTION TIMEOUT after 60s: $e');
      throw Exception('Tiempo de espera agotado: ${e.message}. Verifica que el servidor esté corriendo en la misma red Wi-Fi y que la URL sea correcta.');
    }
  }

  Future<void> _tryReconnect(String serverUrl) async {
    if (_reconnectAttempts >= _maxReconnectAttempts) return;
    _reconnectAttempts++;
    await Future.delayed(_reconnectDelay * _reconnectAttempts);
    if (_socket?.connected ?? false) return;
    try {
      await connect(serverUrl);
    } catch (_) {}
  }

  Future<Map<String, dynamic>> emitWithAck(
      String event, Map<String, dynamic> data) async {
    final socket = _socket;
    if (socket == null) {
      print('[socket] ✗✗✗ emitWithAck: Socket is null');
      throw StateError('Socket no conectado');
    }
    if (!socket.connected) {
      print('[socket] ✗✗✗ emitWithAck: Socket not connected (status: ${socket.connected})');
      throw StateError('Socket no conectado (estado: ${socket.connected ? 'connected' : 'disconnected'})');
    }
    
    print('[socket] 📤 Emitting event: "$event"');
    print('[socket] Data: $data');
    
    final completer = Completer<Map<String, dynamic>>();
    try {
      socket.emitWithAck(event, data, ack: (response) {
        print('[socket] 📥 ACK received for "$event"');
        print('[socket] Response: $response');
        if (completer.isCompleted) return;
        if (response is Map) {
          completer.complete(Map<String, dynamic>.from(response));
        } else {
          completer.complete({});
        }
      });
    } catch (e) {
      print('[socket] ✗✗✗ emitWithAck error for "$event": $e');
      throw Exception('Error al emitir "$event": $e');
    }
    
    print('[socket] Waiting for ACK (timeout: 30s)...');

    try {
      return await completer.future.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('[socket] ✗✗✗ Timeout waiting for ACK on "$event"');
          throw TimeoutException('El servidor no respondió a tiempo para "$event"');
        },
      );
    } on TimeoutException catch (e) {
      print('[socket] ✗✗✗ TimeoutException caught: $e');
      throw Exception('Tiempo de espera agotado: $e');
    }
  }

  /// Emite un evento y espera una respuesta en un evento separado
  /// Más confiable que emitWithAck porque no depende del mecanismo de ack
  String? get socketId => _socket?.id;

  void listenOnce(String event, Function(dynamic) handler) {
    _socket?.once(event, handler);
  }

  Future<Map<String, dynamic>> emitWithResponse(
      String event, Map<String, dynamic> data, String responseEvent) async {
    final socket = _socket;
    if (socket == null) {
      print('[socket] ✗✗✗ emitWithResponse: Socket is null');
      throw StateError('Socket no conectado');
    }
    if (!socket.connected) {
      print('[socket] ✗✗✗ emitWithResponse: Socket not connected');
      throw StateError('Socket no conectado');
    }
    
    print('[socket] 📤 Emitting event: "$event" (waiting for "$responseEvent")');
    
    final completer = Completer<Map<String, dynamic>>();
    
    // Listener para la respuesta
    void responseHandler(dynamic response) {
      print('[socket] 📥 Response received for "$responseEvent"');
      print('[socket] Response: $response');
      if (completer.isCompleted) return;
      if (response is Map) {
        completer.complete(Map<String, dynamic>.from(response));
      } else {
        completer.complete({});
      }
    }
    
    // Escuchar la respuesta
    socket.on(responseEvent, responseHandler);
    
    try {
      // Emitir el evento
      socket.emit(event, data);
      
      // Esperar la respuesta
      return await completer.future.timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('[socket] ✗✗✗ Timeout waiting for "$responseEvent"');
          throw TimeoutException('El servidor no respondió a tiempo');
        },
      );
    } catch (e) {
      print('[socket] ✗✗✗ emitWithResponse error: $e');
      throw Exception('Error al emitir "$event": $e');
    } finally {
      // Limpiar el listener
      socket.off(responseEvent, responseHandler);
    }
  }

  void emit(String event, Map<String, dynamic> data) {
    _socket?.emit(event, data);
  }

  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  void disconnect() {
    _stopKeepAlive();
    _socket?.dispose();
    _socket = null;
    _reconnectAttempts = 0;
  }
}

