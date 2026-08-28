import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'character.dart';
import '../../services/game_session.dart';
import '../../utils/storage_service.dart';

/// Pantalla de editor de avatar con previsualización
class AvatarEditorScreen extends StatefulWidget {
  final Character? character;
  
  const AvatarEditorScreen({super.key, this.character});

  @override
  State<AvatarEditorScreen> createState() => _AvatarEditorScreenState();
}

class _AvatarEditorScreenState extends State<AvatarEditorScreen> {
  String _hairStyle = 'corto';
  String _hairColor = 'negro';
  int _heightCm = 170;
  String _gender = 'masculino';
  
  @override
  void initState() {
    super.initState();
    if (widget.character != null) {
      _hairStyle = widget.character!.hairStyle;
      _hairColor = widget.character!.hairColor;
      _heightCm = widget.character!.heightCm;
      _gender = widget.character!.gender;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor de Avatar'),
        actions: [
          TextButton(
            onPressed: _saveCharacter,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Previsualización del personaje
            Text('Previsualización', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            Container(
              width: 200,
              height: 300,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outline),
              ),
              child: _buildAvatarPreview(theme),
            ),
            const SizedBox(height: 32),
            
            // Editor de pelo
            Text('Estilo de Pelo', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Corto', 'Largo', 'Rizado', 'Trenzado', 'Calvo', 'Mohawk',
                'Largo Ondulado', 'Moño', 'Cabello Rizado', 'Pelos Largos Desordenados'
              ].map((style) {
                final isSelected = _hairStyle == style;
                return ChoiceChip(
                  label: Text(style),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected && !isSelected) {
                      setState(() => _hairStyle = style);
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            
            // Editor de color
            Text('Color de Pelo', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Negro', 'Castaño Oscuro', 'Castaño', 'Castaño Claro',
                'Rubio Oscuro', 'Rubio', 'Rubio Platino', 'Marrón',
                'Rojo', 'Rojo Fuego', 'Morado', 'Azul', 'Verde',
                'Naranja', 'Rosa', 'Morado Oscuro', 'Rosa Claro',
                'Plateado', 'Blanco', 'Dorado', 'Violeta', 'Turquesa', 'Cian', 'Magenta', 'Amarillo'
              ].map((color) {
                final isSelected = _hairColor == color;
                final colorValue = _getHairColor(color);
                return GestureDetector(
                  onTap: () {
                    if (!isSelected) {
                      setState(() => _hairColor = color);
                    }
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colorValue,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: isSelected
                        ? Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 24,
                          )
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
            
            // Altura
            Text('Altura', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _heightCm.toDouble(),
                    min: 100,
                    max: 220,
                    divisions: 12,
                    label: '${_heightCm} cm',
                    onChanged: (value) {
                      setState(() => _heightCm = value.toInt());
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_heightCm} cm',
                  style: theme.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Género
            Text('Género', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'masculino', label: Text('Masculino'), icon: Icon(Icons.male)),
                ButtonSegment(value: 'femenino', label: Text('Femenino'), icon: Icon(Icons.female)),
                ButtonSegment(value: 'otro', label: Text('Otro'), icon: Icon(Icons.transgender)),
              ],
              selected: {_gender},
              onSelectionChanged: (Set<String> newSelection) {
                if (newSelection.isNotEmpty) {
                  setState(() => _gender = newSelection.first);
                }
              },
            ),
            const SizedBox(height: 32),
            
            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _saveCharacter,
                    icon: const Icon(Icons.save),
                    label: const Text('Guardar Cambios'),
                  ),
                ),
                const SizedBox(width: 16),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancelar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Color _getHairColor(String color) {
    switch (color) {
      case 'negro': return Colors.black;
      case 'castaño oscuro': return Colors.brown[800] ?? Colors.brown;
      case 'castaño': return Colors.brown[600] ?? Colors.brown;
      case 'castaño claro': return Colors.brown[500] ?? Colors.brown;
      case 'rubio oscuro': return Colors.amber[300] ?? Colors.amber[300];
      case 'rubio': return Colors.amber[100] ?? Colors.amber[100];
      case 'rubio platino': return Colors.grey[100] ?? Colors.grey[100];
      case 'marrón': return Colors.brown[400] ?? Colors.brown[400];
      case 'rojo': return Colors.red;
      case 'rojo fuego': return Colors.orange;
      case 'morado': return Colors.purple;
      case 'azul': return Colors.blue;
      case 'verde': return Colors.green;
      case 'naranja': return Colors.orange;
      case 'rosa': return Colors.pink;
      case 'morado oscuro': return Colors.purple[800] ?? Colors.purple[800];
      case 'rosa claro': return Colors.pink[200] ?? Colors.pink[200];
      case 'plateado': return Colors.silver;
      case 'blanco': return Colors.white;
      case 'dorado': return Colors.amber;
      case 'violeta': return Colors.purple[300] ?? Colors.purple[300];
      case 'turquesa': return Colors.teal;
      case 'cian': return Colors.cyan;
      case 'magenta': return Colors.purple;
      case 'amarillo': return Colors.yellow;
      default: return Colors.black;
    }
  }
  
  Widget _buildAvatarPreview(theme) {
    final hairColor = _getHairColor(_hairColor);
    final genderIcon = _gender == 'masculino' ? Icons.male : (_gender == 'femenino' ? Icons.female : Icons.transgender);
    
    return Stack(
      children: [
        // Cuerpo del personaje
        Container(
          width: 200,
          height: 300,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary.withOpacity(0.2),
                theme.colorScheme.surfaceContainerHighest,
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Cabeza
              Container(
                width: 100,
                height: 120,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(60),
                ),
                child: Center(
                  child: Icon(genderIcon, size: 60, color: theme.colorScheme.onSurface),
                ),
              ),
              const SizedBox(height: 12),
              // Cuerpo
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              const SizedBox(height: 12),
              // Piernas
              Container(
                width: 60,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ],
          ),
        ),
        // Efecto de pelo
        Positioned(
          top: -10,
          left: 0,
          right: 0,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 120,
            height: 140,
            decoration: BoxDecoration(
              color: hairColor,
              borderRadius: BorderRadius.circular(60),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  hairColor.withOpacity(0.8),
                  hairColor.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Future<void> _saveCharacter() async {
    final session = context.read<GameSession>();
    if (session.myCharacter == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay personaje para guardar')),
        );
      }
      return;
    }
    
    // Actualizar personaje
    final updatedCharacter = session.myCharacter!.copyWith(
      hairStyle: _hairStyle,
      hairColor: _hairColor,
      heightCm: _heightCm,
      gender: _gender,
    );
    
    session.myCharacter = updatedCharacter;
    
    // Guardar en storage
    await StorageService().saveCharacter(updatedCharacter.toJson());
    
    // Enviar al servidor
    final code = session.roomCode;
    if (code != null) {
      session._socketService.emit('player:updateAppearance', {
        'code': code,
        'hairStyle': _hairStyle,
        'hairColor': _hairColor,
        'heightCm': _heightCm,
        'gender': _gender,
      });
    }
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar guardado correctamente')),
      );
      Navigator.of(context).pop();
    }
  }
}
