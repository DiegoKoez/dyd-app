# 🔧 INSTRUCCIONES COMPLETAS PARA INICIAR EL SERVIDOR DYD

## ⚠️ PROBLEMA SOLUCIONADO

**Error anterior:** "No se pudo conectar al servidor"

**Causa:** El servidor tenía errores de código (roomManager no declarado antes de usarse).

**Estado actual:** ✅ El servidor ha sido corregido y ahora funciona correctamente.

---

## ✅ PASOS PARA INICIAR EL SERVIDOR

### Opción A: Usar el Script Automático (Recomendado)

1. **Haz doble clic** en `INICIAR_SERVIDOR.bat`
2. Espera a que se abra la ventana de PowerShell/Terminal
3. **Anota la IP** que muestra (ej: `http://192.168.1.10:3000`)
4. ¡Listo! El servidor está corriendo

### Opción B: Usar PowerShell Manual

1. Abre **PowerShell** o **Terminal**
2. Escribe:
   ```powershell
   cd d:\proyectos\DYDAndroid
   node server/index.js
   ```
3. Espera a ver los mensajes de inicio
4. **Anota la IP** que aparece

---

## 📊 MENSAJES DE ÉXITO

Cuando el servidor inicia correctamente, verás:

```
Servidor DYD escuchando en puerto 3000
Accesible desde la red en http://192.168.X.X:3000
Discovery UDP en puerto 3001
IMPORTANTE: Permití el puerto 3000 en el firewall de Windows para conexiones externas.
```

✅ **Si ves estos mensajes, el servidor está funcionando correctamente.**

---

## 📱 USAR EL SERVIDOR EN LA APP

### Paso 1: Ingresar la IP

1. Abre la app DYD en tu celular
2. En la pantalla de inicio, en "Dirección del servidor"
3. Escribe la IP completa (ej: `http://192.168.1.10:3000`)
4. Toca el botón **"Probar conexión"**

### Paso 2: Verificar Conexión

- ✅ Si dice "Conexión exitosa" → ¡Sigue adelante!
- ❌ Si dice "No se pudo conectar" → Revisa los problemas abajo

### Paso 3: Crear Sala

1. Toca el botón **"Crear sala"**
2. Verás un código de 5 caracteres (ej: `A3K9M`)
3. **Copia ese código** y dáselo a tus jugadores
4. Ellos usan "Unirse a sala" y ponen el código

---

## 🔍 DIAGNÓSTICO DE PROBLEMAS

### Problema: Firewall de Windows Bloqueando

**Síntoma:** El servidor inicia pero el celular no puede conectarse.

**Solución:**

1. En la terminal donde está el servidor, presiona `Ctrl+C` para detenerlo
2. Busca en el menú inicio: **"Firewall de Windows"**
3. Ve a **"Permitir una aplicación a través del Firewall"**
4. Haz clic en **"Cambiar configuración"** (necesitas permisos de admin)
5. Busca tu app **DYDApp.exe** en la lista
6. Marca las casillas para **"Red privada"** y **"Red pública"**
7. Si no aparece, haz clic en **"Permitir otra aplicación..."**
8. Navega a la carpeta de tu app y selecciona el `.exe`
9. Reinicia el servidor

**O solución más rápida:** El script `INICIAR_SERVIDOR.bat` ya intenta agregar las reglas automáticamente.

---

### Problema: Celular y PC no están en la misma WiFi

**Síntoma:** Error de conexión aunque el servidor esté encendido.

**Solución:**

1. En tu celular, verifica que esté en la **misma red WiFi** que la PC
2. **NO uses datos móviles** en el celular
3. En la PC, abre PowerShell y escribe: `ipconfig`
4. Busca "Dirección IPv4" - debe ser algo como `192.168.1.X`
5. Asegúrate de que la IP del servidor empiece con el mismo número

---

### Problema: El servidor muestra "localhost" en vez de IP de red

**Síntoma:** Ves `http://localhost:3000` en lugar de `http://192.168.x.x:3000`

**Solución:**

1. Detén el servidor: `Ctrl+C`
2. Edita el archivo `INICIAR_SERVIDOR.bat`
3. Busca la parte que dice:
   ```batch
   for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
   ```
4. Cambia a una extracción más precisa (el script ya fue corregido)
5. Reinicia el servidor

