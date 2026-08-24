#!/usr/bin/env bash
# Reset d'annata: riporta il repository allo stato di fresh clone rimuovendo
# in un solo comando dichiarato tutto il dato dell'annata e l'output generato
# (Readme.md §6).
#
# Perimetro della rimozione (e SOLO questo):
#   - build/            svuotata e ricreata vuota, stessa semantica di make clean
#   - dati/squadriglie.json
#   - golden/           snapshot di verifica regressione
#   - dvd/*/src/        SOLO i file non tracciati da git: le pagine generate
#                       a ogni build e qualunque contenuto non tracciato; le
#                       pagine scritte a mano tracciate restano per costruzione
#   - dvd/*/materiale/  il contenuto di tutte le sezioni (le cartelle restano)
#   - materiale_archiviato/
#   - anagrafica/       i file dati reali (*.csv *.xls *.xlsm *.xlsx *.ods non
#                       tracciati); le fixture *_example.csv tracciate in git
#                       restano per costruzione
#
# Mai toccati i file tracciati da git (codice, template, dati/*.json di
# struttura) ne' scripts/star_jedi/ (font ri-scaricabile con make font).
# Le esclusioni dal perimetro vivono in scripts/reset_annata.eccezioni (file
# tracciato in git): un percorso relativo alla radice del repo per riga,
# commenti con #; una voce che non corrisponde a nessun file produce un
# warning anti-typo senza fermare il reset.
#
# Prima di cancellare mostra i conteggi reali per area e chiede conferma dal
# terminale (/dev/tty: funziona anche dentro make). Senza conferma non tocca
# nulla. Il backup dei dati resta responsabilita' dell'operatore, FUORI dal
# repo, DA FARE PRIMA del comando: la rimozione e' irreversibile.
#
# Uso:
#   scripts/reset_annata.sh             riepilogo + conferma + rimozione
#   FORCE=1 scripts/reset_annata.sh     procede senza chiedere nulla
#
# Exit code: 0 = rimozione completata, rifiutata o nessuna cosa da fare;
#            2 = errore (fuori repo, rimozioni fallite).
set -u

REPO="$(cd "$(dirname "$0")/.." && pwd)"
ECCEZIONI="$REPO/scripts/reset_annata.eccezioni"

muori() { echo "ERRORE: $*" >&2; exit 2; }

cd "$REPO" || muori "repo non raggiungibile: $REPO"
command -v git >/dev/null 2>&1 || muori "git non trovato nel PATH"
git rev-parse --is-inside-work-tree >/dev/null 2>&1 \
  || muori "$REPO non e' un repository git"

case "${FORCE:-}" in
  ""|0) FORCE="" ;;
  *) FORCE=1 ;;
esac

# ---------------------------------------------------------------------------
# Eccezioni: percorsi da non toccare anche se dentro il perimetro.
# ---------------------------------------------------------------------------

# voci normalizzate del file di configurazione
ECCEZIONI_ATTIVE=()

