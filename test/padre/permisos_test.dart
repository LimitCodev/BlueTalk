import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_controller.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_model.dart';
import 'package:bluetalk/features/padre/monitoreo/uso_telefono_gateway.dart';
import 'package:bluetalk/features/padre/permisos/permiso_model.dart';
import 'package:bluetalk/features/padre/permisos/permisos_asistente_screen.dart';
import 'package:bluetalk/features/padre/permisos/permisos_controller.dart';
import 'package:bluetalk/features/padre/permisos/permisos_gateway.dart';
import 'package:bluetalk/features/padre/filtro_web/filtro_web_controller.dart';
import 'package:bluetalk/features/padre/filtro_web/filtro_web_gateway.dart';
import 'package:bluetalk/features/padre/filtro_web/filtro_web_model.dart';
import 'package:bluetalk/features/padre/padre_screen.dart';
import 'package:bluetalk/features/padre/proteccion/proteccion_controller.dart';
import 'package:bluetalk/features/padre/proteccion/proteccion_gateway.dart';

import '../core/accessibility_helper.dart';
import 'harness.dart';

/// Gateway de avisos y batería que se lleva a mano en el test.
class _PermisosFalsos implements PermisosGateway {
  _PermisosFalsos({
    this.avisos = EstadoPermiso.pendiente,
    this.bateria = EstadoPermiso.pendiente,
  });

  EstadoPermiso avisos;
  EstadoPermiso bateria;
  int peticiones = 0;

  @override
  Future<EstadoPermiso> estadoAvisos() async => avisos;

  @override
  Future<EstadoPermiso> estadoBateria() async => bateria;

  @override
  Future<bool> pedirAvisos() async {
    peticiones++;
    avisos = EstadoPermiso.concedido;
    return true;
  }

  @override
  Future<bool> pedirBateria() async {
    peticiones++;
    bateria = EstadoPermiso.concedido;
    return true;
  }
}

/// «Acceso al uso» con el estado fijado por el test.
class _UsoFalso implements UsoTelefonoGateway {
  _UsoFalso(this.concedido, {this.estado});

  bool concedido;

  /// Fija un «no se pudo comprobar» de verdad, para el test que comprueba
  /// que un fallo de consulta no se convierte en bloqueo.
  EstadoPermiso? estado;

  @override
  Future<bool> estaPermitido() async => concedido;

  @override
  Future<EstadoPermiso> estadoPermiso() async =>
      estado ??
      (concedido ? EstadoPermiso.concedido : EstadoPermiso.pendiente);

  @override
  Future<bool> abrirAjustes() async {
    concedido = true;
    estado = null;
    return true;
  }

  @override
  Future<ResumenUso> resumen(DateTime desde, DateTime hasta) async =>
      ResumenUso.sinPermiso(desde, hasta);
}

/// Administrador del dispositivo con el estado fijado por el test.
class _AdminFalso implements ProteccionGateway {
  _AdminFalso(this.activo);

  bool activo;
  int activaciones = 0;

  @override
  Future<ProteccionEstado> estado() async => ProteccionEstado(activo: activo);

  @override
  Future<bool> pedirActivacion() async {
    activaciones++;
    activo = true;
    return true;
  }

  @override
  Future<void> desactivar() async {
    activo = false;
  }
}

/// Los gateways del asistente que no son de permisos, decididos por el test.
/// El de permisos vive en [overridesDePadre] (o en [_fuentes]) para no
/// declarar la misma doble dos veces en el mismo contenedor.
List<Object> _gateways({
  bool usoConcedido = true,
  EstadoPermiso? usoEstado,
  bool adminActivo = true,
}) =>
    [
      usoTelefonoGatewayProvider.overrideWithValue(
        _UsoFalso(usoConcedido, estado: usoEstado),
      ),
      proteccionGatewayProvider.overrideWithValue(_AdminFalso(adminActivo)),
    ];

