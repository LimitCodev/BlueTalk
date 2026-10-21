import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/app/di.dart';
import 'package:bluetalk/features/padre/filtro_web/filtro_web_controller.dart';
import 'package:bluetalk/features/padre/filtro_web/filtro_web_gateway.dart';
import 'package:bluetalk/features/padre/filtro_web/filtro_web_model.dart';
import 'package:bluetalk/features/padre/filtro_web/filtro_web_screen.dart';

import 'harness.dart';

class _GatewayFalso implements FiltroWebGateway {
  bool activarOk = true;
  bool activo = false;
  int activaciones = 0;
  int desactivaciones = 0;
  int limpiezas = 0;
  FiltroWebConfig? ultimaConfig;
  List<BloqueoWeb> bloqueos = [];

  @override
  Future<FiltroWebEstado> estado() async => FiltroWebEstado(
        activo: activo,
        consentimiento: true,
        bloqueos: bloqueos,
      );

  @override
  Future<bool> activar() async {
    activaciones++;
    if (!activarOk) return false;
    activo = true;
    return true;
  }

  @override
  Future<void> desactivar() async {
    desactivaciones++;
    activo = false;
  }

  @override
  Future<void> actualizar(FiltroWebConfig config) async {
    ultimaConfig = config;
  }

  @override
  Future<void> limpiarRegistro() async {
    limpiezas++;
    bloqueos = [];
  }

  @override
  Future<bool> abrirAjustesVpn() async => true;

  @override
  Future<bool> abrirAjustesDns() async => true;
}

