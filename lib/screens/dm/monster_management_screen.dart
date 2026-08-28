import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/monster.dart';
import '../../services/game_session.dart';

/// Full-screen monster management: lists every available monster
/// (catalog + custom), lets the DM edit existing ones or create new ones
/// with a photo, delete custom monsters, and select which to bring into battle.
class MonsterManagementScreen extends StatefulWidget {
  final Monster? editMonster;

  const MonsterManagementScreen({super.key, this.editMonster});

  @override
  State<MonsterManagementScreen> createState() =>
      _MonsterManagementScreenState();
}

class _MonsterManagementScreenState extends State<MonsterManagementScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.editMonster != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _openEditDialog(widget.editMonster!);
        }
      });
    }
  }

  Future<void> _openEditDialog(Monster monster) async {
    final session = context.read<GameSession>();
    final result = await showMonsterEditDialog(
      context,
      monster: monster,
    );
    if (result == null || !mounted) return;

    final isCustom = session.customMonsters.any((m) => m.id == monster.id);
    if (isCustom) {
      session.updateCustomMonster(monster.id, result);
    } else {
      session.addCustomMonster(result);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.name} actualizado')),
    );
  }

  Future<void> _createNewMonster() async {
    final session = context.read<GameSession>();
    final result = await showMonsterEditDialog(
      context,
      monster: Monster(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        name: '',
        description: '',
        maxHp: 10,
        armorClass: 10,
        attackName: '',
        damageDice: '1d6',
      ),
      isNew: true,
    );
    if (result == null || !mounted) return;
    session.addCustomMonster(result);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${result.name} creado')),
    );
  }

  Future<void> _deleteCustomMonster(Monster monster) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Eliminar enemigo?'),
        content: Text(
          '¿Estás seguro de que quieres eliminar a "${monster.name}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    context.read<GameSession>().removeCustomMonster(monster.id);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Administrar enemigos')),
      body: Consumer<GameSession>(
        builder: (context, session, _) {
          final available = session.allAvailableMonsters;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Catálogo de monstruos',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              for (final monster in available)
                _buildMonsterCard(
                  monster,
                  theme,
                  isCustom:
                      session.customMonsters.any((m) => m.id == monster.id),
                  onDelete:
                      session.customMonsters.any((m) => m.id == monster.id)
                          ? () => _deleteCustomMonster(monster)
                          : null,
                ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewMonster,
        icon: const Icon(Icons.add),
        label: const Text('Nuevo enemigo'),
      ),
    );
  }

  Widget _buildMonsterCard(
    Monster monster,
    ThemeData theme, {
    required bool isCustom,
    VoidCallback? onDelete,
  }) {
    return Card(
      child: ListTile(
        leading: monster.photoBase64 != null
            ? CircleAvatar(
                radius: 20,
                backgroundImage: MemoryImage(base64Decode(monster.photoBase64!)),
              )
            : const CircleAvatar(radius: 20, child: Icon(Icons.pets)),
        title: Text(monster.name.isEmpty ? 'Sin nombre' : monster.name),
        subtitle: Text(
          '${monster.description}\nHP ${monster.maxHp} · AC ${monster.armorClass} · ${monster.attackName} (${monster.damageDice})',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 4,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              tooltip: 'Editar',
              onPressed: () => _openEditDialog(monster),
            ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Eliminar',
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

Future<Monster?> showMonsterEditDialog(
  BuildContext context, {
  required Monster monster,
  bool isNew = false,
}) {
  final nameController = TextEditingController(text: monster.name);
  final descriptionController =
      TextEditingController(text: monster.description);
  final hpController = TextEditingController(text: monster.maxHp.toString());
  final acController =
      TextEditingController(text: monster.armorClass.toString());
  final attackController = TextEditingController(text: monster.attackName);
  final diceController = TextEditingController(text: monster.damageDice);
  String? photoBase64 = monster.photoBase64;

  return showDialog<Monster>(
    context: context,
    barrierDismissible: false,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(isNew ? 'Crear nuevo enemigo' : 'Editar enemigo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                   final photo = await picker.pickImage(
                     source: ImageSource.gallery,
                     imageQuality: 70,
                   );
                   if (photo == null) return;
                   final bytes = await photo.readAsBytes();
                   setState(() {
                     photoBase64 = base64Encode(bytes);
                  });
                },
                child: CircleAvatar(
                  radius: 40,
                  backgroundImage:
                      photoBase64 != null ? MemoryImage(base64Decode(photoBase64!)) : null,
                  child: photoBase64 == null
                      ? const Icon(Icons.camera_alt, size: 32)
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hpController,
                decoration: const InputDecoration(
                  labelText: 'Puntos de vida máximos',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: acController,
                decoration: const InputDecoration(
                  labelText: 'Clase de armadura (AC)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: attackController,
                decoration: const InputDecoration(
                  labelText: 'Ataque',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: diceController,
                decoration: const InputDecoration(
                  labelText: 'Dados de daño',
                  border: OutlineInputBorder(),
                  hintText: 'Ej: 1d6, 2d8',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              if (name.isEmpty) return;
              final hp = int.tryParse(hpController.text.trim()) ?? 0;
              final ac = int.tryParse(acController.text.trim()) ?? 0;
              final attack = attackController.text.trim();
              final dice = diceController.text.trim();
              final result = monster.copyWith(
                name: name,
                description: descriptionController.text.trim(),
                maxHp: hp,
                armorClass: ac,
                attackName: attack,
                damageDice: dice,
                photoBase64: photoBase64,
              );
              Navigator.of(context).pop(result);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
}