**Opción alternativa:** Usa directamente la IP que ves en `ipconfig`:
```
192.168.1.10:3000
```

---

### Problema: Error al iniciar el servidor

**Síntoma:** La terminal muestra un error de JavaScript.

**Solución:**

1. **Cierra la terminal**
2. Abre PowerShell nuevo en `d:\proyectos\DYDAndroid`
3. Ejecuta: `node server/index.js`
4. **Copia el error completo** y muéstralo

---

### Problema: "No se pudo conectar al servidor" después de iniciar

**Solución rápida:**

1. Detén el servidor: `Ctrl+C`
2. Verifica que estés en la misma red WiFi
3. En la app del celular, borra la IP y vuelve a ingresarla
4. Asegúrate de que la IP sea `http://` y tenga el puerto `:3000`
5. Reinicia el servidor: `node server/index.js`

---

## 🚀 INICIO RÁPIDO (AUTO-COMPLETO)

### Pasos para jugar con amigos:

1. **En la PC con el servidor:**
   ```powershell
   cd d:\proyectos\DYDAndroid
   node server/index.js
   ```
   (o haz doble clic en `INICIAR_SERVIDOR.bat`)

2. **Anota la IP** que muestra la terminal

3. **En el celular del DM (Dungeon Master):**
   - Abre la app DYD
   - Escribe la IP completa
   - Toca "Probar conexión"
   - Toca "Crear sala"
   - Copia el código

4. **En los celulares de los jugadores:**
   - Abren la app DYD
   - Escribe la misma IP
   - Toca "Probar conexión"
   - Toca "Unirse a sala"
   - Pone el código del DM

5. **¡Listo!** Todos están conectados y el DM puede empezar la partida

---

## 📋 RESUMEN DE PRUEBA COMPLETA

| Paso | Acción | Resultado esperado |
|------|--------|-------------------|
| 1 | Iniciar servidor | "Servidor DYD escuchando en puerto 3000" |
| 2 | Verificar IP | `http://192.168.X.X:3000` |
| 3 | Celular: Ingresar IP | IP válida en el campo |
| 4 | Celular: Probar conexión | "Conexión exitosa" |
| 5 | Celular: Crear sala | Código de 5 letras/números |
| 6 | Jugadores: Unirse | Código copiado |
| 7 | ¡Jugar! | Batalla iniciada |

---

## 🆘 AYUDA ADICIONAL

### Comandos útiles:

| Comando | Para qué sirve |
|---------|---------------|
| `node server/index.js` | Iniciar servidor |
| `Ctrl+C` | Detener servidor |
| `ipconfig` | Ver IP de tu PC |
| `netstat -ano \| findstr 3000` | Ver si el puerto 3000 está en uso |

### Verificar si el servidor está escuchando:

Abre el navegador y entra a: `http://localhost:3000/health`

- ✅ Debería mostrar: `{"ok":true}`
- ❌ Si da error, el servidor no está corriendo

---

## 📝 REQUISITOS

Para que todo funcione necesitas:

1. ✅ **Node.js instalado** en la PC (versión 14 o superior)
2. ✅ **Servidor iniciado** con `node server/index.js`
3. ✅ **Celular y PC en la misma red WiFi**
4. ✅ **Firewall de Windows** permitiendo el puerto 3000
5. ✅ **App DYD instalada** en el celular

---

## 💡 CONSEJOS

1. **Siempre inicia el servidor primero** antes de abrir la app
2. **Usa la misma red WiFi** para todos los dispositivos
3. **Guarda la IP** del servidor para no tener que escribirla cada vez
4. **Si el servidor se congela**, deténlo con `Ctrl+C` y reinicia
5. **El script INICIAR_SERVIDOR.bat** ya configura el firewall automáticamente

---

## 🎯 VERIFICACIÓN FINAL

**Antes de jugar, verifica:**

- [ ] El servidor está corriendo (ver consola)
- [ ] Ves "Accesible desde la red en http://X.X.X.X:3000"
- [ ] Celular y PC están en la misma WiFi
- [ ] La IP en la app es correcta (con `http://` y `:3000`)
- [ ] El botón "Probar conexión" dice "Conexión exitosa"
- [ ] Se muestra el código de la sala

**¡Si todos los checkboxes están marcados, ¡puedes jugar!**

---

**Fecha de actualización:** 25 de agosto de 2026  
**Versión corregida:** Server bug de roomManager solucionado
