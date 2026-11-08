"""Genera las voces premium con Amazon Polly ANTES de compilar la app.

La app no llama a AWS: solo reproduce los MP3 que salen de aquí.

Uso (simulación, no llama a AWS ni gasta):
    python3 scripts/aws/polly/generar_voces.py --voz Lupe
Uso real (requiere `aws configure` y la política PermisosPublicar):
    python3 scripts/aws/polly/generar_voces.py --voz Lupe --de-verdad
"""
import argparse
import hashlib
import json
import sys
from pathlib import Path

import plan
import sintetizar
import vocabulario

RAIZ = Path(__file__).resolve().parents[3]


def guardar_manifiesto(carpeta: Path, voz: str, motor: str, elementos: dict):
    datos = {"voz": voz, "motor": motor, "elementos": elementos}
    (carpeta / "manifiesto.json").write_text(
        json.dumps(datos, ensure_ascii=False, indent=2, sort_keys=True),
        encoding="utf-8")


def generar(textos, voz, motor, carpeta: Path, de_verdad: bool,
            ejecutar=None) -> int:
    carpeta.mkdir(parents=True, exist_ok=True)
    faltan = plan.pendientes(textos, voz, motor, carpeta)
    coste = plan.coste_usd(faltan, motor)
    print(f"{len(faltan)} de {len(textos)} audios por generar "
          f"(~{coste:.4f} USD fuera del nivel gratuito).")
    if not de_verdad:
        for p in faltan[:10]:
            print(f"  [simulación] {p.ident}: «{p.texto}»")
        return len(faltan)
    elementos = plan.leer_manifiesto(carpeta)
    extra = {"ejecutar": ejecutar} if ejecutar else {}
    for p in faltan:
        destino = carpeta / f"{p.ident}.mp3"
        sintetizar.sintetizar(p.texto, voz, motor, destino, **extra)
        elementos[p.ident] = {
            "texto": p.texto, "archivo": destino.name, "huella": p.huella,
            "sha256": hashlib.sha256(destino.read_bytes()).hexdigest()}
        # Tras cada audio: si se corta a mitad, lo ya pagado no se repite.
        guardar_manifiesto(carpeta, voz, motor, elementos)
    return len(faltan)


def main(argv=None) -> int:
    a = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    a.add_argument("--voz", default="Lupe")
    a.add_argument("--motor", default="neural", choices=plan.PRECIO_MILLON_USD)
    a.add_argument("--salida", type=Path, default=RAIZ / "build" / "voces")
    a.add_argument("--de-verdad", action="store_true")
    args = a.parse_args(argv)
    textos = vocabulario.cargar(RAIZ / "assets/seed/pictogramas.json")
    generar(textos, args.voz, args.motor, args.salida / args.voz,
            args.de_verdad)
    return 0


if __name__ == "__main__":
    sys.exit(main())
