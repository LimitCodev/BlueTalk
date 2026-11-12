/// Porcentajes enteros de [conteos] que suman exactamente 100.
///
/// Usa el método del mayor resto para repartir los puntos que quedan tras
/// redondear. Con todos los conteos en 0 devuelve ceros.
List<int> porcentajes(List<int> conteos) {
  final total = conteos.fold<int>(0, (suma, c) => suma + (c > 0 ? c : 0));
  if (total <= 0) return List<int>.filled(conteos.length, 0);
  final exactos = [
    for (final conteo in conteos) (conteo > 0 ? conteo : 0) * 100 / total,
  ];
  final base = [for (final exacto in exactos) exacto.floor()];
  var falta = 100 - base.fold<int>(0, (suma, n) => suma + n);
  final orden = [for (var i = 0; i < conteos.length; i++) i]
    ..sort((a, b) => (exactos[b] - base[b]).compareTo(exactos[a] - base[a]));
  for (var i = 0; falta > 0; i++, falta--) {
    base[orden[i % orden.length]]++;
  }
  return base;
}
