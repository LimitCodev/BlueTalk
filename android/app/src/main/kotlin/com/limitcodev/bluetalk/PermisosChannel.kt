package com.limitcodev.bluetalk

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.PowerManager
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Permiso de avisos (horario) y exclusión de optimización de batería.
 *
 * Solo informa y abre las pantallas de Android: la app no concede nada por
 * su cuenta y no lee qué avisos se han mandado.
 *
 * Sobre la batería se usa [Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS],
 * que abre la lista de Android, **no** la petición directa
 * `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`: esa última está restringida en
 * Google Play a tipos de app concretos y una app de control parental no
 * entra. Se anota en los informes para que el dueño pueda cambiarlo.
 */
class PermisosChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val canal = MethodChannel(messenger, "bluetalk/permisos")

    init {
        canal.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "estado" -> result.success(estado())
            "pedirAvisos" -> result.success(pedirAvisos())
            "pedirBateria" -> result.success(pedirBateria())
            "abrirAjustesVoz" -> result.success(abrirAjustesVoz())
            else -> result.notImplemented()
        }
    }

    private fun abrirAjustesVoz(): Boolean = try {
        // Android no publica una constante para esta pantalla.
        activity.startActivity(Intent("com.android.settings.TTS_SETTINGS"))
        true
    } catch (e: android.content.ActivityNotFoundException) {
        Log.w("PermisosChannel", "sin pantalla de ajustes de voz", e)
        false
    }

    private fun estado(): Map<String, Any> = mapOf(
        // Los avisos están bloqueados si el permiso está concedido pero la
        // app tiene los avisos apagados en Ajustes de Android.
        "avisos" to avisosConcedidos(),
        "bateria" to bateriaExenta(),
    )

    private fun avisosConcedidos(): Boolean = try {
        val permiso = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.checkSelfPermission(android.Manifest.permission.POST_NOTIFICATIONS) ==
                android.content.pm.PackageManager.PERMISSION_GRANTED
        } else {
            // En Android 12- no hay permiso en tiempo de ejecución.
            true
        }
        // `areNotificationsEnabled` (API 24+) cubre el caso de tener el
        // permiso concedido pero los avisos apagados a mano en Ajustes.
        val interruptor = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            val nm = activity.getSystemService(Context.NOTIFICATION_SERVICE)
                as? android.app.NotificationManager
            nm?.areNotificationsEnabled() ?: false
        } else {
            true
        }
        permiso && interruptor
    } catch (e: Exception) {
        Log.w(TAG, "No se pudo leer el estado de los avisos", e)
        false
    }

    private fun bateriaExenta(): Boolean = try {
        val pm = activity.getSystemService(Context.POWER_SERVICE) as? PowerManager
        if (pm == null) {
            true
        } else {
            pm.isIgnoringBatteryOptimizations(activity.packageName)
        }
    } catch (e: Exception) {
        Log.w(TAG, "No se pudo leer la optimización de batería", e)
        false
    }

    /**
     * Pide el permiso de avisos con el diálogo propio de Android (13+); en
     * versiones anteriores abre los ajustes de la app.
     */
    private fun pedirAvisos(): Boolean = try {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            activity.requestPermissions(
                arrayOf(android.Manifest.permission.POST_NOTIFICATIONS),
                1,
            )
        } else {
            activity.startActivity(
                Intent(
                    Settings.ACTION_APP_NOTIFICATION_SETTINGS,
                    Uri.parse("package:${activity.packageName}"),
                ),
            )
        }
        true
    } catch (e: Exception) {
        Log.w(TAG, "No se pudo pedir el permiso de avisos", e)
        false
    }

    /**
     * Abre la lista de batería optimizada de Android, donde el adulto
     * encuentra BlueTalk y la excluye. Ver comentario de la clase.
     */
    private fun pedirBateria(): Boolean = try {
        activity.startActivity(
            Intent(Settings.ACTION_IGNORE_BATTERY_OPTIMIZATION_SETTINGS),
        )
        true
    } catch (e: Exception) {
        // Algunos fabricantes no exponen esa pantalla: se abre la de la app.
        try {
            activity.startActivity(
                Intent(
                    Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                    Uri.parse("package:${activity.packageName}"),
                ),
            )
            true
        } catch (e2: Exception) {
            Log.w(TAG, "No se pudo abrir la pantalla de batería", e2)
            false
        }
    }

    fun dispose() {
        canal.setMethodCallHandler(null)
    }

    companion object {
        private const val TAG = "Permisos"
    }
}
