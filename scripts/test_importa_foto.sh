#!/usr/bin/env bash
# Verifica per scripts/importa_foto.sh (import foto staff, Readme.md §3).
# Uso: scripts/test_importa_foto.sh   (oppure bash scripts/test_importa_foto.sh)
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/importa_foto.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
# HOME isolato: l'auto-rilevamento non deve guardare gli script della macchina
HOME="$TMP/home"
mkdir -p "$HOME"

PASS=0; FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
no()   { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# prepara una share finta con struttura giorno/categoria, spazzatura e
# file non-immagine
crea_share() { # dir
  mkdir -p "$1/giorno_uno_martedi/varie" "$1/giorno_uno_martedi/squadriglia" \
           "$1/giorno_zero" "$1/documenti"
  echo "foto A" > "$1/giorno_uno_martedi/varie/a.jpg"
  echo "foto B" > "$1/giorno_uno_martedi/squadriglia/b.jpg"
  echo "foto C" > "$1/giorno_zero/c.png"
  echo "UP"     > "$1/giorno_uno_martedi/varie/MAIUSCOLA.JPG"
  echo "junk"   > "$1/giorno_zero/Thumbs.db"
  echo "junk"   > "$1/giorno_zero/.DS_Store"
  echo "junk"   > "$1/.nascosto"
  echo "leggi"  > "$1/giorno_zero/README.md"
  echo "note"   > "$1/documenti/note.txt"
}

# script di rotazione finto: registra la chiamata su <script>.chiamate;
# comportamento: noop (default), renomina (a.jpg -> IMG_a.jpg), fallisce (exit 1)
crea_ruota() { # dir_script [noop|renomina|fallisce]
  mkdir -p "$(dirname "$1")"
  {
    echo '#!/usr/bin/env bash'
    echo 'echo "$@" >> "'"$1"'.chiamate"'
    case "${2:-noop}" in
      renomina) echo 'mv "$1/giorno_uno_martedi/varie/a.jpg" "$1/giorno_uno_martedi/varie/IMG_a.jpg"' ;;
      fallisce) echo 'echo "boom" >&2'; echo 'exit 1' ;;
    esac
    echo 'exit 0'
  } > "$1"
  chmod +x "$1"
}

echo "== prerequisiti =="
[ -x "$SCRIPT" ] && ok "script esiste ed e' eseguibile" || no "script esiste ed e' eseguibile"
bash -n "$SCRIPT" && ok "sintassi bash" || no "sintassi bash"

echo "== errori di prerequisito =="
out=$("$SCRIPT" "$TMP/inesistente" 2>&1); [ $? -ne 0 ] && grep -qi "sorgente" <<<"$out" \
  && ok "sorgente inesistente rifiutata" || no "sorgente inesistente rifiutata ($out)"

crea_share "$TMP/src"
out=$(FOTO_DST="$TMP/dst" RUOTA_SCRIPT="$TMP/nope.sh" "$SCRIPT" "$TMP/src" 2>&1); rc=$?
[ $rc -ne 0 ] && grep -qi "non eseguibile" <<<"$out" \
  && ok "ruota esplicita ma assente rifiutata (exit $rc)" || no "ruota esplicita ma assente rifiutata (exit $rc: $out)"

out=$("$SCRIPT" --pippo "$TMP/src" 2>&1); grep -qi "sconosciuta" <<<"$out" \
  && ok "opzione sconosciuta rifiutata" || no "opzione sconosciuta rifiutata ($out)"

out=$("$SCRIPT" --interval xyz "$TMP/src" 2>&1); grep -qi "numero" <<<"$out" \
  && ok "--interval non numerico rifiutato" || no "--interval non numerico rifiutato ($out)"

echo "== import completo: struttura mantenuta, spazzatura esclusa =="
crea_ruota "$TMP/ruota.sh"
out=$(FOTO_DST="$TMP/dst" RUOTA_SCRIPT="$TMP/ruota.sh" "$SCRIPT" "$TMP/src" 2>&1); rc=$?
[ $rc -eq 0 ] || no "import completo exit $rc: $out"
for f in "giorno_uno_martedi/varie/a.jpg" "giorno_uno_martedi/squadriglia/b.jpg" \
         "giorno_zero/c.png" "giorno_uno_martedi/varie/MAIUSCOLA.JPG"; do
  [ -f "$TMP/dst/$f" ] && cmp -s "$TMP/src/$f" "$TMP/dst/$f" \
    && ok "copiata fedele: $f" || no "copiata fedele: $f"
done
for f in "giorno_zero/Thumbs.db" "giorno_zero/.DS_Store" ".nascosto" "giorno_zero/README.md"; do
  [ ! -e "$TMP/dst/$f" ] && ok "escluso: $f" || no "escluso: $f"