carica_eccezioni() {
  [ -f "$ECCEZIONI" ] || return 0
  local riga pulita
  while IFS= read -r riga || [ -n "$riga" ]; do
    riga="${riga%%#*}"                       # via i commenti, in testa e di coda
    pulita="$(printf '%s\n' "$riga" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    [ -n "$pulita" ] || continue
    case "$pulita" in
      /*)
        echo "WARNING: voce di eccezione assoluta scartata (servono percorsi relativi al repo): $pulita" >&2 ;;
      ./*)
        ECCEZIONI_ATTIVE+=("${pulita#./}") ;;
      *)
        ECCEZIONI_ATTIVE+=("$pulita") ;;
    esac
  done < "$ECCEZIONI"
}

# true se il candidato coincide con una voce di eccezione o cade sotto di essa
protetto() { # $1 percorso candidato
  local exc
  for exc in ${ECCEZIONI_ATTIVE[@]+"${ECCEZIONI_ATTIVE[@]}"}; do
    case "$1" in
      "$exc"|"$exc"/*) return 0 ;;
    esac
  done
  return 1
}

# warning anti-typo: una voce che non corrisponde a nessun file esistente
avvisa_voci_senza_match() {
  local exc
  for exc in ${ECCEZIONI_ATTIVE[@]+"${ECCEZIONI_ATTIVE[@]}"}; do
    [ -e "$exc" ] || echo "WARNING: voce di eccezione senza corrispondenza nel repo (typo?): $exc" >&2
  done
}

# ---------------------------------------------------------------------------
# Raccolta candidati, area per area. Nessuna cancellazione qui dentro.
# ---------------------------------------------------------------------------

# nel perimetro solo cio' che git non protegge: tracciato lui stesso o
# qualcosa sotto di lui (vale uguale per file e cartelle), e non coperto da
# una voce di eccezione
da_rimuovere() { # $1 percorso relativo al repo
  [ -e "$1" ] || [ -L "$1" ] || return 1     # sparito intanto: niente da fare
  if [ -n "$(git ls-files -- "$1")" ]; then return 1; fi
  ! protetto "$1"
}

AREE="materiale src anagrafica output"
declare -A N_FILE N_BYTE
for a in $AREE; do N_FILE[$a]=0; N_BYTE[$a]=0; done

CANDIDATE_AREE=()
CANDIDATE_PERCORSI=()
OUTPUT_INTERI=()          # golden/, materiale_archiviato/: via intere
RICREA_BUILD=0

aggiungi() { # $1 area  $2 percorso
  CANDIDATE_AREE+=("$1")
  CANDIDATE_PERCORSI+=("$2")
  local sz=0
  [ -f "$2" ] && sz=$(stat -c %s -- "$2" 2>/dev/null || echo 0)
  N_FILE[$1]=$(( ${N_FILE[$1]} + 1 ))
  N_BYTE[$1]=$(( ${N_BYTE[$1]} + sz ))
}

# somma delle dimensioni dei file sotto un albero (per gli output rimossi interi)
byte_file_albero() {
  find "$1" -type f -print0 2>/dev/null \
    | xargs -0 -r stat -c %s -- 2>/dev/null \
    | awk '{ s += $1 } END { printf "%.0f", s + 0 }'
}

raccogli_src() {
  local d f
  for d in dvd/*/src; do
    [ -d "$d" ] || continue
    while IFS= read -r -d '' f; do
      da_rimuovere "$f" && aggiungi src "$f"
    done < <(find "$d" -type f -print0 | sort -z)
  done
}

raccogli_materiale() {
  local d e
  for d in dvd/*/materiale; do
    [ -d "$d" ] || continue
    # entrate di primo livello: le cartelle non tracciate vanno rimosse intere
    # (git ls-files sulla cartella copre anche l'interno), cosi' il controllo
    # "tracciato?" resta uniforme su ogni candidato
    while IFS= read -r -d '' e; do
      da_rimuovere "$e" && aggiungi materiale "$e"
    done < <(find "$d" -mindepth 1 -maxdepth 1 -print0 | sort -z)
  done
}

ESTENSIONI_DATI="csv xls xlsm xlsx ods"

raccogli_anagrafica() {
  local f est
  # registro squadriglie generato dal CSV (dati/.gitignore)
  da_rimuovere dati/squadriglie.json && aggiungi anagrafica dati/squadriglie.json
  [ -d anagrafica ] || return 0
  while IFS= read -r -d '' f; do
    est=$(basename "$f"); est="${est##*.}"; est="${est,,}"
    case " $ESTENSIONI_DATI " in
      *" $est "*)
        da_rimuovere "$f" && aggiungi anagrafica "$f" ;;
    esac
  done < <(find anagrafica -maxdepth 1 -type f -print0 | sort -z)
}

raccogli_output() {
  local e
  if [ -d build ]; then
    RICREA_BUILD=1
    N_FILE[output]=$(( ${N_FILE[output]} + $(find build -type f | wc -l) ))
    N_BYTE[output]=$(( ${N_BYTE[output]} + $(byte_file_albero build) ))
  fi
  for e in golden materiale_archiviato; do
    [ -e "$e" ] || continue
    OUTPUT_INTERI+=("$e")
    if [ -d "$e" ]; then
      N_FILE[output]=$(( ${N_FILE[output]} + $(find "$e" -type f | wc -l) ))
      N_BYTE[output]=$(( ${N_BYTE[output]} + $(byte_file_albero "$e") ))
    else
      N_FILE[output]=$(( ${N_FILE[output]} + 1 ))
      N_BYTE[output]=$(( ${N_BYTE[output]} + $(stat -c %s -- "$e" 2>/dev/null || echo 0) ))
    fi
  done
}

umanizza() { # $1 byte -> forma leggibile
  awk -v b="$1" 'BEGIN {
    if (b >= 1073741824)      printf "%.1f GiB", b/1073741824;
    else if (b >= 1048576)    printf "%.1f MiB", b/1048576;
    else if (b >= 1024)       printf "%.1f KiB", b/1024;
    else                      printf "%d B", b;
  }'
}

DESC_materiale="dvd/*/materiale/"
DESC_src="dvd/*/src/ (solo non tracciati)"
DESC_anagrafica="anagrafica/ + dati/squadriglie.json"
DESC_output="build/, golden/, materiale_archiviato/"

riepilogo() {
  local a desc totale_file=0 totale_byte=0
  echo "Reset d'annata: percorsi trovati nel perimetro della rimozione:"
  for a in $AREE; do
    desc="DESC_$a"
    totale_file=$(( totale_file + ${N_FILE[$a]} ))
    totale_byte=$(( totale_byte + ${N_BYTE[$a]} ))
    printf '  %-11s %5s file %10s   %s\n' "$a" "${N_FILE[$a]}" "$(umanizza "${N_BYTE[$a]}")" "${!desc}"
  done
  printf '  %-11s %5s file %10s\n' "TOTALE" "$totale_file" "$(umanizza "$totale_byte")"
  if [ "${#ECCEZIONI_ATTIVE[@]}" -gt 0 ]; then
    echo "Eccezioni applicate (scripts/reset_annata.eccezioni): ${ECCEZIONI_ATTIVE[*]}"
  fi
}

carica_eccezioni
avvisa_voci_senza_match
raccogli_src
raccogli_materiale
raccogli_anagrafica
raccogli_output
riepilogo

# ---------------------------------------------------------------------------
# Conferma e rimozione
# ---------------------------------------------------------------------------

totale_candidati() {
  local a t=0
  for a in $AREE; do t=$(( t + ${N_FILE[$a]} )); done
  echo "$t"
}

# true solo se l'operatore ha confermato (o c'e' FORCE=1): la lettura avviene
# da /dev/tty perche' dentro make lo stdin non e' il terminale
conferma_operatore() {
  [ "$FORCE" = 1 ] && return 0
  local risp
  if ! exec 3</dev/tty 2>/dev/null; then
    echo ""
    echo "Conferma impossibile (nessun terminale collegato): nessuna rimozione."
    echo "Rilancia dal terminale, oppure forza l'esecuzione con FORCE=1."
    return 1
  fi
  printf 'Backup dei dati fatto FUORI dal repo? La rimozione e%s irreversibile.\nConfermi la rimozione? [si/no] ' "'"
  if ! IFS= read -r risp <&3; then
    exec 3<&-
    echo ""
    echo "Nessuna risposta: nessuna rimozione."
    return 1
  fi
  exec 3<&-
  case "$risp" in
    s|S|si|Si|SI|sì|Sì|y|Y|yes) return 0 ;;
    *) echo "Annullato: nessun file rimosso." ; return 1 ;;
  esac
}

