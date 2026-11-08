import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Límite de tamaño por archivo (evita «archivos Dios»).
///
/// Trinquete: un archivo nuevo no pasa de [limite] líneas, y los que ya lo
/// superaban solo pueden encoger. Al bajar de [limite], bórralo de
/// [_deuda]; al partir uno, baja su número. Nunca subas un número.
const limite = 100;

const _deuda = <String, int>{
  'lib/app/router.dart': 101,
  'lib/app/shell.dart': 111,
  'lib/core/theme/app_colors.dart': 339,
  'lib/core/theme/app_theme.dart': 213,
  'lib/core/widgets/logo_bluetalk.dart': 136,
  'lib/features/ajustes/ajustes_screen.dart': 589,
  'lib/features/comunicador/comunicador_screen.dart': 602,
  'lib/features/comunicador/phrase_bar.dart': 203,
  'lib/features/comunicador/tts_service.dart': 138,
  'lib/features/entorno/entorno_screen.dart': 183,
  'lib/features/juegos/artista/artista_controller.dart': 191,
  'lib/features/juegos/artista/artista_dibujos.dart': 137,
  'lib/features/juegos/artista/artista_screen.dart': 453,
  'lib/features/juegos/avance_juegos.dart': 171,
  'lib/features/juegos/cuentos/cuentos_controller.dart': 288,
  'lib/features/juegos/cuentos/cuentos_screen.dart': 481,
  'lib/features/juegos/juegos_screen.dart': 142,
  'lib/features/juegos/memoria/memoria_controller.dart': 194,
  'lib/features/juegos/memoria/memoria_screen.dart': 298,
  'lib/features/onboarding/onboarding_screen.dart': 144,
  'lib/features/padre/control/cambiar_codigo.dart': 146,
  'lib/features/padre/control/control_parental.dart': 159,
  'lib/features/padre/control/control_screen.dart': 252,
  'lib/features/padre/control/juegos_gate.dart': 173,
  'lib/features/padre/control/recuperacion_dialogo.dart': 156,
  'lib/features/padre/dashboard/barras.dart': 107,
  'lib/features/padre/dashboard/metricas.dart': 142,
  'lib/features/padre/dashboard/resumen_screen.dart': 291,
  'lib/features/padre/diagnostico/observaciones.dart': 333,
  'lib/features/padre/filtro_web/filtro_web_controller.dart': 290,
  'lib/features/padre/filtro_web/filtro_web_gateway.dart': 122,
  'lib/features/padre/filtro_web/filtro_web_model.dart': 482,
  'lib/features/padre/filtro_web/filtro_web_screen.dart': 721,
  'lib/features/padre/gate/almacen_pin.dart': 245,
  'lib/features/padre/gate/gate_controller.dart': 254,
  'lib/features/padre/gate/gate_screen.dart': 379,
  'lib/features/padre/gate/pin_store.dart': 449,
  'lib/features/padre/gate/recuperar_screen.dart': 298,
  'lib/features/padre/legal/legal_screen.dart': 203,
  'lib/features/padre/legal/textos_legales.dart': 291,
  'lib/features/padre/monitoreo/uso_telefono_screen.dart': 494,
  'lib/features/padre/padre_screen.dart': 174,
  'lib/features/padre/perfil_edad.dart': 134,
  'lib/features/padre/permisos/permiso_model.dart': 108,
  'lib/features/padre/permisos/permisos_asistente_screen.dart': 182,
  'lib/features/padre/permisos/permisos_controller.dart': 127,
  'lib/features/padre/salud_padre/salud_screen.dart': 230,
  'lib/features/rutinas/actividad_tile.dart': 147,
  'lib/features/rutinas/editor_horario_view.dart': 378,
  'lib/features/rutinas/estadisticas_view.dart': 174,
  'lib/features/rutinas/horario_view.dart': 225,
  'lib/features/rutinas/recordatorios/recordatorio_scheduler_real.dart': 175,
  'lib/features/rutinas/recordatorios/recordatorios_controller.dart': 141,
  'lib/features/rutinas/rutinas_providers.dart': 188,
  'lib/features/rutinas/rutinas_screen.dart': 164,
  'lib/features/salud/salud_providers.dart': 122,
  'lib/features/salud/salud_screen.dart': 276,
};

void main() {
  final archivos = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  test('ningún archivo crece por encima de su tope', () {
    final excesos = <String>[];
    for (final f in archivos) {
      final n = f.readAsLinesSync().length;
      final tope = _deuda[f.path] ?? limite;
      if (n > tope) excesos.add('${f.path}: $n > $tope');
    }
    expect(excesos, isEmpty);
  });

  test('la deuda registrada es real (sin entradas viejas)', () {
    final viejas = _deuda.entries.where((e) {
      final f = File(e.key);
      return !f.existsSync() || f.readAsLinesSync().length <= limite;
    }).map((e) => e.key);
    expect(viejas, isEmpty, reason: 'Bórralas de _deuda: ya cumplen.');
  });
}
