import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item.dart';
import '../../services/game_session.dart';
import '../../data/weapons_data.dart';
import '../../widgets/image_search_dialog.dart';

class WeaponAssignmentScreen extends StatefulWidget {
  final String roomCode;

  const WeaponAssignmentScreen({super.key, required this.roomCode});

  @override
  State<WeaponAssignmentScreen> createState() => _WeaponAssignmentScreenState();
}

class _WeaponAssignmentScreenState extends State<WeaponAssignmentScreen> {
  final _weaponController = TextEditingController();
  final _diceController = TextEditingController();
  String? _selectedPlayerId;
  String? _lastWeapon;
  String? _pendingImageBase64;

  @override
  void initState() {
    super.initState();
    _weaponController.addListener(() => setState(() {}));
    _diceController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _weaponController.dispose();
    _diceController.dispose();
    super.dispose();
  }

  Future<void> _openWeaponPicker() async {
    final selected = await showDialog<GameItem?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecciona un arma'),
        content: SizedBox(
          width: 360,
          child: ListView(
            shrinkWrap: true,
            children: [
              for (final weapon in kWeapons)
                ListTile(
                  leading: Text(emojiForItemName(weapon.name), style: const TextStyle(fontSize: 28)),
                  title: Text(weapon.name),
                  subtitle: Text(weapon.damageDice ?? weapon.description),
                  onTap: () => Navigator.of(ctx).pop(weapon),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Otro...'),
                subtitle: const Text('Ingresar arma personalizada'),
                onTap: () => Navigator.of(ctx).pop(null),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && mounted) {
      setState(() {
        _weaponController.text = selected.name;
        _diceController.text = selected.damageDice ?? '1d8';
      });
    }
  }

  Future<void> _assignWeapon() async {
    final weapon = _weaponController.text.trim();
    final dice = _diceController.text.trim();
    if (weapon.isEmpty || _selectedPlayerId == null) return;

    final session = context.read<GameSession>();
    final error = await session.assignWeapon(
      playerId: _selectedPlayerId!,
      weaponName: weapon,
      dice: dice,
      imageBase64: _pendingImageBase64,
    );

    setState(() {
      _lastWeapon = weapon;
      _pendingImageBase64 = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error == null
            ? 'Arma asignada'
            : 'Error: $error'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Asignar armas - ${widget.roomCode}')),
      body: Consumer<GameSession>(
        builder: (context, session, _) {
          if (session.players.isEmpty) {
            return const Center(
              child: Text('No hay jugadores conectados.'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Selecciona un jugador', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Jugador',
                  border: OutlineInputBorder(),
                ),
                items: [
                  for (final player in session.players)
                    DropdownMenuItem(
                      value: player.id,
                      child: Text(player.name),
                    ),
                ],
                value: _selectedPlayerId,
                onChanged: (value) {
                  setState(() => _selectedPlayerId = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _weaponController,
                decoration: InputDecoration(
                  labelText: 'Nombre del arma',
                  border: const OutlineInputBorder(),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_pendingImageBase64 != null)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CircleAvatar(
                            radius: 14,
                            backgroundImage: MemoryImage(base64Decode(_pendingImageBase64!)),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.list),
                        tooltip: 'Seleccionar de lista',
                        onPressed: _openWeaponPicker,
                      ),
                      IconButton(
                        icon: const Icon(Icons.image),
                        tooltip: 'Agregar imagen',
                        onPressed: () async {
                          try {
                            final base64 = await showImageSearchDialog(context, _weaponController.text.trim(), isWeapon: true);
                            if (base64 != null && mounted) {
                              setState(() => _pendingImageBase64 = base64);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Imagen agregada al arma')),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error al buscar imagen: $e')),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _diceController,
                decoration: const InputDecoration(
                  labelText: 'Dados (ej: 1d6, 2d8)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _selectedPlayerId == null ||
                        _weaponController.text.trim().isEmpty
                    ? null
                    : _assignWeapon,
                icon: const Icon(Icons.assignment_turned_in),
                label: const Text('Asignar arma'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 24),
              if (_lastWeapon != null && _selectedPlayerId != null)
                Card(
                  color: theme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('Última asignación', style: theme.textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Builder(
                          builder: (context) {
                            final player = session.players.firstWhere(
                              (p) => p.id == _selectedPlayerId,
                              orElse: () => session.players.first,
                            );
                            return Text(
                              '${player.name} recibió $_lastWeapon',
                              style: theme.textTheme.bodyLarge,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
