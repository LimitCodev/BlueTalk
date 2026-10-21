package com.limitcodev.bluetalk

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.net.ConnectivityManager
import android.net.LinkProperties
import android.net.Network
import android.net.NetworkCapabilities
import android.net.NetworkRequest
import android.net.VpnService
import android.os.Build
import android.os.ParcelFileDescriptor
import android.util.Log
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.net.DatagramPacket
import java.net.DatagramSocket
import java.net.InetAddress
import java.net.SocketTimeoutException
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors
import java.util.concurrent.RejectedExecutionException

/**
 * VPN local que **solo** intercepta DNS (plan 14).
 *
 * No envía el tráfico del niño a ningún servidor: el TUN solo recibe las
 * consultas dirigidas al DNS de la propia VPN. Las consultas permitidas se
 * reenvían al DNS de la red (Wi-Fi/datos) con `protect`, y las bloqueadas
 * reciben NXDOMAIN. El registro de bloqueos se queda en el teléfono.
 */
class FiltroWebVpnService : VpnService() {

    private data class Config(val activo: Boolean, val dominios: List<String>) {
        fun bloquea(host: String): Boolean {
            if (!activo) return false
            val normalizado = host.lowercase().trimEnd('.')
            if (normalizado.isEmpty()) return false
            return dominios.any { dominio ->
                val d = dominio.lowercase().trimEnd('.').removePrefix("www.")
                d.isNotEmpty() && (normalizado == d || normalizado.endsWith(".$d"))
            }
        }
    }

    private data class ConsultaDns(
        val nombre: String,
        val finPregunta: Int,
    )

    private data class Paquete(
        val ipVersion: Int,
        val srcIp: ByteArray,
        val dstIp: ByteArray,
        val srcPort: Int,
        val dstPort: Int,
        val payload: ByteArray,
    )

    private var tun: ParcelFileDescriptor? = null
    private var hilo: Thread? = null
    private val pool = Executors.newFixedThreadPool(4)
    private val escritura = Any()
    private val registroLock = Any()
    private val ultimoRegistro = ConcurrentHashMap<String, Long>()

    @Volatile
    private var config = Config(false, emptyList())

    @Volatile
    private var upstreamDns: List<InetAddress> = emptyList()

    private val callbackRed = object : ConnectivityManager.NetworkCallback() {
        override fun onAvailable(network: Network) = actualizarDns()
        override fun onLost(network: Network) = actualizarDns()
        override fun onLinkPropertiesChanged(
            network: Network,
            linkProperties: LinkProperties,
        ) = actualizarDns()
    }

    override fun onCreate() {
        super.onCreate()
        instancia = this
        crearCanalNotificacion()
        try {
            val cm = getSystemService(ConnectivityManager::class.java)
            cm.registerNetworkCallback(solicitudRed, callbackRed)
        } catch (e: Exception) {
            Log.w(TAG, "Sin permiso para observar la red", e)
        }
        actualizarDns()
        recargarConfig()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        when (intent?.action) {
            ACTION_STOP -> {
                detenerServicio()
                return START_NOT_STICKY
            }
            ACTION_UPDATE -> {
                recargarConfig()
                if (hilo == null) {
                    stopSelf(startId)
                    return START_NOT_STICKY
                }
                return START_STICKY
            }
            else -> iniciar()
        }
        return if (activo) START_STICKY else START_NOT_STICKY
    }

    private fun iniciar() {
        if (hilo != null) return
        recargarConfig()
        empezarForeground()
        actualizarDns()

        val builder = Builder()
            .setSession("BlueTalk - filtro de páginas")
            .setMtu(1500)
            .addAddress(DNS_V4_CLIENTE, 24)
            .addRoute(DNS_V4_RED, 24)
            .addDnsServer(DNS_V4_SERVIDOR)
            .addAddress(DNS_V6_CLIENTE, 64)
            .addRoute(DNS_V6_RED, 64)
            .addDnsServer(DNS_V6_SERVIDOR)
            .setBlocking(true)

        val descriptor = try {
            builder.establish()
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo establecer la VPN", e)
            null
        }
        if (descriptor == null) {
            Log.w(TAG, "Android no entregó el TUN")
            detenerServicio()
            return
        }

        tun = descriptor
        activo = true
        prefs(this).edit().putBoolean(KEY_ACTIVO, true).apply()
        hilo = Thread { bucle(descriptor) }.also { it.start() }
    }

