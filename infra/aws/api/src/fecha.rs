//! Fechas civiles en UTC, sin crates de fechas. Algoritmos `days_from_civil` y
//! `civil_from_days` de Howard Hinnant.

fn dias_desde_civil(y: i64, m: i64, d: i64) -> i64 {
    let y = if m <= 2 { y - 1 } else { y };
    let era = y.div_euclid(400);
    let yoe = y - era * 400;
    let doy = (153 * (m + if m > 2 { -3 } else { 9 }) + 2) / 5 + d - 1;
    let doe = yoe * 365 + yoe / 4 - yoe / 100 + doy;
    era * 146_097 + doe - 719_468
}

fn civil_desde_dias(z: i64) -> (i64, i64, i64) {
    let z = z + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z - era * 146_097;
    let yoe = (doe - doe / 1460 + doe / 36_524 - doe / 146_096) / 365;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    (yoe + era * 400 + i64::from(m <= 2), m, d)
}

/// `"AAAA-MM-DD"` del instante (segundos Unix) en UTC.
pub fn dia_civil(segundos: u64) -> String {
    let (y, m, d) = civil_desde_dias((segundos / 86_400) as i64);
    format!("{y:04}-{m:02}-{d:02}")
}

/// `"AAAA-MM-DD"` exacto (cifras ASCII) y que exista en el calendario.
pub fn es_dia_valido(s: &str) -> bool {
    let b = s.as_bytes();
    let cifras = b.len() == 10 && b.iter().enumerate().all(|(i, c)| if i == 4 || i == 7 { *c == b'-' } else { c.is_ascii_digit() });
    if !cifras {
        return false;
    }
    let n = |r: std::ops::Range<usize>| s[r].parse::<i64>().unwrap_or(0);
    let (y, m, d) = (n(0..4), n(5..7), n(8..10));
    civil_desde_dias(dias_desde_civil(y, m, d)) == (y, m, d)
}

/// `"AAAA-Www"` (semana ISO 8601) del instante en UTC.
pub fn semana_iso(segundos: u64) -> String {
    let dias = (segundos / 86_400) as i64;
    // 1970-01-01 fue jueves; el jueves de la semana decide el año ISO.
    let jueves = dias - (dias + 3).rem_euclid(7) + 3;
    let (y, _, _) = civil_desde_dias(jueves);
    format!("{y:04}-W{:02}", (jueves - dias_desde_civil(y, 1, 1)) / 7 + 1)
}
