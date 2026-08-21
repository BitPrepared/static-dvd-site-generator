#!/usr/bin/env bash
# Verifica per scripts/genera_footer.js (change OpenSpec footer-dinamico-da-svg).
# Uso: scripts/test_genera_footer.sh   (oppure bash scripts/test_genera_footer.sh)
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/genera_footer.js"
TEMPLATE="$DIR/footer_template.svg"
FONT="$DIR/star_jedi/Starjout.ttf"
NODE_BIN="${NODE_BIN:-node}"
export NODE_PATH="${NODE_PATH:-$DIR/../static-dvd-site-generator/node_modules}"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
no()   { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# esce 0 + eventualmente file creato
run_ok() { # nome attesa_file cmd...
  local nome="$1" attesa_file="$2"; shift 2
  local out="$TMP/out.png"; rm -f "$out"
  if "$@" --out "$out" >"$TMP/stdout" 2>"$TMP/stderr"; then
    if [ "$attesa_file" = "file" ] && [ ! -f "$out" ]; then no "$nome (file non creato)"; return; fi
    if [ "$attesa_file" = "nofile" ] && [ -f "$out" ]; then no "$nome (file scritto!)"; return; fi
    ok "$nome"
  else
    no "$nome (exit != 0: $(head -c 120 "$TMP/stderr"))"
  fi
}
# esce != 0, nessun file scritto, messaggio presente
run_ko() { # nome messaggio_atteso cmd...
  local nome="$1" msg="$2"; shift 2
  local out="$TMP/out.png"; rm -f "$out"
  if "$@" --out "$out" >"$TMP/stdout" 2>"$TMP/stderr"; then
    no "$nome (exit 0 inatteso)"; return
  fi
  if [ -f "$out" ]; then no "$nome (scritta PNG nonostante l'errore)"; return; fi
  if [ -n "$msg" ] && ! grep -qi "$msg" "$TMP/stderr"; then no "$nome (messaggio senza '$msg')"; return; fi
  ok "$nome"
}

png_dims() { # stampa "WxH" leggendo l'IHDR
  "$NODE_BIN" -e "const b=require('fs').readFileSync('$1');console.log(b.readUInt32BE(16)+'x'+b.readUInt32BE(20))"
}

echo "== prerequisiti =="
[ -f "$SCRIPT" ] && ok "script esiste" || no "script esiste"
[ -f "$TEMPLATE" ] && ok "template esiste" || no "template esiste"
[ -f "$FONT" ] && ok "font presente" || no "font presente (make font)"

echo "== validazione input (spec: generazione riproducibile) =="
# senza argomenti: la build usa dati/campo.json (se presente nel repo)
if [ -f "$DIR/../dati/campo.json" ]; then
  run_ok "nessun argomento -> dati/campo.json (percorso della build)" "file" "$NODE_BIN" "$SCRIPT"
else
  run_ko "DATE assente e nessun config" "mancanti" "$NODE_BIN" "$SCRIPT"
fi
run_ko "formato non data" "formato" "$NODE_BIN" "$SCRIPT" "pippo"
run_ko "anno corto" "formato" "$NODE_BIN" "$SCRIPT" "22-26/08/23"
run_ko "giorno 31+ non valido" "giorn" "$NODE_BIN" "$SCRIPT" "32-35/08/2023"
run_ko "mese 13 non valido" "mese" "$NODE_BIN" "$SCRIPT" "22-26/13/2023"
run_ko "fine prima di inizio" "fine" "$NODE_BIN" "$SCRIPT" "26-22/08/2023"

echo "== errori ambiente (spec: fallimento isolato) =="
run_ko "font assente" "make font" "$NODE_BIN" "$SCRIPT" "22-26/08/2023" --font "$TMP/non_esiste.ttf"

echo "== generazione valida (spec: ricetta + self-check) =="
rm -f "$TMP/out.png"
if "$NODE_BIN" "$SCRIPT" "22-26/08/2023" --out "$TMP/out.png" >"$TMP/stdout" 2>"$TMP/stderr"; then
  ok "rigenerazione 2023"
else
  no "rigenerazione 2023 ($(head -c 120 "$TMP/stderr"))"
fi
largh="$(cat "$TMP/stdout" "$TMP/stderr" | grep -o 'inchiostro [0-9]*x' | grep -o '[0-9]*' | head -1)"
if [ -n "$largh" ] && [ "$largh" -ge 565 ] && [ "$largh" -le 580 ]; then
  ok "larghezza inchiostro 2023 ~572 (lett: $largh)"
else
  no "larghezza inchiostro 2023 ~572 (lett: ${largh:-nessuna})"
fi
if [ -f "$TMP/out.png" ]; then
  dims="$(png_dims "$TMP/out.png")"
  [ "$dims" = "760x49" ] && ok "PNG 760x49 (lett: $dims)" || no "PNG 760x49 (lett: $dims)"
else
  no "PNG 760x49 (non generata)"
fi

echo "== determinismo (spec: byte identici) =="
"$NODE_BIN" "$SCRIPT" "21-25/08/2026" --out "$TMP/a.png" >/dev/null 2>&1
"$NODE_BIN" "$SCRIPT" "21-25/08/2026" --out "$TMP/b.png" >/dev/null 2>&1
if [ -f "$TMP/a.png" ] && [ -f "$TMP/b.png" ] && cmp -s "$TMP/a.png" "$TMP/b.png"; then
  ok "due run -> PNG identiche"
else
  no "due run -> PNG identiche"
fi

echo "== configurazione dati/campo.json (spec: build genera il footer) =="
CFG="$TMP/campo.json"
echo '{"date": "22-26/08/2023"}' > "$CFG"
run_ok "config valida" "file" "$NODE_BIN" "$SCRIPT" --config "$CFG"
CFG_VUOTO="$TMP/campo_vuoto.json"
echo '{}' > "$CFG_VUOTO"
run_ko "config senza campo date" "date" "$NODE_BIN" "$SCRIPT" --config "$CFG_VUOTO"
CFG_CATTIVO="$TMP/campo_cattivo.json"
echo '{"date": "pippo"}' > "$CFG_CATTIVO"
run_ko "config con date invalida" "formato" "$NODE_BIN" "$SCRIPT" --config "$CFG_CATTIVO"
CFG_MALATO="$TMP/campo_malato.json"
echo 'non json' > "$CFG_MALATO"
run_ko "config non json" "campo.json" "$NODE_BIN" "$SCRIPT" --config "$CFG_MALATO"
run_ko "config inesistente" "campo.json" "$NODE_BIN" "$SCRIPT" --config "$TMP/non_esiste.json"
run_ko "data e config insieme" "insieme" "$NODE_BIN" "$SCRIPT" "22-26/08/2023" --config "$CFG"

echo "== fallback (spec: risorsa aggiornata a generazione riuscita) =="
FB="$TMP/footer_fallback.png"
rm -f "$FB"
"$NODE_BIN" "$SCRIPT" "22-26/08/2023" --out "$TMP/c.png" --fallback "$FB" >/dev/null 2>&1
if [ -f "$FB" ] && cmp -s "$FB" "$TMP/c.png"; then
  ok "fallback aggiornato con la PNG generata"
else
  no "fallback aggiornato con la PNG generata"
fi
FB_REALE="$DIR/footer_fallback.png"
if [ -f "$FB_REALE" ]; then
  SOMMA_PRIMA="$(sha256sum "$FB_REALE" 2>/dev/null | cut -d' ' -f1)"
  "$NODE_BIN" "$SCRIPT" "22-26/08/2023" --out "$TMP/d.png" >/dev/null 2>&1
  SOMMA_DOPO="$(sha256sum "$FB_REALE" 2>/dev/null | cut -d' ' -f1)"
  if [ "$SOMMA_PRIMA" = "$SOMMA_DOPO" ]; then
    ok "--out personalizzato non tocca il fallback reale"
  else
    no "--out personalizzato non tocca il fallback reale"
  fi
else
  echo "SKIP: fallback reale assente (verrà creato dal seed 7.4)"
fi

echo
echo "Esito: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
