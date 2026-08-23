#!/usr/bin/env bash
# Importa e codifica le foto segnaletiche dei ragazzi dalla share dello staff
# (Readme.md §3, change foto-segnaletiche-codificate).
#
# Formato obbligatorio del filename: nome_cognome_squadriglia.<ext>
#   primo campo = nome, campi intermedi = cognome, ultimo = squadriglia
#   (minimo 3 campi: i file fuori formato vengono rifiutati con messaggio
#   chiaro e senza alcuna copia).
#
# Per ogni foto accettata:
#   1. codice stabile <iniziali><progressivo>_<squadriglia> (es. mr1_blu):
#      assegnato una volta sola e mai piu' cambiato; il mapping
#      codice <-> nome;cognome;squadriglia vive in anagrafica/
#      registro_segnaletiche.csv (gitignored), aggiornato SOLO in appensione:
#      un'identita' gia' registrata riusa sempre il suo codice;
#   2. copia rinominata in dvd/angolisq/materiale/reparto/<codice>.<ext>:
#      incrementale (solo nuove o piu' recenti), un ritake sovrascrive la
#      copia locale (last wins), una foto sparita dalla share non cancella
#      nulla: stesso patto non distruttivo di importa_foto.sh;
#   3. incrocio con anagrafica/elenco_ragazzi.csv per nome+cognome+
#      squadriglia: match silenzioso, mismatch -> warning con il file e il
#      motivo (tipico: typo nel filename) ma import comunque completato.
#
# Uso:
#   scripts/importa_segnaletiche.sh [DIR_SORGENTE]     una passata
#
# Variabili d'ambiente:
#   SEGNALETICHE_SRC         sorgente     (default ~/share_disks/staff/segnaletiche)
#   SEGNALETICHE_DST         destinazione (default <repo>/dvd/angolisq/materiale/reparto)
#   REGISTRO_SEGNALETICHE    registro dei codici
#                            (default <repo>/anagrafica/registro_segnaletiche.csv)
#   ELENCO_RAGAZZI           elenco ragazzi per l'incrocio
#                            (default <repo>/anagrafica/elenco_ragazzi.csv)
#   SEGNALETICHE_ESTENSIONI  elenco estensioni immagine, separato da spazi
#                            (default "jpg jpeg png gif bmp tif tiff webp heic heif")
#
# Exit code: 0 = importato o nessuna novita' (warning di incrocio compresi);
#            2 = errore (sorgente assente, file rifiutati, copie fallite).
set -u

muori() { echo "ERRORE: $*" >&2; exit 2; }
adesso() { date '+%H:%M:%S'; }

usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print } NR > 1 && !/^#/ { exit }' "$0"; }

[ $# -le 1 ] || muori "troppi argomenti (uso: $0 [DIR_SORGENTE], -h per l'aiuto)"
for a in "$@"; do
  case "$a" in
    -h|--help) usage; exit 0 ;;
    -*) muori "opzione sconosciuta: $a" ;;
  esac
done

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:-${SEGNALETICHE_SRC:-$HOME/share_disks/staff/segnaletiche}}"
DST="${SEGNALETICHE_DST:-$REPO/dvd/angolisq/materiale/reparto}"
REGISTRO="${REGISTRO_SEGNALETICHE:-$REPO/anagrafica/registro_segnaletiche.csv}"
ELENCO="${ELENCO_RAGAZZI:-$REPO/anagrafica/elenco_ragazzi.csv}"
ESTENSIONI="${SEGNALETICHE_ESTENSIONI:-jpg jpeg png gif bmp tif tiff webp heic heif}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

[ -d "$SRC" ] || muori "sorgente non trovata: $SRC
(aspettati le foto segnaletiche li', oppure passala come argomento /
con SEGNALETICHE_SRC=/percorso/share)"
mkdir -p "$DST" || muori "destinazione non creabile: $DST"

# --------------------------------------------------------------- identita'