    private fun bucle(descriptor: ParcelFileDescriptor) {
        val entrada = FileInputStream(descriptor.fileDescriptor)
        val salida = FileOutputStream(descriptor.fileDescriptor)
        val buffer = ByteArray(32767)

        while (activo && !Thread.currentThread().isInterrupted) {
            val leido = try {
                entrada.read(buffer)
            } catch (e: IOException) {
                if (activo) Log.w(TAG, "Lectura del TUN terminada", e)
                break
            }
            if (leido <= 0) continue
            val copia = buffer.copyOf(leido)
            try {
                pool.execute { procesar(copia, salida) }
            } catch (e: RejectedExecutionException) {
                // El servicio se está deteniendo.
                break
            }
        }
    }

    private fun procesar(datos: ByteArray, salida: FileOutputStream) {
        val paquete = parsearPaquete(datos) ?: return
        val consulta = parsearConsulta(paquete.payload) ?: return
        val cfg = config

        val respuestaDns = if (cfg.bloquea(consulta.nombre)) {
            registrarBloqueo(consulta.nombre)
            respuestaDns(paquete.payload, consulta, RCODE_NXDOMAIN)
        } else {
            reenviar(paquete.payload)
                ?: respuestaDns(paquete.payload, consulta, RCODE_SERVFAIL)
        }

        val respuesta = construirRespuesta(paquete, respuestaDns)
        try {
            synchronized(escritura) {
                salida.write(respuesta)
            }
        } catch (e: IOException) {
            if (activo) Log.w(TAG, "No se pudo escribir la respuesta DNS", e)
        }
    }

    // --- Reenvío al DNS real de la red -------------------------------

    private fun reenviar(payload: ByteArray): ByteArray? {
        val servidores = upstreamDns
        if (servidores.isEmpty()) return null

        for (servidor in servidores) {
            try {
                DatagramSocket().use { socket ->
                    if (!protect(socket)) {
                        Log.w(TAG, "No se pudo proteger el socket DNS")
                        continue
                    }
                    socket.soTimeout = 2500
                    socket.send(
                        DatagramPacket(payload, payload.size, servidor, 53),
                    )
                    val buffer = ByteArray(4096)
                    val respuesta = DatagramPacket(buffer, buffer.size)
                    socket.receive(respuesta)
                    // No reenviar paquetes de otro origen ni con otro ID:
                    // evita respuestas DNS falsificadas.
                    if (respuesta.port != 53 ||
                        respuesta.address != servidor ||
                        respuesta.length < 12 ||
                        u16(respuesta.data, 0) != u16(payload, 0) ||
                        (u16(respuesta.data, 2) and 0x8000) == 0
                    ) {
                        return null
                    }
                    return respuesta.data.copyOf(respuesta.length)
                }
            } catch (e: SocketTimeoutException) {
                Log.w(TAG, "Tiempo agotado al consultar $servidor")
            } catch (e: Exception) {
                Log.w(TAG, "No se pudo consultar $servidor", e)
            }
        }
        return null
    }

    private fun actualizarDns() {
        try {
            upstreamDns = dnsDelSistema()
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo leer el DNS de la red", e)
        }
    }

    private fun dnsDelSistema(): List<InetAddress> {
        val cm = getSystemService(ConnectivityManager::class.java)
        val salida = LinkedHashSet<InetAddress>()
        val activa = cm.activeNetwork
        if (activa != null) agregarDnsDe(cm, activa, salida)
        for (red in cm.allNetworks) {
            if (red == activa) continue
            agregarDnsDe(cm, red, salida)
        }
        return salida.toList()
    }

