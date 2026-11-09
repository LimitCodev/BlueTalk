/// Plan de la persona adulta que instaló la app (modelo freemium).
///
/// Regla de producto no negociable: **comunicar nunca es premium**. El
/// tablero, la voz del teléfono, las frases, las rutinas y el modo calma
/// son gratis para siempre. Premium solo añade extras que cuestan dinero
/// producir (voces grabadas, paquetes de vocabulario).
enum Plan { gratis, premium }

/// Extras que exigen un plan concreto. Lo que no está aquí es gratis.
///
/// Añadir una entrada aquí no bloquea nada por sí solo: cada pantalla
/// pregunta con `puedeUsarProvider(Funcion.x)`.
enum Funcion {
  /// Voces naturales grabadas con Amazon Polly antes de compilar
  /// (`scripts/aws/polly/`). En gratis suena la voz del teléfono.
  vocesNaturales(Plan.premium),

  /// Paquetes de vocabulario extra servidos desde CloudFront
  /// (`docs/infra/aws-freemium.md`). El vocabulario núcleo es gratis.
  paquetesVocabulario(Plan.premium);

  const Funcion(this.planMinimo);

  final Plan planMinimo;

  bool disponibleEn(Plan plan) => plan.index >= planMinimo.index;
}
