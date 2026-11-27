# Crear la cuenta de AWS de BlueTalk, paso a paso

**Para:** el dueño · **Tiempo:** unos 45 minutos, más la espera de la cuota de Lambda (de horas a 1-2 días).
**Lo que necesitas a mano:** una tarjeta de crédito o de débito, tu teléfono y una app de autenticación (Google Authenticator, Microsoft Authenticator o similar).

Al terminar tendrás una cuenta de AWS protegida, con una alarma de gasto. Claude podrá desplegar el servidor de BlueTalk desde esta laptop **sin ver nunca tus claves**.

> **Nunca pegues en el chat** contraseñas, códigos MFA, claves de acceso (`AKIA…`), la clave JSON de Google ni la contraseña del keystore. Si Claude necesita algo, ejecutará un comando que solo muestra el número de cuenta.

## Antes de empezar: ¿una cuenta o dos?

| Opción | Qué es | Cuándo conviene |
|---|---|---|
| **A. Una sola cuenta** (recomendada para empezar) | Toda la infraestructura de BlueTalk vive en tu cuenta nueva | Eres el único desarrollador y la cuenta es solo para BlueTalk |
| B. AWS Organizations + cuenta miembro `bluetalk` | Una cuenta «madre» que solo paga, y una cuenta hija solo para BlueTalk. Es gratis | Ya tienes otra cuenta de AWS con cosas tuyas, o quieres separar facturas y permisos |

Si eliges B, hazlo **antes** del primer despliegue: mover recursos después es molesto. En la parte 7 está lo que cambia.

## Parte 1: crear la cuenta (unos 15 minutos)

1. Entra en `https://aws.amazon.com` → **Crear una cuenta de AWS**.
2. Usa un correo que leas a menudo. Puede ser `bluetalk.soporte@gmail.com` o el tuyo. Ese correo será el usuario **raíz** (root), el dueño absoluto de la cuenta.
3. Nombre de la cuenta: `BlueTalk`.
4. Elige el tipo **Personal**, salvo que ya tengas una empresa constituida.
5. Introduce la tarjeta. AWS hace un cargo de verificación de 1 USD que devuelve.
6. Verifica tu teléfono con el código por SMS o por llamada.
7. Plan de soporte: **Basic (gratis)**.
8. Si te ofrecen elegir entre el plan gratuito con créditos y el plan de pago, elige el **gratuito**.

✅ Listo cuando puedas entrar en la consola: `https://console.aws.amazon.com`.

## Parte 2: proteger el usuario raíz (5 minutos, **no te la saltes**)

1. En la consola, arriba a la derecha, abre tu nombre → **Credenciales de seguridad**.
2. En **Autenticación multifactor (MFA)** → **Asignar dispositivo MFA** → **Aplicación de autenticación**.
3. Escanea el QR con tu app de autenticación y escribe los dos códigos seguidos que te pide.
4. **No crees claves de acceso para el usuario raíz.** Si ves la sección «Claves de acceso», déjala vacía.
5. Guarda la contraseña del raíz en tu gestor de contraseñas. A partir de aquí casi no la usarás.

## Parte 3: alarma de gasto (5 minutos)

El diseño fija un tope de **10 USD al mes**. Esto te avisa por correo antes de llegar.

1. En la barra de búsqueda de la consola escribe **Billing** → **Presupuestos (Budgets)** → **Crear presupuesto**.
2. Elige **Usar una plantilla** → **Presupuesto de gasto mensual**.
3. Nombre: `bluetalk-tope`. Importe: `10` USD.
4. Correos: el tuyo.
5. Crear.

Opcional: en **Billing → Preferencias de facturación**, activa «Recibir alertas de la capa gratuita».

> El corte automático del servidor (que apaga la API si el gasto se dispara) lo crea Claude en la plantilla SAM. Esta alarma es tu segunda red de seguridad.

## Parte 4: tu usuario de trabajo (10 minutos)

No se trabaja con el raíz. Crea un usuario administrador para el día a día con **IAM Identity Center**, el método que recomienda AWS: no deja claves permanentes en la laptop.

1. Arriba a la derecha, elige la región **EE. UU. Este (Norte de Virginia) `us-east-1`**. BlueTalk usa esa región.
2. Busca **IAM Identity Center** → **Habilitar**. Si pregunta, elige «Habilitar con AWS Organizations».
3. **Usuarios → Agregar usuario.** Nombre de usuario: `bluetalk-admin`. Correo: el tuyo. Nombre y apellido: los tuyos.
4. Te llegará un correo de invitación. Ábrelo, crea la contraseña y registra MFA también para este usuario.
5. **Conjuntos de permisos → Crear** → **Conjunto predefinido** → `AdministratorAccess`. Duración de la sesión: 8 horas.
6. **Cuentas de AWS** → marca tu cuenta → **Asignar usuarios o grupos** → `bluetalk-admin` → conjunto `AdministratorAccess` → Enviar.
7. Apunta la **URL del portal de acceso** que aparece en el panel de IAM Identity Center. Tiene esta forma: `https://d-xxxxxxxxxx.awsapps.com/start`. No es secreta.

