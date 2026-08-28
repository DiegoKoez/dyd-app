/// Utilidades para detectar y gestionar direcciones de red local.
import 'dart:io';

class NetworkUtils {
  /// Detecta la IP de red local del servidor.
  ///
  /// Intenta varias estrategias:
  /// 1. Extraer IP de URL si se proporciona
  /// 2. Si es IP de red local y estamos en Windows, convertir a 127.0.0.1
  /// 3. Usar localhost/127.0.0.1 como fallback
  static String? detectServerIp({String? serverUrl}) {
    // No convertir ninguna URL - usar tal cual
    return serverUrl;
  }
  
  /// Verifica si una cadena es una IP válida
  static bool _isValidIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    for (final part in parts) {
      if (part.isEmpty) return false;
      final num = int.tryParse(part);
      if (num == null || num < 0 || num > 255) return false;
    }
    
    return true;
  }
  
  /// Verifica si una IP es de red local (privada)
  static bool _isLocalIp(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    
    try {
      final first = int.parse(parts[0]);
      final second = int.parse(parts[1]);
      
      // 10.x.x.x
      if (first == 10) return true;
      
      // 172.16.x.x - 172.31.x.x
      if (first == 172 && second >= 16 && second <= 31) return true;
      
      // 192.168.x.x
      if (first == 192 && second == 168) return true;
      
      // 127.x.x.x (localhost)
      if (first == 127) return true;
      
      // ::1 (IPv6 localhost)
      if (ip == '::1') return true;
      
      return false;
    } catch (e) {
      return false;
    }
  }
  
  /// Construye URL completa para el servidor
  static String buildServerUrl({
    required String host,
    int port = 8080,
    String scheme = 'http',
  }) {
    return '$scheme://$host:$port';
  }
  
  /// Resuelve localhost a 127.0.0.1 para conexiones locales
  static Future<String> resolveLocalhost(String serverUrl) async {
    try {
      final uri = Uri.parse(serverUrl);
      final host = uri.host;
      
      if (host == 'localhost' || host == '127.0.0.1') {
        print('[NetworkUtils] Converting localhost to 127.0.0.1');
        return uri.replace(host: '127.0.0.1').toString();
      }
      
      // Si es IP de red local, devolver como está
      if (_isLocalIp(host)) {
        print('[NetworkUtils] Using local IP as-is: $serverUrl');
        return serverUrl;
      }
      
      return serverUrl;
    } catch (e) {
      print('[NetworkUtils] Error resolving localhost: $e');
      return serverUrl;
    }
  }
}
