#!/usr/bin/env python3
"""Genera el ícono de BlueTalk a mano desde la geometría del cartel (P3.4).

Sin dependencias: solo la librería estándar. Salida por defecto sobre
`android/app/src/main/res`:

- `drawable/ic_launcher_foreground.xml` — VectorDrawable del primer
  plano adaptivo (API >= 26), logo dentro de la zona segura r<=36.
- `mipmap-{m,h,x,xx,xxx}hdpi/ic_launcher.png` — PNG heredado (API < 26):
  cuadrado con fondo de marca y el logo al 72 % centrado, rasterizado
  con supersampling 3x3.

Geometría del logo en viewbox 100x100 medida sobre el cartel
(`referencia_logo_y_colores_iniciales.jpeg`): anillo de la burbuja
centro (46,43) radio 32 con hueco 25; cola con dos cuadráticas por los
controles (21,78) y (30,83); ojos discos radio 3.4 en (37,37) y
(57,37); sonrisa cuadrática (36,49)->(47,59)->(58,49) grosor 4.2;
corazón: discos radio 7.52 en (71.28,63.6)/(84.72,63.6) + triángulo
(64.4,67.44)(89.6,67.44)(78,85.04).

Transformación al lienzo adaptivo 108x108 (escala 0.63, zona segura):
    X = 54 + 0.63*(x-54)      Y = 54 + 0.63*(y-49.5)

Verificado el 2026-10-18: el XML regenerado es idéntico byte a byte al
versionado en el repo y los PNGs regenerados son visualmente idénticos
a los versionados (los binarios del repo se conservan por estabilidad).
"""
import math
import pathlib
import struct
import sys
import zlib

AZUL = (0x2E, 0x64, 0x92)    # anillo, ojos, sonrisa, cola
BLANCO = (0xFF, 0xFF, 0xFF)  # interior de la burbuja
VERDE = (0x20, 0xA0, 0x78)   # corazón (solo relleno/decoración)
CELESTE = (0x70, 0xD0, 0xF8) # fondo del PNG heredado

K_VECTOR = 0.63   # escala del adaptivo (108dp con zona segura r<=36)
K_PNG = 0.72      # fracción del cuadrado que ocupa el logo heredado

PNG_POR_DENSIDAD = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


# ---------------------------------------------------------------- geometría

def tx(x, y):
    """Punto del viewbox 100x100 al lienzo adaptivo 108x108."""
    return (54 + K_VECTOR * (x - 54), 54 + K_VECTOR * (y - 49.5))


def fnum(v):
    """Mismo formato del arte commiteado: 2 decimales sin ceros colgantes."""
    s = f"{v:.2f}"
    if "." in s:
        s = s.rstrip("0").rstrip(".")
    return s


def fpt(p):
    return f"{fnum(p[0])},{fnum(p[1])}"


def circulo(c, r):
    """Círculo como pathData de dos arcos (formato del arte)."""
    izq = (c[0] - r, c[1])
    der = (c[0] + r, c[1])
    rr = fnum(r)
    return (f"M{fpt(izq)} A{rr},{rr} 0 1 1 {fpt(der)} "
            f"A{rr},{rr} 0 1 1 {fpt(izq)} Z")


def cuadratica(p0, c, p1, n=24):
    """Aplana una cuadrática de Bézier a una polilínea."""
    puntos = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        puntos.append((
            u * u * p0[0] + 2 * u * t * c[0] + t * t * p1[0],
            u * u * p0[1] + 2 * u * t * c[1] + t * t * p1[1],
        ))
    return puntos


def generar_vector():
    """XML exacto del primer plano adaptivo (formato del arte commiteado)."""
    lineas = [
        '<?xml version="1.0" encoding="utf-8"?>',
        '<vector xmlns:android="http://schemas.android.com/apk/res/android"',
        '    android:width="108dp" android:height="108dp"',
        '    android:viewportWidth="108" android:viewportHeight="108">',
        "",
        "    <!-- Primer plano del ícono adaptive: logo oficial de BlueTalk",
        "         (plan 13 P3.4), dibujado a mano a partir del cartel. -->",
    ]

    def add(path, color):
        lineas.append(
            f'    <path android:fillColor="{color}" android:pathData="{path}" />'
        )

    # Cola: dos cuadráticas medidas sobre el arte final (controles ya
    # transformados quedan raros; se transforman desde el viewbox).
    cola = (f"M{fpt(tx(31, 64))} Q{fpt(tx(21, 78))} {fpt(tx(14, 88))} "
            f"Q{fpt(tx(30, 83))} {fpt(tx(41, 70))} Z")
    add(cola, "#2E6492")
    # Anillo azul de la burbuja y disco blanco encima (el hueco).
    add(circulo(tx(46, 43), 32 * K_VECTOR), "#2E6492")
    add(circulo(tx(46, 43), 25 * K_VECTOR), "#FFFFFF")
    # Ojos.
    add(circulo(tx(37, 37), 3.4 * K_VECTOR), "#2E6492")
    add(circulo(tx(57, 37), 3.4 * K_VECTOR), "#2E6492")
    # Sonrisa: trazo redondo, no relleno.
    sonrisa = f"M{fpt(tx(36, 49))} Q{fpt(tx(47, 59))} {fpt(tx(58, 49))}"
    lineas.append(
        '    <path android:fillColor="@android:color/transparent"'
        ' android:strokeColor="#2E6492"'
        f' android:strokeWidth="{fnum(4.2 * K_VECTOR)}"'
        ' android:strokeLineCap="round"'
        f' android:pathData="{sonrisa}" />'
    )
    # Corazón: dos lóbulos y la punta.
    add(circulo(tx(71.28, 63.6), 7.52 * K_VECTOR), "#20A078")
    add(circulo(tx(84.72, 63.6), 7.52 * K_VECTOR), "#20A078")
    punta = (f"M{fpt(tx(64.4, 67.44))} L{fpt(tx(89.6, 67.44))} "
             f"L{fpt(tx(78, 85.04))} Z")
    add(punta, "#20A078")
    lineas.append("</vector>")
    return "\n".join(lineas) + "\n"


