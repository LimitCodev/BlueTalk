package com.limitcodev.bluetalk

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger

/** Canales que solo existen en el APK directo: filtro VPN y acceso al uso. */
class CanalesEdicion(activity: Activity, messenger: BinaryMessenger) {
    private val filtroWeb = FiltroWebChannel(activity, messenger)
    private val usoTelefono = UsoTelefonoChannel(activity, messenger)

    fun onActivityResult(requestCode: Int, resultCode: Int) =
        filtroWeb.onActivityResult(requestCode, resultCode)

    fun dispose() {
        filtroWeb.dispose()
        usoTelefono.dispose()
    }
}