done
[ ! -d "$TMP/dst/documenti" ] \
  && ok "cartella senza immagini non creata in destinazione" \
  || no "cartella senza immagini non creata in destinazione"
[ "$(cat "$TMP/ruota.sh.chiamate" 2>/dev/null | wc -l)" -eq 1 ] \
  && ok "ruota chiamata una volta sulla sorgente" || no "ruota chiamata una sola volta"

echo "== idempotenza: seconda passata senza novita' =="
mt_prima=$(stat -c %Y "$TMP/dst/giorno_zero/c.png")
out=$(FOTO_DST="$TMP/dst" RUOTA_SCRIPT="$TMP/ruota.sh" "$SCRIPT" "$TMP/src" 2>&1); rc=$?
grep -qi "nessuna foto" <<<"$out" && [ $rc -eq 0 ] \
  && ok "seconda passata: nessuna novita'" || no "seconda passata: nessuna novita' (exit $rc: $out)"
mt_dopo=$(stat -c %Y "$TMP/dst/giorno_zero/c.png")
[ "$mt_prima" = "$mt_dopo" ] && ok "file gia' importato non ritoccato" || no "file gia' importato non ritoccato"

echo "== incrementale: solo le nuove =="
echo "foto D" > "$TMP/src/giorno_zero/d.jpg"
out=$(FOTO_DST="$TMP/dst" RUOTA_SCRIPT="$TMP/ruota.sh" "$SCRIPT" "$TMP/src" 2>&1); rc=$?
[ $rc -eq 0 ] && grep -q "copiate 1 foto" <<<"$out" && [ -f "$TMP/dst/giorno_zero/d.jpg" ] \
  && ok "solo la nuova foto copiata" || no "solo la nuova foto copiata (exit $rc: $out)"

echo "== modifica di una foto gia' importata =="
echo "foto A2" > "$TMP/src/giorno_uno_martedi/varie/a.jpg"
sleep 1; touch "$TMP/src/giorno_uno_martedi/varie/a.jpg"
out=$(FOTO_DST="$TMP/dst" RUOTA_SCRIPT="$TMP/ruota.sh" "$SCRIPT" "$TMP/src" 2>&1); rc=$?
cmp -s "$TMP/src/giorno_uno_martedi/varie/a.jpg" "$TMP/dst/giorno_uno_martedi/varie/a.jpg" \
  && ok "foto modificata aggiornata" || no "foto modificata aggiornata (exit $rc: $out)"

echo "== rotazione con rinomina =="
crea_share "$TMP/src2"
crea_ruota "$TMP/ruota2.sh" renomina
out=$(FOTO_DST="$TMP/dst2" RUOTA_SCRIPT="$TMP/ruota2.sh" "$SCRIPT" "$TMP/src2" 2>&1); rc=$?
[ -f "$TMP/dst2/giorno_uno_martedi/varie/IMG_a.jpg" ] && [ ! -e "$TMP/dst2/giorno_uno_martedi/varie/a.jpg" ] \
  && [ $rc -eq 0 ] \
  && ok "foto rinominata importata col nuovo nome" || no "foto rinominata importata col nuovo nome (exit $rc: $out)"

echo "== rotazione fallita =="
crea_share "$TMP/src3"
crea_ruota "$TMP/ruota3.sh" fallisce
out=$(FOTO_DST="$TMP/dst3" RUOTA_SCRIPT="$TMP/ruota3.sh" "$SCRIPT" "$TMP/src3" 2>&1); rc=$?
[ $rc -ne 0 ] && [ ! -e "$TMP/dst3/giorno_zero/c.png" ] \
  && ok "rotazione fallita: nessuna copia, exit $rc" || no "rotazione fallita: nessuna copia (exit $rc)"

echo "== --salta-rotazione =="
out=$(FOTO_DST="$TMP/dst4" RUOTA_SCRIPT="$TMP/nope.sh" "$SCRIPT" --salta-rotazione "$TMP/src3" 2>&1); rc=$?
[ $rc -eq 0 ] && [ -f "$TMP/dst4/giorno_zero/c.png" ] && [ ! -e "$TMP/nope.sh.chiamate" ] \
  && ok "copia senza toccare la rotazione" || no "copia senza toccare la rotazione (exit $rc: $out)"

echo "== auto-rilevamento dello script di rotazione =="
crea_share "$TMP/src6"
mkdir -p "$TMP/home/scripts"
crea_ruota "$TMP/home/scripts/autoRuotaImmagini.sh"
out=$(FOTO_DST="$TMP/dst6" "$SCRIPT" "$TMP/src6" 2>&1); rc=$?
[ $rc -eq 0 ] && [ -f "$TMP/home/scripts/autoRuotaImmagini.sh.chiamate" ] \
  && ok "nome locale (autoRuotaImmagini.sh) rilevato da solo" \
  || no "nome locale rilevato da solo (exit $rc: $out)"

