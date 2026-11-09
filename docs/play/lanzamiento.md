# Lanzamiento en Google Play

Consultado en la ayuda oficial de Play Console el 8-nov-2026. Google puede
cambiarlo: confirmar en la propia consola antes de planificar.

## Regla para una cuenta personal nueva

Las cuentas personales creadas después del 13-nov-2023 deben pasar una prueba
cerrada antes de publicar en producción:

- **Mínimo 12 testers** apuntados sin interrupción.
- **Mínimo 14 días seguidos.** Quien sale y vuelve a entrar reinicia su cuenta
  de días.
- Después se solicita el acceso a producción desde el panel. La revisión suele
  tardar **7 días o menos**, y a veces más.
- Google puede pedir más pruebas si hay menos de 12 testers o si **casi no usan
  la app**. Estar apuntado no basta: tienen que abrirla y usarla.

No se conoce una excepción para cuentas personales. Una cuenta de organización
no tiene esta regla, pero exige una entidad legal y número D-U-N-S, cuyo trámite
puede tardar 30 días o más.

## Vías para probar antes

| Vía | Quién | Espera | Sirve para los 14 días |
|---|---|---|---|
| APK `directa` (`scripts/build-apk.sh`) | Quien reciba el archivo | Ninguna, no necesita cuenta | No |
| Prueba interna de Play | Hasta 100 testers | Minutos; la primera vez, unas horas | No |
| Prueba cerrada de Play | Los 12 o más testers | La primera vez, unas horas | **Sí** |

## Pasos, en orden

1. Crear la cuenta personal `limitcodev` en Play Console. Pago único de 25 USD
   con tarjeta no prepago y documento de identidad. Los datos deben coincidir
   exactamente con el perfil de pagos de Google. El nombre legal puede mostrarse
   en la ficha.
2. Verificar el acceso a un teléfono Android con la app Play Console.
3. Generar el AAB firmado: `./scripts/build-aab.sh`, fuera del sandbox.
4. Crear la app `com.limitcodev.bluetalk`, activar Play App Signing y subir el
   AAB a **prueba interna**. Probarlo en un teléfono.
5. Publicar la política de privacidad en una URL pública, con correo real.
6. Completar en la consola: seguridad de los datos, clasificación de contenido,
   público objetivo y Familias, acceso a la app y ficha. El acceso a la app no
   necesita credenciales: el código del adulto se crea en el primer uso.
7. Subir el AAB a **prueba cerrada** y añadir al menos 15 correos, para tener
   margen si alguien sale.
8. Mandar el enlace de aceptación. Cada tester acepta e instala desde Play.
9. Mantener la prueba 14 días seguidos. Pedir a los testers que usen la app varias
   veces y que envíen comentarios: el formulario pregunta por ellos.
10. Solicitar acceso a producción y esperar la revisión.

## Calendario

| Momento | Hecho |
|---|---|
| Día 0 | Arranca la prueba cerrada con 12 o más testers apuntados |
| Día 14 | Primer día en que se puede solicitar producción |
| Hasta el día 21 | Respuesta habitual de Google |

Antes del día 0 hay que contar la verificación de identidad de la cuenta. Las
páginas consultadas no indican cuánto tarda.

## Fuentes

- [Requisitos de prueba para cuentas personales nuevas](https://support.google.com/googleplay/android-developer/answer/14151465?hl=en)
- [Configurar pruebas abiertas, cerradas o internas](https://support.google.com/googleplay/android-developer/answer/9845334?hl=en)
- [Información requerida para crear una cuenta](https://support.google.com/googleplay/android-developer/answer/13628312?hl=en)
- [Primeros pasos con Play Console](https://support.google.com/googleplay/android-developer/answer/6112435?hl=en)
