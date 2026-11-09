"""Llamada a Polly con la CLI de AWS (sin boto3: no añade dependencias)."""
import subprocess
from pathlib import Path


def comando(texto: str, voz: str, motor: str, destino: Path) -> list[str]:
    return [
        "aws", "polly", "synthesize-speech",
        "--engine", motor,
        "--voice-id", voz,
        "--output-format", "mp3",
        "--sample-rate", "22050",
        "--text", texto,
        str(destino),
    ]


def sintetizar(texto: str, voz: str, motor: str, destino: Path,
               ejecutar=subprocess.run) -> None:
    """Escribe el MP3 en [destino]. Lanza error si AWS falla."""
    ejecutar(comando(texto, voz, motor, destino), check=True,
             stdout=subprocess.DEVNULL)
    if not destino.exists() or destino.stat().st_size == 0:
        raise RuntimeError(f"Polly no devolvió audio para {destino.name}")