ProviderContainer _contenedor(
  SharedPreferences prefs,
  _GatewayFalso gateway,
) {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      filtroWebGatewayProvider.overrideWithValue(gateway),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

/// Baja la lista hasta que el campo de texto esté construido y visible.
/// `scrollUntilVisible` no sirve aquí porque el campo aún no existe y hay
/// más de un `Scrollable` (el del campo aparece al construirse).
Future<void> _irAlFormulario(WidgetTester tester) async {
  for (var i = 0; i < 6 && find.byType(TextField).evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  final campo = find.byType(TextField);
  await tester.ensureVisible(campo);
  await tester.pumpAndSettle();
}

Future<void> _tocarProhibir(WidgetTester tester) async {
  final boton = find.widgetWithText(FilledButton, 'Prohibir sitio');
  await tester.ensureVisible(boton);
  await tester.pumpAndSettle();
  await tester.tap(boton);
  await tester.pumpAndSettle();
}

void main() {
  group('normalizarDominio', () {
    test('acepta URL completa y devuelve solo el sitio', () {
      expect(
        normalizarDominio('https://www.Ejemplo.com/ruta?x=1'),
        'ejemplo.com',
      );
      expect(normalizarDominio('ejemplo.com/ruta'), 'ejemplo.com');
      expect(
        normalizarDominio('http://sub.ejemplo.com:8080/x'),
        'sub.ejemplo.com',
      );
      expect(normalizarDominio('ejemplo.com.'), 'ejemplo.com');
    });

    test('rechaza lo que DNS no puede bloquear', () {
      expect(normalizarDominio(''), isNull);
      expect(normalizarDominio('com'), isNull);
      expect(normalizarDominio('192.168.1.1'), isNull);
      expect(normalizarDominio('https://192.168.1.1/x'), isNull);
      expect(normalizarDominio('sin-punto'), isNull);
      expect(normalizarDominio('ejemplo con espacio.com'), isNull);
      expect(normalizarDominio('*'), isNull);
    });
  });

  test('dominioBloqueado cubre subdominios y no confunde sufijos', () {
    expect(dominioBloqueado('ejemplo.com', ['ejemplo.com']), isTrue);
    expect(dominioBloqueado('www.ejemplo.com', ['ejemplo.com']), isTrue);
    expect(dominioBloqueado('noejemplo.com', ['ejemplo.com']), isFalse);
    expect(dominioBloqueado('ejemplo.com.evil.com', ['ejemplo.com']), isFalse);
  });

  group('FiltroWebConfig', () {
    test('sin filtro activo no bloquea nada', () {
      const config = FiltroWebConfig();
      expect(config.estaBloqueado('pornhub.com'), isFalse);
    });

    test('las categorías y los sitios propios se bloquean', () {
      const config = FiltroWebConfig(
        activo: true,
        dominiosPersonalizados: ['ejemplo.com'],
      );
      expect(config.estaBloqueado('pornhub.com'), isTrue);
      expect(config.estaBloqueado('www.pornhub.com'), isTrue);
      expect(config.estaBloqueado('ejemplo.com'), isTrue);
      expect(config.estaBloqueado('ejemplo.com.mx'), isFalse);
      expect(config.estaBloqueado('wikipedia.org'), isFalse);
    });

    test('los dominios técnicos solo entran con el filtro activo', () {
      const apagado = FiltroWebConfig();
      const encendido = FiltroWebConfig(activo: true);
      expect(apagado.dominiosActivos, isNot(contains('dns.google')));
      expect(encendido.dominiosActivos, contains('dns.google'));
      expect(encendido.dominiosActivos, contains('use-application-dns.net'));
    });

    test('se puede apagar una categoría', () {
      const config = FiltroWebConfig(activo: true, bloquearRedes: false);
      expect(config.estaBloqueado('facebook.com'), isFalse);
      expect(config.estaBloqueado('pornhub.com'), isTrue);
    });

    test('los buscadores solo se bloquean si el adulto los enciende', () {
      const apagados = FiltroWebConfig(activo: true);
      expect(apagados.estaBloqueado('google.com'), isFalse);
      expect(apagados.estaBloqueado('bing.com'), isFalse);

      const encendidos = FiltroWebConfig(
        activo: true,
        bloquearBuscadores: true,
      );
      expect(encendidos.estaBloqueado('google.com'), isTrue);
      expect(encendidos.estaBloqueado('www.google.com'), isTrue);
      expect(encendidos.estaBloqueado('images.google.com'), isTrue);
      expect(encendidos.estaBloqueado('bing.com'), isTrue);
      expect(encendidos.estaBloqueado('duckduckgo.com'), isTrue);
      expect(encendidos.estaBloqueado('wikipedia.org'), isFalse);
      expect(encendidos.estaBloqueado('nogoogle.com'), isFalse);
    });
  });

  group('preferencias', () {
    test('guarda y vuelve a leer la configuración', () async {
      final prefs = await prefsDePrueba();
      const config = FiltroWebConfig(
        activo: true,
        bloquearJuegos: true,
        bloquearBuscadores: true,
        dominiosPersonalizados: ['ejemplo.com', 'otro.org'],
      );
      await FiltroWebPrefs.guardar(prefs, config);
      final leida = FiltroWebPrefs.leer(prefs);
      expect(leida.activo, isTrue);
      expect(leida.bloquearJuegos, isTrue);
      expect(leida.bloquearBuscadores, isTrue);
      expect(leida.dominiosPersonalizados, ['ejemplo.com', 'otro.org']);
    });

    test('una lista corrupta no rompe la pantalla', () async {
      final prefs = await prefsDePrueba(
        iniciales: {FiltroWebPrefs.personalizados: 'no es json'},
      );
      final leida = FiltroWebPrefs.leer(prefs);
      expect(leida.dominiosPersonalizados, isEmpty);
    });
  });

  group('controlador', () {
    test('activar guarda el estado y empuja la lista al servicio', () async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso();
      final container = _contenedor(prefs, gateway);
      final controller = container.read(filtroWebProvider.notifier);

      expect(await controller.setActivo(true), isTrue);
      expect(container.read(filtroWebProvider).activo, isTrue);
      expect(prefs.getBool(FiltroWebPrefs.activo), isTrue);
      expect(gateway.activaciones, 1);
      expect(gateway.ultimaConfig?.activo, isTrue);
      expect(gateway.ultimaConfig?.dominiosActivos, contains('pornhub.com'));

      expect(await controller.setActivo(false), isTrue);
      expect(container.read(filtroWebProvider).activo, isFalse);
      expect(gateway.desactivaciones, 1);
      expect(gateway.ultimaConfig?.activo, isFalse);
    });

    test('si Android niega la VPN el interruptor queda apagado', () async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso()..activarOk = false;
      final container = _contenedor(prefs, gateway);
      final controller = container.read(filtroWebProvider.notifier);

      expect(await controller.setActivo(true), isFalse);
      expect(container.read(filtroWebProvider).activo, isFalse);
      expect(prefs.getBool(FiltroWebPrefs.activo), isFalse);
      expect(gateway.ultimaConfig?.activo, isFalse);
    });

    test('agregar sitio normaliza, evita duplicados y actualiza al servicio',
        () async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso()..activo = true;
      final container = _contenedor(prefs, gateway);
      final controller = container.read(filtroWebProvider.notifier);
      await controller.setActivo(true);

      final primero = await controller.agregarDominio(
        'https://www.Ejemplo.com/ruta',
      );
      expect(primero.resultado, ResultadoAgregar.agregado);
      expect(primero.dominio, 'ejemplo.com');
      expect(
        container.read(filtroWebProvider).dominiosPersonalizados,
        ['ejemplo.com'],
      );
      expect(gateway.ultimaConfig?.dominiosPersonalizados, ['ejemplo.com']);

      final repetido = await controller.agregarDominio('ejemplo.com');
      expect(repetido.resultado, ResultadoAgregar.duplicado);

      final invalido = await controller.agregarDominio('192.168.1.1');
      expect(invalido.resultado, ResultadoAgregar.invalido);

      await controller.quitarDominio('ejemplo.com');
      expect(
        container.read(filtroWebProvider).dominiosPersonalizados,
        isEmpty,
      );
    });

    test('cambiar una categoría con el filtro activo actualiza la lista',
        () async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso();
      final container = _contenedor(prefs, gateway);
      final controller = container.read(filtroWebProvider.notifier);
      await controller.setActivo(true);
      await controller.setCategoria(CategoriaSitio.redes, false);

      expect(
        gateway.ultimaConfig!.dominiosActivos,
        isNot(contains('facebook.com')),
      );
      expect(gateway.ultimaConfig!.dominiosActivos, contains('pornhub.com'));
    });
  });

  group('pantalla del adulto', () {
    testWidgets('agrega un sitio y explica que bloquea el sitio completo',
        (tester) async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso();
      await pumpPadre(
        tester,
        home: const FiltroWebScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          filtroWebGatewayProvider.overrideWithValue(gateway),
        ],
      );

      await _irAlFormulario(tester);
      await tester.enterText(
        find.byType(TextField),
        'https://www.ejemplo.com/ruta',
      );
      await _tocarProhibir(tester);

      expect(
        find.text(
          'Se bloqueará ejemplo.com y sus subdominios. '
          'No se puede bloquear solo una página dentro del sitio.',
        ),
        findsOneWidget,
      );
      expect(find.text('ejemplo.com'), findsOneWidget);
    });

    testWidgets('rechaza una dirección IP', (tester) async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso();
      await pumpPadre(
        tester,
        home: const FiltroWebScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          filtroWebGatewayProvider.overrideWithValue(gateway),
        ],
      );

      await _irAlFormulario(tester);
      await tester.enterText(find.byType(TextField), '192.168.1.1');
      await _tocarProhibir(tester);

      expect(
        find.text(
          'Escribe un sitio como ejemplo.com. '
          'No se puede bloquear una dirección IP ni una página suelta.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('activar pide confirmación y muestra el filtro activo',
        (tester) async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso();
      await pumpPadre(
        tester,
        home: const FiltroWebScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          filtroWebGatewayProvider.overrideWithValue(gateway),
        ],
      );

      await tester.tap(
        find.widgetWithText(FilledButton, 'Activar filtro'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Activar filtro de páginas'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(gateway.activaciones, 1);
      expect(find.text('Filtro activo'), findsOneWidget);
    });

    testWidgets('si la VPN se detuvo, ofrece reactivarla', (tester) async {
      final prefs = await prefsDePrueba(
        iniciales: {FiltroWebPrefs.activo: true},
      );
      final gateway = _GatewayFalso();
      await pumpPadre(
        tester,
        home: const FiltroWebScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          filtroWebGatewayProvider.overrideWithValue(gateway),
        ],
      );

      expect(find.text('Reactivar filtro'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Reactivar filtro'));
      await tester.pumpAndSettle();
      expect(find.text('Activar filtro de páginas'), findsOneWidget);

      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(gateway.activaciones, 1);
      expect(find.text('Filtro activo'), findsOneWidget);
    });
  });
}
