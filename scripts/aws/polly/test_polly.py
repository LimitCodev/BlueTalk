"""Pruebas sin red: Polly se sustituye por un falso que escribe bytes."""
import json
import tempfile
import unittest
from pathlib import Path

import generar_voces
import plan
import vocabulario


def polly_falso(llamadas):
    def ejecutar(cmd, **_):
        llamadas.append(cmd)
        Path(cmd[-1]).write_bytes(b"ID3-audio")
    return ejecutar


class PruebasPolly(unittest.TestCase):
    def setUp(self):
        self.dir = Path(tempfile.mkdtemp())
        self.textos = {"hola": "Hola", "agua": "Agua"}

    def test_simulacion_no_llama_a_aws(self):
        llamadas = []
        n = generar_voces.generar(self.textos, "Lupe", "neural", self.dir,
                                  False, polly_falso(llamadas))
        self.assertEqual(n, 2)
        self.assertEqual(llamadas, [])

    def test_genera_y_la_cache_evita_repetir(self):
        llamadas = []
        falso = polly_falso(llamadas)
        generar_voces.generar(self.textos, "Lupe", "neural", self.dir, True, falso)
        self.assertEqual(len(llamadas), 2)
        m = json.loads((self.dir / "manifiesto.json").read_text())
        self.assertEqual(m["elementos"]["hola"]["archivo"], "hola.mp3")
        n = generar_voces.generar(self.textos, "Lupe", "neural", self.dir, True, falso)
        self.assertEqual((n, len(llamadas)), (0, 2))

    def test_texto_cambiado_o_audio_borrado_se_regenera(self):
        falso = polly_falso([])
        generar_voces.generar(self.textos, "Lupe", "neural", self.dir, True, falso)
        (self.dir / "agua.mp3").unlink()
        cambiados = {"hola": "Hola amigo", "agua": "Agua"}
        faltan = plan.pendientes(cambiados, "Lupe", "neural", self.dir)
        self.assertEqual([p.ident for p in faltan], ["agua", "hola"])

    def test_coste(self):
        faltan = plan.pendientes({"a": "x" * 1000}, "Lupe", "neural", self.dir)
        self.assertAlmostEqual(plan.coste_usd(faltan, "neural"), 0.016)

    def test_vocabulario_rechaza_ids_repetidos(self):
        ruta = self.dir / "p.json"
        ruta.write_text(json.dumps([{"id": "a", "label": "A"}] * 2))
        with self.assertRaises(ValueError):
            vocabulario.cargar(ruta)


if __name__ == "__main__":
    unittest.main()
