# Decisiones y trámites del dueño que retrasan la publicación (en progreso)

**Actualizado:** 26-nov-2026 · **Para:** LimitCodev
**Estado general:** (en progreso). Claude avanza el código por módulos (`docs/superpowers/plans/`); este documento recoge solo lo que **no puede hacer Claude** y frena el despliegue.

Leyenda: ⛔ bloquea · ⏳ (en progreso) · ✅ resuelto

## Ruta crítica (en este orden)

| # | Decisión o trámite | Qué retrasa | Estado |
|---|---|---|---|
| 1 | Restaurar el keystore | Todo AAB, y por tanto el reloj de 14 días | ⏳ (en progreso), D-4 |
| 2 | Empezar ya la prueba cerrada con la versión actual | Producción: Google exige 12 testers durante 14 días seguidos | ⛔ decidir |
| 3 | Reclutar a los testers | Lo mismo que el punto 2 | ⏳ puedes hacerlo ya |
| 4 | Perfil de pagos y cuenta bancaria en Play Console | Crear la suscripción | ⛔ |
| 5 | Precio y países de la suscripción | Crear el producto y fijar la ley aplicable | ⛔ |
| 6 | Proyecto de Google Cloud vinculado a Play | Que el servidor verifique pagos e Integrity | ⛔ |
| 7 | Cuenta de AWS | El despliegue real del servidor | ⏳ (en progreso) |
| 8 | Revisión legal | Publicar la versión con nube | ⛔ |
| 9 | Enviar a revisión y pedir producción | La salida a la tienda | Al final |

## 1. Keystore ⏳

- Copia el archivo a `~/keystores/bluetalk-release.keystore` y corre `./scripts/build-aab.sh` en una terminal normal.
- No pegues sus contraseñas en el chat.
- Sin este paso no hay AAB, y sin AAB no empieza la prueba cerrada.

## 2. Prueba cerrada: empezarla ya ⛔ (decisión)

**Recomendación: empezarla en cuanto exista el AAB, con la app actual (sin nube).** Google cuenta los 14 días desde que hay 12 testers inscritos, y la versión se puede actualizar durante la prueba sin reiniciar el reloj. Así los 14 días transcurren mientras Claude termina los módulos de la suscripción. Esperar a tener la suscripción lista añadiría como mínimo 14 días al final.

**Condiciones:**
- Los testers deben **seguir inscritos** los 14 días.
- Cada versión nueva se sube a la misma pista de prueba cerrada.
- Antes de subirla hay que tener completa la **Seguridad de los datos** (punto 2b).

### 2b. Seguridad de los datos para la versión de prueba ⛔ (decisión)

Decidiste «Sí, recopila» (D-1). Para la prueba cerrada hay dos caminos:

- **A (recomendado):** declarar ya lo que recogerá la versión final.
  - Lo que hay que declarar:
    - Interacciones con la app, para analítica, opcional y anónimo.
    - Historial de compras, para la funcionalidad de la app. Que haga falta declararlo está **NO VERIFICADO**.
  - Lo que no se declara: los informes y la copia de seguridad cifrados de extremo a extremo, porque Google los exime.
  - Declarar de más es menos grave que declarar de menos. Esto último sí se sanciona.
- **B:** declarar «No recopila» para la versión actual y cambiarlo antes de subir la versión con nube. Hay que acordarse de hacerlo.

## 3. Testers: sí, puedes avanzarlo ya ⏳

No depende de Claude ni del keystore:

1. Reúne **15–20 adultos** con cuenta de Gmail y teléfono Android. Así tienes margen si alguno se sale; el mínimo es 12. Mejor si son familias o terapeutas reales.
2. Pídeles permiso para usar su correo **solo** en la prueba.
3. En Play Console, en Pruebas → Prueba cerrada → Testers, crea la lista de correos. Claude puede cargarla con tu OK.
4. Cuando exista el AAB, envíales el enlace de inscripción. Deben aceptarlo, instalar la app y usarla varias veces durante los 14 días.
5. Guarda sus comentarios: Google pregunta por ellos al pedir producción.

**No uses cuentas de niños ni datos reales de menores** en la prueba.

## 4. Perfil de pagos ⛔

En Play Console → Configuración → Perfil de pagos registra la cuenta bancaria y los datos fiscales. Google puede tardar días en verificarlos, así que conviene empezar ya. Sin el perfil no se puede crear la suscripción `bluetalk_familia`.

## 5. Precio y países ⛔ (decisión)

- **Ya decidido:**
  - Mensual con 7 días de prueba.
  - Hasta 3 niños por pago.
  - Comunicar sigue gratis.
- **Falta:**
  - El precio. El pitch dice CLP 10.500; Google se queda con el 15 %.
  - Los países. Perú y Chile, ¿o toda Latinoamérica? Cada país añade su ley de datos.

## 6. Proyecto de Google Cloud ⛔

1. En Play Console → Configuración → Acceso a la API, vincula un proyecto de Google Cloud.
2. Activa las API **Google Play Android Developer** y **Play Integrity**.
3. Crea una cuenta de servicio con permiso para ver datos financieros y gestionar pedidos y suscripciones.
4. Descarga su clave JSON. **Tú** la guardas en SSM de AWS (`/bluetalk/google-cuenta-servicio`). Nunca va al chat ni al repo.

## 7. Cuenta de AWS ⏳

1. Crea la cuenta y activa MFA en la cuenta raíz.
2. Crea un usuario administrador aparte para trabajar.
3. Ejecuta tú mismo `aws configure --profile bluetalk-admin`. **No pegues claves en el chat.**
4. En Service Quotas, pide que la concurrencia de Lambda sea al menos 50.
5. Cuando Claude cree la distribución, elige el plan **Free** de tarifa plana de CloudFront.
6. Dale a Claude el OK explícito para el primer despliegue real.

AWS cobra siempre a tu tarjeta. El diseño fija un tope de 10 USD al mes con corte automático. El coste estimado es menor de 0,001 USD por familia.

## 8. Legal ⛔

- **Abogado:**
  - Ley 29733 de Perú: si el banco de datos debe inscribirse ante la Autoridad de Protección de Datos Personales (**NO VERIFICADO**) y la transferencia internacional a AWS en EE. UU.
  - La ley de cada país donde se venda.
- **Aprobar** la política de privacidad y los términos nuevos que prepare Claude: suscripción, nube cifrada y contadores.
- **Antes del 1-mar-2027:** qué teléfono y dirección mostrará Google como comerciante.

## 9. Al final

- Probar el AAB en un teléfono físico de gama baja.
- Dar el OK, archivo por archivo, para subir las capturas nuevas.
- Pulsar «Enviar a revisión» y responder el formulario de acceso a producción.
- Que alguien atienda `bluetalk.soporte@gmail.com`.
