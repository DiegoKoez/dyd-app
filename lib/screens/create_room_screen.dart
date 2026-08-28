import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/game_session.dart';
import 'dm/dm_options_screen.dart';

/// Connects to the configured server and creates a real room, receiving the
/// code assigned by the backend.
class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  String? _code;
  String? _error;
  String? _connectionStatus;

  @override
  void initState() {
    super.initState();
    // NO llamar a _createRoom() aquí - dejamos que el usuario presione el botón
  }

  /// Intenta conectar al servidor si no está conectado, y luego crear la sala
  Future<void> _createRoom() async {
    final session = context.read<GameSession>();
    final serverUrl = session.serverUrl;
    
    print('[CreateRoom] _createRoom started');
    print('[CreateRoom] serverUrl: "$serverUrl"');
    print('[CreateRoom] connected: ${session.connected}');

    if (serverUrl.isEmpty) {
      if (!mounted) return;
      setState(() {
        _error = 'No hay servidor configurado. Por favor ingresa la URL del servidor en la configuración primero.';
      });
      return;
    }

    setState(() {
      _error = null;
      _code = null;
      _connectionStatus = 'Conectando al servidor...';
    });

    try {
      bool needsConnection = !session.connected;
      
      if (needsConnection) {
        print('[CreateRoom] Connecting to server: $serverUrl');
        final connected = await session.connectOrRefresh(serverUrl);
        print('[CreateRoom] Connected after connectOrRefresh(): $connected');
        
        if (!connected) {
          setState(() {
            _connectionStatus = 'Error de conexión';
          });
          throw Exception('No se pudo conectar al servidor. Verifica que:\n'
              '1. El servidor esté corriendo (ver terminal)\n'
              '2. Estés en la misma red Wi-Fi\n'
              '3. La URL sea correcta (con http:// y el puerto :3000)\n\n'
              'Diagnóstico:\n'
              '- Endpoint /socket-io-test: http://${serverUrl.split("://").last.split("/").first}/socket-io-test\n'
              '- Endpoint /health: http://${serverUrl.split("://").last.split("/").first}/health');
        }
        
        setState(() {
          _connectionStatus = 'Conectado - creando sala...';
        });
      }

      print('[CreateRoom] Calling createRoom()...');
      // Esperar máximo 30 segundos para crear la sala (aumentado por problemas de conexión)
      final code = await session.createRoom().timeout(
        Duration(seconds: 30),
        onTimeout: () => throw Exception('El servidor tardó más de 30s en crear la sala. Intenta de nuevo o verifica que el servidor tenga recursos suficientes.'),
      );

      print('[CreateRoom] Received code: $code');

      if (!mounted) return;
      setState(() {
        _code = code;
        _connectionStatus = null;
      });
      print('[CreateRoom] UI updated with code: $_code');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al crear sala: $e';
        _connectionStatus = null;
      });
      print('[CreateRoom] Error: $e');
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Código copiado')),
    );
  }

  void _shareCode(String code) {
    SharePlus.instance.share(
      ShareParams(text: 'Únete a mi partida de DYD con el código: $code'),
    );
  }

  void _retry() {
    setState(() {
      _error = null;
      _code = null;
      _connectionStatus = null;
    });
    _createRoom();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Si ya tenemos el código, mostrar pantalla de éxito
    if (_code != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crear sala')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Eres el Dungeon Master',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  Text('Código de la sala',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 8),
                  Text(
                    _code!,
                    style: theme.textTheme.displaySmall?.copyWith(
                        letterSpacing: 8, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Comparte este código con tu grupo para que se unan',
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _copyCode(_code!),
                        icon: const Icon(Icons.copy),
                        label: const Text('Copiar'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _shareCode(_code!),
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => DmOptionsScreen(roomCode: _code!)),
                    ),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continuar'),
                    style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Mostrar error
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crear sala')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: _ErrorState(message: _error!, onRetry: _retry),
            ),
          ),
        ),
      );
    }

    // Estado de conexión
    if (_connectionStatus != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Crear sala')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_connectionStatus!, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Estado inicial - mostrar botón visible
    return Scaffold(
      appBar: AppBar(title: const Text('Crear sala')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gamepad, size: 80, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'Crear nueva sala',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Presiona el botón para crear una sala y compartir con tus jugadores',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _createRoom,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Text('CREAR SALA'),
                  ),
                ),
                const SizedBox(height: 16),
                if (context.read<GameSession>().serverUrl.isEmpty)
                  Text(
                    '⚠️ No hay servidor configurado. Añade la URL en la configuración primero.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dividir el mensaje por \n para mostrar en líneas separadas
    final lines = message.split('\n');
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.error_outline,
            size: 48, color: theme.colorScheme.error),
        const SizedBox(height: 16),
        // Mostrar cada línea del mensaje
        ...lines.map((line) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            line,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
        )),
        const SizedBox(height: 24),
        FilledButton(onPressed: onRetry, child: const Text('Reintentar')),
      ],
    );
  }
}
