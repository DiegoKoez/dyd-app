import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import '../data/character_creation/character_creation_flow.dart';
import '../models/character.dart';
import '../models/race.dart';
import '../services/game_session.dart';

/// Datos de previsualización de avatares
class AvatarPreviewData {
  // Estilos de pelo con sus iconos
  static const Map<String, IconData> hairStyles = {
    'corto': Icons.person,
    'largo recto': Icons.person,
    'largo ondulado': Icons.person,
    'moño': Icons.person,
    'cabello rizado': Icons.person,
    'pelos largos desordenados': Icons.person,
    'corto rebelde': Icons.person,
    'cabello largo rubio': Icons.person,
    'cabello largo negro': Icons.person,
    'cabello corto oscuro': Icons.person,
    'cabello largo oscuro': Icons.person,
    'cabello largo claro': Icons.person,
    'cabello corto rubio': Icons.person,
    'cabello corto negro': Icons.person,
    'cabello corto claro': Icons.person,
  };
  
  // Colores de pelo con sus códigos hex
  static const Map<String, Color> hairColors = {
    'negro': const Color(0xFF000000),
    'castaño oscuro': const Color(0xFF3B2219),
    'castaño': const Color(0xFF654321),
    'castaño claro': const Color(0xFF8B6F47),
    'rubio oscuro': const Color(0xFFD2B48C),
    'rubio': const Color(0xFFF5DEB3),
    'rubio platino': const Color(0xFFE8E8E8),
    'marrón': const Color(0xFF8B4513),
    'rojo': const Color(0xFF8B0000),
    'rojo fuego': const Color(0xFFFF4500),
    'morado': const Color(0xFF800080),
    'azul': const Color(0xFF0000FF),
    'verde': const Color(0xFF008000),
    'naranja': const Color(0xFFFFA500),
    'rosa': const Color(0xFFFFC0CB),
    'morado oscuro': const Color(0xFF4B0082),
    'rosa claro': const Color(0xFFFFB6C1),
    'plateado': const Color(0xFFC0C0C0),
    'blanco': const Color(0xFFFFFFFF),
    'dorado': const Color(0xFFFFD700),
    'violeta': const Color(0xFFEE82EE),
    'turquesa': const Color(0xFF40E0D0),
    'cian': const Color(0xFF00FFFF),
    'magenta': const Color(0xFFFF00FF),
    'amarillo': const Color(0xFFFFE400),
  };
}

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
  String _selectedImage = ''; // Base64 de la imagen seleccionada
  
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
            onPressed: _hairStyle != widget.character?.hairStyle || 
                        _hairColor != widget.character?.hairColor ||
                        _heightCm != widget.character?.heightCm ||
                        _gender != widget.character?.gender
                ? () => _saveCharacter()
                : null,
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
              children: HairStylesData.all.map((style) {
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
              children: HairColorsData.all.map((color) {
                final isSelected = _hairColor == color;
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
                      color: AvatarPreviewData.hairColors[color],
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
              segments: HairStylesData.all.map((gender) {
                return ButtonSegment(
                  value: gender,
                  label: Text(gender),
                  icon: Icon(
                    gender == 'masculino' ? Icons.male : (gender == 'femenino' ? Icons.female : Icons.transgender),
                  ),
                );
              }).toList(),
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
                  onPressed: _cancel,
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
  
  Widget _buildAvatarPreview(theme) {
    final hairColor = AvatarPreviewData.hairColors[_hairColor] ?? const Color(0xFF000000);
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
            width: _hairStyle == 'largo recto' || 
                    _hairStyle == 'largo ondulado' || 
                    _hairStyle == 'cabello largo rubio' ||
                    _hairStyle == 'cabello largo negro' ||
                    _hairStyle == 'cabello largo claro' ||
                    _hairStyle == 'cabello largo oscuro' ||
                    _hairStyle == 'cabello largo claro' ? 120 : 100,
            height: _hairStyle == 'largo recto' || 
                    _hairStyle == 'largo ondulado' || 
                    _hairStyle == 'cabello largo rubio' ||
                    _hairStyle == 'cabello largo negro' ||
                    _hairStyle == 'cabello largo claro' ||
                    _hairStyle == 'cabello largo oscuro' ? 140 : 60,
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
  
  void _cancel() {
    Navigator.of(context).pop();
  }
}
