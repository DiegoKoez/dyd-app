# DYD - Mesa de Rol Digital

Una app multiplataforma (Android, iOS, tablet) para jugar D&D y otros RPGs de mesa con amigos, en cualquier lugar.

## Características

### Creación de personajes
- Selecciona una de 8 razas (Humano, Elfo, Enano, Medioda, Tiefling, Dracónido, Gnomo, Semiorca)
- Elige una de 8 clases (Guerrero, Mago, Clérigo, Pícaro, Bardo, Ranger, Paladín, Druida)
- Calcula automáticamente los stats (Fuerza, Destreza, Constitución, Inteligencia, Sabiduría, Carisma) basado en prioridades de clase + bonos de raza
- Personaliza apariencia (color/estilo de pelo, altura)
- HP y AC se calculan automáticamente
- Especializaciones/pasiones únicas por clase

### Sesiones en tiempo real
- El Dungeon Master (DM) crea una sala y obtiene un código de 5 caracteres
- Comparte el código vía copiar/portapapeles o compartir nativo (WhatsApp, SMS, etc.)
- Los jugadores ingresan el código, ponen su nombre y crean su personaje
- Todos conectados ven a los demás en vivo (nombres, razas, clases, fichas)

### Combate por turnos
- **DM**: Ve monstruos y sus HP en vivo; elige monstruos del bestiario (8 por defecto) y da daño
- **Jugadores**: Ven su HP, aliados, enemigos; atacan monstruos en su turno (rollean daño automático)
- Turno del DM, de los monstruos y de cada jugador sincronizados en tiempo real

### Sistema de objetos
- El DM puede repartir objetos (pociones, venenos, cristales de hielo, cuerdas, etc.) a los jugadores
- Cada jugador ve su mochila en tiempo real

### Fotos compartidas
- El DM toma foto de la mesa física (mapa, miniaturas, etc.) y la envía a todos los jugadores
- Útil para sincronizar lo que ven en la pantalla con la mesa real

## Requisitos

### Server (backend)
- Node.js 24+ (o cualquier versión reciente con soporte para import/export)
- npm

### App (Flutter)
- Flutter SDK 3.0+ (Android, iOS, macOS, Linux, Windows listos para compilar)

## Instalación y uso

### 1. Configurar el servidor

Desde la raíz del proyecto:

```bash
# Windows
start-server.bat

# Linux/macOS
bash start-server.sh
```

Esto instala dependencias y lanza el servidor en `http://localhost:3000`.

Por defecto, el servidor escucha en puerto **3000**. Para cambiar:

```bash
PORT=5000 npm start
```

### 2. Obtén la dirección IP/puerto del servidor

Si está en otra máquina o es un servidor público:

```bash
# Obtén la IP local (Linux/macOS)
ipconfig (Windows) / ifconfig (Linux/macOS)

# O si está en la nube
# Usa la URL pública: https://tuservidor.com:3000
```

### 3. Ejecutar la app

```bash
flutter run
```

Aparece la pantalla de inicio. Ingresa la URL del servidor (ej: `http://192.168.1.10:3000`).

Luego:
- **DM**: Botón "Crear sala" → elige monstruos → "Iniciar partida"
- **Jugadores**: Botón "Unirse a sala" → ingresa código + nombre → crea personaje → entra a la batalla

## Estructura del código

```
lib/
  models/
    ability.dart, character.dart, character_class.dart, race.dart
    monster.dart, battle_monster.dart, item.dart, player_info.dart
  data/
    races_data.dart (8 razas), classes_data.dart (8 clases)
    monsters_data.dart (8 monstruos), items_data.dart (8 objetos)
  services/
    game_session.dart (estado central, sincronización con servidor)
    socket_service.dart (cliente Socket.IO)
    server_prefs.dart (persiste dirección del servidor)
  screens/
    home_screen.dart (selecciona servidor)
    create_room_screen.dart (DM crea sala)
    join_room_screen.dart (Jugador se une)
    dm/ → dm_lobby_screen.dart (DM espera), dm_battle_screen.dart (batalla)
    player/ → player_lobby_screen.dart (Jugador espera), player_battle_screen.dart (batalla)
    character_creation/ → character_creation_flow.dart + steps/
  widgets/
    character_sheet_view.dart, stat_row.dart, selectable_card.dart
  utils/
    dice.dart (rollDice), turn_label.dart

server/
  index.js (servidor Socket.IO express)
  src/rooms.js (lógica de salas, batalla, objetos)
  package.json
```

## Próximas iteraciones

1. **Acciones más complejas**: tiradas de ataque (d20), bonos de habilidad, tiros de defensa
2. **Hechizos y habilidades especiales**: catálogo de hechizos por clase, costos de maná/acciones
3. **Objetos mágicos persistentes**: guardar/cargar campañas
4. **Mapas/tablero en vivo**: grid de combate, movimiento de personajes y enemigos
5. **Voz/video**: integración de Twilio/Agora para llamadas en la app
6. **Historial de sesiones**: guardar partidas, logs, experiencia ganada

## Tecnología

- **Frontend**: Flutter (Dart) con Provider para state management
- **Backend**: Node.js + Express + Socket.IO para sincronización en tiempo real
- **Real-time**: WebSockets (Socket.IO)
- **Base de datos**: (Próximo) MongoDB/Firestore para persistencia

## Licencia

MIT