# ASCII minuscolo di un campo d'identita': accenti italiani traslitterati,
# via apostrofi e spazi. Stesso criterio dell'idRagazzo() del generatore
# dell'anagrafica: una sola implementazione del concetto "ASCII minuscolo"
# su entrambi i lati dell'incrocio (filename vs CSV).
ascii_minuscolo() {
  printf '%s' "$1" \
    | sed -e 's/à/a/g; s/á/a/g; s/â/a/g; s/ä/a/g; s/À/a/g; s/Á/a/g; s/Â/a/g; s/Ä/a/g' \
          -e 's/è/e/g; s/é/e/g; s/ê/e/g; s/ë/e/g; s/È/e/g; s/É/e/g; s/Ê/e/g; s/Ë/e/g' \
          -e 's/ì/i/g; s/í/i/g; s/î/i/g; s/ï/i/g; s/Ì/i/g; s/Í/i/g; s/Î/i/g; s/Ï/i/g' \
          -e 's/ò/o/g; s/ó/o/g; s/ô/o/g; s/ö/o/g; s/Ò/o/g; s/Ó/o/g; s/Ô/o/g; s/Ö/o/g' \
          -e 's/ù/u/g; s/ú/u/g; s/û/u/g; s/ü/u/g; s/Ù/u/g; s/Ú/u/g; s/Û/u/g; s/Ü/u/g' \
          -e 's/ç/c/g; s/Ç/c/g; s/ñ/n/g; s/Ñ/n/g' \
          -e "s/['’‘]//g" \
          -e 's/"//g' \
          -e 's/[[:space:]]//g' \
    | tr '[:upper:]' '[:lower:]'
}

# Chiave d'identita' normalizzata: confronto nome+cognome+squadriglia
# indipendente da maiuscole, accenti, apostrofi e spazi (cosi' "Dell'Orto"
# nel CSV matcha "dellorto" nel filename). Con newline finale: nelle
# sostituzioni di comando sparisce, nell'elenco delle chiavi separa le righe.
chiave_identita() { # nome cognome squadriglia
  printf '%s|%s|%s\n' "$(ascii_minuscolo "$1")" "$(ascii_minuscolo "$2")" "$(ascii_minuscolo "$3")"
}

# Prima lettera ASCII del campo (per le iniziali del codice); 'x' se il
# campo non produce lettere ASCII.
iniziale() {
  local c="$(ascii_minuscolo "$1" | cut -c1)"
  case "$c" in [a-z]) printf '%s' "$c" ;; *) printf 'x' ;; esac
}

# ----------------------------------------------------------------- registro

# Registro caricato una volta a passata: righe nome;cognome;squadriglia;
# codice (la prima riga di intestazione viene scritta alla creazione ed
# ignorata qui). Le ricerche non rilleggono il file.
REG_NOME=(); REG_COGNOME=(); REG_SQ=(); REG_CODICE=()
carica_registro() {
  [ -f "$REGISTRO" ] || return 0
  while IFS=';' read -r n c s cod; do
    [ "$cod" = "codice" ] && continue        # intestazione
    [ -z "$n$c$s$cod" ] && continue          # righe vuote tollerate
    REG_NOME+=("$n"); REG_COGNOME+=("$c"); REG_SQ+=("$s"); REG_CODICE+=("$cod")
  done < "$REGISTRO"
}

