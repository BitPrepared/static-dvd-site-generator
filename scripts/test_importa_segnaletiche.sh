#!/usr/bin/env bash
# Verifica per scripts/importa_segnaletiche.sh (import foto segnaletiche
# codificate, Readme.md §3): copre gli scenari della spec foto-segnaletiche —
# formato obbligatorio del filename, codifica stabile e registro in sola
# appensione, copia rinominata incrementale e non distruttiva, incrocio con
# l'anagrafica CSV, generazione automatica dell'elenco quando assente,
# comando e diagnostica.
#
# Uso: scripts/test_importa_segnaletiche.sh   (oppure bash scripts/test_...)
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/importa_segnaletiche.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0; FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
no()   { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# Share finta con le foto di un'annata (soli filename validi: i file fuori
# formato hanno test dedicati a parte)
crea_share() { # dir
  mkdir -p "$1"
  printf 'foto mario v1' > "$1/mario_rossi_blu.jpg"
  printf 'foto marta'    > "$1/marta_riva_blu.jpg"
  printf 'foto marco'    > "$1/marco_rossi_oro.jpg"
  printf 'foto ginevra'  > "$1/ginevra_pero'_oro.jpg"
  printf 'foto maria'    > "$1/maria_chiara_dei_rossi_blu.jpg"
  printf 'note staff'    > "$1/note_staff.txt"      # non-immagine: fuori
  printf 'junk'          > "$1/.nascosto.jpg"       # nascosto: fuori
}

# elenco ragazzi finto: stessa intestazione del CSV vero, colonne nell'ordine
# standard (Nome;...;Cognome;...;Squadriglia)
crea_elenco() { # dir [con_mario]
  mkdir -p "$1"
  {
    printf '"Codicecensimento";"Nome";"Cognome";"Sesso";"Specialita";"SquadrigliaOrigine";"Reparto";"Gruppo";"Zona";"Via";"Ncivico";"CAP";"Citta";"Provincia";"Regione";"Squadriglia";"Ruolo";"Dt Nascita";"Telefono";"Email";"Instagram"\n'
    printf '"001";"Pippo";"Zoo";"M";"";"";"Topos";"Topolinia 1";"Reggio Emilia";"";"";"";"Topolinia";"";"veneto";"ORO";"";"24/07/2007";"";"";""\n'
    if [ "${2:-sì}" = "sì" ]; then
      printf '"002";"Mario";"Rossi";"M";"";"";"Topos";"Topolinia 1";"Reggio Emilia";"";"";"";"Topolinia";"";"veneto";"BLU";"";"01/01/2007";"";"";""\n'
    fi
  } > "$1/elenco_ragazzi.csv"
}

# lancio dell'import con destinazioni isolate: $1 sorgente, $2 cartella di
# lavoro (reparto/ e registro dentro), $3 elenco ragazzi (opzionale)
lancia() { # dir_src dir_lavoro [elenco]
  SEGNALETICHE_DST="$2/reparto" \
  REGISTRO_SEGNALETICHE="$2/registro_segnaletiche.csv" \
  ELENCO_RAGAZZI="${3:-$TMP/nessun_elenco.csv}" \
  bash "$SCRIPT" "$1" 2>&1
}

echo "== prerequisiti =="
[ -x "$SCRIPT" ] && ok "script esiste ed e' eseguibile" || no "script esiste ed e' eseguibile"
bash -n "$SCRIPT" && ok "sintassi bash" || no "sintassi bash"

echo "== formato obbligatorio del filename =="
SRC="$TMP/src_fmt"; LAV="$TMP/lav_fmt"; crea_share "$SRC"
out=$(lancia "$SRC" "$LAV"); rc=$?
reg="$LAV/registro_segnaletiche.csv"
if [ $rc -ne 0 ]; then
  no "filename validi: import riuscito (rc=$rc): $out"
else
  grep -qx "mario;rossi;blu;mr1_blu" "$reg" \
    && ok "filename canonico: mario_rossi_blu -> mr1_blu" \
    || no "filename canonico: manca mario;rossi;blu;mr1_blu ($(cat "$reg"))"
  grep -qx "maria;chiara dei rossi;blu;mc1_blu" "$reg" \
    && ok "nome composto: primo campo nome, campi medi cognome, ultimo squadriglia" \
    || no "nome composto: manca maria;chiara dei rossi;blu;mc1_blu"
fi

# file fuori formato: rifiutato con messaggio chiaro, nessuna copia
SRC="$TMP/src_ko"; LAV="$TMP/lav_ko"; mkdir -p "$SRC"
printf 'img macchina' > "$SRC/IMG_1234.jpg"
out=$(lancia "$SRC" "$LAV"); rc=$?
[ $rc -ne 0 ] && grep -qi "formato" <<<"$out" \
  && ok "file fuori formato: rifiutato con messaggio sul formato atteso" \
  || no "file fuori formato rifiutato (rc=$rc): $out"
[ -e "$LAV/reparto/IMG_1234.jpg" ] \
  && no "fuori formato: nessuna copia del file" \
  || ok "fuori formato: nessuna copia del file"
[ -f "$LAV/registro_segnaletiche.csv" ] \
  && no "fuori formato: registro non creato" \
  || ok "fuori formato: registro non creato"

echo "== codifica stabile e registro persistente =="
SRC="$TMP/src_cod"; LAV="$TMP/lav_cod"; crea_share "$SRC"
out=$(lancia "$SRC" "$LAV"); rc=$?
reg="$LAV/registro_segnaletiche.csv"
if [ $rc -ne 0 ]; then
  no "codifica: import riuscito (rc=$rc): $out"
else
  grep -qx "mario;rossi;blu;mr1_blu" "$reg" \
    && grep -qx "marta;riva;blu;mr2_blu" "$reg" \
    && ok "primo arrivo + secondo mr*_blu: mr1_blu resta di Mario, Marta prende mr2_blu" \
    || no "progressivo per squadriglia+iniziali ($(cat "$reg"))"
  grep -qx "marco;rossi;oro;mr1_oro" "$reg" \
    && ok "stesse iniziali in altra squadriglia: progressivo indipendente (mr1_oro)" \
    || no "stesse iniziali in altra squadriglia ($(cat "$reg"))"
  grep -qx "ginevra;pero';oro;gp1_oro" "$reg" \
    && ok "identita' accentata/apostrofo: iniziali ASCII (gp1_oro)" \
    || no "identita' apostrofo/accentata ($(cat "$reg"))"
fi

# re-import della stessa identita': riusa il codice, nessuna riga doppia;
# la versione nuova del file viene copiata sulla stessa destinazione (ritake)
printf 'foto mario v2' > "$SRC/mario_rossi_blu.jpg"
touch "$SRC/mario_rossi_blu.jpg"
out=$(lancia "$SRC" "$LAV"); rc=$?
if [ $rc -ne 0 ]; then
  no "re-import: passata riuscita (rc=$rc): $out"
else
  [ "$(grep -c '^mario;rossi;blu;' "$reg")" -eq 1 ] \
    && ok "re-import: identita' gia' registrata riusa il codice, nessuna riga doppia" \
    || no "re-import: righe mario duplicate o mancanti ($(cat "$reg"))"
  cmp -s "$SRC/mario_rossi_blu.jpg" "$LAV/reparto/mr1_blu.jpg" \
    && ok "ritake: la copia locale viene sovrascritta (last wins)" \
    || no "ritake: reparto/mr1_blu.jpg non aggiornata al contenuto nuovo"
fi

# registro mai riscritto: le righe esistenti restano identiche byte a byte
printf 'foto pino' > "$SRC/pino_caldo_gialli.jpg"
snapshot="$TMP/reg_snapshot"
cp "$reg" "$snapshot"
lancia "$SRC" "$LAV" >/dev/null
head -n "$(wc -l < "$snapshot")" "$reg" > "$TMP/reg_head"
diff -q "$snapshot" "$TMP/reg_head" >/dev/null \
  && ok "registro mai riscritto: solo appensione, righe precedenti intoccate" \
  || no "registro mai riscritto: le vecchie righe sono cambiate"

echo "== copia rinominata incrementale e non distruttiva =="
rep="$LAV/reparto"
cmp -s "$SRC/marta_riva_blu.jpg" "$rep/mr2_blu.jpg" \
  && ok "primo import: reparto/<codice>.<ext> con contenuto fedele" \
  || no "primo import: reparto/mr2_blu.jpg mancante o diversa"
# foto ritirata dal remoto: niente cancellazioni
rm "$SRC/mario_rossi_blu.jpg"
mt_prima="$(stat -c %Y "$rep/mr1_blu.jpg")"
sleep 1
out=$(lancia "$SRC" "$LAV"); rc=$?
[ $rc -eq 0 ] && [ -f "$rep/mr1_blu.jpg" ] \
  && grep -qx "mario;rossi;blu;mr1_blu" "$reg" \
  && ok "foto ritirata dal remoto: copia locale e riga di registro restano" \
  || no "foto ritirata dal remoto (rc=$rc): $out"
# passata senza novita': exit 0, dichiarazione esplicita, nessuna ricopiatura
[ "$mt_prima" = "$(stat -c %Y "$rep/mr1_blu.jpg")" ] \
  && grep -qi "nessuna foto nuova" <<<"$out" \
  && ok "passata senza novita': exit 0 e nessuna ricopiatura" \
  || no "passata senza novita' (rc=$rc): $out"
# disco pulito: nei filename prodotti compaiono soli codici
nomi_residui=$(ls "$rep" | grep -Ei 'mario|marta|riva|marco|ginevra|maria|chiara|rossi|pino|caldo' | wc -l)
[ "$nomi_residui" -eq 0 ] \
  && ok "disco pulito dopo l'import: nei filename prodotti compaiono soli codici" \
  || no "disco pulito dopo l'import ($nomi_residui filename con nomi)"

echo "== incrocio con l'anagrafica CSV =="
SRC="$TMP/src_inc"; LAV="$TMP/lav_inc"; crea_share "$SRC"
crea_elenco "$TMP/inc"            # elenco CON Mario Rossi
out=$(lancia "$SRC" "$LAV" "$TMP/inc/elenco_ragazzi.csv"); rc=$?
[ $rc -eq 0 ] && ! grep -q "mario_rossi_blu" <<<"$(grep -i warning <<<"$out")" \
  && ok "incrocio: foto coerente con l'anagrafica, match silenzioso" \
  || no "incrocio: match silenzioso atteso per mario_rossi_blu (rc=$rc): $out"

crea_elenco "$TMP/inc2" no        # elenco SENZA Mario Rossi
LAV2="$TMP/lav_inc2"; mkdir -p "$LAV2"
out=$(SEGNALETICHE_DST="$LAV2/reparto" REGISTRO_SEGNALETICHE="$LAV2/registro.csv" \
      ELENCO_RAGAZZI="$TMP/inc2/elenco_ragazzi.csv" \
      bash "$SCRIPT" "$SRC" 2>&1); rc=$?
[ $rc -eq 0 ] \
  && ok "incrocio: mismatch non fatale, import comunque completato (exit 0)" \
  || no "incrocio: mismatch deve restare exit 0 (rc=$rc)"
grep -q "mario_rossi_blu" <<<"$(grep -i warning <<<"$out")" \
  && ok "incrocio: warning esplicito con il file coinvolto" \
  || no "incrocio: manca il warning sul file senza corrispondenza: $out"
[ -f "$LAV2/reparto/mr1_blu.jpg" ] \
  && ok "incrocio: la foto senza corrispondenza viene comunque importata" \
  || no "incrocio: la foto senza corrispondenza doveva essere importata"
# elenco assente: incrocio saltato con avviso, ma l'import procede
LAV3="$TMP/lav_inc3"; mkdir -p "$LAV3"
out=$(SEGNALETICHE_DST="$LAV3/reparto" REGISTRO_SEGNALETICHE="$LAV3/registro.csv" \
      ELENCO_RAGAZZI="$TMP/inesistente.csv" \
      bash "$SCRIPT" "$SRC" 2>&1); rc=$?
[ $rc -eq 0 ] && grep -qi "elenco" <<<"$out" && [ -f "$LAV3/reparto/mr1_blu.jpg" ] \
  && ok "incrocio: elenco assente -> avviso, import prosegue" \
  || no "incrocio: elenco assente (rc=$rc): $out"

echo "== generazione automatica dell'elenco dal registro =="
# elenco assente: a fine passata nasce dal registro, con avviso unico e zero
# warning per-foto (senza elenco non c'e' confronto che possa fallire)
SRC="$TMP/src_gen"; LAV="$TMP/lav_gen"; crea_share "$SRC"
EL="$LAV/anagrafica/elenco_ragazzi.csv"
out=$(SEGNALETICHE_DST="$LAV/reparto" REGISTRO_SEGNALETICHE="$LAV/anagrafica/registro.csv" \
      ELENCO_RAGAZZI="$EL" bash "$SCRIPT" "$SRC" 2>&1); rc=$?
[ $rc -eq 0 ] && [ -f "$EL" ] && grep -qi "generato" <<<"$out" \
  && ok "elenco assente: generato dal registro a fine passata" \
  || no "elenco assente: attesa la generazione (rc=$rc): $out"
[ "$(head -n1 "$EL")" = "nome;cognome;squadriglia" ] \
  && ok "elenco generato: intestazione nome;cognome;squadriglia" \
  || no "elenco generato: intestazione sbagliata ($(head -n1 "$EL"))"
diff <(tail -n +2 "$LAV/anagrafica/registro.csv" | cut -d';' -f1-3) <(tail -n +2 "$EL") >/dev/null \
  && ok "elenco generato: una riga per identita', stesso ordine del registro" \
  || no "elenco generato: righe diverse dal registro"
grep -q "nessuna corrispondenza nell'elenco" <<<"$out" \
  && no "senza elenco: nessun warning per-foto atteso: $out" \
  || ok "senza elenco: zero warning per-foto (solo l'avviso unico)"
# passata successiva: l'elenco generato fa matchare l'incrocio, silenzio totale
out=$(lancia "$SRC" "$LAV" "$EL"); rc=$?
[ $rc -eq 0 ] && ! grep -qi "warning" <<<"$out" \
  && ok "passata successiva: incrocio matcha sull'elenco generato, zero warning" \
  || no "passata successiva (rc=$rc): $out"
# elenco fornito o corretto a mano: mai toccato, nemmeno di un byte
printf 'nome;cognome;squadriglia\nPippo;Paperino;ORO\n' > "$TMP/elenco_a_mano.csv"
cp "$TMP/elenco_a_mano.csv" "$TMP/elenco_prima"
lancia "$SRC" "$LAV" "$TMP/elenco_a_mano.csv" >/dev/null
cmp -s "$TMP/elenco_a_mano.csv" "$TMP/elenco_prima" \
  && ok "elenco fornito a mano: resta byte per byte invariato" \
  || no "elenco fornito a mano: e' stato modificato"
# nessuna identita' nel registro (share tutta rifiutata): nessun elenco vuoto
SRC="$TMP/src_ko2"; LAV="$TMP/lav_ko2"; mkdir -p "$SRC"
printf 'img macchina' > "$SRC/IMG_9999.jpg"
out=$(SEGNALETICHE_DST="$LAV/reparto" REGISTRO_SEGNALETICHE="$LAV/anagrafica/registro.csv" \
      ELENCO_RAGAZZI="$LAV/anagrafica/elenco_ragazzi.csv" bash "$SCRIPT" "$SRC" 2>&1); rc=$?
[ $rc -ne 0 ] && [ ! -f "$LAV/anagrafica/elenco_ragazzi.csv" ] && grep -qi "registro vuoto" <<<"$out" \
  && ok "registro vuoto: nessun elenco creato, niente crash" \
  || no "registro vuoto: atteso niente elenco (rc=$rc): $out"
# elenco non scrivibile (la "cartella" e' un file piatto): errore rumoroso
SRC="$TMP/src_fail"; LAV="$TMP/lav_fail"; crea_share "$SRC"
mkdir -p "$LAV" && touch "$LAV/blocco"
out=$(SEGNALETICHE_DST="$LAV/reparto" REGISTRO_SEGNALETICHE="$LAV/registro.csv" \
      ELENCO_RAGAZZI="$LAV/blocco/elenco_ragazzi.csv" bash "$SCRIPT" "$SRC" 2>&1); rc=$?
[ $rc -ne 0 ] && grep -qi "creabile" <<<"$out" \
  && ok "elenco non scrivibile: exit != 0 con messaggio azionabile" \
  || no "fallimento scrittura elenco (rc=$rc): $out"

echo "== comando e diagnostica =="
out=$(bash "$SCRIPT" "$TMP/inesistente" 2>&1); rc=$?
[ $rc -ne 0 ] && grep -qi "sorgente" <<<"$out" \
  && ok "sorgente assente: exit != 0 con messaggio azionabile" \
  || no "sorgente assente (rc=$rc): $out"
mkdir -p "$TMP/vuota"
out=$(lancia "$TMP/vuota" "$TMP/lav_vuota"); rc=$?
[ $rc -eq 0 ] && grep -qi "nessuna foto" <<<"$out" \
  && ok "passata su share vuota: exit 0 dichiarando che non c'e' nulla da fare" \
  || no "share vuota (rc=$rc): $out"

echo "== filtro estensioni come importa_foto.sh =="
SRC="$TMP/src_ext"; LAV="$TMP/lav_ext"; mkdir -p "$SRC"
printf 'testo'    > "$SRC/documento.txt"
printf 'immagine' > "$SRC/anna_messi_verde.heic"
out=$(lancia "$SRC" "$LAV"); rc=$?
[ $rc -eq 0 ] && [ -f "$LAV/reparto/am1_verde.heic" ] && [ ! -e "$LAV/reparto/documento.txt" ] \
  && ok "estensioni: immagini prese (anche .heic), testo lasciato fuori" \
  || no "filtro estensioni (rc=$rc): $(ls "$LAV/reparto" 2>/dev/null)"

echo
echo "esito: $PASS PASS, $FAIL FAIL"
[ "$FAIL" -eq 0 ]