## Parte 5: conectar la laptop (5 minutos, en tu terminal)

Ejecuta esto **tú**, en una terminal normal (o en Claude Code con `!` delante):

```bash
aws configure sso --profile bluetalk-admin
```

Responde así:

| Pregunta | Respuesta |
|---|---|
| SSO session name | `bluetalk` |
| SSO start URL | la URL del portal de la parte 4, paso 7 |
| SSO region | `us-east-1` |
| SSO registration scopes | deja el valor por defecto (Enter) |

Se abrirá el navegador para que autorices. Después elige tu cuenta y el rol `AdministratorAccess`, y responde:

| Pregunta | Respuesta |
|---|---|
| Default client Region | `us-east-1` |
| CLI default output format | `json` |

Comprueba que funciona:

```bash
aws sts get-caller-identity --profile bluetalk-admin
```

Debe mostrar tu número de cuenta (12 dígitos) y un `Arn` con `AdministratorAccess`. Ese número de cuenta sí lo puedes compartir con Claude.

La sesión dura 8 horas. Cuando caduque, renuévala con:

```bash
aws sso login --profile bluetalk-admin
```

> **Si IAM Identity Center no te deja habilitarlo**, usa el plan B del archivo `solo-el-dueno-2026-11-26.md` §7: un usuario IAM con claves de acceso y `aws configure --profile bluetalk-admin`. Las claves las escribes tú en la terminal, nunca en el chat.

## Parte 6: pedir más concurrencia para Lambda (2 minutos, y luego esperar)

Las cuentas nuevas empiezan con un límite muy bajo de ejecuciones simultáneas de Lambda. El servidor de BlueTalk reserva 10, así que hace falta subirlo.

1. En la región `us-east-1`, busca **Service Quotas** → **Servicios de AWS** → **AWS Lambda**.
2. Abre **Concurrent executions** → **Solicitar un aumento de nivel de cuenta**.
3. Valor nuevo: `50`. Envíalo.
4. AWS responde por correo, normalmente en horas y a veces en 1-2 días. Mientras tanto Claude puede seguir con todo lo demás.

## Parte 7 (solo si elegiste la opción B: Organizations)

1. Haz las partes 1 a 3 en la cuenta «madre».
2. Busca **AWS Organizations** → **Crear una organización**.
3. **Agregar una cuenta de AWS** → **Crear una cuenta**. Nombre: `bluetalk`. Usa un correo distinto: un alias como `tucorreo+bluetalk@gmail.com` sirve.
4. En la parte 4, al asignar el usuario `bluetalk-admin`, elige la cuenta **`bluetalk`**, no la madre.
5. Haz la parte 6 dentro de la cuenta `bluetalk`.
6. El presupuesto de la parte 3 puede vivir en la madre: ve la factura de las dos.

## Parte 8: qué le dices a Claude cuando termines

Escribe en el chat algo como:

> «Cuenta de AWS lista. Perfil `bluetalk-admin` configurado con SSO. Pedí la cuota de Lambda a 50 (aprobada o pendiente). Tienes mi OK para desplegar el servidor».

Con eso Claude:

1. Ejecuta `aws sts get-caller-identity --profile bluetalk-admin` para comprobar el acceso.
2. Prueba primero todo en local con el emulador (`aws-emu`).
3. Te muestra qué va a crear (Lambda, DynamoDB, CloudFront, WAF, alarma con corte) y su coste estimado.
4. Despliega **solo después de tu OK explícito** para ese despliegue.
5. Cuando cree la distribución de CloudFront, te pedirá que elijas el plan **Free** de tarifa plana en la consola.

## Lo que AWS te puede cobrar

- **Estimado para BlueTalk:** menos de 0,001 USD por familia al mes. Con pocas familias, el total queda en céntimos.
- **El riesgo real** es un abuso o un error que dispare peticiones. Por eso hay tres capas: el WAF limita peticiones, la concurrencia de Lambda está reservada a 10 y una alarma corta la API si el gasto se dispara. Tu presupuesto de 10 USD es la cuarta.
- Si un día quieres cerrar todo: Claude borra la pila con SAM, y tú cierras la cuenta en **Cuenta → Cerrar cuenta**.

## Después de AWS (para que la suscripción funcione en Play)

Estos pasos no son de AWS, pero sin ellos la suscripción no funciona:

1. **Play Console → Monetiza con Play → Comenzar:** cuenta de comerciante, con tu banco y tus datos fiscales.
2. **Play Console → Configuración → Acceso a la API:** vincula un proyecto de Google Cloud y activa las API *Google Play Android Developer* y *Play Integrity*.
3. Crea en ese proyecto una cuenta de servicio y descarga su clave JSON. **Tú** la guardas en AWS con:

   ```bash
   aws ssm put-parameter --profile bluetalk-admin --region us-east-1 \
     --name /bluetalk/google-cuenta-servicio --type SecureString \
     --value file://RUTA/A/LA/CLAVE.json
   ```

   Después borra el archivo JSON de tu carpeta de descargas.
4. Decide el precio y los países de la suscripción `bluetalk_familia`.
