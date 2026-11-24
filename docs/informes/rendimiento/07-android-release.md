# Rendimiento — Android y release

Archivos: `android/app/build.gradle.kts`, `android/app/src/*/AndroidManifest.xml`,
`scripts/build-apk.sh`, `scripts/build-aab.sh`, `pubspec.yaml`.

## Configuración actual (verificada)

- **R8 activo** en release: `isMinifyEnabled = true` y
  `isShrinkResources = true` (`build.gradle.kts`). El AAB además se compila
  con `--obfuscate --split-debug-info` (`scripts/build-aab.sh`).
- **Un APK por arquitectura** en `scripts/build-apk.sh` con
  `--split-per-abi`; se reparte el `arm64-v8a` como `dist/BlueTalk.apk`.
- **Permisos mínimos**: la edición Play solo declara avisos y reinicio. La
  edición `directa` añade `PACKAGE_USAGE_STATS`, `INTERNET` y la VPN local;
  Play no los lleva (decisión de ruta A).
- **Sin backup**: `allowBackup=false` y reglas de extracción; los datos del
  menor no salen del dispositivo.
- **Imágenes de la mascota** con `cacheWidth: 300` (`mascota.dart`): no se
  decodifica el PNG a tamaño completo.
- **Caché de imágenes** limitada a 20 MB en equipos con ≤ 3 GB de RAM
  (`main.dart`).
- **Desugaring** activo para `flutter_local_notifications` (Java 17).
- El APK de depuración pesa ~79 MB porque incluye todas las ABI y símbolos;
  el de release arm64 ronda los 20 MB. **No medir el peso con el debug.**

## AND-01 · La mascota en PNG ocupa 1,8 MB (P2)

`assets/mascota/` son 11 PNG de ~479 px y 140–200 KB cada uno. Con
`cacheWidth` el coste en RAM está controlado, pero el APK paga el peso.

**Arreglo pequeño**
Convertir a WebP con pérdida ligera (calidad 85) o a PNG optimizado. Suele
bajar 60–70 % sin diferencia visible a 120–300 px. Es un cambio de assets y
una línea en `pubspec.yaml`; no toca código.

**Cómo comprobarlo**
Comparar el APK release antes/después y abrir la guía en el emulador para
verificar que no hay halos.

**Riesgo** bajo.

## AND-02 · Los SVG de pictos se parsean en tiempo de ejecución (P2)

234 SVG (2,1 MB). `flutter_svg` cachea, pero el primer parseo de cada picto
cuesta CPU. La alternativa es precompilar con `vector_graphics_compiler`
(paso de build) o rasterizar a WebP por tamaño. Ver PERF-AAC-05. No se
recomienda para el próximo APK: primero medir el parseo en gama baja.

## AND-03 · No hay Baseline Profile (P2, evaluar)

Flutter puede generar un Baseline Profile con Macrobenchmark para mejorar el
arranque en frío en Android 7+. Requiere un módulo de benchmark y un teléfono
físico; no es un cambio de una tarde. Se anota como mejora futura si el
arranque medido supera ~2 s en el equipo objetivo.

## AND-04 · Verificación de release antes de publicar (obligatoria)

Cada vez que se toque `build.gradle.kts`, un plugin o un asset:

1. `./scripts/build-apk.sh` (release, split por ABI, firma).
2. Instalar el `arm64-v8a` en un teléfono real y hacer humo:
   - arranque en frío,
   - onboarding,
   - tocar 10 pictos (voz),
   - abrir el panel del adulto (PIN),
   - abrir Informes,
   - programar un recordatorio,
   - filtrar una página (solo edición directa).
3. `./scripts/build-aab.sh` y guardar símbolos + keystore fuera del repo.
4. Revisar `aapt dump badging` si cambió el manifiesto.

R8 puede romper plugins que usan reflexión; si aparece un
`ClassNotFoundException` solo en release, añadir la regla `keep` concreta en
`android/app/proguard-rules.pro` (hoy no existe porque no hizo falta).

## Lo que ya está bien

- El proyecto no incluye `QUERY_ALL_PACKAGES`; el diagnóstico de uso pide
  permiso y consulta solo apps con lanzador.
- La VPN del filtro es local y no exportada; Play no declara INTERNET.
- El AAB guarda los símbolos de ofuscación fuera del repo.
- La firma se lee de `key.properties` (gitignored); sin keystore el release
  firma con debug para no bloquear el desarrollo.
- `flutter_local_notifications` usa `inexactAllowWhileIdle`: no exige el
  permiso de alarmas exactas, que Play revisa con lupa.
- El ícono y el tema de lanzamiento son nativos; no hay pantalla en blanco
  antes del primer frame de Flutter.

## Prueba de tamaño sugerida

```bash
./scripts/build-apk.sh
ls -lh build/app/outputs/flutter-apk/app-*-release.apk
```

Anotar el tamaño de `arm64-v8a` antes y después de cada cambio de assets. El
objetivo razonable es no crecer más de 1–2 MB por tanda.
