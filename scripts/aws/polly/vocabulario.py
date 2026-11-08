"""Textos que se graban: las etiquetas del vocabulario de la app."""
import json
from pathlib import Path


def cargar(ruta_pictos: Path) -> dict[str, str]:
    """Devuelve {id_picto: texto}. Falla si hay ids repetidos o vacíos."""
    datos = json.loads(ruta_pictos.read_text(encoding="utf-8"))
    textos: dict[str, str] = {}
    for p in datos:
        ident, texto = p["id"], p["label"].strip()
        if not ident or not texto:
            raise ValueError(f"Pictograma sin id o sin texto: {p}")
        if ident in textos:
            raise ValueError(f"Id repetido: {ident}")
        textos[ident] = texto
    return textos
