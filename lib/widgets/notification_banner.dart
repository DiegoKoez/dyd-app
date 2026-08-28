import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/game_session.dart';
import '../services/navigator_key.dart';

class NotificationBanner extends StatefulWidget {
  final Widget child;

  const NotificationBanner({super.key, required this.child});

  @override
  State<NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<NotificationBanner> with WidgetsBindingObserver {
  String? _lastMessage;
  bool _appResumed = true;
  late final GameSession _session;

  @override
  void initState() {
    super.initState();
    _session = context.read<GameSession>();
    _session.addListener(_onSessionChanged);
    WidgetsBinding.instance.addObserver(this);
    _appResumed = WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state != AppLifecycleState.paused;
    if (resumed && !_appResumed) {
      _appResumed = true;
      _flushPendingMessages();
    } else if (!resumed) {
      _appResumed = false;
    }
  }

  void _onSessionChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_appResumed) {
        _flushPendingMessages();
      }
    });
  }

  void _flushPendingMessages() {
    final messenger = ScaffoldMessenger.of(navigatorKey.currentContext ?? context);
    if (!mounted) return;

    final battleMessage = _session.lastBattleMessage;
    if (battleMessage != null && battleMessage != _lastMessage) {
      _lastMessage = battleMessage;
      messenger.showSnackBar(
        SnackBar(
          content: Text(battleMessage),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      _session.clearBattleEffects();
      return;
    }

    final message = _session.lastNotificationMessage;
    if (message != null && message != _lastMessage) {
      _lastMessage = message;
      messenger.showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      _session.clearNotification();
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