/// [_gateways] más las preferencias y el canal de permisos: sin ellas
/// `filtroWebProvider` (que el asistente consulta) lanza
/// `UnimplementedError` y el diagnóstico no termina nunca.
List<Object> _fuentes(
  SharedPreferences prefs, {
  PermisosGateway? permisos,
  bool usoConcedido = true,
  EstadoPermiso? usoEstado,
  bool adminActivo = true,
}) =>
    [
      sharedPreferencesProvider.overrideWithValue(prefs),
      permisosGatewayProvider.overrideWithValue(permisos ?? _PermisosFalsos()),
      ..._gateways(
        usoConcedido: usoConcedido,
        usoEstado: usoEstado,
        adminActivo: adminActivo,
      ),
    ];

/// Filtro con el estado que fije el test: sirve para emular el canal
/// nativo caído (`comprobado == false`).
class _FiltroFalso implements FiltroWebGateway {
  _FiltroFalso(this.estadoFijo);

  final FiltroWebEstado estadoFijo;

  @override
  Future<FiltroWebEstado> estado() async => estadoFijo;

  @override
  Future<bool> activar() async => false;

  @override
  Future<void> desactivar() async {}

  @override
  Future<void> actualizar(FiltroWebConfig config) async {}

  @override
  Future<void> limpiarRegistro() async {}

  @override
  Future<bool> abrirAjustesVpn() async => false;

  @override
  Future<bool> abrirAjustesDns() async => false;
}

/// Diagnóstico completo con el filtro encendido y el estado de VPN que se
/// le pida: es lo que hace el canal nativo en un teléfono real.
Future<PermisosEstado> _diagnostico({required FiltroWebEstado filtro}) async {
  final prefs = await prefsDePrueba(
    iniciales: {'padre_filtro_web_activo': true},
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      permisosGatewayProvider.overrideWithValue(
        _PermisosFalsos(
          avisos: EstadoPermiso.concedido,
          bateria: EstadoPermiso.concedido,
        ),
      ),
      usoTelefonoGatewayProvider.overrideWithValue(_UsoFalso(true)),
      proteccionGatewayProvider.overrideWithValue(_AdminFalso(true)),
      filtroWebGatewayProvider.overrideWithValue(_FiltroFalso(filtro)),
    ],
  );
  addTearDown(container.dispose);
  return container.read(permisosProvider.future);
}

