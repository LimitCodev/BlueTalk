"""Comprueba la plantilla sin red: seguridad y coste mínimo no se pierden."""
import unittest
from pathlib import Path

import yaml


class _CargadorCfn(yaml.SafeLoader):
    pass


# Etiquetas de CloudFormation (!Ref, !Sub...) como datos simples.
_CargadorCfn.add_multi_constructor(
    "!", lambda l, sufijo, nodo: (
        l.construct_scalar(nodo) if isinstance(nodo, yaml.ScalarNode)
        else l.construct_sequence(nodo) if isinstance(nodo, yaml.SequenceNode)
        else l.construct_mapping(nodo)))

PLANTILLA = yaml.load((Path(__file__).parent / "cdn.yaml").read_text(),
                      Loader=_CargadorCfn)
R = PLANTILLA["Resources"]


class PruebasPlantilla(unittest.TestCase):
    def test_bucket_privado_y_cifrado(self):
        p = R["Contenido"]["Properties"]
        self.assertTrue(all(p["PublicAccessBlockConfiguration"].values()))
        self.assertIn("BucketEncryption", p)
        self.assertEqual(R["Contenido"]["DeletionPolicy"], "Retain")

    def test_cdn_https_barato_y_sin_registros(self):
        c = R["Distribucion"]["Properties"]["DistributionConfig"]
        self.assertEqual(c["PriceClass"], "PriceClass_100")
        self.assertNotIn("Logging", c)
        b = c["DefaultCacheBehavior"]
        self.assertEqual(b["ViewerProtocolPolicy"], "redirect-to-https")
        self.assertEqual(b["AllowedMethods"], ["GET", "HEAD"])

    def test_solo_cloudfront_lee_el_bucket(self):
        (regla,) = R["PoliticaContenido"]["Properties"]["PolicyDocument"]["Statement"]
        self.assertEqual(regla["Principal"], {"Service": "cloudfront.amazonaws.com"})
        self.assertEqual(regla["Action"], "s3:GetObject")
        self.assertIn("AWS:SourceArn", regla["Condition"]["StringEquals"])

    def test_permisos_de_publicar_sin_comodines_peligrosos(self):
        reglas = R["PermisosPublicar"]["Properties"]["PolicyDocument"]["Statement"]
        acciones = [a for r in reglas for a in r["Action"]]
        self.assertFalse([a for a in acciones if a.endswith("*")])
        self.assertNotIn("s3:PutBucketPolicy", acciones)

    def test_publicar_puede_leer_las_salidas_de_su_pila(self):
        reglas = R["PermisosPublicar"]["Properties"]["PolicyDocument"]["Statement"]
        (regla,) = [r for r in reglas
                    if "cloudformation:DescribeStacks" in r["Action"]]
        self.assertEqual(regla["Resource"], "AWS::StackId")


if __name__ == "__main__":
    unittest.main()
