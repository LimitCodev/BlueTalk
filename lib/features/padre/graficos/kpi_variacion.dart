import 'package:flutter/material.dart';

/// Comparación de [actual] con [anterior].
///
/// [porcentaje] null significa «Nuevo»: antes no había nada con qué comparar.
/// [direccion] es 1 si sube, -1 si baja y 0 si queda igual.
typedef VariacionKpi = ({int? porcentaje, int direccion});

/// Calcula la variación porcentual sin dividir entre cero.
VariacionKpi variacion(int actual, int anterior) {
  if (anterior == 0) {
    if (actual == 0) return (porcentaje: 0, direccion: 0);
    return (porcentaje: null, direccion: 1);
  }
  final porcentaje = ((actual - anterior) * 100 / anterior).round();
  return (porcentaje: porcentaje, direccion: porcentaje.sign);
}

/// Frase literal de la comparación para la tarjeta.
String textoVariacion(VariacionKpi dato, String periodo) {
  if (dato.porcentaje == null) return 'Nuevo respecto a $periodo';
  if (dato.porcentaje == 0) return 'Igual que $periodo';
  final signo = dato.porcentaje! > 0 ? '+' : '';
  return '$signo${dato.porcentaje} % respecto a $periodo';
}

/// Icono de la flecha según la dirección.
IconData iconoVariacion(int direccion) => switch (direccion) {
      > 0 => Icons.arrow_upward,
      < 0 => Icons.arrow_downward,
      _ => Icons.remove,
    };
