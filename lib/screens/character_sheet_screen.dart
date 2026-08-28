import 'package:flutter/material.dart';
import '../models/character.dart';
import '../widgets/character_sheet_view.dart';

/// Read-only character sheet shown after creation. Later this becomes the
/// player's "ver a mi personaje" screen with HP tracking and inventory.
class CharacterSheetScreen extends StatelessWidget {
  final Character character;

  const CharacterSheetScreen({super.key, required this.character});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(character.name)),
      body: CharacterSheetView(character: character),
    );
  }
}