crea_ruota "$TMP/home/scripts/ruota_rinomina_immagini.sh"
out=$(FOTO_DST="$TMP/dst7" "$SCRIPT" "$TMP/src6" 2>&1); rc=$?
[ -f "$TMP/home/scripts/ruota_rinomina_immagini.sh.chiamate" ] \
  && ok "nome server ha la precedenza quando esistono entrambi" \
  || no "nome server in precedenza (exit $rc: $out)"

out=$(FOTO_DST="$TMP/dst8" RUOTA_SCRIPT="$TMP/ruota.sh" "$SCRIPT" "$TMP/src6" 2>&1); rc=$?
tail -n 1 "$TMP/ruota.sh.chiamate" | grep -q "$TMP/src6" \
  && ok "override esplicito RUOTA_SCRIPT vince sull'auto-rilevamento" \
  || no "override esplicito (exit $rc: $out)"

out=$(FOTO_DST="$TMP/dst9" HOME="$TMP/vuoto" "$SCRIPT" --salta-rotazione "$TMP/src6" 2>&1); rc=$?
[ $rc -eq 0 ] && [ -f "$TMP/dst9/giorno_zero/c.png" ] \
  && ok "--salta-rotazione funziona anche senza alcuno script di rotazione" \
  || no "--salta-rotazione senza script (exit $rc: $out)"

mkdir -p "$TMP/homeMaiuscolo/Scripts"
crea_ruota "$TMP/homeMaiuscolo/Scripts/autoRuotaImmagini.sh"
out=$(FOTO_DST="$TMP/dst10" HOME="$TMP/homeMaiuscolo" "$SCRIPT" "$TMP/src6" 2>&1); rc=$?
[ $rc -eq 0 ] && [ -f "$TMP/homeMaiuscolo/Scripts/autoRuotaImmagini.sh.chiamate" ] \
  && ok "cartella ~/Scripts (maiuscolo) rilevata" \
  || no "cartella ~/Scripts (maiuscolo) rilevata (exit $rc: $out)"

mkdir -p "$TMP/homeSenzaS/Script"
crea_ruota "$TMP/homeSenzaS/Script/autoRuotaImmagini.sh"
out=$(FOTO_DST="$TMP/dst11" HOME="$TMP/homeSenzaS" "$SCRIPT" "$TMP/src6" 2>&1); rc=$?
[ $rc -eq 0 ] && [ -f "$TMP/homeSenzaS/Script/autoRuotaImmagini.sh.chiamate" ] \
  && ok "cartella ~/Script (senza s finale) rilevata" \
  || no "cartella ~/Script (senza s finale) rilevata (exit $rc: $out)"

echo "== filtro estensioni configurabile =="
out=$(FOTO_DST="$TMP/dst12" FOTO_ESTENSIONI="png" RUOTA_SCRIPT="$TMP/ruota.sh" \
      "$SCRIPT" --salta-rotazione "$TMP/src" 2>&1); rc=$?
[ $rc -eq 0 ] && [ -f "$TMP/dst12/giorno_zero/c.png" ] \
  && [ ! -e "$TMP/dst12/giorno_uno_martedi/varie/a.jpg" ] \
  && [ ! -d "$TMP/dst12/giorno_uno_martedi/varie" ] \
  && [ ! -d "$TMP/dst12/documenti" ] \
  && ok "FOTO_ESTENSIONI=png: solo png, niente cartelle senza png" \
  || no "FOTO_ESTENSIONI=png (exit $rc: $out)"

echo "== watch (polling) =="
crea_share "$TMP/src5"
crea_ruota "$TMP/ruota5.sh"
if command -v timeout >/dev/null 2>&1; then
  out=$(FOTO_DST="$TMP/dst5" RUOTA_SCRIPT="$TMP/ruota5.sh" timeout 2 \
        "$SCRIPT" --watch --interval 0.3 "$TMP/src5" 2>&1); rc=$?
  passate=$(grep -c "nessuna foto" <<<"$out")
  [ -f "$TMP/dst5/giorno_uno_martedi/varie/a.jpg" ] && [ "$passate" -ge 2 ] \
    && ok "watch: prima importazione + polling attivo ($passate passate)" \
    || no "watch: prima importazione + polling attivo (exit $rc, $passate passate: $out)"
else
  echo "SKIP: watch (timeout non disponibile)"
fi

echo
echo "Risultato: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
