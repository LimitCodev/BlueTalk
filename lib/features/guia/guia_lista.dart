import '../inicio/menu_opciones.dart';
import 'guia_pasos.dart';
import 'mascota.dart';

const _menu = '/inicio';
const _comunicar = '/home/comunicar';

/// Los 11 pasos (plan 14B §3). Texto literal, para el adulto.
const pasosGuia = <GuiaPaso>[
  GuiaPaso(
    ruta: _menu,
    postura: PosturaAve.brazosAbiertos,
    texto:
        '¡Hola! Soy el ave de BlueTalk. Te enseño la app en 11 pasos cortos.',
  ),
  GuiaPaso(
    ruta: _menu,
    postura: PosturaAve.bandera,
    objetivo: GuiaObjetivo.menuCarrusel,
    texto:
        'Este es el menú. Desliza hacia arriba o abajo, o usa las flechas. Toca el botón del centro para entrar.',
  ),
  GuiaPaso(
    ruta: _menu,
    postura: PosturaAve.saludaTablero,
    objetivo: GuiaObjetivo.tarjetaComunicar,
    tarjeta: MenuOpcion.comunicar,
    titulo: 'Comunicar',
    texto:
        'tu hijo o hija toca pictogramas para formar frases. La voz suena solo al tocar.',
  ),
  GuiaPaso(
    ruta: _menu,
    postura: PosturaAve.volando,
    objetivo: GuiaObjetivo.tarjetaAprender,
    tarjeta: MenuOpcion.aprender,
    titulo: 'Aprender',
    texto: 'juegos de memoria, cuentos y dibujo.',
  ),
  GuiaPaso(
    ruta: _menu,
    postura: PosturaAve.manosJuntas,
    objetivo: GuiaObjetivo.tarjetaRutinas,
    tarjeta: MenuOpcion.rutinas,
    titulo: 'Rutinas',
    texto:
        'el horario del día y «primero y luego». Ayudan a saber qué viene después.',
  ),
  GuiaPaso(
    ruta: _menu,
    postura: PosturaAve.alasAbiertas,
    objetivo: GuiaObjetivo.tarjetaAjustes,
    tarjeta: MenuOpcion.ajustes,
    titulo: 'Ajustes',
    texto: 'la voz, los colores y el tamaño.',
  ),
  GuiaPaso(
    ruta: _comunicar,
    postura: PosturaAve.saludaTablero,
    objetivo: GuiaObjetivo.fraseBarra,
    texto: 'Aquí se arma la frase. El botón de hablar la lee en voz alta.',
  ),
  GuiaPaso(
    ruta: _comunicar,
    postura: PosturaAve.perfil,
    objetivo: GuiaObjetivo.tableroNuclear,
    titulo: 'Palabras básicas',
    texto: 'siempre están en el mismo lugar. Así se aprenden de memoria.',
  ),
  GuiaPaso(
    ruta: _comunicar,
    postura: PosturaAve.pensando,
    objetivo: GuiaObjetivo.categorias,
    texto:
        'Las categorías tienen más palabras: comida, lugares, emociones y más.',
  ),
  GuiaPaso(
    ruta: _comunicar,
    postura: PosturaAve.pulgar,
    objetivo: GuiaObjetivo.barraSuperior,
    texto:
        'La casa vuelve al menú. El botón de contraste activa el modo calma: menos color y sin movimiento.',
  ),
  GuiaPaso(
    ruta: _menu,
    postura: PosturaAve.candadoSenala,
    objetivo: GuiaObjetivo.tarjetaPadre,
    tarjeta: MenuOpcion.padre,
    titulo: 'Modo padre',
    texto:
        'es solo para ti. Primero acepta las condiciones y luego crea un código de 6 dígitos que solo tú sepas.',
  ),
];

/// Texto del último paso cuando el código ya existe (guía repetida).
const textoPadreConCodigo =
    'es solo para ti. Aquí entras con tu código para ver estadísticas y ajustes.';
