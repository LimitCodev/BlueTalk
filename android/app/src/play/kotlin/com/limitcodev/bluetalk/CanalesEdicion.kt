package com.limitcodev.bluetalk

import android.app.Activity
import io.flutter.plugin.common.BinaryMessenger

/** Edición Play (ruta A de requisitosPlayStore.md): sin VPN ni acceso al uso. */
@Suppress("UNUSED_PARAMETER")
class CanalesEdicion(activity: Activity, messenger: BinaryMessenger) {
    fun onActivityResult(requestCode: Int, resultCode: Int) = Unit

    fun dispose() = Unit
}
