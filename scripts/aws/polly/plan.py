"""Qué falta por sintetizar. La caché evita pagar dos veces el mismo audio."""
import hashlib
import json
from dataclasses import dataclass
from pathlib import Path

# Precio por millón de caracteres (aws.amazon.com/polly/pricing, nov-2026).
PRECIO_MILLON_USD = {"standard": 4.0, "neural": 16.0, "generative": 30.0}


def huella(texto: str, voz: str, motor: str) -> str:
    return hashlib.sha256(f"{motor}|{voz}|{texto}".encode()).hexdigest()


@dataclass(frozen=True)
class Pendiente:
    ident: str
    texto: str
    huella: str


def leer_manifiesto(carpeta: Path) -> dict:
    ruta = carpeta / "manifiesto.json"
    if not ruta.exists():
        return {}
    return json.loads(ruta.read_text(encoding="utf-8")).get("elementos", {})


def pendientes(textos: dict[str, str], voz: str, motor: str,
               carpeta: Path) -> list[Pendiente]:
    hechos = leer_manifiesto(carpeta)
    faltan = []
    for ident, texto in sorted(textos.items()):
        h = huella(texto, voz, motor)
        previo = hechos.get(ident, {})
        archivo = carpeta / f"{ident}.mp3"
        if previo.get("huella") != h or not archivo.exists():
            faltan.append(Pendiente(ident, texto, h))
    return faltan


def coste_usd(lista: list[Pendiente], motor: str) -> float:
    caracteres = sum(len(p.texto) for p in lista)
    return caracteres * PRECIO_MILLON_USD[motor] / 1_000_000