# --------------------------------------------------------------- rasterizar

def _dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def _dist_polilinea(p, linea):
    return min(
        _dist_segmento(p, a, b) for a, b in zip(linea, linea[1:])
    )


def _dist_segmento(p, a, b):
    dx, dy = b[0] - a[0], b[1] - a[1]
    largo2 = dx * dx + dy * dy
    if largo2 == 0:
        return _dist(p, a)
    t = max(0.0, min(1.0, ((p[0] - a[0]) * dx + (p[1] - a[1]) * dy) / largo2))
    return _dist(p, (a[0] + t * dx, a[1] + t * dy))


def _en_poligono(p, poli):
    dentro = False
    j = len(poli) - 1
    for i in range(len(poli)):
        xi, yi = poli[i]
        xj, yj = poli[j]
        if (yi > p[1]) != (yj > p[1]) and \
           p[0] < (xj - xi) * (p[1] - yi) / (yj - yi) + xi:
            dentro = not dentro
        j = i
    return dentro


_SONRISA = cuadratica((36, 49), (47, 59), (58, 49))
_COLA = (cuadratica((31, 64), (21, 78), (14, 88)) +
         cuadratica((14, 88), (30, 83), (41, 70))[1:])
_TRI = [(64.4, 67.44), (89.6, 67.44), (78, 85.04)]


def _color_muestra(v):
    """Color del viewbox para un punto, al estilo del orden de dibujo.

    El orden inverso (de arriba abajo del vector) da prioridad al
    corazón, que es lo último que se pinta en el adaptivo.
    """
    if (_dist(v, (71.28, 63.6)) <= 7.52 or
            _dist(v, (84.72, 63.6)) <= 7.52 or
            _en_poligono(v, _TRI)):
        return VERDE
    if _dist_polilinea(v, _SONRISA) <= 2.1:
        return AZUL
    if _dist(v, (37, 37)) <= 3.4 or _dist(v, (57, 37)) <= 3.4:
        return AZUL
    d = _dist(v, (46, 43))
    if d <= 25:
        return BLANCO
    if d <= 32:
        return AZUL
    if _en_poligono(v, _COLA):
        return AZUL
    return CELESTE


def rasterizar(tam):
    """RGB del logo heredado: fondo celeste + logo al 72 % centrado."""
    paso = (tam * K_PNG) / 100.0  # px por unidad del viewbox

    def a_viewbox(px, py):
        return ((px / paso - 50) / K_PNG + 50,
                (py / paso - 50) / K_PNG + 50)

    filas = []
    for py in range(tam):
        fila = bytearray()
        for px in range(tam):
            cuenta = {AZUL: 0, BLANCO: 0, VERDE: 0, CELESTE: 0}
            for sy in range(3):
                for sx in range(3):
                    v = a_viewbox(px + (sx + 0.5) / 3, py + (sy + 0.5) / 3)
                    cuenta[_color_muestra(v)] += 1
            fila += bytes(max(cuenta, key=cuenta.get))
        filas.append(bytes(fila))
    return filas


def escribir_png(ruta, tam, filas):
    """PNG mínimo (RGB 8 bits, sin filtros)."""
    def bloque(tipo, datos):
        return (struct.pack(">I", len(datos)) + tipo + datos +
                struct.pack(">I", zlib.crc32(tipo + datos) & 0xFFFFFFFF))

    ihdr = struct.pack(">IIBBBBB", tam, tam, 8, 2, 0, 0, 0)
    crudo = b"".join(b"\x00" + fila for fila in filas)
    ruta.write_bytes(
        b"\x89PNG\r\n\x1a\n" + bloque(b"IHDR", ihdr) +
        bloque(b"IDAT", zlib.compress(crudo, 9)) + bloque(b"IEND", b"")
    )


def main():
    res = (pathlib.Path(__file__).resolve().parent.parent /
           "android/app/src/main/res")
    if len(sys.argv) > 1:  # salida alternativa (para verificar sin tocar)
        res = pathlib.Path(sys.argv[1])
    res.mkdir(parents=True, exist_ok=True)

    vector = res / "drawable" / "ic_launcher_foreground.xml"
    vector.parent.mkdir(parents=True, exist_ok=True)
    vector.write_text(generar_vector(), encoding="utf-8")
    print("VECTOR", vector)

    for carpeta, tam in PNG_POR_DENSIDAD.items():
        destino = res / carpeta / "ic_launcher.png"
        destino.parent.mkdir(parents=True, exist_ok=True)
        escribir_png(destino, tam, rasterizar(tam))
        print("PNG", destino.name, tam)
    print("LISTO")


if __name__ == "__main__":
    main()
