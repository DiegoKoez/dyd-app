import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_session.dart';
import '../services/server_prefs.dart';
import '../services/server_discovery.dart';
import '../services/socket_service.dart';
import '../utils/network_utils.dart';
import 'create_room_screen.dart';
import 'join_room_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _urlController = TextEditingController();
  bool _loadingSavedUrl = true;
  bool _discovering = false;
  String? _discoveryError;
  String? _discoveryStatus;
  String? _effectiveUrl;

  @override
  void initState() {
    super.initState();
    _loadSavedSession();
  }

  Future<void> _loadSavedSession() async {
    // Cargar URL guardada
    final savedUrl = await ServerPrefs.getSavedUrl();
    final session = await ServerPrefs.getSavedSession();
    
    if (!mounted) return;
    
    // Si hay una sesión guardada, intentar restaurar
    if (session != null && savedUrl != null) {
      final savedRoomCode = session['roomCode'] as String?;
      final savedPlayerId = session['playerId'] as String?;
      final wasDm = session['isDm'] as bool? ?? false;
      
      if (savedRoomCode != null && savedPlayerId != null && savedPlayerId.isNotEmpty) {
        print('[HomeScreen] Restoring session: room=$savedRoomCode dm=$wasDm');
        setState(() {
          _urlController.text = savedUrl;
          _loadingSavedUrl = false;
        });
        _updateEffectiveUrl();
        
        // Intentar reconectar automáticamente
        _restoreSession(savedUrl, savedRoomCode, savedPlayerId, wasDm);
        return;
      }
    }
    
    // Si no hay sesión guardada, usar localhost por defecto
    final url = savedUrl ?? 'http://localhost:8080';
    await ServerPrefs.saveUrl(url);
    setState(() {
      _urlController.text = url;
      _loadingSavedUrl = false;
    });
    _updateEffectiveUrl();
  }

  Future<void> _restoreSession(String url, String roomCode, String playerId, bool wasDm) async {
    try {
      final session = context.read<GameSession>();
      await session.connect(url);
      session.serverUrl = url;
      session.roomCode = roomCode;
      session.myPlayerId = playerId;
      session.isDm = wasDm;
      session.connected = true;
      session.notifyListeners();
      print('[HomeScreen] Session restored successfully');
    } catch (e) {
      print('[HomeScreen] Failed to restore session: $e');
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _updateEffectiveUrl() async {
    final value = _urlController.text.trim();
    if (value.isEmpty) {
      if (mounted) setState(() => _effectiveUrl = null);
      return;
    }
    final socketService = SocketService();
    final resolved = await socketService.resolveLocalhostIfNeeded(value);
    if (mounted) {
      setState(() => _effectiveUrl = resolved == value ? null : resolved);
    }
  }

  String? get _serverUrl {
    final value = _urlController.text.trim();
    return value.isEmpty ? null : value;
  }

  Future<void> _discoverServer() async {
    if (_discovering) return;
    setState(() {
      _discovering = true;
      _discoveryError = null;
      _discoveryStatus = 'Buscando servidor en la red...';
    });

    try {
      final discovery = ServerDiscovery();
      await for (final server in discovery.discover()) {
        if (!mounted) return;
        if (server.url.isEmpty) {
          setState(() {
            _discoveryStatus = 'No se pudo obtener la IP de esta red. Probá escribirla manualmente.';
            _discovering = false;
          });
          return;
        }
        
        print('[Discovery] Encontrado: ${server.url}');
        
        // Usar NetworkUtils para convertir IP de red local a 127.0.0.1
        final convertedUrl = NetworkUtils.detectServerIp(serverUrl: server.url);
        final urlToUse = convertedUrl ?? server.url;
        
        print('[Discovery] Using URL: $urlToUse');
        
        setState(() {
          _urlController.text = urlToUse;
          _discoveryStatus = 'Servidor encontrado: $urlToUse. Conectando...';
        });
        
        // Guardar URL original
        await ServerPrefs.saveUrl(server.url);
        
        // Intentar conectar automáticamente (3 segundos)
        print('[Discovery] Attempting auto-connection...');
        try {
          final socketService = SocketService();
          await socketService.connect(urlToUse).timeout(Duration(seconds: 30));
          
          if (!mounted) return;
          
          if (socketService.isConnected) {
            setState(() {
              _discoveryStatus = '✓ ¡Servidor encontrado! URL: $urlToUse';
              _discoveryError = null;
            });
            
            // Solo llenar la URL, no navegar automáticamente
            await ServerPrefs.saveUrl(urlToUse);
            if (mounted) {
              context.read<GameSession>().serverUrl = urlToUse;
              _urlController.text = urlToUse;
              _updateEffectiveUrl();
              setState(() {
                _discovering = false;
              });
            }
          } else {
            // Conexión falló, permitir ingresar URL manualmente
            setState(() {
              _discoveryError = 'El servidor detectado no responde. Probá ingresando la URL manualmente.';
              _discovering = false;
            });
            print('[Discovery] Auto-connection failed, allowing manual input');
          }
        } catch (e) {
          if (!mounted) return;
          setState(() {
            _discoveryError = 'Error al conectar: $e. Probá ingresando la URL manualmente.';
            _discovering = false;
          });
          print('[Discovery] Connection error: $e');
        }
        
        break;
      }
      if (mounted && _discovering) {
        setState(() {
          _discoveryStatus = 'Búsqueda terminada. Tocá "Buscar" para reintentar.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _discovering = false;
        _discoveryStatus = 'Error en el descubrimiento.';
        _discoveryError = 'No se pudo buscar automáticamente. Revisá que estés en la misma red Wi-Fi.';
      });
    }
  }

  Future<void> _testConnection() async {
    final url = _serverUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        setState(() {
          _discoveryError = 'Primero debes ingresar la URL del servidor';
        });
      }
      return;
    }

    if (!mounted) return;
    setState(() {
      _loadingSavedUrl = true;
      _discoveryError = null;
      _discoveryStatus = 'Probando conexión al servidor...';
    });

    print('[home] Testing connection to: $url');

    try {
      // Convertir IP de red local a 127.0.0.1 automáticamente
      final convertedUrl = NetworkUtils.detectServerIp(serverUrl: url);
      final testUrl = convertedUrl ?? url;
      
      print('[home] Converted URL: $testUrl');

      // Usar el socket service para probar conexión
      final socketService = SocketService();
      print('[home] Calling socket.connect()...');

      await socketService.connect(testUrl);

      print('[home] Checking socket.isConnected...');
      print('[home] Socket isConnected = ${socketService.isConnected}');

      if (socketService.isConnected) {
        if (mounted) {
          setState(() {
            _discoveryStatus = '✓ ¡Conexión exitosa! El servidor está funcionando.';
          });

          // Guardar la URL original (la app la convertirá automáticamente al usarla)
          await ServerPrefs.saveUrl(url);
          if (mounted) {
            print('[home] URL saved to preferences');
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _discoveryError = 'El servidor respondió pero no podemos mantener conexión.';
          });
        }
      }
    } on Exception catch (e) {
      print('[home] ✗✗✗ Connection Exception: $e');
      if (mounted) {
        setState(() {
          _discoveryError = 'Error de conexión: $e';
          _discoveryStatus = null;
        });
      }
    } catch (e, st) {
      print('[home] ✗✗✗ Unexpected error: $e');
      print('[home] Stack trace: $st');
      if (mounted) {
        setState(() {
          _discoveryError = 'Error desconocido: $e';
          _discoveryStatus = null;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loadingSavedUrl = false;
        });
      }
    }
  }

  void _goTo(Widget screen) {
    final url = _serverUrl;
    if (url == null || url.isEmpty) return;
    
    // Usar NetworkUtils para detectar y convertir automáticamente
    final convertedUrl = NetworkUtils.detectServerIp(serverUrl: url);
    if (convertedUrl != null) {
      print('[HomeScreen] Using converted URL: $convertedUrl');
      ServerPrefs.saveUrl(convertedUrl);
      context.read<GameSession>().serverUrl = convertedUrl;
    } else {
      print('[HomeScreen] Using original URL: $url');
      ServerPrefs.saveUrl(url);
      context.read<GameSession>().serverUrl = url;
    }
    
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canContinue = _serverUrl != null;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.castle, size: 72, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text('DYD', style: theme.textTheme.displaySmall),
                  Text(
                    'Tu mesa de rol, en cualquier lugar',
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  
                  // Campo de URL del servidor
                  TextField(
                    controller: _urlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'Dirección del servidor',
                      hintText: 'http://192.168.1.10:8080',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.dns),
                    ),
                    onChanged: (_) {
                      _updateEffectiveUrl();
                      setState(() {});
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Botones de buscar y probar
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _discovering ? null : _discoverServer,
                          icon: _discovering
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search),
                          label: Text(_discovering ? 'Buscando...' : 'Buscar servidor'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _testConnection,
                          icon: const Icon(Icons.wifi),
                          label: const Text('Probar conexión'),
                        ),
                      ),
                    ],
                  ),
                  
                  // Estado del descubrimiento
                  if (_discoveryStatus != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _discoveryStatus!,
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  // Error del descubrimiento
                  if (_discoveryError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _discoveryError!,
                        style: TextStyle(color: theme.colorScheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  
                  const SizedBox(height: 24),
                  
                  // Botones de acción
                  FilledButton.icon(
                    onPressed: canContinue
                        ? () => _goTo(const CreateRoomScreen())
                        : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Crear sala'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed:
                        canContinue ? () => _goTo(const JoinRoomScreen()) : null,
                    icon: const Icon(Icons.login),
                    label: const Text('Unirse a sala'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Muestra información diagnóstica sobre la conexión
  void _showDiagnostic() async {
    final url = _serverUrl;
    if (url == null || url.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay servidor configurado')),
        );
        return;
      }
    }

    // Extraer host de la URL (url no es null porque ya fue verificada)
    final hostNoPath = url!.contains('/')
        ? url!.split('/').first
        : url!;
    final hostNoScheme = hostNoPath.contains('://')
        ? hostNoPath.split('://').last
        : hostNoPath;
    
    // Diagnosticar conexión HTTP
    String? detectedIp;
    String? resolvedUrl;
    
    final ipResult = NetworkUtils.detectServerIp(serverUrl: url);
    if (ipResult != null) {
      detectedIp = ipResult;
      print('[HomeScreen] Detected server IP: $detectedIp');
    }
    
    resolvedUrl = await NetworkUtils.resolveLocalhost(url);
    
    final diagnostic = DiagnosticInfo(
      serverUrl: url,
      detectedIp: detectedIp,
      resolvedUrl: resolvedUrl,
      healthUrl: 'http://$hostNoScheme/health',
      socketIoTestUrl: 'http://$hostNoScheme/socket-io-test',
    );
    
    if (mounted) {
      showModalBottomSheet(
        context: context,
        builder: (ctx) => DiagnosticInfoSheet(diagnostic: diagnostic),
      );
    }
  }
}

/// Información de diagnóstico para mostrar en el UI
class DiagnosticInfo {
  final String serverUrl;
  final String? detectedIp;
  final String? resolvedUrl;
  final String? healthUrl;
  final String? socketIoTestUrl;

  DiagnosticInfo({
    required this.serverUrl,
    this.detectedIp,
    this.resolvedUrl,
    this.healthUrl,
    this.socketIoTestUrl,
  });
}

/// Hoja de diálogo para mostrar información de diagnóstico
class DiagnosticInfoSheet extends StatelessWidget {
  final DiagnosticInfo diagnostic;

  const DiagnosticInfoSheet({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 24,
        right: 24,
        top: 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Diagnóstico de Conexión',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text('Servidor configurado:', style: theme.textTheme.bodyMedium),
          Text(
            diagnostic.serverUrl ?? 'N/A',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text('IP detectada:', style: theme.textTheme.bodyMedium),
          Text(
            diagnostic.detectedIp ?? 'No detectada',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 12),
          Text('URL resuelta:', style: theme.textTheme.bodyMedium),
          Text(
            diagnostic.resolvedUrl ?? diagnostic.serverUrl ?? 'N/A',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text('Endpoints de diagnóstico:', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          _DiagnosticEndpointLink(
            label: 'Health',
            url: diagnostic.healthUrl ?? '',
          ),
          const SizedBox(height: 8),
          _DiagnosticEndpointLink(
            label: 'Socket.IO Test',
            url: diagnostic.socketIoTestUrl ?? '',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

/// Enlace para endpoint de diagnóstico
class _DiagnosticEndpointLink extends StatelessWidget {
  final String label;
  final String url;

  const _DiagnosticEndpointLink({required this.label, required this.url});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: Theme.of(context).textTheme.bodySmall),
          Expanded(
            child: SelectableText(
              url,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
