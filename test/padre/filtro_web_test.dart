import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:bluetalk/core/almacen/almacen_local.dart';
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
/// Campo de direcciones de la sección «Prohibir un sitio».
final _campoDireccion = find.widgetWithText(
  TextField,
  'Pega la dirección del sitio',
);

/// Campo de palabras de la sección «Bloquear por palabras».
final _campoPalabra = find.widgetWithText(
  TextField,
  'Palabra que no debe aparecer',
);

Future<void> _irAlFormulario(WidgetTester tester) async {
  for (var i = 0; i < 8 && _campoDireccion.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(_campoDireccion);
  await tester.pumpAndSettle();
}

/// Baja hasta el interruptor de SafeSearch (queda bajo las categorías).
Future<void> _irASafeSearch(WidgetTester tester) async {
  final titulo = find.text('Google con SafeSearch obligatorio');
  for (var i = 0; i < 10 && titulo.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -200));
    await tester.pumpAndSettle();
  }
  expect(titulo, findsOneWidget);
}

Future<void> _irAPalabras(WidgetTester tester) async {
  for (var i = 0; i < 10 && _campoPalabra.evaluate().isEmpty; i++) {
    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(_campoPalabra);
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
      await FiltroWebPrefs.guardar(AlmacenPrefs(prefs), config);
      final leida = FiltroWebPrefs.leer(AlmacenPrefs(prefs));
      expect(leida.activo, isTrue);
      expect(leida.bloquearJuegos, isTrue);
      expect(leida.bloquearBuscadores, isTrue);
      expect(leida.dominiosPersonalizados, ['ejemplo.com', 'otro.org']);
    });

    test('una lista corrupta no rompe la pantalla', () async {
      final prefs = await prefsDePrueba(
        iniciales: {FiltroWebPrefs.personalizados: 'no es json'},
      );
      final leida = FiltroWebPrefs.leer(AlmacenPrefs(prefs));
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
        _campoDireccion,
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
      await _irAlFormulario(tester);
      await tester.enterText(_campoDireccion, '192.168.1.1');
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

  group('SafeSearch y bloqueo por palabras (fase 3b)', () {
    test('normalizarPalabra deja una palabra simple y sin tildes', () {
      expect(normalizarPalabra(' Niño '), 'nino');
      expect(normalizarPalabra('P0RNO'), 'p0rno');
      expect(normalizarPalabra('dos palabras'), isNull);
      expect(normalizarPalabra('   '), isNull);
      expect(normalizarPalabra(''), isNull);
    });

    test('una palabra bloquea los sitios que la contengan', () {
      const config = FiltroWebConfig(
        activo: true,
        bloquearAdultos: false,
        bloquearApuestas: false,
        bloquearRedes: false,
        palabrasProhibidas: ['porno'],
      );

      expect(config.bloqueaPorPalabra('pornositio.com'), isTrue);
      expect(config.bloqueaPorPalabra('sub.ejemplo-pornografia.net'), isTrue);
      expect(config.bloqueaPorPalabra('juegoscasual.com'), isFalse);
      expect(config.bloqueaPorPalabra(''), isFalse);
      // Sin la palabra no se bloquea nada, aunque el filtro esté activo.
      expect(const FiltroWebConfig(activo: true).bloqueaPorPalabra('x.com'), isFalse);
    });

    test('la lista permitida escapa del bloqueo por palabra', () {
      const config = FiltroWebConfig(
        activo: true,
        bloquearAdultos: false,
        bloquearApuestas: false,
        bloquearRedes: false,
        palabrasProhibidas: ['sexo'],
        dominiosPermitidos: ['sexton.edu'],
      );

      expect(config.bloqueaPorPalabra('sexton.edu'), isFalse);
      expect(config.bloqueaPorPalabra('www.sexton.edu'), isFalse);
      expect(config.bloqueaPorPalabra('portal.sexton.edu'), isFalse);
      expect(config.bloqueaPorPalabra('sexoxx.com'), isTrue);
    });

    test('el mapa que recibe el servicio lleva todo lo nuevo', () {
      const config = FiltroWebConfig(
        activo: true,
        forzarSafeSearch: false,
        palabrasProhibidas: ['pepe'],
        dominiosPermitidos: ['ejemplo.com'],
      );
      final mapa = config.paraServicioNativo;

      expect(mapa['activo'], true);
      expect(mapa['safeSearch'], false);
      expect(mapa['palabras'], ['pepe']);
      expect(mapa['permitidos'], ['ejemplo.com']);
      expect(mapa['dominios'], isA<List<Object?>>());
    });

    test('SafeSearch viene encendido y se puede apagar', () async {
      final prefs = await prefsDePrueba();
      expect(FiltroWebPrefs.leer(AlmacenPrefs(prefs)).forzarSafeSearch, isTrue);

      final gateway = _GatewayFalso();
      final container = _contenedor(prefs, gateway);
      final controller = container.read(filtroWebProvider.notifier);
      await controller.setSafeSearch(false);

      expect(container.read(filtroWebProvider).forzarSafeSearch, isFalse);
      expect(prefs.getBool(FiltroWebPrefs.safeSearch), isFalse);
      // Se relee igual tras un reinicio.
      expect(FiltroWebPrefs.leer(AlmacenPrefs(prefs)).forzarSafeSearch, isFalse);
    });

    test('agregar palabra y sitio permitido se guardan y llegan al servicio',
        () async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso()..activo = true;
      final container = _contenedor(prefs, gateway);
      final controller = container.read(filtroWebProvider.notifier);
      await controller.setActivo(true);

      final agregada = await controller.agregarPalabra('Niño');
      expect(agregada.resultado, ResultadoAgregar.agregado);
      expect(agregada.dominio, 'nino');
      expect(container.read(filtroWebProvider).palabrasProhibidas, ['nino']);
      expect(gateway.ultimaConfig?.palabrasProhibidas, ['nino']);

      final repetida = await controller.agregarPalabra('nino');
      expect(repetida.resultado, ResultadoAgregar.duplicado);

      final invalida = await controller.agregarPalabra('dos palabras');
      expect(invalida.resultado, ResultadoAgregar.invalido);

      final permitido = await controller.agregarPermitido('https://sexton.edu');
      expect(permitido.resultado, ResultadoAgregar.agregado);
      expect(permitido.dominio, 'sexton.edu');
      expect(gateway.ultimaConfig?.dominiosPermitidos, ['sexton.edu']);

      // Tras un reinicio siguen ahí.
      final releeido = FiltroWebPrefs.leer(AlmacenPrefs(prefs));
      expect(releeido.palabrasProhibidas, ['nino']);
      expect(releeido.dominiosPermitidos, ['sexton.edu']);

      await controller.quitarPalabra('nino');
      await controller.quitarPermitido('sexton.edu');
      expect(container.read(filtroWebProvider).palabrasProhibidas, isEmpty);
      expect(container.read(filtroWebProvider).dominiosPermitidos, isEmpty);
      expect(gateway.ultimaConfig?.palabrasProhibidas, isEmpty);
    });

    testWidgets('la pantalla agrega una palabra y la lista la refleja',
        (tester) async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso();
      final container = await pumpPadre(
        tester,
        home: const FiltroWebScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          filtroWebGatewayProvider.overrideWithValue(gateway),
        ],
      );
      // Con el filtro encendido, cada cambio se empuja al servicio.
      await container.read(filtroWebProvider.notifier).setActivo(true);

      await _irAPalabras(tester);
      await tester.enterText(_campoPalabra, 'Niño');
      final boton = find.widgetWithText(FilledButton, 'Bloquear palabra');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pumpAndSettle();

      expect(
        find.text('Se bloqueará cualquier sitio cuyo nombre contenga «nino».'),
        findsOneWidget,
      );
      expect(find.text('nino'), findsOneWidget);
      expect(gateway.ultimaConfig?.palabrasProhibidas, contains('nino'));
    });

    testWidgets('el interruptor de SafeSearch se puede apagar', (tester) async {
      final prefs = await prefsDePrueba();
      final gateway = _GatewayFalso()..activo = true;
      await pumpPadre(
        tester,
        home: const FiltroWebScreen(),
        overrides: [
          ...overridesDePadre(prefs),
          filtroWebGatewayProvider.overrideWithValue(gateway),
        ],
      );

      await _irASafeSearch(tester);
      final interruptor = find.ancestor(
        of: find.text('Google con SafeSearch obligatorio'),
        matching: find.byType(SwitchListTile),
      );
      await tester.ensureVisible(interruptor);
      await tester.pumpAndSettle();
      expect(tester.widget<SwitchListTile>(interruptor).value, isTrue);

      await tester.tap(interruptor);
      await tester.pumpAndSettle();

      expect(
        tester.widget<SwitchListTile>(interruptor).value,
        isFalse,
        reason: 'la pantalla refleja lo que decidió el adulto',
      );
      expect(prefs.getBool(FiltroWebPrefs.safeSearch), isFalse);
    });
  });
}
