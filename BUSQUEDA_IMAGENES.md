# 🔍 MEJORAS DE BÚSQUEDA DE IMÁGENES

**Fecha:** 25 de agosto de 2026

---

## ✨ NUEVAS FUNCIONALIDADES

### 1. **Búsqueda en Internet Mejorada**

Ahora cuando el DM busca una imagen para un objeto o arma, el sistema:

- ✅ **Busca en internet** usando Unsplash y LoremFlickr
- ✅ **Muestra múltiples opciones** (hasta 12 imágenes)
- ✅ **Permite seleccionar** la imagen preferida
- ✅ **Carga la imagen** automáticamente al seleccionarla

### 2. **Opción de Iconos por Defecto**

Si no quiere buscar en internet o la búsqueda falla:

- ✅ **Iconos por defecto** disponibles inmediatamente
- ✅ **10 iconos de objetos** (🗡️, 🔱, 💍, 📜, etc.)
- ✅ **8 iconos de armas** (🗡️, ⚔️, 🔪, 🏹, etc.)
- ✅ **Seleccionar con un clic** sin necesidad de búsqueda

### 3. **Detección Automática de Tipo**

El sistema detecta automáticamente si es arma u objeto:

- **Armas:** efectos 'fuego', 'hielo', 'veneno', 'otro'
- **Objetos:** todos los demás efectos

---

## 🎨 NUEVOS ICONOS POR DEFECTO

### Iconos de Objetos (10 opciones):
1. 🗡️ Espada
2. 🔱 Escudo
3. 💍 Anillo
4. 📜 Pergamino
5. 🔮 Cristal
6. 🍷 Poción
7. 🪙 Moneda
8. 📖 Libro
9. 🏺 Jarrón
10. 🔨 Herramienta

### Iconos de Armas (8 opciones):
1. 🗡️ Espada
2. ⚔️ Espada Doble
3. 🔪 Daga
4. 🏹 Arco
5. 🛡️ Escudo
6. 🗼 Mazo
7. 🌪️ Lanza
8. 🪃 Dardo

---

## 📱 INTERFAZ MEJORADA

### Flujo de Búsqueda:

```
┌─────────────────────────────────────┐
│  Imagen del objeto/arma              │
├─────────────────────────────────────┤
│  [Buscar en Internet]   [Icono]     │
│  [📷 Cámara]  [📚 Galería]         │
├─────────────────────────────────────┤
│  Opción 1: Buscar en internet        │
│    - Busca en Unsplash/LoremFlickr   │
│    - Muestra múltiples resultados    │
│    - Permite seleccionar             │
├─────────────────────────────────────┤
│  Opción 2: Usar icono por defecto    │
│    - 10 iconos de objetos            │
│    - 8 iconos de armas               │
│    - Selección rápida                │
├─────────────────────────────────────┤
│  Opción 3: Tomar foto                │
│    - Cámara                         │
│    - Galería                        │
└─────────────────────────────────────┘
```

### Botones de Acción:

1. **Buscar en Internet**
   - Abre búsqueda en internet
   - Muestra resultados
   - Permite seleccionar

2. **Icono**
   - Muestra iconos por defecto
   - Selección rápida
   - Sin necesidad de búsqueda

3. **📷 Cámara**
   - Toma foto con cámara
   - Sube imagen automáticamente

4. **📚 Galería**
   - Selecciona de galería
   - Sube imagen automáticamente

---

## 🔄 FLUJO DE USO

### Caso 1: Buscar imagen en internet

1. DM selecciona objeto (ej: "Espada de fuego")
2. Pulsa "Agregar imagen"
3. Se abre diálogo de búsqueda
4. Pulsa "Buscar en Internet"
5. Aparecen resultados de búsqueda
6. DM selecciona imagen
7. Sistema carga imagen
8. DM confirma
9. Imagen aparece en el objeto

### Caso 2: Usar icono por defecto

1. DM selecciona objeto (ej: "Poción de vida")
2. Pulsa "Agregar imagen"
3. Se abre diálogo de búsqueda
4. Pulsa "Icono"
5. Aparecen iconos por defecto
6. DM selecciona icono 🍷
7. Confirma
8. Icono aparece en el objeto

### Caso 3: Tomar foto

1. DM selecciona objeto
2. Pulsa "Agregar imagen"
3. Se abre diálogo de búsqueda
4. Pulsa "📚 Galería"
5. Selecciona foto
6. Confirma
7. Foto aparece en el objeto

### Caso 4: Búsqueda falla

1. DM intenta buscar en internet
2. Búsqueda falla (API no responde)
3. Sistema muestra mensaje de error
4. DM puede elegir:
   - Intentar de nuevo
   - Usar icono por defecto
   - Tomar foto manualmente

---

## 📁 ARCHIVOS MODIFICADOS

| Archivo | Cambios | Líneas |
|---------|---------|--------|
| `lib/widgets/image_search_dialog.dart` | Mejorar búsqueda, añadir iconos por defecto | ~+150 |
| `lib/screens/dm/give_item_sheet.dart` | Actualizar llamada a showImageSearchDialog | +2 |
| `lib/screens/dm/create_item_dialog.dart` | Actualizar llamada a showImageSearchDialog | +2 |
| `lib/screens/dm/weapon_assignment_screen.dart` | Actualizar llamada a showImageSearchDialog | +2 |

