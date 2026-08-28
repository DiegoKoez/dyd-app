import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

/// Iconos por defecto para objetos sin imagen
const List<Map<String, String>> _defaultItemIcons = [
  {'emoji': '🗡️', 'description': 'Espada'},
  {'emoji': '🔱', 'description': 'Escudo'},
  {'emoji': '💍', 'description': 'Anillo'},
  {'emoji': '📜', 'description': 'Pergamino'},
  {'emoji': '🔮', 'description': 'Cristal'},
  {'emoji': '🍷', 'description': 'Poción'},
  {'emoji': '🪙', 'description': 'Moneda'},
  {'emoji': '📖', 'description': 'Libro'},
  {'emoji': '🏺', 'description': 'Jarrón'},
  {'emoji': '🔨', 'description': 'Herramienta'},
];

/// Iconos por defecto para armas
const List<Map<String, String>> _defaultWeaponIcons = [
  {'emoji': '🗡️', 'description': 'Espada'},
  {'emoji': '⚔️', 'description': 'Espada Doble'},
  {'emoji': '🔪', 'description': 'Daga'},
  {'emoji': '🏹', 'description': 'Arco'},
  {'emoji': '🛡️', 'description': 'Escudo'},
  {'emoji': '🗼', 'description': 'Mazo'},
  {'emoji': '🌪️', 'description': 'Lanza'},
  {'emoji': '🪃', 'description': 'Dardo'},
];

class ImageSearchDialog extends StatefulWidget {
  final String query;
  final bool isWeapon; // Si es true, usa iconos de armas, si es false usa iconos de objetos

  const ImageSearchDialog({
    super.key,
    required this.query,
    this.isWeapon = false,
  });

  @override
  State<ImageSearchDialog> createState() => _ImageSearchDialogState();
}

class _ImageSearchDialogState extends State<ImageSearchDialog> {
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> _imageResults = [];
  List<Map<String, String>> _defaultIcons = [];
  bool _searching = false;
  String? _selectedUrl;
  String? _selectedBase64;
  bool _useDefaultIcon = false;
  String? _selectedDefaultIcon;

  @override
  void initState() {
    super.initState();
    _controller.text = widget.query;
    _initDefaultIcons();
  }

  void _initDefaultIcons() {
    setState(() {
      _defaultIcons = widget.isWeapon ? List<Map<String, String>>.from(_defaultWeaponIcons)
                                        : List<Map<String, String>>.from(_defaultItemIcons);
    });
  }

  Future<List<Map<String, dynamic>>> _buildImageUrls(String q) async {
    if (q.trim().isEmpty) return [];

    final encoded = Uri.encodeComponent(q);
    return [
      {'url': 'https://loremflickr.com/320/240/$encoded?random=1'},
      {'url': 'https://loremflickr.com/320/240/$encoded?random=2'},
      {'url': 'https://loremflickr.com/320/240/$encoded?random=3'},
      {'url': 'https://loremflickr.com/320/240/$encoded?random=4'},
      {'url': 'https://loremflickr.com/320/240/$encoded?random=5'},
      {'url': 'https://loremflickr.com/320/240/$encoded?random=6'},
      {'url': 'https://loremflickr.com/320/240/$encoded?random=7'},
      {'url': 'https://loremflickr.com/320/240/$encoded?random=8'},
      {'url': 'https://loremflickr.com/320/240/$encoded?random=9'},
    ];
  }

  Future<void> _search(String q) async {
    if (q.trim().isEmpty) return;

    setState(() {
      _searching = true;
      _selectedUrl = null;
      _selectedBase64 = null;
      _useDefaultIcon = false;
      _selectedDefaultIcon = null;
    });

    try {
      final urls = await _buildImageUrls(q);
      if (mounted) {
        setState(() {
          _imageResults = urls.map((url) => {
            'url': url,
            'selected': false,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error buscando imágenes: $e');
    } finally {
      if (mounted) {
        setState(() {
          _searching = false;
        });
      }
    }
  }

  void _toggleDefaultIcon(String iconKey) {
    setState(() {
      if (_useDefaultIcon) {
        _useDefaultIcon = false;
        _selectedDefaultIcon = null;
      } else {
        _useDefaultIcon = true;
        _selectedDefaultIcon = iconKey;
        _selectedUrl = null;
        _selectedBase64 = null;
      }
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: source, imageQuality: 70);
    if (photo == null) return;

    final bytes = await File(photo.path).readAsBytes();
    final base64 = base64Encode(bytes);
    if (mounted) {
      Navigator.of(context).pop(base64);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.isWeapon ? 'Imagen del arma' : 'Imagen del objeto';

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Buscar imagen',
                hintText: 'Ej: espada, poción, escudo...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : null,
              ),
              onSubmitted: (value) => _search(value),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _searching ? null : () => _search(_controller.text.trim()),
                    icon: _searching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Buscar en Internet'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _toggleDefaultIcon('default'),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Icono'),
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Tomar foto',
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                ),
                IconButton(
                  tooltip: 'Galería',
                  onPressed: () => _pickImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sección de iconos por defecto
            if (_useDefaultIcon)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selecciona un icono por defecto:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _defaultIcons.length,
                    itemBuilder: (context, index) {
                      final icon = _defaultIcons[index];
                      final selected = _selectedDefaultIcon == icon['emoji'];
                      return InkWell(
                        onTap: () => _toggleDefaultIcon(icon['emoji']!),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              icon['emoji']!,
                              style: TextStyle(fontSize: 32),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),

            // Sección de imágenes de internet
            if (!_useDefaultIcon && _imageResults.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Resultados de búsqueda:',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    itemCount: _imageResults.length,
                    itemBuilder: (context, index) {
                      final result = _imageResults[index];
                      final url = result['url'] as String;
                      final selected = _selectedUrl == url;

                      return InkWell(
                        onTap: () async {
                          setState(() {
                            _selectedUrl = url;
                            _selectedBase64 = null;
                            _useDefaultIcon = false;
                            _selectedDefaultIcon = null;
                          });

                          try {
                            final response = await http.get(Uri.parse(url));
                            if (response.statusCode == 200 && mounted) {
                              final base64 = base64Encode(response.bodyBytes);
                              if (mounted) {
                                setState(() {
                                  _selectedBase64 = base64;
                                });
                              }
                            }
                          } catch (e) {
                            debugPrint('Error cargando imagen: $e');
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: selected
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              width: 3,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: 80,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Sin imagen'),
        ),
        if (_useDefaultIcon)
          FilledButton(
            onPressed: _selectedDefaultIcon != null
                ? () => Navigator.of(context).pop(_selectedDefaultIcon)
                : null,
            child: const Text('Usar icono'),
          ),
        if (!_useDefaultIcon && _selectedBase64 != null)
          FilledButton(
            onPressed: () => Navigator.of(context).pop(_selectedBase64),
            child: const Text('Usar imagen'),
          ),
      ],
    );
  }
}

Future<String?> showImageSearchDialog(BuildContext context, String query, {bool isWeapon = false}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => ImageSearchDialog(query: query, isWeapon: isWeapon),
  );
}
