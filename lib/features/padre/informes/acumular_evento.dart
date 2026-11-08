import '../../../data/models/models.dart';
import 'dia.dart';
import 'resumen_dia.dart';

/// Suma un evento de uso al resumen de su día. Función pura: no guarda.
///
/// `actividad_pendiente` **quita** la actividad de las hechas: desmarcar
/// no puede contar como hacer (el panel antiguo sumaba cualquier
/// `actividad_*`).
ResumenDia acumular(ResumenDia? previo, UsageEvent e) {
  final r = previo ?? ResumenDia(dia: claveDia(e.createdAt));
  String? texto(String clave) =>
      e.data[clave] is String ? e.data[clave] as String : null;
  Map<String, int> mas(Map<String, int> m, String? clave) =>
      clave == null ? m : {...m, clave: (m[clave] ?? 0) + 1};

  return switch (e.type) {
    'picto_tap' => _con(
        r,
        pictos: r.pictos + 1,
        categorias: mas(r.categorias, texto('categoryId')),
        pictosUsados: mas(r.pictosUsados, texto('pictoId')),
      ),
    'juego_fin' => _con(
        r,
        sesionesJuego: r.sesionesJuego + 1,
        segundosJuego:
            r.segundosJuego + ((e.data['segundos'] as num?)?.toInt() ?? 0),
      ),
    'cuento_completado' => _con(r, cuentos: r.cuentos + 1),
    'dibujo_guardado' => _con(r, dibujos: r.dibujos + 1),
    'actividad_hecha' => _con(
        r,
        actividadesHechas: {...r.actividadesHechas, ?texto('entradaId')},
      ),
    'actividad_pendiente' => _con(
        r,
        actividadesHechas: {...r.actividadesHechas}..remove(texto('entradaId')),
      ),
    _ => r,
  };
}

/// [r] con el uso de otras apps de ese día (captura de `captura_apps.dart`).
ResumenDia conApps(ResumenDia r, UsoAppsDia apps) => _con(r, apps: apps);

ResumenDia _con(
  ResumenDia r, {
  int? pictos,
  Map<String, int>? categorias,
  Map<String, int>? pictosUsados,
  int? segundosJuego,
  int? sesionesJuego,
  int? cuentos,
  int? dibujos,
  Set<String>? actividadesHechas,
  UsoAppsDia? apps,
}) =>
    ResumenDia(
      dia: r.dia,
      pictos: pictos ?? r.pictos,
      categorias: categorias ?? r.categorias,
      pictosUsados: pictosUsados ?? r.pictosUsados,
      segundosJuego: segundosJuego ?? r.segundosJuego,
      sesionesJuego: sesionesJuego ?? r.sesionesJuego,
      cuentos: cuentos ?? r.cuentos,
      dibujos: dibujos ?? r.dibujos,
      actividadesHechas: actividadesHechas ?? r.actividadesHechas,
      apps: apps ?? r.apps,
    );
