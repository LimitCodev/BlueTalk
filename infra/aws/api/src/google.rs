/// Lo que importa del veredicto de Play Integrity.
#[derive(Clone, Debug)]
pub struct Veredicto {
    pub paquete: String,
    /// `appRecognitionVerdict == PLAY_RECOGNIZED`.
    pub reconocida: bool,
    /// `deviceRecognitionVerdict` contiene `MEETS_DEVICE_INTEGRITY`.
    pub dispositivo_ok: bool,
    pub hash_peticion: String,
}

/// Estado de una suscripción según Android Publisher.
#[derive(Clone, Debug)]
pub struct Suscripcion {
    pub activa: bool,
    pub producto: String,
    /// Fin del periodo pagado, en segundos Unix.
    pub fin: u64,
    /// La compra ya está reconocida (*acknowledged*).
    pub reconocida: bool,
}
