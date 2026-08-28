import 'package:flutter/material.dart';

const List<String> kHairColors = [
  'Negro',
  'Castaño',
  'Rubio',
  'Pelirrojo',
  'Gris',
  'Blanco',
  'Azul',
  'Verde',
];

const List<String> kHairStyles = [
  'Corto',
  'Largo',
  'Rizado',
  'Trenzado',
  'Calvo',
  'Mohawk',
];

class AppearanceStep extends StatelessWidget {
  final String hairColor;
  final String hairStyle;
  final int heightCm;
  final ValueChanged<String> onHairColorChanged;
  final ValueChanged<String> onHairStyleChanged;
  final ValueChanged<int> onHeightChanged;

  const AppearanceStep({
    super.key,
    required this.hairColor,
    required this.hairStyle,
    required this.heightCm,
    required this.onHairColorChanged,
    required this.onHairStyleChanged,
    required this.onHeightChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Apariencia del personaje', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('Color de pelo', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kHairColors
              .map((color) => ChoiceChip(
                    label: Text(color),
                    selected: hairColor == color,
                    onSelected: (_) => onHairColorChanged(color),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        Text('Estilo de pelo', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kHairStyles
              .map((style) => ChoiceChip(
                    label: Text(style),
                    selected: hairStyle == style,
                    onSelected: (_) => onHairStyleChanged(style),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        Text('Altura: $heightCm cm', style: theme.textTheme.titleSmall),
        Slider(
          value: heightCm.toDouble(),
          min: 140,
          max: 210,
          divisions: 70,
          label: '$heightCm cm',
          onChanged: (value) => onHeightChanged(value.round()),
        ),
        const SizedBox(height: 24),
        const Text(
          'Editar Avatar (próximamente)',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        const SizedBox(height: 30),
      ],
    );
  }
}
