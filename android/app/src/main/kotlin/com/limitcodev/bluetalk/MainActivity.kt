package com.limitcodev.bluetalk

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    private var filtroWeb: FiltroWebChannel? = null
    private var usoTelefono: UsoTelefonoChannel? = null
    private var proteccion: ProteccionChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        filtroWeb = FiltroWebChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        usoTelefono = UsoTelefonoChannel(this, flutterEngine.dartExecutor.binaryMessenger)
        proteccion = ProteccionChannel(this, flutterEngine.dartExecutor.binaryMessenger)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        filtroWeb?.onActivityResult(requestCode, resultCode)
    }

    override fun onDestroy() {
        filtroWeb?.dispose()
        filtroWeb = null
        usoTelefono?.dispose()
        usoTelefono = null
        proteccion?.dispose()
        proteccion = null
        super.onDestroy()
    }
}
