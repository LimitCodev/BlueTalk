package com.limitcodev.bluetalk

import android.app.Activity
import android.content.Intent
import android.net.VpnService
import android.os.Build
import android.provider.Settings
import android.util.Log
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Puente entre Flutter y la VPN local de filtrado DNS.
 *
 * El consentimiento de VPN lo concede Android con su propio diálogo. Si el
 * adulto lo cancela, `activar` devuelve `false` y la app no enciende el
 * interruptor.
 */
class FiltroWebChannel(
    private val activity: Activity,
    messenger: BinaryMessenger,
) : MethodChannel.MethodCallHandler {

    private val canal = MethodChannel(messenger, "bluetalk/filtro_web")
    private var pendiente: MethodChannel.Result? = null

    init {
        canal.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "estado" -> result.success(FiltroWebVpnService.estado(activity))
            "activar" -> activar(result)
            "desactivar" -> {
                FiltroWebVpnService.detener(activity)
                result.success(null)
            }
            "actualizar" -> {
                val config = call.argument<String>("config") ?: "{}"
                FiltroWebVpnService.guardarConfig(activity, config)
                result.success(null)
            }
            "limpiarRegistro" -> {
                FiltroWebVpnService.limpiarRegistro(activity)
                result.success(null)
            }
            "abrirAjustesVpn" -> result.success(abrirAjustes(Intent(Settings.ACTION_VPN_SETTINGS)))
            "abrirAjustesDns" -> {
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                    result.success(
                        abrirAjustes(Intent("android.settings.PRIVATE_DNS_SETTINGS")),
                    )
                } else {
                    result.success(false)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun activar(result: MethodChannel.Result) {
        if (pendiente != null) {
            result.error("ocupado", "Ya hay una solicitud de VPN en curso.", null)
            return
        }
        val intento = VpnService.prepare(activity)
        if (intento == null) {
            result.success(iniciarServicio())
            return
        }
        pendiente = result
        try {
            activity.startActivityForResult(intento, REQ_VPN)
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo abrir el diálogo de VPN", e)
            pendiente = null
            result.success(false)
        }
    }

    fun onActivityResult(requestCode: Int, resultCode: Int) {
        if (requestCode != REQ_VPN) return
        val resultado = pendiente ?: return
        pendiente = null
        if (resultCode == Activity.RESULT_OK) {
            resultado.success(iniciarServicio())
        } else {
            resultado.success(false)
        }
    }

    private fun iniciarServicio(): Boolean = try {
        val intent = Intent(activity, FiltroWebVpnService::class.java)
            .setAction(FiltroWebVpnService.ACTION_START)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            activity.startForegroundService(intent)
        } else {
            activity.startService(intent)
        }
        true
    } catch (e: Exception) {
        Log.w(TAG, "No se pudo iniciar el servicio de filtro", e)
        false
    }

    private fun abrirAjustes(intent: Intent): Boolean = try {
        activity.startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    fun dispose() {
        canal.setMethodCallHandler(null)
        pendiente = null
    }

    companion object {
        private const val REQ_VPN = 4101
        private const val TAG = "FiltroWebChannel"
    }
}
