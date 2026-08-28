import '../models/ability.dart';
import '../models/race.dart';

/// Static catalog of playable races. Adjust bonuses/traits freely later.
const List<Race> kRaces = [
  Race(
    id: 'humano',
    name: 'Humano',
    description: 'Versátiles y ambiciosos, se adaptan a cualquier oficio.',
    abilityBonuses: {
      Ability.fuerza: 1,
      Ability.destreza: 1,
      Ability.constitucion: 1,
      Ability.inteligencia: 1,
      Ability.sabiduria: 1,
      Ability.carisma: 1,
    },
    traits: ['Un idioma adicional', 'Adaptable a cualquier clase'],
    avatarAsset: 'assets/avatars/race_human.png',
  ),
  Race(
    id: 'elfo',
    name: 'Elfo',
    description: 'Ágiles y longevos, conectados con la magia y la naturaleza.',
    abilityBonuses: {Ability.destreza: 2, Ability.inteligencia: 1},
    traits: ['Visión en la oscuridad', 'Resistencia a hechizos de sueño'],
    avatarAsset: 'assets/avatars/race_elf.png',
  ),
  Race(
    id: 'enano',
    name: 'Enano',
    description: 'Resistentes guerreros y artesanos de las montañas.',
    abilityBonuses: {Ability.constitucion: 2, Ability.sabiduria: 1},
    traits: ['Visión en la oscuridad', 'Resistencia a veneno'],
    avatarAsset: 'assets/avatars/race_dwarf.png',
  ),
  Race(
    id: 'mediano',
    name: 'Mediano',
    description: 'Pequeños, sigilosos y sorprendentemente afortunados.',
    abilityBonuses: {Ability.destreza: 2, Ability.carisma: 1},
    traits: ['Suerte de mediano (repetir 1 en dados)', 'Sigiloso por naturaleza'],
    avatarAsset: 'assets/avatars/race_halfling.png',
  ),
  Race(
    id: 'semiorco',
    name: 'Semiorco',
    description: 'Fuertes y feroces, destacan en el combate directo.',
    abilityBonuses: {Ability.fuerza: 2, Ability.constitucion: 1},
    traits: ['Resistencia implacable', 'Ataques salvajes'],
    avatarAsset: 'assets/avatars/race_half_orc.png',
  ),
  Race(
    id: 'draconido',
    name: 'Dracónido',
    description: 'Descendientes de dragones, con aliento elemental.',
    abilityBonuses: {Ability.fuerza: 2, Ability.carisma: 1},
    traits: ['Aliento de dragón', 'Resistencia elemental'],
    avatarAsset: 'assets/avatars/race_dragonborn.png',
  ),
  Race(
    id: 'gnomo',
    name: 'Gnomo',
    description: 'Curiosos e ingeniosos, brillantes con la magia arcana.',
    abilityBonuses: {Ability.inteligencia: 2, Ability.constitucion: 1},
    traits: ['Visión en la oscuridad', 'Astucia gnoma (ventaja vs. magia)'],
    avatarAsset: 'assets/avatars/race_gnome.png',
  ),
  Race(
    id: 'semielfo',
    name: 'Semielfo',
    description: 'Carismáticos y versátiles, a caballo entre dos mundos.',
    abilityBonuses: {Ability.carisma: 2, Ability.destreza: 1, Ability.sabiduria: 1},
    traits: ['Visión en la oscuridad', 'Versatilidad en habilidades'],
    avatarAsset: 'assets/avatars/race_half_elf.png',
  ),
];
