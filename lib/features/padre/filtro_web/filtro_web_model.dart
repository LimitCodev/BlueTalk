/// Filtro de páginas del modo padre (solicitud del dueño, 2026-10-20).
///
/// El filtro bloquea **nombres de sitios** (dominios) en todo el teléfono
/// mediante una VPN local que solo intercepta las consultas DNS. No puede
/// bloquear una página suelta dentro de un sitio, una dirección IP ni una
/// app que use su propio resolutor: eso se explica en la pantalla del
/// adulto y en `docs/plan/14-filtro-web.md`.
library;

/// Grupos de sitios que el adulto puede encender o apagar.
enum CategoriaSitio { adultos, apuestas, redes, juegos, buscadores }

extension CategoriaSitioTexto on CategoriaSitio {
  String get titulo => switch (this) {
        CategoriaSitio.adultos => 'Contenido para adultos (+18)',
        CategoriaSitio.apuestas => 'Apuestas y azar',
        CategoriaSitio.redes => 'Redes sociales y citas',
        CategoriaSitio.juegos => 'Videos y juegos',
        CategoriaSitio.buscadores => 'Buscadores de internet',
      };

  String get ayuda => switch (this) {
        CategoriaSitio.adultos =>
          'Sitios de pornografía y contenido sexual explícito.',
        CategoriaSitio.apuestas =>
          'Casinos, apuestas deportivas y loterías.',
        CategoriaSitio.redes =>
          'Facebook, TikTok, Instagram, Snapchat y similares.',
        CategoriaSitio.juegos =>
          'YouTube, Twitch, Roblox y sitios de juegos.',
        CategoriaSitio.buscadores =>
          'Google, Bing, Yahoo, DuckDuckGo y otros buscadores.',
      };
}

/// Lista inicial de dominios por categoría.
///
/// Es una lista **de arranque**, no un catálogo completo: los sitios +18
/// cambian y el colegio puede agregar los suyos con «Prohibir sitio».
/// Se compara el dominio y todos sus subdominios.
const dominiosPorCategoria = <CategoriaSitio, List<String>>{
  CategoriaSitio.adultos: [
    'pornhub.com',
    'pornhub.org',
    'pornhub.net',
    'pornhubpremium.com',
    'phncdn.com',
    'porn.com',
    'porn300.com',
    'pornone.com',
    'pornhat.com',
    'pornhd.com',
    'porn7.xxx',
    'xvideos.com',
    'xvideos.es',
    'xvideos2.com',
    'xvideos3.com',
    'xnxx.com',
    'xnxx.es',
    'xnxx.tv',
    'xhamster.com',
    'xhamster.desi',
    'xhamster.xxx',
    'xhopen.com',
    'xhamsterlive.com',
    'redtube.com',
    'redtube.net',
    'youporn.com',
    'youporngay.com',
    'spankbang.com',
    'spankbang.net',
    'eporner.com',
    'txxx.com',
    'hqporner.com',
    'beeg.com',
    'tnaflix.com',
    'drtuber.com',
    'empflix.com',
    'sunporno.com',
    'porntrex.com',
    'hclips.com',
    'upornia.com',
    'hotmovs.com',
    'vipporns.com',
    'alohatube.com',
    'tubegalore.com',
    'onlyfans.com',
    'fansly.com',
    'manyvids.com',
    'chaturbate.com',
    'chaturbate.eu',
    'stripchat.com',
    'livejasmin.com',
    'bongacams.com',
    'cam4.com',
    'camsoda.com',
    'myfreecams.com',
    'nhentai.net',
    'hanime.tv',
    'rule34.xxx',
    'motherless.com',
    'brazzers.com',
    'bangbros.com',
    'kink.com',
    'penthouse.com',
    'playboy.com',
    'hustler.com',
    'sex.com',
  ],
  CategoriaSitio.apuestas: [
    'bet365.com',
    'betfair.com',
    'betano.com',
    'betsson.com',
    'pokerstars.com',
    '888casino.com',
    '1xbet.com',
    'betway.com',
    'williamhill.com',
    'codere.com',
    'caliente.mx',
    'playdoit.mx',
    'stake.com',
    'draftkings.com',
    'fanduel.com',
  ],
  CategoriaSitio.redes: [
    'facebook.com',
    'instagram.com',
    'tiktok.com',
    'snapchat.com',
    'x.com',
    'twitter.com',
    'reddit.com',
    'discord.com',
    'tumblr.com',
    'telegram.org',
    'tinder.com',
    'badoo.com',
    'grindr.com',
    'omegle.com',
    'chatroulette.com',
    'vk.com',
    'weibo.com',
    'threads.net',
    'bereal.com',
    'yubo.live',
  ],
  CategoriaSitio.juegos: [
    'youtube.com',
    'youtu.be',
    'twitch.tv',
    'roblox.com',
    'minecraft.net',
    'poki.com',
    'friv.com',
    'coolmathgames.com',
    'netflix.com',
    'disneyplus.com',
    'primevideo.com',
    'max.com',
    'hulu.com',
    'crunchyroll.com',
    'kick.com',
    'miniclip.com',
    'crazygames.com',
    'y8.com',
    'addictinggames.com',
    'newgrounds.com',
  ],
  CategoriaSitio.buscadores: [
    'google.com',
    'google.com.mx',
    'google.es',
    'google.co',
    'google.com.co',
    'google.com.ar',
    'google.com.pe',
    'google.cl',
    'bing.com',
    'yahoo.com',
    'search.yahoo.com',
    'duckduckgo.com',
    'ecosia.org',
    'search.brave.com',
    'yandex.com',
    'yandex.ru',
    'baidu.com',
    'ask.com',
    'aol.com',
    'qwant.com',
    'startpage.com',
    'searx.be',
  ],
};