trova_codice() { # nome cognome squadriglia -> stampa il codice ('' se assente)
  local k="$(chiave_identita "$1" "$2" "$3")" i
  for ((i=0; i<${#REG_CODICE[@]}; i++)); do
    if [ "$(chiave_identita "${REG_NOME[i]}" "${REG_COGNOME[i]}" "${REG_SQ[i]}")" = "$k" ]; then
      printf '%s' "${REG_CODICE[i]}"
      return 0
    fi
  done
}

# Nuovo codice <iniziali><progressivo>_<sq>: il progressivo conta le
# identita' con le stesse iniziali nella stessa squadriglia, guardando sia
# il registro sia i file gia' presenti in reparto/ (cosi' un re-import dopo
# la perdita del registro riparte dagli stessi progressivi, stesso ordine di
# scansione permettendo).
nuovo_codice() { # nome cognome squadriglia
  local ini="$(iniziale "$1")$(iniziale "$2")"
  local sq="$(ascii_minuscolo "$3")"
  local max=0 cod num re="^${ini}[0-9]+_${sq}$" f base
  for cod in "${REG_CODICE[@]}"; do
    [[ "$cod" =~ $re ]] || continue
    num="${cod#${ini}}"; num="${num%%_*}"
    [ "$num" -gt "$max" ] && max=$num
  done
  for f in "$DST"/"$ini"*_"$sq".*; do
    [ -f "$f" ] || continue
    base="$(basename "$f")"; base="${base%.*}"
    [[ "$base" =~ $re ]] || continue
    num="${base#${ini}}"; num="${num%%_*}"
    [ "$num" -gt "$max" ] && max=$num
  done
  printf '%s%d_%s' "$ini" "$((max+1))" "$sq"
}

# Appensione al registro: il file nasce con la riga di intestazione alla
# prima identificazione; le righe esistenti non vengono mai toccate.
registra() { # nome cognome squadriglia codice
  if [ ! -f "$REGISTRO" ]; then
    mkdir -p "$(dirname "$REGISTRO")" || muori "cartella del registro non creabile: $(dirname "$REGISTRO")"
    printf 'nome;cognome;squadriglia;codice\n' > "$REGISTRO"
  fi
  printf '%s;%s;%s;%s\n' "$1" "$2" "$3" "$4" >> "$REGISTRO"
}

# ------------------------------------------------------------ incrocio CSV

CHIAVI_ELENCO=""       # file temporaneo delle chiavi normalizzate del CSV
ELENCO_OK=0

# Carica le chiavi d'identita' dell'elenco ragazzi: colonne trovate per
# posizione dall'intestazione (l'ordine delle colonne dell'export puo'
# cambiare), valori tra virgolette ripuliti e normalizzati come i filename.
carica_elenco() {
  CHIAVI_ELENCO="$TMP/chiavi_elenco.txt"
  [ -f "$ELENCO" ] || {
    echo "WARNING: elenco ragazzi non trovato ($ELENCO): incrocio saltato
  (per una prova: cp anagrafica/elenco_ragazzi_example.csv $ELENCO)" >&2
    return 1
  }
  local intestazione linea idx=0 i_n=-1 i_c=-1 i_s=-1 campo
  IFS= read -r intestazione < "$ELENCO"
  intestazione="${intestazione#$'\xef\xbb\xbf'}"   # BOM utf-8 dell'export
  IFS=';' read -ra colonne <<< "$intestazione"
  for campo in "${colonne[@]}"; do
    campo="$(printf '%s' "$campo" | tr -d '"' | tr '[:upper:]' '[:lower:]' | tr -d '[:space:]')"
    case "$campo" in
      nome) i_n=$idx ;;
      cognome) i_c=$idx ;;
      squadriglia) i_s=$idx ;;
    esac
    idx=$((idx+1))
  done
  if [ "$i_n" -lt 0 ] || [ "$i_c" -lt 0 ] || [ "$i_s" -lt 0 ]; then
    echo "WARNING: elenco ragazzi senza le colonne Nome/Cognome/Squadriglia ($ELENCO): incrocio saltato" >&2
    return 1
  fi
  tail -n +2 "$ELENCO" | while IFS= read -r linea; do
    linea="${linea%$'\r'}"
    [ -n "$linea" ] || continue
    IFS=';' read -ra campi <<< "$linea"
    [ "${#campi[@]}" -gt "$i_s" ] || continue   # riga malformata: la si salta
    # nota: split ingenuo sui ';': vale per l'export attuale, che non cita
    # mai ';' dentro i campi Nome/Cognome/Squadriglia
    chiave_identita "${campi[$i_n]}" "${campi[$i_c]}" "${campi[$i_s]}"
  done > "$CHIAVI_ELENCO"
  ELENCO_OK=1
}

elenco_contiene() { # nome cognome squadriglia -> 0 se presente nell'elenco
  [ "$ELENCO_OK" -eq 1 ] || return 1
  grep -qxF "$(chiave_identita "$1" "$2" "$3")" "$CHIAVI_ELENCO"
}

# ------------------------------------------------------------------- passata

lista_immagini() {
  # elenco deterministico (LC_ALL=C): l'ordine di scansione fa parte del
  # patto del registro (vedi nuovo_codice)
  (cd "$SRC" && find . -type f ! -name '.*' -print0) \
    | LC_ALL=C sort -z \
    | while IFS= read -r -d '' p; do
        rel="${p#./}"
        est="${rel##*.}"; est="${est,,}"
        immagine=0
        for e in $ESTENSIONI; do
          [ "$est" = "$e" ] && { immagine=1; break; }
        done
        [ "$immagine" -eq 1 ] && printf '%s\0' "$rel"
      done
}

