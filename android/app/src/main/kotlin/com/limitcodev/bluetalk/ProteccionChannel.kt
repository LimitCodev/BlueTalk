package com.limitcodev.bluetalk

import android.app.Activity
import android.app.admin.DeviceAdminReceiver
import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Receptor de administrador del dispositivo (encargo §3.2).
 *
 * No pide ningún poder (ver `res/xml/device_admin.xml`). Su única función
 * es que desinstalar BlueTalk desde Ajustes de Android exija primero pasar
 * por la pantalla de desactivación del administrador: un escollo, no un
 * muro. Un adulto puede desactivarlo igualmente, y eso se dice en la app.
 */
class ProteccionReceiver : DeviceAdminReceiver()

/**
 * Puente Dart ↔ administrador del dispositivo.
 *
 * Devuelve siempre booleanos o mapas; nunca lanza hacia Dart. Si algo falla
 * se devuelve `false` y se registra en log, para que la pantalla pueda
 * enseñar el estado real en vez de suponerlo.
 */
class ProteccionChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val canal = MethodChannel(messenger, "bluetalk/proteccion")

    init {
        canal.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "activo" -> result.success(mapOf("activo" to estaActivo()))
            "pedirActivacion" -> result.success(pedirActivacion())
            "desactivar" -> result.success(desactivar())
            else -> result.notImplemented()
        }
    }

    private fun componente(): ComponentName =
        ComponentName(activity, ProteccionReceiver::class.java)

    private fun estaActivo(): Boolean = try {
        val dpm = activity.getSystemService(Context.DEVICE_POLICY_SERVICE)
            as? DevicePolicyManager
        dpm?.isAdminActive(componente()) == true
    } catch (e: Exception) {
        Log.w(TAG, "No se pudo leer el estado del administrador", e)
        false
    }

    /**
     * Abre la pantalla de Android para activarse como administrador.
     * Devuelve `true` si se lanzó la pantalla.
     */
    private fun pedirActivacion(): Boolean = try {
        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN)
        intent.putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, componente())
        // Android 10+ ya no muestra este texto, pero en versiones anteriores
        // explica el motivo al adulto.
        intent.putExtra(
            DevicePolicyManager.EXTRA_ADD_EXPLANATION,
            "Para que un niño pequeño no pueda desinstalar BlueTalk por error.",
        )
        activity.startActivity(intent)
        true
    } catch (e: Exception) {
        Log.w(TAG, "No se pudo abrir la activación del administrador", e)
        false
    }

    /**
     * Quita la app de administradores.
     *
     * `removeActiveAdmin` devuelve `void` y **no** pide confirmación: la
     * desactivación por esta vía es inmediata, y por eso esta ruta solo se
     * abre desde el modo padre, detrás del PIN. La otra vía («Desinstalar»
     * desde Ajustes de Android) sí es del sistema y sí pide pasar por su
     * propia pantalla.
     */
    private fun desactivar(): Boolean = try {
        val dpm = activity.getSystemService(Context.DEVICE_POLICY_SERVICE)
            as? DevicePolicyManager
        val componente = componente()
        if (dpm != null && dpm.isAdminActive(componente)) {
            dpm.removeActiveAdmin(componente)
        }
        true
    } catch (e: Exception) {
        Log.w(TAG, "No se pudo quitar el administrador", e)
        false
    }

    fun dispose() {
        canal.setMethodCallHandler(null)
    }

    companion object {
        private const val TAG = "Proteccion"
    }
}
