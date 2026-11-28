use std::future::Future;

use crate::error::ErrorApi;
use crate::familia::{Alta, Familia};
use crate::google::{Suscripcion, Veredicto};

type R<T> = Result<T, ErrorApi>;

/// Persistencia de la API (DynamoDB en producción, memoria en pruebas).
pub trait Almacen: Send + Sync {
    fn familia(&self, fid: &str) -> impl Future<Output = R<Option<Familia>>> + Send;
    /// Alta atómica (condicional, en una sola operación; nunca leer y luego escribir):
    /// - `f.fid` no existe: lo guarda y lo liga a `token_hash` (máximo `max` fids por token,
    ///   si no `Llena`) y devuelve `Nueva`.
    /// - `f.fid` existe con otro `wh`: no cambia nada y devuelve `OtroWh`. Nunca sobrescribe.
    /// - `f.fid` existe con el mismo `wh`: actualiza `token`, `hasta` y `fin` con los de `f`
    ///   (renovación o nueva compra) y devuelve `YaExistia`. Si `token_hash` es un token al que
    ///   el `fid` aún no estaba ligado, lo liga con el mismo tope `max` (si no, `Llena` sin
    ///   cambios).
    fn alta(&self, f: &Familia, token_hash: &str, max: usize) -> impl Future<Output = R<Alta>> + Send;
    fn vigencia(&self, fid: &str, hasta: u64, fin: u64) -> impl Future<Output = R<()>> + Send;
    /// Gasta un uso de la cuota `ruta` de `fid` en el `dia` ("AAAA-MM-DD", UTC), en una sola
    /// operación atómica. `false` si ya llevaba `tope` usos (entonces no cuenta).
    fn consumir_cuota(&self, fid: &str, ruta: &str, dia: &str, tope: u32) -> impl Future<Output = R<bool>> + Send;
    /// Guarda (o sobrescribe) los bloques de día, con caducidad `ttl` (segundos Unix).
    /// `dias` no repite fecha.
    fn guardar_dias(&self, fid: &str, dias: &[(String, Vec<u8>)], ttl: u64) -> impl Future<Output = R<()>> + Send;
    /// Hasta `max` bloques con fecha >= `desde`, en orden ascendente.
    fn leer_dias(&self, fid: &str, desde: &str, max: usize) -> impl Future<Output = R<Vec<(String, Vec<u8>)>>> + Send;
    /// Guarda (o sobrescribe) la única copia de seguridad, con caducidad `ttl` (segundos Unix).
    fn guardar_respaldo(&self, fid: &str, b: &[u8], ttl: u64) -> impl Future<Output = R<()>> + Send;
    fn leer_respaldo(&self, fid: &str) -> impl Future<Output = R<Option<Vec<u8>>>> + Send;
    /// Borra todos los ítems de la familia (ella, días y copia) y quita `fid` de la ligadura de
    /// `token_hash`, que libera su cupo. NO borra los contadores de cuota (sin datos personales,
    /// caducan por TTL): si no, borrar y reactivar reiniciaría la cuota del día. Si ya no
    /// existe, no hace nada.
    fn borrar_familia(&self, fid: &str, token_hash: &str) -> impl Future<Output = R<()>> + Send;
}

/// Servicios de Google: Play Integrity y Android Publisher.
pub trait Google: Send + Sync {
    fn integridad(&self, token: &str) -> impl Future<Output = R<Veredicto>> + Send;
    fn suscripcion(&self, token: &str) -> impl Future<Output = R<Suscripcion>> + Send;
    fn reconocer(&self, producto: &str, token: &str) -> impl Future<Output = R<()>> + Send;
}

pub struct Config {
    pub paquete: String,
    pub producto: String,
}

pub struct Estado<A, G> {
    pub almacen: A,
    pub google: G,
    pub cfg: Config,
}
