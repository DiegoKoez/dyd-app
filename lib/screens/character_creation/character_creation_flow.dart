import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ability.dart';
import '../../models/ability_scores.dart';
import '../../models/character.dart';
import '../../models/character_class.dart';
import '../../models/race.dart';
import '../../services/game_session.dart';
import '../../services/navigator_key.dart';
import '../player/player_battle_screen.dart';
import '../player/player_lobby_screen.dart';
import 'steps/appearance_step.dart';
import 'steps/ability_scores_step.dart';
import 'steps/class_step.dart';
import 'steps/name_step.dart';
import 'steps/race_step.dart';
import 'steps/summary_step.dart';
import 'steps/manual_stats_edit_step.dart';

/// Multi-step wizard: raza -> clase -> genero -> apariencia -> estadísticas -> nombre -> resumen.
class CharacterCreationFlow extends StatefulWidget {
  const CharacterCreationFlow({super.key});

  @override
  State<CharacterCreationFlow> createState() => _CharacterCreationFlowState();
}

class _CharacterCreationFlowState extends State<CharacterCreationFlow> {
  final PageController _pageController = PageController();
  int _step = 0;

  Race? _race;
  CharacterClass? _characterClass;
  String _hairColor = kHairColors.first;
  String _hairStyle = kHairStyles.first;
  int _heightCm = 170;
  String _gender = 'masculino';
  String _name = '';
  final Map<Ability, int> _manualScores = {
    Ability.fuerza: 10,
    Ability.destreza: 10,
    Ability.constitucion: 10,
    Ability.inteligencia: 10,
    Ability.sabiduria: 10,
    Ability.carisma: 10,
  };
  int _customMaxHp = 10; // HP personalizado
  int _customAgility = 10; // Agilidad personalizada

  static const int _totalSteps = 8; // Añadido paso de edición manual
  late final GameSession _session;

  @override
  void initState() {
    super.initState();
    _session = context.read<GameSession>();
    _session.addListener(_onSessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _session.startCustomizing();
      }
    });
  }

  @override
  void dispose() {
    _session.removeListener(_onSessionChanged);
    _pageController.dispose();
    super.dispose();
  }

  void _onSessionChanged() {
    if (_session.battleStarted && _session.myCharacter != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && navigatorKey.currentState != null) {
          navigatorKey.currentState!.pushReplacement(
            MaterialPageRoute(builder: (_) => const PlayerBattleScreen()),
          );
        }
      });
    }
  }

  bool get _canGoNext {
    switch (_step) {
      case 0:
        return _race != null;
      case 1:
        return _characterClass != null;
      case 2:
        return true; // Género siempre permitido
      case 3:
        return true; // Apariencia siempre permitida
      case 4:
        return true; // Estadísticas base siempre permitidas
      case 5:
        return _name.trim().isNotEmpty;
      case 6:
        return true; // Edición manual de estadísticas siempre permitida
      case 7:
        return true; // Resumen
      default:
        return true;
    }
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  void _confirmCharacter(Character character) {
    context.read<GameSession>().sendCharacter(character);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => PlayerLobbyScreen(character: character)),
    );
  }

  Character _buildCharacter() {
    final finalScores = AbilityScores(Map.from(_manualScores))
        .withBonuses(_race!.abilityBonuses);
    final conMod = finalScores.modifier(Ability.constitucion);
    final dexMod = finalScores.modifier(Ability.destreza);
    final ac = 10 + dexMod + _characterClass!.armorBonus;
    
    // Usar valores personalizados si el usuario los ha editado manualmente
    // El paso ManualStatsEditStep establece estos valores
    final maxHp = _customMaxHp > 1 ? _customMaxHp : (_characterClass!.hitDie + conMod < 1 ? 1 : _characterClass!.hitDie + conMod);
    
    return Character(
      name: _name.trim().isEmpty ? 'Sin nombre' : _name.trim(),
      race: _race!,
      characterClass: _characterClass!,
      hairStyle: _hairStyle,
      hairColor: _hairColor,
      heightCm: _heightCm,
      abilityScores: finalScores,
      maxHp: maxHp,
      armorClass: ac,
      gender: _gender,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear personaje (${_step + 1}/$_totalSteps)'),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          RaceStep(
            selected: _race,
            onSelected: (race) {
              setState(() => _race = race);
              if (_characterClass != null) {
                for (final a in Ability.values) {
                  _manualScores[a] = 10;
                }
              }
            },
          ),
          ClassStep(
            selected: _characterClass,
            onSelected: (c) => setState(() => _characterClass = c),
          ),
          const GenderStep(),
          AppearanceStep(
            hairColor: _hairColor,
            hairStyle: _hairStyle,
            heightCm: _heightCm,
            onHairColorChanged: (v) => setState(() => _hairColor = v),
            onHairStyleChanged: (v) => setState(() => _hairStyle = v),
            onHeightChanged: (v) => setState(() => _heightCm = v),
          ),
          if (_race != null && _characterClass != null)
            AbilityScoresStep(
              scores: _manualScores,
              onIncrement: (ability) => setState(() {
                if (_manualScores[ability]! < 20) _manualScores[ability] = _manualScores[ability]! + 1;
              }),
              onDecrement: (ability) => setState(() {
                if (_manualScores[ability]! > 1) _manualScores[ability] = _manualScores[ability]! - 1;
              }),
              baseScores: AbilityScores(_manualScores),
              raceBonuses: _race!.abilityBonuses,
            ),
          NameStep(
            name: _name,
            onNameChanged: (v) => setState(() => _name = v),
          ),
          if (_race != null && _characterClass != null)
            ManualStatsEditStep(
              maxHp: _buildCharacter().maxHp,
              currentAc: _buildCharacter().armorClass,
              onStatsChanged: (stats) {
                setState(() {
                  _customMaxHp = stats['maxHp'] as int? ?? _customMaxHp;
                  _customAgility = stats['agility'] as int? ?? _customAgility;
                });
              },
            ),
          if (_race != null && _characterClass != null)
            SummaryStep(
              character: _buildCharacter(),
              onConfirm: () => _confirmCharacter(_buildCharacter()),
            )
          else
            const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: _step == _totalSteps - 1
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (_step > 0)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _goTo(_step - 1),
                          child: const Text('Atrás'),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _canGoNext ? () => _goTo(_step + 1) : null,
                        child: const Text('Siguiente'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class GenderStep extends StatefulWidget {
  const GenderStep({super.key});

  @override
  State<GenderStep> createState() => _GenderStepState();
}

class _GenderStepState extends State<GenderStep> {
  String _gender = 'masculino';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Género', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'masculino',
              label: Text('Masculino'),
              icon: Icon(Icons.male),
            ),
            ButtonSegment(
              value: 'femenino',
              label: Text('Femenino'),
              icon: Icon(Icons.female),
            ),
            ButtonSegment(
              value: 'otro',
              label: Text('Otro'),
              icon: Icon(Icons.transgender),
            ),
          ],
          selected: {_gender},
          onSelectionChanged: (Set<String> newSelection) {
            if (newSelection.isNotEmpty) {
              setState(() => _gender = newSelection.first);
            }
          },
        ),
        const SizedBox(height: 16),
        if (_gender == 'masculino')
          const Icon(Icons.male, size: 64, color: Colors.blue)
        else if (_gender == 'femenino')
          const Icon(Icons.female, size: 64, color: Colors.pink)
        else
          const Icon(Icons.transgender, size: 64, color: Colors.purple),
      ],
    );
  }
}
