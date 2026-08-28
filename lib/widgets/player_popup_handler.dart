import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/game_session.dart';
import 'item_received_dialog.dart';
import 'weapon_received_dialog.dart';

class PlayerPopupHandler extends StatefulWidget {
  final Widget child;

  const PlayerPopupHandler({super.key, required this.child});

  @override
  State<PlayerPopupHandler> createState() => _PlayerPopupHandlerState();
}

class _PlayerPopupHandlerState extends State<PlayerPopupHandler> with WidgetsBindingObserver {
  bool _itemDialogPending = false;
  bool _weaponDialogPending = false;
  bool _appResumed = false;
  late final GameSession _session;
  
  @override
  void initState() {
    super.initState();
    _session = context.read<GameSession>();
    _session.addListener(_onSessionChanged);
    WidgetsBinding.instance.addObserver(this);
    _appResumed = WidgetsBinding.instance.lifecycleState != AppLifecycleState.paused;
    if (_appResumed) _checkPopups();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _session.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkPopups();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final resumed = state != AppLifecycleState.paused;
    if (resumed && !_appResumed) {
      _appResumed = true;
      _checkPopups();
    } else if (!resumed) {
      _appResumed = false;
    }
  }

  void _onSessionChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkPopups());
  }

  // Verificar si popup ya se mostró antes
  Future<bool> _popupAlreadyShown(String type) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'popup_shown_$type';
    return prefs.getBool(key) ?? false;
  }

  // Marcar popup como mostrado
  Future<void> _markPopupShown(String type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('popup_shown_$type', true);
  }

  void _checkPopups() {
    if (!mounted) return;

    // Verificar arma
    if (!_weaponDialogPending && _session.lastReceivedWeapon != null) {
      // Verificar si ya se mostró antes
      _popupAlreadyShown('weapon').then((alreadyShown) async {
        if (!alreadyShown) {
          _weaponDialogPending = true;
          final weapon = _session.lastReceivedWeapon!;
          showWeaponReceivedDialog(context, weapon).then((_) {
            _weaponDialogPending = false;
            if (mounted) {
              _session.clearReceivedWeapon();
              _markPopupShown('weapon');
            }
          });
        }
      });
    }

    // Verificar objeto
    if (!_itemDialogPending && _session.lastReceivedItem != null) {
      _popupAlreadyShown('item').then((alreadyShown) async {
        if (!alreadyShown) {
          _itemDialogPending = true;
          final item = _session.lastReceivedItem!;
          showItemReceivedDialog(context, item).then((_) {
            _itemDialogPending = false;
            if (mounted) {
              _session.clearReceivedItem();
              _markPopupShown('item');
            }
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