    private fun agregarDnsDe(
        cm: ConnectivityManager,
        red: Network,
        salida: MutableSet<InetAddress>,
    ) {
        val capacidades = cm.getNetworkCapabilities(red) ?: return
        if (capacidades.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) return
        if (!capacidades.hasCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)) {
            return
        }
        val enlace = cm.getLinkProperties(red) ?: return
        for (dns in enlace.dnsServers) {
            if (!esDnsPropio(dns)) salida.add(dns)
        }
    }

    private fun esDnsPropio(direccion: InetAddress): Boolean =
        direccion.hostAddress == DNS_V4_SERVIDOR ||
            direccion.hostAddress == DNS_V6_SERVIDOR

    // --- Parseo de paquetes IP/UDP y DNS -----------------------------

    private fun parsearPaquete(datos: ByteArray): Paquete? {
        if (datos.size < 28) return null
        val version = (datos[0].toInt() ushr 4) and 0x0F
        return when (version) {
            4 -> parsearV4(datos)
            6 -> parsearV6(datos)
            else -> null
        }
    }

    private fun parsearV4(datos: ByteArray): Paquete? {
        val ihl = (datos[0].toInt() and 0x0F) * 4
        if (ihl < 20 || datos.size < ihl + 8) return null
        val protocolo = datos[9].toInt() and 0xFF
        if (protocolo != 17) return null
        val total = u16(datos, 2)
        if (total < ihl + 8 || total > datos.size) return null
        val fragmento = u16(datos, 6)
        if ((fragmento and 0x3FFF) != 0) return null
        val destino = datos.copyOfRange(16, 20)
        if (!destino.contentEquals(DNS_V4_BYTES)) return null
        val puertoDestino = u16(datos, ihl + 2)
        if (puertoDestino != 53) return null
        val udpLen = u16(datos, ihl + 4)
        if (udpLen < 8 || ihl + udpLen > total) return null
        return Paquete(
            ipVersion = 4,
            srcIp = datos.copyOfRange(12, 16),
            dstIp = destino,
            srcPort = u16(datos, ihl),
            dstPort = puertoDestino,
            payload = datos.copyOfRange(ihl + 8, ihl + udpLen),
        )
    }

    private fun parsearV6(datos: ByteArray): Paquete? {
        if (datos.size < 48) return null
        val longitudPayload = u16(datos, 4)
        if (datos.size < 40 + longitudPayload) return null
        if ((datos[6].toInt() and 0xFF) != 17) return null
        val destino = datos.copyOfRange(24, 40)
        if (!destino.contentEquals(DNS_V6_BYTES)) return null
        val puertoDestino = u16(datos, 42)
        if (puertoDestino != 53) return null
        val udpLen = u16(datos, 44)
        if (udpLen < 8 || 40 + udpLen > 40 + longitudPayload) return null
        return Paquete(
            ipVersion = 6,
            srcIp = datos.copyOfRange(8, 24),
            dstIp = destino,
            srcPort = u16(datos, 40),
            dstPort = puertoDestino,
            payload = datos.copyOfRange(48, 40 + udpLen),
        )
    }

    private fun parsearConsulta(payload: ByteArray): ConsultaDns? {
        if (payload.size < 12) return null
        val flags = u16(payload, 2)
        if ((flags and 0x8000) != 0) return null
        val preguntas = u16(payload, 4)
        if (preguntas != 1) return null

        var offset = 12
        var fin = -1
        var saltos = 0
        val nombre = StringBuilder()
        while (offset < payload.size && saltos < 30) {
            val largo = payload[offset].toInt() and 0xFF
            if (largo == 0) {
                offset++
                if (fin < 0) fin = offset
                break
            }
            if ((largo and 0xC0) == 0xC0) {
                if (offset + 1 >= payload.size) return null
                val puntero = ((largo and 0x3F) shl 8) or
                    (payload[offset + 1].toInt() and 0xFF)
                if (puntero >= payload.size) return null
                if (fin < 0) fin = offset + 2
                offset = puntero
                saltos++
                continue
            }
            if (largo > 63 || offset + 1 + largo > payload.size) return null
            if (nombre.isNotEmpty()) nombre.append('.')
            nombre.append(String(payload, offset + 1, largo, Charsets.US_ASCII))
            if (nombre.length > 253) return null
            offset += 1 + largo
            saltos++
        }
        if (fin < 0 || fin + 4 > payload.size) return null
        val nombreFinal = nombre.toString().lowercase().trimEnd('.')
        if (nombreFinal.isEmpty()) return null
        return ConsultaDns(nombre = nombreFinal, finPregunta = fin + 4)
    }

    private fun respuestaDns(
        payload: ByteArray,
        consulta: ConsultaDns,
        rcode: Int,
    ): ByteArray {
        val fin = consulta.finPregunta.coerceAtMost(payload.size)
        val salida = payload.copyOf(fin)
        salida[2] = ((payload[2].toInt() and 0x79) or 0x80).toByte()
        salida[3] = (0x80 or (rcode and 0x0F)).toByte()
        for (i in 6..11) salida[i] = 0
        return salida
    }

    // --- Construcción de la respuesta IP/UDP --------------------------

    private fun construirRespuesta(paquete: Paquete, dns: ByteArray): ByteArray {
        val udp = ByteArray(8 + dns.size)
        putU16(udp, 0, paquete.dstPort)
        putU16(udp, 2, paquete.srcPort)
        putU16(udp, 4, udp.size)
        System.arraycopy(dns, 0, udp, 8, dns.size)
        putU16(
            udp,
            6,
            udpChecksum(
                paquete.dstIp,
                paquete.srcIp,
                udp,
                paquete.ipVersion == 6,
            ),
        )

        return if (paquete.ipVersion == 4) {
            val salida = ByteArray(20 + udp.size)
            salida[0] = 0x45
            putU16(salida, 2, salida.size)
            putU16(salida, 6, 0x4000)
            salida[8] = 64
            salida[9] = 17
            System.arraycopy(paquete.dstIp, 0, salida, 12, 4)
            System.arraycopy(paquete.srcIp, 0, salida, 16, 4)
            putU16(salida, 10, checksum(salida, 0, 20))
            System.arraycopy(udp, 0, salida, 20, udp.size)
            salida
        } else {
            val salida = ByteArray(40 + udp.size)
            salida[0] = 0x60
            putU16(salida, 4, udp.size)
            salida[6] = 17
            salida[7] = 64
            System.arraycopy(paquete.dstIp, 0, salida, 8, 16)
            System.arraycopy(paquete.srcIp, 0, salida, 24, 16)
            System.arraycopy(udp, 0, salida, 40, udp.size)
            salida
        }
    }

    private fun udpChecksum(
        src: ByteArray,
        dst: ByteArray,
        udp: ByteArray,
        ipv6: Boolean,
    ): Int {
        val pseudo = ByteArray(if (ipv6) 40 else 12)
        if (ipv6) {
            System.arraycopy(src, 0, pseudo, 0, 16)
            System.arraycopy(dst, 0, pseudo, 16, 16)
            putU32(pseudo, 32, udp.size)
            pseudo[39] = 17
        } else {
            System.arraycopy(src, 0, pseudo, 0, 4)
            System.arraycopy(dst, 0, pseudo, 4, 4)
            pseudo[9] = 17
            putU16(pseudo, 10, udp.size)
        }
        val datos = ByteArray(pseudo.size + udp.size)
        System.arraycopy(pseudo, 0, datos, 0, pseudo.size)
        System.arraycopy(udp, 0, datos, pseudo.size, udp.size)
        val suma = checksum(datos, 0, datos.size)
        return if (suma == 0) 0xFFFF else suma
    }

    private fun checksum(datos: ByteArray, inicio: Int, longitud: Int): Int {
        var suma = 0L
        var i = inicio
        val fin = inicio + longitud
        while (i + 1 < fin) {
            suma += ((datos[i].toInt() and 0xFF) shl 8) or
                (datos[i + 1].toInt() and 0xFF)
            i += 2
        }
        if (i < fin) suma += (datos[i].toInt() and 0xFF) shl 8
        while ((suma ushr 16) != 0L) {
            suma = (suma and 0xFFFF) + (suma ushr 16)
        }
        return (suma.inv() and 0xFFFF).toInt()
    }

    private fun u16(datos: ByteArray, offset: Int): Int =
        ((datos[offset].toInt() and 0xFF) shl 8) or
            (datos[offset + 1].toInt() and 0xFF)

    private fun putU16(datos: ByteArray, offset: Int, valor: Int) {
        datos[offset] = (valor ushr 8).toByte()
        datos[offset + 1] = valor.toByte()
    }

    private fun putU32(datos: ByteArray, offset: Int, valor: Int) {
        datos[offset] = (valor ushr 24).toByte()
        datos[offset + 1] = (valor ushr 16).toByte()
        datos[offset + 2] = (valor ushr 8).toByte()
        datos[offset + 3] = valor.toByte()
    }

    // --- Configuración y registro -------------------------------------

    private fun recargarConfig() {
        config = leerConfig(this)
    }

    private fun registrarBloqueo(dominio: String) {
        val ahora = System.currentTimeMillis()
        val previo = ultimoRegistro[dominio]
        if (previo != null && ahora - previo < 5000) return
        ultimoRegistro[dominio] = ahora
        synchronized(registroLock) {
            val lista = try {
                JSONArray(prefs(this).getString(KEY_LOG, "[]"))
            } catch (e: JSONException) {
                JSONArray()
            }
            lista.put(JSONObject().put("dominio", dominio).put("hora", ahora))
            val recortada = JSONArray()
            val desde = maxOf(0, lista.length() - MAX_REGISTRO)
            for (i in desde until lista.length()) recortada.put(lista.get(i))
            prefs(this).edit().putString(KEY_LOG, recortada.toString()).apply()
        }
    }

    // --- Notificación en primer plano ---------------------------------

    private fun crearCanalNotificacion() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val gestor = getSystemService(NotificationManager::class.java)
        val canal = NotificationChannel(
            CANAL,
            "Filtro de páginas",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Aviso de que BlueTalk está filtrando sitios."
            setSound(null, null)
            enableVibration(false)
        }
        gestor.createNotificationChannel(canal)
    }

    private fun notificacion(): Notification {
        val abrir = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CANAL)
        } else {
            Notification.Builder(this)
        }
        return builder
            .setSmallIcon(android.R.drawable.ic_lock_lock)
            .setContentTitle(
                if (config.activo) {
                    "Filtro de páginas activo"
                } else {
                    "VPN local de BlueTalk"
                },
            )
            .setContentText(
                if (config.activo) {
                    "BlueTalk bloquea los sitios elegidos."
                } else {
                    "El filtro está apagado; solo se reenvía el DNS."
                },
            )
            .setContentIntent(abrir)
            .setOngoing(true)
            .setCategory(Notification.CATEGORY_SERVICE)
            .setPriority(Notification.PRIORITY_LOW)
            .build()
    }

    private fun empezarForeground() {
        val notificacion = notificacion()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                ID_NOTIFICACION,
                notificacion,
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE,
            )
        } else {
            startForeground(ID_NOTIFICACION, notificacion)
        }
    }

    private fun detenerServicio() {
        activo = false
        try {
            tun?.close()
        } catch (e: IOException) {
            Log.w(TAG, "No se pudo cerrar el TUN", e)
        }
        tun = null
        hilo?.interrupt()
        hilo = null
        prefs(this).edit().putBoolean(KEY_ACTIVO, false).apply()
        stopForeground(STOP_FOREGROUND_REMOVE)
        stopSelf()
    }

    override fun onRevoke() {
        detenerServicio()
        super.onRevoke()
    }

    override fun onDestroy() {
        activo = false
        instancia = null
        try {
            val cm = getSystemService(ConnectivityManager::class.java)
            cm.unregisterNetworkCallback(callbackRed)
        } catch (e: Exception) {
            Log.w(TAG, "No se pudo dejar de observar la red", e)
        }
        try {
            tun?.close()
        } catch (e: IOException) {
            Log.w(TAG, "No se pudo cerrar el TUN al destruir", e)
        }
        tun = null
        hilo?.interrupt()
        hilo = null
        pool.shutdownNow()
        prefs(this).edit().putBoolean(KEY_ACTIVO, false).apply()
        super.onDestroy()
    }

    companion object {
        private const val TAG = "FiltroWeb"
        private const val CANAL = "bluetalk_filtro_web"
        private const val ID_NOTIFICACION = 4102
        private const val MAX_REGISTRO = 100
        private const val RCODE_SERVFAIL = 2
        private const val RCODE_NXDOMAIN = 3

        const val ACTION_START = "com.limitcodev.bluetalk.FILTRO_WEB_START"
        const val ACTION_STOP = "com.limitcodev.bluetalk.FILTRO_WEB_STOP"
        const val ACTION_UPDATE = "com.limitcodev.bluetalk.FILTRO_WEB_UPDATE"

        const val KEY_CONFIG = "config"
        const val KEY_LOG = "log"
        const val KEY_ACTIVO = "activo"
        private const val PREFS = "bluetalk_filtro_web"

        private const val DNS_V4_SERVIDOR = "10.111.222.1"
        private const val DNS_V4_CLIENTE = "10.111.222.2"
        private const val DNS_V4_RED = "10.111.222.0"
        private const val DNS_V6_SERVIDOR = "fd00:1:fd00:1::1"
        private const val DNS_V6_CLIENTE = "fd00:1:fd00:1::2"
        private const val DNS_V6_RED = "fd00:1:fd00:1::"

        private val DNS_V4_BYTES = InetAddress.getByName(DNS_V4_SERVIDOR).address
        private val DNS_V6_BYTES = InetAddress.getByName(DNS_V6_SERVIDOR).address

        private val solicitudRed = NetworkRequest.Builder()
            .addCapability(NetworkCapabilities.NET_CAPABILITY_INTERNET)
            .build()

        @Volatile
        private var activo = false

        @Volatile
        private var instancia: FiltroWebVpnService? = null

        fun prefs(context: Context) =
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        fun guardarConfig(context: Context, json: String) {
            prefs(context).edit().putString(KEY_CONFIG, json).apply()
            instancia?.recargarConfig()
        }

        private fun leerConfig(context: Context): Config {
            val crudo = prefs(context).getString(KEY_CONFIG, null)
                ?: return Config(false, emptyList())
            return try {
                val objeto = JSONObject(crudo)
                val activo = objeto.optBoolean("activo", false)
                val arreglo = objeto.optJSONArray("dominios")
                val dominios = mutableListOf<String>()
                if (arreglo != null) {
                    for (i in 0 until arreglo.length()) {
                        val dominio = arreglo.optString(i).trim().lowercase()
                        if (dominio.isNotEmpty()) dominios.add(dominio)
                    }
                }
                Config(activo, dominios)
            } catch (e: JSONException) {
                Config(false, emptyList())
            }
        }

        fun estado(context: Context): Map<String, Any> = mapOf(
            "activo" to activo,
            "consentimiento" to (VpnService.prepare(context) == null),
            "dnsPrivado" to hayDnsPrivado(context),
            "bloqueos" to leerBloqueos(context),
        )

        private fun hayDnsPrivado(context: Context): Boolean {
            if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return false
            val cm = context.getSystemService(ConnectivityManager::class.java)
            for (red in cm.allNetworks) {
                val capacidades = cm.getNetworkCapabilities(red) ?: continue
                if (capacidades.hasTransport(NetworkCapabilities.TRANSPORT_VPN)) {
                    continue
                }
                val enlace = cm.getLinkProperties(red) ?: continue
                if (enlace.isPrivateDnsActive) return true
            }
            return false
        }

        private fun leerBloqueos(context: Context): List<Map<String, Any>> {
            val crudo = prefs(context).getString(KEY_LOG, "[]") ?: "[]"
            val salida = mutableListOf<Map<String, Any>>()
            try {
                val arreglo = JSONArray(crudo)
                for (i in arreglo.length() - 1 downTo 0) {
                    val objeto = arreglo.optJSONObject(i) ?: continue
                    salida.add(
                        mapOf(
                            "dominio" to objeto.optString("dominio"),
                            "hora" to objeto.optLong("hora"),
                        ),
                    )
                }
            } catch (e: JSONException) {
                // Registro corrupto: se muestra vacío y se puede borrar.
            }
            return salida
        }

        fun limpiarRegistro(context: Context) {
            prefs(context).edit().remove(KEY_LOG).apply()
            instancia?.ultimoRegistro?.clear()
        }

        fun detener(context: Context) {
            activo = false
            context.stopService(
                Intent(context, FiltroWebVpnService::class.java),
            )
            prefs(context).edit().putBoolean(KEY_ACTIVO, false).apply()
        }
    }
}
