import 'package:bluetalk/core/almacen/almacen_local.dart';
import 'package:bluetalk/features/padre/informes/captura_apps.dart';
import 'package:bluetalk/features/padre/informes/resumenes_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gateway_falso.dart';

void main() {
  final ahora = DateTime(2026, 11, 20, 18);
  late ResumenesRepo repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = ResumenesRepo(AlmacenPrefs(await SharedPreferences.getInstance()));
  });

  test('copia los días que Android conserva, con 10 apps como mucho', () async {
    final g = GatewayFalso();
    expect(await capturarUsoApps(gateway: g, repo: repo, ahora: ahora), 9);
    final hoy = repo.dia('2026-11-20')!.apps!;
    expect((hoy.totalSegundos, hoy.apps.length), (600, 10));
    expect(repo.dia('2026-11-12')!.apps, isNotNull);
    expect(repo.dia('2026-11-11'), isNull, reason: 'Android ya lo borró');
  });

  test('la segunda vez solo relee hoy y ayer', () async {
    final g = GatewayFalso();
    await capturarUsoApps(gateway: g, repo: repo, ahora: ahora);
    g.pedidos.clear();
    expect(await capturarUsoApps(gateway: g, repo: repo, ahora: ahora), 2);
    expect(g.pedidos, [DateTime(2026, 11, 19), DateTime(2026, 11, 20)]);
  });

  test('sin permiso no lee nada', () async {
    final g = GatewayFalso(permitido: false);
    expect(await capturarUsoApps(gateway: g, repo: repo, ahora: ahora), 0);
    expect(g.pedidos, isEmpty);
  });
}
