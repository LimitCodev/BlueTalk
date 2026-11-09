package com.limitcodev.bluetalk

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var canalesEdicion: CanalesEdicion? = null
    private var permisos: PermisosChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        canalesEdicion = CanalesEdicion(this, flutterEngine.dartExecutor.binaryMessenger)
        permisos = PermisosChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        canalesEdicion?.onActivityResult(requestCode, resultCode)
    }

    override fun onDestroy() {
        canalesEdicion?.dispose()
        canalesEdicion = null
        permisos?.dispose()
        permisos = null
        super.onDestroy()
    }
}