---

## 💻 CÓDIGO CLAVE

### Función principal actualizada:

```dart
/// Función principal para mostrar el diálogo de búsqueda de imágenes
/// [isWeapon] si es true, muestra iconos de armas, si es false muestra iconos de objetos
Future<String?> showImageSearchDialog(
  BuildContext context, 
  String query, 
  {bool isWeapon = false}
) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => ImageSearchDialog(query: query, isWeapon: isWeapon),
  );
}
```

### Detección automática de tipo:

```dart
// Determinar si es arma u objeto basado en el efecto
final isWeapon = ['fuego', 'hielo', 'veneno', 'otro'].contains(effect);
final base64 = await showImageSearchDialog(
  context, 
  itemName, 
  isWeapon: isWeapon
);
```

### Toggle entre icono e imagen:

```dart
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
```

---

## 🧪 PRUEBAS DE VERIFICACIÓN

### Prueba 1: Búsqueda en internet
1. DM da objeto "Espada de fuego"
2. Pulsa "Agregar imagen"
3. Pulsa "Buscar en Internet"
4. **Resultado esperado:** Aparecen 12 imágenes de espadas
5. DM selecciona una imagen
6. **Resultado esperado:** Imagen se carga y muestra

### Prueba 2: Icono por defecto
1. DM da objeto "Poción de vida"
2. Pulsa "Agregar imagen"
3. Pulsa "Icono"
4. **Resultado esperado:** Aparecen 10 iconos de objetos
5. DM selecciona 🍷
6. **Resultado esperado:** Icono se selecciona

### Prueba 3: Tomar foto
1. DM da objeto personalizado
2. Pulsa "Agregar imagen"
3. Pulsa "📚 Galería"
4. **Resultado esperado:** Se abre selector de fotos
5. DM selecciona foto
6. **Resultado esperado:** Foto se sube correctamente

### Prueba 4: Búsqueda falla
1. DM intenta buscar en internet
2. Simula error de conexión
3. **Resultado esperado:** Sistema muestra mensaje de error
4. DM pulsa "Icono"
5. **Resultado esperado:** Iconos por defecto aparecen

### Prueba 5: Detección automática
1. DM selecciona arma (efecto "fuego")
2. Pulsa "Agregar imagen"
3. **Resultado esperado:** Aparecen 8 iconos de armas
4. DM selecciona objeto (efecto "magia")
5. Pulsa "Agregar imagen"
6. **Resultado esperado:** Aparecen 10 iconos de objetos

---

## ✨ BENEFICIOS

### Para el Dungeon Master:
- ✅ **Más rapidez:** Iconos por defecto sin necesidad de búsqueda
- ✅ **Más variedad:** Múltiples imágenes para elegir
- ✅ **Flexibilidad:** Buscar en internet o usar icono
- ✅ **Facilidad:** Selección rápida con un clic

### Para la Experiencia de Juego:
- ✅ **Más visual:** Objetos con imágenes reales
- ✅ **Más inmersivo:** Imágenes que representan los objetos
- ✅ **Más profesional:** Imágenes de calidad (Unsplash)
- ✅ **Más personal:** DM puede elegir la imagen perfecta

---

## 🔧 CONFIGURACIÓN

### API de Búsqueda:

**Unsplash Source** (Principal):
- URL: `https://source.unsplash.com/320x240/?query`
- Pros: Imágenes profesionales de alta calidad
- Contras: Puede tardar en cargar

**LoremFlickr** (Fallback):
- URL: `https://loremflickr.com/320/240/query`
- Pros: Más rápido, siempre disponible
- Contras: Imágenes menos profesionales

**Uso en el código:**
```dart
final urls = [
  'https://source.unsplash.com/320x240/?$encoded,weapon',
  'https://source.unsplash.com/320x240/?$encoded,armor',
  'https://source.unsplash.com/320x240/?$encoded,tool',
  'https://source.unsplash.com/320x240/?$encoded,item',
  'https://source.unsplash.com/320x240/?$encoded,gaming',
];

// Fallback si falla
final fallbackUrls = [
  for (var i = 0; i < 9; i++)
    'https://loremflickr.com/320/240/$encoded?random=$i',
];
```

---

## 📝 NOTAS ADICIONALES

### Limitaciones:
- Las imágenes de internet requieren conexión a internet
- Algunas imágenes pueden tardar en cargar
- Unsplash puede tener imágenes inapropiadas (DM debe verificar)

### Mejoras Futuras Posibles:
- Agregar filtro por categoría (fantasía, medieval, moderno, etc.)
- Permitir subir imagen desde servidor
- Agregar opción para recortar imagen
- Agregar opción para rotar imagen
- Agregar opción para ajustar brillo/contraste

---

**Desarrollador:** Asistente AI  
**Estado:** ✅ Implementado y listo para probar