void main() {
  group('PermisosEstado', () {
    test('bloquea solo con un obligatorio que Android marcó como pendiente',
        () {
      const conPendienteObligatorio = PermisosEstado([
        PermisoPadre(
          id: PermisoId.avisos,
          titulo: 'Avisos',
          paraQueSirve: 'x',
          queNoLee: 'y',
          estado: EstadoPermiso.pendiente,
          requerido: true,
        ),
      ]);
      expect(conPendienteObligatorio.faltanRequeridos, isTrue);

      const soloOpcional = PermisosEstado([
        PermisoPadre(
          id: PermisoId.administrador,
          titulo: 'Admin',
          paraQueSirve: 'x',
          queNoLee: 'y',
          estado: EstadoPermiso.pendiente,
          requerido: false,
        ),
      ]);
      expect(soloOpcional.faltanRequeridos, isFalse);
    });

    test(
        'un «no se pudo comprobar» no bloquea, para no dejar al adulto '
        'sin salida', () {
      const desconocido = PermisosEstado([
        PermisoPadre(
          id: PermisoId.uso,
          titulo: 'Uso',
          paraQueSirve: 'x',
          queNoLee: 'y',
          estado: EstadoPermiso.desconocido,
          requerido: true,
        ),
      ]);
      expect(desconocido.faltanRequeridos, isFalse);
      expect(desconocido.pendientes, isEmpty);
    });

    test('todo concedido deja pasar', () {
      const listo = PermisosEstado([
        PermisoPadre(
          id: PermisoId.avisos,
          titulo: 'Avisos',
          paraQueSirve: 'x',
          queNoLee: 'y',
          estado: EstadoPermiso.concedido,
          requerido: true,
        ),
      ]);
      expect(listo.faltanRequeridos, isFalse);
    });
  });

  group('asistente de permisos', () {
    Future<void> bombear(
      WidgetTester tester, {
      PermisosGateway? permisos,
      bool usoConcedido = true,
      EstadoPermiso? usoEstado,
      bool adminActivo = true,
    }) async {
      final prefs = await prefsDePrueba();
      await tester.pumpWidget(
        ProviderScope(
          overrides: _fuentes(
            prefs,
            permisos: permisos,
            usoConcedido: usoConcedido,
            usoEstado: usoEstado,
            adminActivo: adminActivo,
          ).cast(),
          child: const MaterialApp(
            home: Scaffold(body: PermisosAsistenteScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('explica qué se pide y qué no se lee', (tester) async {
      await bombear(tester);

      expect(find.text('Permisos del teléfono'), findsOneWidget);
      expect(find.text('Avisos del teléfono'), findsOneWidget);
      expect(find.text('Acceso al uso de las apps'), findsOneWidget);
      expect(
        find.textContaining('Todavía no se puede avanzar'),
        findsOneWidget,
        reason: 'faltan los avisos, que son obligatorios',
      );
      expect(find.textContaining('informes semanal y mensual'), findsOneWidget);
      // La lista es perezosa: la tarjeta de batería queda más abajo.
      await tester.scrollUntilVisible(
        find.text('Batería sin ahorro para BlueTalk'),
        200,
      );
      expect(find.text('Batería sin ahorro para BlueTalk'), findsOneWidget);
      expect(find.textContaining('No lee:'), findsWidgets);
      expect(find.textContaining('necesario'), findsWidgets);
    });

    testWidgets('tocar un permiso pendiente pide el permiso al sistema',
        (tester) async {
      final falso = _PermisosFalsos();
      await bombear(tester, permisos: falso);

      expect(falso.peticiones, 0);
      await tester.tap(find.text('Avisos del teléfono'));
      await tester.pumpAndSettle();

      expect(falso.peticiones, 1);
      expect(find.textContaining('Avisos del teléfono'), findsOneWidget);
    });

    testWidgets('con todo concedido ya no se pide nada', (tester) async {
      await bombear(
        tester,
        permisos: _PermisosFalsos(
          avisos: EstadoPermiso.concedido,
          bateria: EstadoPermiso.concedido,
        ),
      );

      expect(find.textContaining('Concedido'), findsWidgets);
      expect(find.textContaining('Todavía no se puede avanzar'), findsNothing);
    });

    testWidgets('solo lo opcional pendiente no bloquea el avance',
        (tester) async {
      await bombear(
        tester,
        permisos: _PermisosFalsos(
          avisos: EstadoPermiso.concedido,
          bateria: EstadoPermiso.pendiente,
        ),
        adminActivo: false,
      );

      expect(find.textContaining('Todavía no se puede avanzar'), findsNothing);
      expect(find.textContaining('Falta concederlo'), findsWidgets);
    });

    testWidgets(
        'un «no se pudo comprobar» del uso no bloquea ni se disfraza de '
        'falta', (tester) async {
      await bombear(
        tester,
        permisos: _PermisosFalsos(
          avisos: EstadoPermiso.concedido,
          bateria: EstadoPermiso.concedido,
        ),
        usoEstado: EstadoPermiso.desconocido,
      );

      expect(find.textContaining('No se pudo comprobar'), findsOneWidget);
      expect(find.textContaining('Todavía no se puede avanzar'), findsNothing);
    });

    testWidgets('el asistente es accesible', (tester) async {
      final prefs = await prefsDePrueba();
      await expectSinProblemasDeAccesibilidad(
        tester,
        overrides: _fuentes(prefs),
        home: const Scaffold(body: PermisosAsistenteScreen()),
      );
    });
  });

  group('paso obligatorio antes del panel', () {
    /// Preferencias con la legal aceptada y el PIN «1234» ya creado.
    Future<SharedPreferences> prefsDeSesion() async {
      final prefs = await prefsDePrueba(
        iniciales: {'padre_legal_aceptacion': aceptacionLegalDePrueba()},
      );
      await crearPinDePrueba(prefs);
      return prefs;
    }

    Future<void> entrar(WidgetTester tester) async {
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pump();
      await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
      await tester.pumpAndSettle();
    }

    testWidgets('mientras falte un permiso obligatorio no aparece el panel',
        (tester) async {
      final prefs = await prefsDeSesion();
      await pumpPadre(
        tester,
        home: PadreScreen(onSalir: () {}),
        overrides: [
          ...overridesDePadre(prefs, permisos: _PermisosFalsos()),
          ..._gateways(),
        ],
      );

      expect(find.text('Escribe tu código'), findsOneWidget);

      await entrar(tester);

      expect(find.byType(NavigationBar), findsNothing,
          reason: 'no se puede avanzar sin los permisos obligatorios');
      expect(find.text('Uso del día'), findsNothing);
      // En modo paso manda la cabecera de PadreScreen («Modo padre»), no
      // la del asistente empujado desde Control.
      expect(find.text('Modo padre'), findsOneWidget);
      expect(find.textContaining('Todavía no se puede avanzar'), findsOneWidget);
      // La salida siempre está, para no dejar al adulto encerrado.
      expect(find.byTooltip('Salir del modo padre'), findsOneWidget);
    });

    testWidgets('con todo concedido el panel se enseña y no estorba',
        (tester) async {
      final prefs = await prefsDeSesion();
      await pumpPadre(
        tester,
        home: PadreScreen(onSalir: () {}),
        overrides: [
          ...overridesDePadre(
            prefs,
            permisos: _PermisosFalsos(
              avisos: EstadoPermiso.concedido,
              bateria: EstadoPermiso.concedido,
            ),
          ),
          ..._gateways(),
        ],
      );

      await entrar(tester);

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.text('Uso del día'), findsOneWidget);
      expect(find.textContaining('Todavía no se puede avanzar'), findsNothing);
    });

    testWidgets(
        'si el adulto revoca un permiso fuera de la app, al volver se '
        'vuelve a comprobar', (tester) async {
      final prefs = await prefsDeSesion();
      final avisos = _PermisosFalsos(
        avisos: EstadoPermiso.concedido,
        bateria: EstadoPermiso.concedido,
      );
      await pumpPadre(
        tester,
        home: PadreScreen(onSalir: () {}),
        overrides: [
          ...overridesDePadre(prefs, permisos: avisos),
          ..._gateways(),
        ],
      );
      await entrar(tester);
      expect(find.byType(NavigationBar), findsOneWidget,
          reason: 'con los permisos concedidos el panel se enseña');

      // Con la app detrás, el adulto revoca el permiso desde Android.
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.paused);
      avisos.avisos = EstadoPermiso.pendiente;
      tester.binding
          .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing,
          reason: 'una caché vieja no puede dejar pasar el panel');
      expect(find.textContaining('Todavía no se puede avanzar'), findsOneWidget);
      expect(find.text('Uso del día'), findsNothing);
    });
  });

  group('tri-estado: un fallo de consulta no se vuelve bloqueo', () {
    test('la VPN sin canal se enseña «no se pudo comprobar» y no bloquea',
        () async {
      final estado =
          await _diagnostico(filtro: const FiltroWebEstado(comprobado: false));

      expect(estado.de(PermisoId.vpn)?.estado, EstadoPermiso.desconocido);
      expect(estado.faltanRequeridos, isFalse,
          reason: 'un canal caído no puede encerrar al adulto');
    });

    test('con el canal vivo y la VPN sin conceder sí bloquea', () async {
      final estado = await _diagnostico(
        filtro: const FiltroWebEstado(activo: true, comprobado: true),
      );

      expect(estado.de(PermisoId.vpn)?.estado, EstadoPermiso.pendiente);
      expect(estado.faltanRequeridos, isTrue);
    });
  });
}
