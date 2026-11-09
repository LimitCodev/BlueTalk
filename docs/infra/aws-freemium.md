# Infraestructura AWS mínima para el freemium de BlueTalk

**Estado (7-nov-2026):** todo listo y probado **en simulación**. No hay cuenta
de AWS conectada ni se ha llamado a ningún servicio. La app **no** habla con
AWS en ningún momento.

## 0. Qué hace falta para el piloto

**Nada de AWS.** La app no usa la red. El piloto y la prueba cerrada solo
necesitan una URL pública con la política de privacidad, y sirve cualquier
alojamiento estable. AWS hace falta únicamente para las voces de Polly y para
servir esa página desde CloudFront, si se elige esa opción. Los pasos están en §4.

## 1. Idea central: AWS trabaja antes de compilar, no mientras el niño usa la app

| Pieza | Qué hace | Cuándo corre | Coste esperado |
|---|---|---|---|
| **Polly** | Graba las voces naturales del vocabulario en MP3 | Una vez por cambio de vocabulario, en el equipo del desarrollador | Céntimos por voz completa |
| **S3** (privado) | Guarda la página legal y, más adelante, paquetes premium | Siempre | < 0,01 USD/mes (pocos MB) |
| **CloudFront** | Sirve la URL pública de la política de privacidad (obligatoria en Play) | Siempre | 0 USD dentro del nivel gratuito permanente (1 TB y 10 M peticiones/mes) |
| **Budgets** | Avisa por correo si el gasto supera el límite (5 USD por defecto) | Siempre | No verificado; los presupuestos básicos no suelen tener coste |
| **Device Farm** | Pruebas en teléfonos y tablets reales antes de la prueba cerrada | A demanda, a mano | Por minuto de dispositivo; no automatizado |

No hay Lambda, base de datos, Cognito ni servidores. Cada uno de esos añade
coste fijo, cuentas de usuario y obligaciones de privacidad con menores. Se
dejan fuera a propósito hasta que un caso concreto los justifique.

### Números de referencia (verificados el 7-nov-2026, cambian)

- Polly neural: 16 USD por millón de caracteres (revisado el 8-nov-2026: una
  página de AWS muestra también 19,20; confirmar antes de pagar). 400 palabras
  × ~8 letras × 6 voces ≈ 19.200 caracteres ≈ **0,31 USD**, una sola vez. El
  vocabulario actual (239 entradas, unos 1.450 caracteres) cuesta ~0,02 USD por voz.
- **Cuentas creadas desde el 15-jul-2025:** ya no hay 12 meses gratis. Reciben
  100 USD de crédito (hasta 200 con actividades) y eligen plan gratuito o de
  pago. El **plan gratuito se cierra a los 6 meses** o al agotar los créditos,
  lo que ocurra antes. La URL de la política debe seguir viva mientras la app
  esté en Play: **hay que pasar a plan de pago antes de los 6 meses**. El coste
  esperado sigue siendo de céntimos al mes.
- Polly permite guardar y reproducir el audio generado sin coste adicional
  (FAQ de Polly). **Pendiente:** leer la sección de Polly en los AWS Service
  Terms antes de publicar, para confirmar la redistribución dentro de la app.
- CloudFront: nivel gratuito de 1 TB de transferencia y 10 M de peticiones al
  mes. La mayoría de fuentes lo dan como permanente, pero alguna lo limita a 12
  meses: **confirmar en la página de precios de AWS**. 10.000 descargas de un
  paquete de 5 MB son 50 GB, dentro de ese nivel.

## 2. Qué es gratis y qué es premium

Regla no negociable (código: `lib/core/premium/plan.dart`): **comunicar nunca
es premium**. Tablero, voz del teléfono, frases, rutinas, juegos, modo calma
y panel del adulto son gratis.

| Extra premium | Origen | Estado |
|---|---|---|
| `Funcion.vocesNaturales` | MP3 de Polly generados antes de compilar | Generador listo (`scripts/aws/polly/`); falta el reproductor (§5) |
| `Funcion.paquetesVocabulario` | Paquetes servidos desde CloudFront `/paquetes/` | Solo infraestructura; sin descarga en la app |

Las pantallas preguntan siempre con `ref.watch(puedeUsarProvider(Funcion.x))`.
Nunca consultan la tienda ni Play directamente.

## 3. Archivos

| Ruta | Qué es |
|---|---|
| `infra/aws/cdn.yaml` | CloudFormation: S3 privado + CloudFront (OAC), política IAM de publicación y alarma de gasto |
| `infra/aws/test_plantilla.py` | Comprueba sin red que el bucket sigue privado, sin registros de IP y con permisos mínimos |
| `infra/aws/sitio/` | Portada y estilo de la página legal |
| `scripts/aws/comun.sh` | Simulación por defecto (`DE_VERDAD=1` para ejecutar) |
| `scripts/aws/desplegar_cdn.sh` | Crea o actualiza la pila |
| `scripts/aws/publicar_legal.sh` | `docs/legal/*.md` → HTML (pandoc) → S3; **se niega** si queda el correo de demostración |
| `scripts/aws/polly/` | Generador de voces con caché por huella: nunca paga dos veces el mismo audio |