/// Dominios que se bloquean siempre que el filtro está encendido.
///
/// - `use-application-dns.net`: Firefox lo consulta para decidir si usa
///   DNS sobre HTTPS; si no existe, lo desactiva.
/// - Los resolutores DoH conocidos: si una app intenta usarlos por nombre,
///   no podrá saltarse el filtro. No cubre DoH por dirección IP.
const dominiosTecnicos = <String>[
  'use-application-dns.net',
  'dns.google',
  'cloudflare-dns.com',
  'mozilla.cloudflare-dns.com',
  'chrome.cloudflare-dns.com',
  'doh.opendns.com',
  'dns.nextdns.io',
  'dns.adguard.com',
  'dns.quad9.net',
  'doh.cleanbrowsing.org',
];

/// Configuración local del filtro. `activo` es el estado **deseado**; el
/// estado real de la VPN se consulta al sistema y puede ser distinto si el
/// niño o Android la detuvieron.
class FiltroWebConfig {
  const FiltroWebConfig({
    this.activo = false,
    this.bloquearAdultos = true,
    this.bloquearApuestas = true,
    this.bloquearRedes = true,
    this.bloquearJuegos = false,
    this.bloquearBuscadores = false,
    this.dominiosPersonalizados = const [],
  });

  final bool activo;
  final bool bloquearAdultos;
  final bool bloquearApuestas;
  final bool bloquearRedes;
  final bool bloquearJuegos;
  final bool bloquearBuscadores;
  final List<String> dominiosPersonalizados;

  static const maxPersonalizados = 200;

  FiltroWebConfig copyWith({
    bool? activo,
    bool? bloquearAdultos,
    bool? bloquearApuestas,
    bool? bloquearRedes,
    bool? bloquearJuegos,
    bool? bloquearBuscadores,
    List<String>? dominiosPersonalizados,
  }) =>
      FiltroWebConfig(
        activo: activo ?? this.activo,
        bloquearAdultos: bloquearAdultos ?? this.bloquearAdultos,
        bloquearApuestas: bloquearApuestas ?? this.bloquearApuestas,
        bloquearRedes: bloquearRedes ?? this.bloquearRedes,
        bloquearJuegos: bloquearJuegos ?? this.bloquearJuegos,
        bloquearBuscadores: bloquearBuscadores ?? this.bloquearBuscadores,
        dominiosPersonalizados:
            dominiosPersonalizados ?? this.dominiosPersonalizados,
      );

  bool estaActiva(CategoriaSitio categoria) => switch (categoria) {
        CategoriaSitio.adultos => bloquearAdultos,
        CategoriaSitio.apuestas => bloquearApuestas,
        CategoriaSitio.redes => bloquearRedes,
        CategoriaSitio.juegos => bloquearJuegos,
        CategoriaSitio.buscadores => bloquearBuscadores,
      };