if [ "$(totale_candidati)" -eq 0 ]; then
  echo ""
  echo "Nulla da rimuovere: il repo e' gia' pulito."
  exit 0
fi

if ! conferma_operatore; then
  exit 0
fi

# rimozione con riepilogo per area; un fallimento non ferma gli altri ma
# condanna l'exit code
declare -A RIMOSSI
FALLITE=()

for i in "${!CANDIDATE_PERCORSI[@]}"; do
  p="${CANDIDATE_PERCORSI[$i]}"
  a="${CANDIDATE_AREE[$i]}"
  if rm -rf -- "$p"; then
    RIMOSSI[$a]=$(( ${RIMOSSI[$a]:-0} + 1 ))
  else
    FALLITE+=("$p")
  fi
done

for p in ${OUTPUT_INTERI[@]+"${OUTPUT_INTERI[@]}"}; do
  if rm -rf -- "$p"; then
    RIMOSSI[output]=$(( ${RIMOSSI[output]:-0} + 1 ))
  else
    FALLITE+=("$p")
  fi
done

if [ "$RICREA_BUILD" = 1 ]; then
  rm -rf build
  if ! mkdir build; then
    FALLITE+=("build/")
  fi
fi

echo ""
if [ "${#FALLITE[@]}" -eq 0 ]; then
  echo "Rimozione completata:"
  for a in $AREE; do
    [ "${RIMOSSI[$a]:-0}" -gt 0 ] || continue
    desc="DESC_$a"
    printf '  %-11s %5s percorsi rimossi   (%s)\n' "$a" "${RIMOSSI[$a]}" "${!desc}"
  done
else
  echo "RIMOZIONE INCOMPLETA: ${#FALLITE[@]} percorsi non eliminabili:" >&2
  for p in "${FALLITE[@]}"; do
    echo "  $p" >&2
  done
  echo "Controlla permessi o file occupati sui percorsi sopra e rilancia." >&2
  exit 2
fi

[ "$RICREA_BUILD" = 1 ] && echo "build/ ricreata vuota (come make clean)."
echo "Repo riportato allo stato di fresh clone."
exit 0
