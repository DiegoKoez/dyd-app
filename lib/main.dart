import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/game_session.dart';
import 'services/navigator_key.dart';
import 'services/server_prefs.dart';
import 'services/socket_service.dart';
import 'widgets/player_popup_handler.dart';
import 'widgets/notification_banner.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    print('[FLUTTER ERROR] ${details.exception}');
    print('${details.stack}');
  };
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  bool _appResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appResumed = WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state != AppLifecycleState.paused;
    if (resumed && !_appResumed) {
      _appResumed = true;
      _handleResumed();
    } else if (!resumed) {
      _appResumed = false;
    }
  }

  Future<void> _handleResumed() async {
    if (!mounted) return;
    // NO conectar automáticamente - el usuario debe configurar la URL manualmente primero
    // final session = context.read<GameSession>();
    // final prefs = await ServerPrefs.getSavedUrl();
    // if (prefs == null || prefs.isEmpty) return;
    // if (session.connected) {
    //   session.restoreCharacterAfterReconnect();
    //   return;
    // }
    // try {
    //   await session.connect(prefs);
    // } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => GameSession(),
      child: MaterialApp(
        title: 'DYD',
        navigatorKey: navigatorKey,
        scaffoldMessengerKey: scaffoldMessengerKey,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        builder: (context, child) => PlayerPopupHandler(
          child: NotificationBanner(child: child!),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
