package com.limitcodev.bluetalk

import android.app.Activity
import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.Process
import android.provider.Settings
import android.util.Base64
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.util.concurrent.Executors

/**
 * Diagnóstico local de uso del teléfono (plan 14).
 *
 * Lee el «Acceso al uso» que el adulto concede en Ajustes de Android y
 * devuelve cuánto tiempo estuvo cada app en primer plano. No lee mensajes,
 * pantallas, historiales ni contenido: solo tiempos y nombres de app.
 * Todo se calcula en el teléfono y no se guarda ni se envía.
 */
class UsoTelefonoChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val canal = MethodChannel(messenger, "bluetalk/uso_telefono")
    private val ejecutor = Executors.newSingleThreadExecutor()
    private val ui = Handler(Looper.getMainLooper())
    private val cacheIconos = HashMap<String, String?>()

    init {
        canal.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "estado" -> result.success(mapOf("permiso" to tienePermiso()))
            "abrirAjustes" -> result.success(abrirAjustes())
            "resumen" -> {
                val desde = call.argument<Number>("desde")?.toLong() ?: 0L
                val hasta = call.argument<Number>("hasta")?.toLong()
                    ?: System.currentTimeMillis()
                ejecutor.execute {
                    val salida = try {
                        resumen(desde, hasta)
                    } catch (e: Exception) {
                        Log.w(TAG, "No se pudo leer el uso del teléfono", e)
                        null
                    }
                    ui.post {
                        if (salida == null) {
                            result.error(
                                "sin_datos",
                                "No se pudo leer el uso del teléfono.",
                                null,
                            )
                        } else {
                            result.success(salida)
                        }
                    }
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun tienePermiso(): Boolean {
        return try {
            val appOps = activity.getSystemService(AppOpsManager::class.java)
            val modo = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                appOps.unsafeCheckOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    activity.packageName,
                )
            } else {
                @Suppress("DEPRECATION")
                appOps.checkOpNoThrow(
                    AppOpsManager.OPSTR_GET_USAGE_STATS,
                    Process.myUid(),
                    activity.packageName,
                )
            }
            modo == AppOpsManager.MODE_ALLOWED
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo comprobar el permiso de uso", e)
            false
        }
    }

    private fun abrirAjustes(): Boolean {
        return try {
            val intent = Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                intent.data = Uri.parse("package:${activity.packageName}")
            }
            activity.startActivity(intent)
            true
        } catch (e: Exception) {
            try {
                activity.startActivity(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
                true
            } catch (otra: Exception) {
                Log.w(TAG, "No se pudo abrir Acceso al uso", otra)
                false
            }
        }
    }

    private fun resumen(desde: Long, hasta: Long): Map<String, Any> {
        if (hasta <= desde) {
            return mapOf(
                "permiso" to true,
                "desde" to desde,
                "hasta" to hasta,
                "totalSegundos" to 0,
                "apps" to emptyList<Map<String, Any>>(),
            )
        }
        if (!tienePermiso()) {
            return mapOf(
                "permiso" to false,
                "desde" to desde,
                "hasta" to hasta,
                "totalSegundos" to 0,
                "apps" to emptyList<Map<String, Any>>(),
            )
        }

        val usm = activity.getSystemService(UsageStatsManager::class.java)
        val eventos = usm.queryEvents(desde, hasta)
        val duraciones = HashMap<String, Long>()
        var paqueteActual: String? = null
        var inicioActual = 0L

        fun cerrar(hora: Long) {
            val paquete = paqueteActual ?: return
            val fin = hora.coerceIn(desde, hasta)
            val inicio = inicioActual.coerceIn(desde, hasta)
            if (fin > inicio) {
                duraciones[paquete] = (duraciones[paquete] ?: 0L) + (fin - inicio)
            }
            paqueteActual = null
            inicioActual = 0L
        }

        val evento = UsageEvents.Event()
        var leidos = 0
        while (eventos.hasNextEvent() && leidos < MAX_EVENTOS) {
            eventos.getNextEvent(evento)
            leidos++
            val hora = evento.timeStamp.coerceIn(desde, hasta)
            when (evento.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED,
                UsageEvents.Event.MOVE_TO_FOREGROUND,
                -> {
                    if (paqueteActual != evento.packageName) {
                        cerrar(hora)
                        paqueteActual = evento.packageName
                        inicioActual = hora
                    }
                }
                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.MOVE_TO_BACKGROUND,
                UsageEvents.Event.ACTIVITY_STOPPED,
                -> {
                    if (paqueteActual == evento.packageName) cerrar(hora)
                }
                UsageEvents.Event.SCREEN_NON_INTERACTIVE,
                UsageEvents.Event.DEVICE_SHUTDOWN,
                UsageEvents.Event.KEYGUARD_SHOWN,
                -> cerrar(hora)
            }
        }
        cerrar(hasta)

        val pm = activity.packageManager
        val lanzador = lanzadorActual(pm)
        val propias = setOfNotNull(
            activity.packageName,
            "com.android.systemui",
            "android",
            lanzador,
        )

        val validas = duraciones.filter { (paquete, segundos) ->
            segundos > 0 &&
                paquete !in propias &&
                pm.getLaunchIntentForPackage(paquete) != null
        }
        // Los eventos vienen en milisegundos; la app trabaja en segundos.
        val totalSegundos = validas.values.sum() / 1000

        val apps = validas.entries
            .filter { it.value >= MINIMO_MILISEGUNDOS }
            .sortedByDescending { it.value }
            .take(MAX_APPS)
            .map { (paquete, milisegundos) ->
                mapOf(
                    "paquete" to paquete,
                    "nombre" to nombreDe(pm, paquete),
                    "segundos" to milisegundos / 1000,
                    "icono" to iconoDe(pm, paquete),
                )
            }

        return mapOf(
            "permiso" to true,
            "desde" to desde,
            "hasta" to hasta,
            "totalSegundos" to totalSegundos,
            "apps" to apps,
        )
    }

    /// Paquete del lanzador de inicio activo, para no contarlo como «app».
    ///
    /// Solo se excluye el lanzador predeterminado: si se excluyeran todos los
    /// paquetes con una actividad HOME, también se perderían Ajustes y otras
    /// apps del sistema que declaran un inicio de respaldo.
    private fun lanzadorActual(pm: PackageManager): String? {
        val intent = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        return try {
            pm.resolveActivity(intent, PackageManager.MATCH_DEFAULT_ONLY)
                ?.activityInfo
                ?.packageName
        } catch (e: Exception) {
            null
        }
    }

    private fun nombreDe(pm: PackageManager, paquete: String): String {
        return try {
            val info = pm.getApplicationInfo(paquete, 0)
            pm.getApplicationLabel(info).toString()
        } catch (e: Exception) {
            paquete
        }
    }

    private fun iconoDe(pm: PackageManager, paquete: String): String? {
        if (cacheIconos.containsKey(paquete)) return cacheIconos[paquete]
        return try {
            val drawable = pm.getApplicationIcon(paquete)
            val lado = 64
            val bitmap = Bitmap.createBitmap(lado, lado, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, lado, lado)
            drawable.draw(canvas)
            val salida = ByteArrayOutputStream()
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, salida)
            val texto = Base64.encodeToString(
                salida.toByteArray(),
                Base64.NO_WRAP,
            )
            cacheIconos[paquete] = texto
            texto
        } catch (e: Exception) {
            cacheIconos[paquete] = null
            null
        }
    }

    fun dispose() {
        canal.setMethodCallHandler(null)
        ejecutor.shutdownNow()
        cacheIconos.clear()
    }

    companion object {
        private const val TAG = "UsoTelefono"
        private const val MINIMO_MILISEGUNDOS = 5_000L
        private const val MAX_APPS = 25
        private const val MAX_EVENTOS = 200_000
    }
}
