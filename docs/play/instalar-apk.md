# Instalar el APK de BlueTalk

BlueTalk aún no está en Play Store: se instala con un archivo `.apk`. Android
y Play Protect avisan con **cualquier** APK que venga de fuera de la tienda,
aunque esté firmado. Es normal; no es que la app sea sospechosa.

## Texto corto para quien prueba la app

> Toca **Instalar de todas formas** (el texto pequeño), no **Entendido**.
> La app no usa internet ni pide cuenta.

## Pasos con detalle

1. Descarga el APK desde el enlace. Si es posible, no lo envíes por WhatsApp:
   WhatsApp muestra su propio aviso con todo `.apk`.
2. Toca el archivo descargado (`BlueTalk.apk` es el de casi todos los
   móviles actuales; si tu móvil es muy viejo, pide el de `armeabi-v7a`).
3. Si aparece «Por tu seguridad, Android no permite instalar aplicaciones
   desconocidas»: activa el permiso para el gestor de archivos que uses y
   vuelve atrás.
4. Si Play Protect dice «aplicación desconocida» o «no reconocida»: toca
   **Instalar de todas formas** (texto pequeño). No toques **Entendido**.
5. Espera a «App instalada» y abre BlueTalk.

## Comprobar que el archivo no cambió (hash SHA-256)

`scripts/build-apk.sh` imprime el hash SHA-256 de cada APK al compilar.
Quien reciba el archivo puede comprobarlo desde una computadora:

```bash
sha256sum BlueTalk.apk
```

El resultado debe ser **exactamente** el hash que se publicó junto al
enlace. Si no coincide, no instales ese archivo.

## Qué significa cada aviso

| Aviso | Qué es |
|---|---|
| «App desconocida» / «desarrollador desconocido» | Certificado nuevo fuera de Play Store. Normal. |
| Play Protect quiere analizar la app | Se puede permitir; la app no hace red. |
| WhatsApp avisa con el archivo | Lo hace con todo `.apk`. Por eso se distribuye por enlace. |

La app **no usa internet** (el permiso `INTERNET` no está en el manifiesto
de release), no pide cuenta y los datos del menor no salen del teléfono.
Los permisos que sí pide están justificados en `docs/play/permisos.md`.

## A largo plazo

Lo único que elimina del todo los avisos es subir la app a una **prueba
cerrada de Play Console**. Es decisión del dueño: ver
`docs/informes/decisiones-pendientes.md`.
