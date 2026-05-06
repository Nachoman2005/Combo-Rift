# Combo Rift - Checklist de preparación Android (Godot 4.6)

## 1) Mobile vertical
- [x] Proyecto en resolución base vertical (`1080x1920`).
- [x] Stretch en `canvas_items` + `expand` para adaptar relación de aspecto.
- [x] Orientación para handheld en vertical.
- [x] Board centrado horizontalmente según el ancho real del viewport.

## 2) Input touch
- [x] Las piezas aceptan `InputEventScreenTouch`.
- [x] Se mantiene compatibilidad con mouse para debug en desktop.
- [x] Activada emulación mouse<->touch en `Project Settings` para pruebas.

## 3) UI escalable (Control + anchors)
- [x] HUD dentro de `CanvasLayer` usando `MarginContainer` anclado completo.
- [x] Menús centrales con anchors al centro.
- [ ] Revisar tamaños mínimos de botones/fuentes (objetivo táctil 48dp+) en QA de dispositivos reales.

## 4) Performance gama media/baja
- [x] Renderer móvil activo (`rendering_method = mobile`).
- [x] Filtrado de texturas canvas en nearest para costo bajo.
- [x] Mantener lógica de tablero sin física pesada.
- [ ] Activar en export Android `Optimize > Strip Debug Symbols` para release.
- [ ] Probar FPS en al menos 2 perfiles: gama baja (2-3 GB RAM) y media (4-6 GB RAM).

## 5) Exportación Android (paso a paso)

### Project Settings (recomendado)
- Display
  - `window/size/viewport_width = 1080`
  - `window/size/viewport_height = 1920`
  - `window/stretch/mode = canvas_items`
  - `window/stretch/aspect = expand`
  - `window/handheld/orientation = Portrait`
- Rendering
  - `renderer/rendering_method = mobile`
- Input Devices
  - `pointing/emulate_mouse_from_touch = true` (útil en UI híbrida)
- GUI
  - `common/snap_controls_to_pixels = true`

### Export Preset (Android)
- [ ] Install Android Build Template desde Editor (si aún no está).
- [ ] Crear preset **Android** (Release + Debug).
- [ ] Keystore:
  - Debug para pruebas internas.
  - Release keystore para producción (guardado seguro).
- [ ] Architecture: incluir `arm64-v8a` (mínimo recomendado hoy).
- [ ] Min SDK: usar valor compatible con Godot 4.6 y tu plugin stack.
- [ ] Target SDK: actualizar al requerido por Google Play vigente.

### Android package name
- **Sugerido:** `com.halfuforwardgames.comborift`
- Debe ir en Export Preset > Package > Unique Name.

### Permisos mínimos (sin extras)
- Mantener solo los que Android/Godot requiera por defecto para ejecución.
- **No** agregar permisos sensibles si no se usan (ubicación, contactos, cámara, micrófono, archivos compartidos, etc.).
- Para integración futura de AdMob:
  - normalmente se usa `INTERNET` y `ACCESS_NETWORK_STATE`.
  - no añadir más hasta integrar SDK real y validar manifiesto final.

## 6) Preparado para futura integración AdMob
- [x] Existe `AdsManager` desacoplado (mock), con puntos de entrada:
  - banner: `show_banner()` / `hide_banner()`
  - interstitial: `show_interstitial()`
  - rewarded: `show_rewarded_continue()`
- [ ] Próximo paso: reemplazar implementación mock por plugin Android (AdMob) manteniendo la misma API pública.
- [ ] Al integrar plugin:
  - definir App ID + Ad Unit IDs por entorno.
  - agregar `INTERNET` y `ACCESS_NETWORK_STATE`.
  - validar flujo de consentimiento (si aplica por región/edad).

## 7) QA rápido previo a subir APK/AAB
- [ ] Arranque en frío < 5s en dispositivo medio.
- [ ] Menú y gameplay sin UI cortada en 19.5:9 y 20:9.
- [ ] Sin taps fantasma: swap de piezas estable.
- [ ] Pausa/reanudar sin congelar estado.
- [ ] Game over + continue rewarded funcional (cuando se conecte SDK).
