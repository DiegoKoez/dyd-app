import 'dart:convert';
import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../widgets/image_search_dialog.dart';

const _kEffects = [
  ('utilidad', 'Utilidad'),
  ('curacion', 'Curación'),
  ('veneno', 'Veneno'),
  ('hielo', 'Hielo'),
  ('fuego', 'Fuego'),
  ('fogata', 'Fogata'),
  ('comida', 'Comida'),
];

class CreateItemDialog extends StatefulWidget {
  const CreateItemDialog({super.key});

  @override
  State<CreateItemDialog> createState() => _CreateItemDialogState();
}

class _CreateItemDialogState extends State<CreateItemDialog> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _damageController = TextEditingController();
  String _effect = _kEffects.first.$1;
  String? _pendingImageBase64;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _damageController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    // Determinar si es arma u objeto basado en el efecto seleccionado
    final isWeapon = ['fuego', 'hielo', 'veneno', 'otro'].contains(_effect);
    final base64 = await showImageSearchDialog(context, _nameController.text.trim(), isWeapon: isWeapon);
    if (base64 != null && mounted) {
      setState(() => _pendingImageBase64 = base64);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Objeto personalizado'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _effect,
              decoration: const InputDecoration(labelText: 'Efecto'),
              items: [
                for (final option in _kEffects)
                  DropdownMenuItem(value: option.$1, child: Text(option.$2)),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _effect = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _damageController,
              decoration: const InputDecoration(
                labelText: 'Daño / estadística (opcional)',
                hintText: 'Ej: 2d6, 1d4+1',
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_pendingImageBase64 != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: MemoryImage(base64Decode(_pendingImageBase64!)),
                    ),
                  ),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: Text(_pendingImageBase64 == null ? 'Agregar imagen' : 'Cambiar imagen'),
                  ),
                ),
              ],
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
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            final item = GameItem(
              id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
              name: name,
              description: _descriptionController.text.trim().isEmpty
                  ? 'Objeto creado por el Dungeon Master.'
                  : _descriptionController.text.trim(),
              effect: _effect,
              damageDice: _damageController.text.trim().isEmpty
                  ? null
                  : _damageController.text.trim(),
              imageBase64: _pendingImageBase64,
            );
            Navigator.of(context).pop(item);
          },
          child: const Text('Crear y dar'),
        ),
      ],
    );
  }
}

Future<GameItem?> showCreateItemDialog(BuildContext context) {
  return showDialog<GameItem>(
    context: context,
    builder: (context) => const CreateItemDialog(),
  );
}
