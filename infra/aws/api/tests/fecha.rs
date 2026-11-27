use bluetalk_api::fecha::{dia_civil, es_dia_valido, semana_iso};

#[test]
fn dia_civil_en_utc() {
    assert_eq!(dia_civil(0), "1970-01-01");
    assert_eq!(dia_civil(1_795_651_200), "2026-11-26");
    assert_eq!(dia_civil(1_795_651_200 - 1), "2026-11-25");
    assert_eq!(dia_civil(951_782_400), "2000-02-29");
}

#[test]
fn es_dia_valido_rechaza_lo_imposible() {
    assert!(es_dia_valido("2026-11-26"));
    assert!(es_dia_valido("2028-02-29"));
    for malo in ["2026-02-30", "2027-02-29", "2026-13-01", "2026-00-10", "2026-11-00", "2026-1-01", "26-11-26", "2026/11/26", "2026-11-26 ", "+026-11-26", "2026-11-2a", ""] {
        assert!(!es_dia_valido(malo), "{malo}");
    }
}

#[test]
fn semana_iso_verificada_con_date() {
    // date -d 2026-11-26 +%G-W%V -> 2026-W48 ; date -d 2027-01-01 +%G-W%V -> 2026-W53
    assert_eq!(semana_iso(1_795_651_200), "2026-W48");
    assert_eq!(semana_iso(1_798_761_600), "2026-W53");
    // 2024-12-30 (lunes) ya es 2025-W01: date -d 2024-12-30 +%G-W%V
    assert_eq!(semana_iso(1_735_516_800), "2025-W01");
}