passata() {
  carica_registro
  carica_elenco || true

  local -a pend=()
  mapfile -d '' pend < <(lista_immagini)
  if [ "${#pend[@]}" -eq 0 ]; then
    echo "[$(adesso)] nessuna foto nuova o modificata in $SRC"
    return 0
  fi
  echo "[$(adesso)] ${#pend[@]} foto da esaminare in $SRC"

  local rel base nome_base est nome sq cognome codice dest ok=0 ko=0 gia=0
  for rel in "${pend[@]}"; do
    base="${rel##*/}"
    nome_base="${base%.*}"
    est="${base##*.}"; est="${est,,}"

    # parsing del formato obbligatorio: minimo 3 campi, nessuno vuoto
    IFS='_' read -ra campi <<< "$nome_base"
    nome="${campi[0]}"
    sq="${campi[${#campi[@]}-1]}"
    cognome="$(IFS=' '; echo "${campi[*]:1:${#campi[@]}-2}")"
    if [ "${#campi[@]}" -lt 3 ] || [ -z "$nome" ] || [ -z "$cognome" ] || [ -z "$sq" ]; then
      echo "RIFIUTATO: $base: il nome non rispetta il formato obbligatorio nome_cognome_squadriglia.<ext>
  (primo campo = nome, campi intermedi = cognome, ultimo = squadriglia, minimo 3 campi separati da _)" >&2
      ko=$((ko+1))
      continue
    fi
    sq="$(ascii_minuscolo "$sq")"
    if ! [[ "$sq" =~ ^[a-z0-9_]+$ ]]; then
      echo "RIFIUTATO: $base: la squadriglia '$sq' non produce un tratto valido per il codice
  (formato obbligatorio: nome_cognome_squadriglia.<ext>, squadriglia con soli caratteri semplici)" >&2
      ko=$((ko+1))
      continue
    fi

    # codice stabile: quello registrato, o uno nuovo appeso al registro
    codice="$(trova_codice "$nome" "$cognome" "$sq")"
    if [ -z "$codice" ]; then
      # memorizzo il campo com'e' stato parsato (legibile e correggibile a mano)
      codice="$(nuovo_codice "$nome" "$cognome" "$sq")"
      registra "$(printf '%s' "$nome" | tr '[:upper:]' '[:lower:]')" \
               "$(printf '%s' "$cognome" | tr '[:upper:]' '[:lower:]')" \
               "$sq" "$codice"
      REG_NOME+=("$(printf '%s' "$nome" | tr '[:upper:]' '[:lower:]')")
      REG_COGNOME+=("$(printf '%s' "$cognome" | tr '[:upper:]' '[:lower:]')")
      REG_SQ+=("$sq"); REG_CODICE+=("$codice")
    fi

    dest="$DST/$codice.$est"
    if [ -f "$dest" ] && ! [ "$SRC/$rel" -nt "$dest" ]; then
      gia=$((gia+1))                       # gia' importata e non modificata
      continue
    fi
    if cp -f -- "$SRC/$rel" "$dest"; then
      ok=$((ok+1))
    else
      echo "  copia fallita: $rel -> $dest" >&2
      ko=$((ko+1))
      continue
    fi

    # incrocio con l'anagrafica: solo diagnostica, l'import prosegue comunque
    if ! elenco_contiene "$nome" "$cognome" "$sq"; then
      echo "WARNING: $base ($codice): nessuna corrispondenza nell'elenco ragazzi per nome='$nome' cognome='$cognome' squadriglia='$sq'
  tipico typo nel filename o ragazzo mancante nell'export: la foto resta fuori dal sito finche' filename o CSV non vengono corretti (poi re-import + make anagrafica + make build)" >&2
    fi
  done

  rm -f "$CHIAVI_ELENCO"
  if [ "$ok" -eq 0 ] && [ "$ko" -eq 0 ]; then
    echo "[$(adesso)] nessuna foto nuova o modificata in $SRC ($gia gia' presenti)"
    return 0
  fi
  echo "[$(adesso)] importate $ok foto in $DST${gia:+, $gia non modificate}${ko:+, $ko rifiutate/fallite}"
  [ "$ko" -eq 0 ] || return 2
}

passata || exit $?
