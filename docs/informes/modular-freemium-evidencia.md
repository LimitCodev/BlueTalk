# Modularización, freemium e infraestructura AWS — evidencia (2026-11-07)

Rama `feat/modular-freemium-aws`, desde `main` en `4be9f4d`. Sin push ni merge.

| Commit | Qué | Verificado |
|---|---|---|
| `c29b27c` | `.gitignore` con fotos, audios y vídeos personales | `git status` ya no los lista |
| `e1d5e86` | `AlmacenLocal`: 15 archivos de features/core dejan de usar `SharedPreferences`; las claves no cambian | analyze 0 · test 348/348 |
| `2e1d312` | `CanalNativo`: 4 gateways sin `try/catch` repetido (−37 líneas) | analyze 0 · test 349 + 3 nuevos |
| `b32ef8b` | Núcleo freemium (`Plan`, `Funcion`, `FuenteDerechos`, `TiendaCompras`) sin conectar | 5 tests nuevos |
| `5190f76` | CloudFormation (S3 + CloudFront + IAM + alarma), página legal y Polly, **solo simulación** | 5 + 4 tests de Python sin red; publicar en modo real sale con 1 si queda `demo@bluetalk.app` |
| `6b7027a` | Trinquete de 100 líneas (58 archivos en deuda) | test verde |
| `21d19ca` `cd05f78` `943f2dd` `6b18b2d` `db21893` | Partidos: repos locales, comunicador, ajustes, cuentos, artista | analyze 0 · test 359/359 tras cada uno |

Deuda que queda: **53 archivos** por encima de 100 líneas (lista en
`test/arquitectura/tamano_test.dart`). No se tocó el filtro web, el monitoreo
ni la protección: la auditoría de Play recomienda sacarlos de la v1, y
partirlos ahora podría ser trabajo perdido.

**NO VERIFICADO:**

- Ningún comando real de AWS; la plantilla no pasó `cfn-lint` ni
  `aws cloudformation validate-template` (no instalados o con red).
- Ningún build de Android ni prueba en teléfono (la máquina estaba cargada).
- La redistribución de audio de Polly según los AWS Service Terms.
- `6b18b2d` por sí solo deja `tamano_test` en rojo (la entrada de
  `cuentos_screen` se borra en el commit siguiente). Afecta solo a un `git bisect`.