Pruebas sin red:

```bash
python3 -m unittest discover -s scripts/aws/polly
python3 -m unittest discover -s infra/aws -p 'test_*.py'
```

## 4. Conectar AWS (cuando el dueño lo decida), en este orden

1. Crear la cuenta de AWS y activar MFA. Nunca usar la cuenta raíz: crear un
   usuario administrador para el despliegue y otro **solo para publicar**. La
   política de publicar no alcanza para crear la pila.
2. `aws configure --profile bluetalk-admin` y `export AWS_PROFILE=bluetalk-admin`.
3. Simular: `scripts/aws/desplegar_cdn.sh tu@correo`. Revisar la salida.
4. Real: `DE_VERDAD=1 scripts/aws/desplegar_cdn.sh tu@correo` y confirmar
   el correo de la alarma.
5. Asignar la política `PoliticaPublicar` (salida de la pila) al usuario de
   publicación, `aws configure --profile bluetalk` y `export AWS_PROFILE=bluetalk`.
6. Poner el correo y la identidad reales en `docs/legal/*.md`.
7. `DE_VERDAD=1 scripts/aws/publicar_legal.sh` y copiar la URL que imprime
   en Play Console (política de privacidad).
8. Voces: `python3 scripts/aws/polly/generar_voces.py --voz Lupe` (simula)
   y luego con `--de-verdad`. Los MP3 quedan en `build/voces/Lupe/`.

Voces neuronales en español para comparar de oído: `Lupe`, `Pedro` (es-US),
`Mia`, `Andrés` (es-MX), `Lucia`, `Sergio` (es-ES).

## 5. Conectar Google Play Billing (decisión del dueño)

Ya existe el contrato: `FuenteDerechos` (`lib/core/premium/derechos.dart`) y
`TiendaCompras` (`lib/core/premium/tienda.dart`). Para conectarlo:

1. Aprobar la dependencia `in_app_purchase` (regla: sin dependencias sin permiso).
2. Crear el producto en Play Console. Recomendado: **compra única** no
   consumible, más simple que una suscripción y sin cobro recurrente a familias.
3. Implementar `DerechosPlayBilling` (consulta las compras al arrancar y las
   **reconoce** en menos de 3 días, o Play las reembolsa) y `TiendaPlay`.
   Sobreescribir `fuenteDerechosProvider` y `tiendaComprasProvider` en
   `lib/app/di.dart`. Ninguna pantalla cambia.
4. El botón de compra va **solo** dentro del modo padre (tras el PIN). La
   Política de Familias exige que un adulto se autentique antes de comprar.
5. Actualizar la política de privacidad: Google procesa el pago; BlueTalk
   no recibe datos de tarjeta.

Para probar la interfaz premium sin Play: `flutter run --dart-define=BLUETALK_PLAN=premium`.

## 6. Atajos conocidos (deuda consciente)

- **Reproductor de MP3 pendiente.** `flutter_tts` no reproduce archivos.
  Opciones: un canal nativo `MediaPlayer` en Kotlin con `CanalNativo` (sin
  dependencia) o el paquete `audioplayers`. Requiere un build de Android, que
  se aplaza mientras la máquina esté cargada.
- **Voces dentro del APK.** Recomendado para la v1: incluir una voz premium en
  el APK (~2–3 MB con 400 palabras) y desbloquearla con la compra. Así la app
  sigue sin red. Los paquetes por CDN quedan para después.

## 7. Impacto en Play Console

- **Data safety:** sin cambios mientras la app no use la red para AWS. Si se
  descargan paquetes, no se envía ningún identificador y CloudFront no guarda
  registros (`cdn.yaml` sin `Logging`).
- **Política de privacidad:** su §2 dice «no hay servidores del
  desarrollador». Sigue siendo cierto con las voces dentro del APK. Si se
  añaden descargas, hay que describirlas.
- **Device Farm:** subir el APK y lanzar una prueba de humo en 2–3 tablets y
  teléfonos de gama baja antes de la prueba cerrada de 14 días. Hoy es un paso manual.

## Fuentes

- [Amazon Polly – FAQ](https://aws.amazon.com/polly/faqs/)
- [Amazon Polly – Precios](https://aws.amazon.com/polly/pricing/)
- [CloudFront – planes de tarifa plana y nivel gratuito](https://aws.amazon.com/blogs/networking-and-content-delivery/introducing-flat-rate-pricing-plans-with-no-overages)
- [Google Play – aprobación de compras en familias](https://support.google.com/families/answer/7039872?hl=en)
