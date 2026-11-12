/// Nivel de calor 0–4 para un valor respecto al máximo del periodo.
///
/// 0 es «sin uso»; 1–4 son cuatro intensidades. Con máximo 0, todo es 0.
int nivelCalor(int valor, int maximo) {
  if (valor <= 0 || maximo <= 0) return 0;
  final proporcion = valor / maximo;
  if (proporcion <= 0.25) return 1;
  if (proporcion <= 0.5) return 2;
  if (proporcion <= 0.75) return 3;
  return 4;
}