  FiltroWebConfig conCategoria(CategoriaSitio categoria, bool valor) =>
      switch (categoria) {
        CategoriaSitio.adultos => copyWith(bloquearAdultos: valor),
        CategoriaSitio.apuestas => copyWith(bloquearApuestas: valor),
        CategoriaSitio.redes => copyWith(bloquearRedes: valor),
        CategoriaSitio.juegos => copyWith(bloquearJuegos: valor),
        CategoriaSitio.buscadores => copyWith(bloquearBuscadores: valor),
      };

  /// Todos los dominios que hay que pasarle al servicio nativo.
  ///
  /// Los dominios técnicos solo se incluyen cuando el filtro está activo:
  /// no tiene sentido bloquear el resolutor de Firefox si no hay filtro.
  List<String> get dominiosActivos {
    final dominios = <String>{};
    for (final categoria in CategoriaSitio.values) {
      if (estaActiva(categoria)) {
        dominios.addAll(dominiosPorCategoria[categoria]!);
      }
    }
    dominios.addAll(dominiosPersonalizados);
    if (activo) dominios.addAll(dominiosTecnicos);
    return dominios.toList()..sort();
  }

  /// `true` si [host] es un dominio bloqueado o un subdominio suyo.
  bool estaBloqueado(String host) {
    if (!activo) return false;
    final normalizado = host
        .trim()
        .toLowerCase()
        .replaceFirst(RegExp(r'\.$'), '')
        .replaceFirst(RegExp(r'^www\.'), '');
    if (normalizado.isEmpty) return false;
    for (final dominio in dominiosActivos) {
      if (normalizado == dominio ||
          normalizado.endsWith('.$dominio')) {
        return true;
      }
    }
    return false;
  }
}

/// Resultado de intentar agregar un sitio a la lista personalizada.
enum ResultadoAgregar { agregado, invalido, duplicado, lleno }

/// Convierte lo que el adulto pega en un dominio bloqueable.
///
/// Acepta `https://www.ejemplo.com/ruta`, `ejemplo.com/ruta` o
/// `ejemplo.com`. Devuelve `null` si no es un nombre de sitio válido.
/// **No** acepta direcciones IP, comodines ni dominios de un solo nivel
/// (`com`), porque bloquearían demasiado o no funcionarían con DNS.
String? normalizarDominio(String entrada) {
  var texto = entrada.trim().toLowerCase();
  if (texto.isEmpty) return null;
  if (texto.contains(' ')) return null;

  if (!texto.contains('://')) texto = 'https://$texto';

  final uri = Uri.tryParse(texto);
  if (uri == null || uri.host.isEmpty) return null;

  var host = uri.host.toLowerCase();
  if (host.endsWith('.')) host = host.substring(0, host.length - 1);
  if (host.startsWith('www.')) host = host.substring(4);

  if (_esDireccionIp.hasMatch(host)) return null;
  if (!_dominioValido.hasMatch(host)) return null;
  if (!host.contains('.')) return null;
  if (host.split('.').any((parte) => parte.isEmpty || parte.length > 63)) {
    return null;
  }
  if (_tldsSueltos.contains(host)) return null;

  return host;
}

/// `true` si el dominio está en la lista que el niño no debería poder abrir.
bool dominioBloqueado(String host, Iterable<String> dominios) {
  final normalizado = host
      .trim()
      .toLowerCase()
      .replaceFirst(RegExp(r'\.$'), '')
      .replaceFirst(RegExp(r'^www\.'), '');
  if (normalizado.isEmpty) return false;
  for (final dominio in dominios) {
    if (normalizado == dominio || normalizado.endsWith('.$dominio')) {
      return true;
    }
  }
  return false;
}

final _dominioValido = RegExp(
  r'^[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?'
  r'(?:\.[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?)+$',
);

final _esDireccionIp = RegExp(
  r'^(?:\d{1,3}\.){3}\d{1,3}$',
);

/// Dominios de nivel superior que, solos, bloquearían internet entero.
const _tldsSueltos = <String>{
  'com',
  'net',
  'org',
  'edu',
  'gob',
  'gov',
  'mil',
  'int',
  'info',
  'biz',
  'io',
  'co',
  'me',
  'tv',
  'app',
  'dev',
  'xyz',
  'online',
  'site',
  'store',
  'shop',
  'pe',
  'mx',
  'cl',
  'ar',
  'es',
};
