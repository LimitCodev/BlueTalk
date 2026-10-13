# Plan 07 — `apk-release` (Ola 3, esfuerzo M)

**Depende de:** Ola 2 completa (todas las features).
**Rutas dueñas:** `android/**`, `docs/play/**`, `scripts/build*`.
**Lee:** `docs/plan/00-PLAN-MAESTRO.md`.

## Misión

Producir el **APK funcional de release** optimizado para celulares de bajos recursos y dejar todo listo para Play Store (AAB, firma, checklist).

## Alcance detallado

1. **Optimización de tamaño y arranque**
   - `flutter build apk --release --analyze-size` → revisar y reducir (quitar assets no usados, tree-shaking de iconos/fuentes activado).
   - Objetivo: **APK ≤15 MB por ABI**; `--split-per-abi` para descargas por arquitectura.
   - `--obfuscate --split-debug-info` para release (símbolos guardados aparte para crash reports).
   - Probar `--dart-define=USE_SUPABASE=false` como build por defecto de tienda (MVP local).

2. **Configuración Android** (`android/`)
   - `minSdk 24`, `targetSdk` vigente de Play (36 en 2026; verificar), `applicationId com.limitcodev.bluetalk`.
   - Permisos mínimos: `INTERNET` (solo si `USE_SUPABASE`), `POST_NOTIFICATIONS` (si aplica recordatorios). Nada más.
   - Icono adaptativo (logo existente) + splash de la paleta pastel.
   - `android:largeHeap="false"` (forzar código liviano) y `extractNativeLibs=false`.

3. **Rendimiento en gama baja** (`docs/play/PERFORMANCE.md`)
   - Prueba en emulador API 24 / Android Go: arranque en frío <3 s, scroll de grids sin jank, memoria pico <200 MB.
   - Checklist: sin work en `build()`, imágenes decodificadas con `cacheWidth`, listas lazy, Modo calma sin filters caros en pantallas grandes.

4. **Firma y builds**
   - Keystore de release con passphrase en variables de entorno (**no** en el repo); `key.properties` en `.gitignore`.
   - Script `scripts/build_release.sh`: genera APK + AAB, verifica tamaño, imprime hashes.

5. **Play Store** (`docs/play/CHECKLIST.md`)
   - Cuenta Play ($25 confirmado en revisión), categorías (Educativo/Familias), clasificación por contenido (IARC), Data Safety form (datos locales; Supabase futuro), política de privacidad URL (GitHub Pages gratis), pantalla de "Diseñado para Familias".
   - Capturas: 4–6 screenshots del flujo niño + uno del modo padre.
   - Store listing texto (ES) corto y preciso.

6. **Verificación de seguridad final**
   - Grep de nombres reales (Laura, San Miguel) y datos reales en todo el repo → 0 hits.
   - Grep de claves → 0 hits.
   - `flutter analyze` + `flutter test` en verde.

## Fuera de alcance

Publicar en Play (lo hace el usuario), CI/CD de releases automáticos (futuro), crash reporting.

## Commits previstos (ejemplos)

```
CHORE: configuracion android con applicationid y sdk de play
FIX: permisos minimales en el manifest de release
PERF: split por abi y obfuscado para apk de 12mb
CHORE: keystore de release fuera del repositorio
CHORE: script de build de release con verificacion de tamano
DOCS: checklist de publicacion en play store
DOCS: guia de rendimiento en dispositivos de gama baja
```

## Criterios de aceptación

- [ ] APK release instalable en API 24 con 1 GB RAM; arranque <3 s.
- [ ] Tamaño por ABI ≤15 MB.
- [ ] Grep de nombres/claves reales: 0 hits.
- [ ] `flutter analyze` 0 issues; tests verdes.
- [ ] AAB generado; checklist de Play completo.
- [ ] Keystore y claves ausentes del repo (`git status` limpio).
