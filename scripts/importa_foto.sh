#!/usr/bin/env bash
# Importa le foto del diario fotografico dalla share dello staff (Readme.md §3).
#
# Due passi, nell'ordine del runbook:
#   1. rotazione/rinomina sulla share con lo script esterno
#      ~/scripts/ruota_rinomina_immagini.sh (prerequisito fuori repo)
#   2. copia fedele 1:1 in dvd/diariofotografico/materiale/foto/
#      mantenendo la struttura giorno/categoria
#
# Incrementale e non distruttivo: vengono copiate solo le foto assenti in
# destinazione o piu' recenti (confronto per percorso relativo + mtime),
# niente viene mai cancellato. Solo file immagine (per estensione, vedi
# FOTO_ESTENSIONI): file nascosti, spazzatura dei sistemi operativi,
# readme e simili restano fuori, e le cartelle della share senza immagini
# non vengono nemmeno create in destinazione.
#
# Uso:
#   scripts/importa_foto.sh [DIR_SORGENTE]            una passata
#   scripts/importa_foto.sh --watch [DIR_SORGENTE]    import continuo (polling)
#   scripts/importa_foto.sh --salta-rotazione ...     solo la copia
#   scripts/importa_foto.sh --interval SECONDI ...    periodo del polling
#
# Variabili d'ambiente:
#   FOTO_SRC         sorgente        (default ~/share_disks/staff/foto)
#   FOTO_DST         destinazione    (default <repo>/dvd/diariofotografico/materiale/foto)
#   FOTO_ESTENSIONI  elenco estensioni immagine, separato da spazi
#                    (default "jpg jpeg png gif bmp tif tiff webp heic heif")
#   RUOTA_SCRIPT     rotazione       (default: primo eseguibile fra
#                    ruota_rinomina_immagini.sh e autoRuotaImmagini.sh
#                    in ~/scripts, ~/Scripts, ~/script e ~/Script)
#   WATCH_INTERVAL  secondi polling (default 300)
#
# Exit code: 0 = importato o nessuna novita'; 2 = errore.
set -u

WATCH=0
SALTA_ROTAZIONE=0
INTERVAL="${WATCH_INTERVAL:-300}"
SRC=""

usage() { awk 'NR > 1 && /^#/ { sub(/^# ?/, ""); print } NR > 1 && !/^#/ { exit }' "$0"; }

muori() { echo "ERRORE: $*" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --watch) WATCH=1 ;;
    --salta-rotazione) SALTA_ROTAZIONE=1 ;;
    --interval) [ $# -ge 2 ] || muori "--interval richiede un valore"; INTERVAL="$2"; shift ;;
    --interval=*) INTERVAL="${1#*=}" ;;
    -h|--help) usage; exit 0 ;;
    -*) muori "opzione sconosciuta: $1" ;;
    *)
      [ -z "$SRC" ] || muori "parametro inatteso: $1"
      SRC="$1"
      ;;
  esac
  shift
done

[[ "$INTERVAL" =~ ^[0-9]+([.][0-9]+)?$ ]] || muori "--interval vuole un numero di secondi: '$INTERVAL'"

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${SRC:-${FOTO_SRC:-$HOME/share_disks/staff/foto}}"
DST="${FOTO_DST:-$REPO/dvd/diariofotografico/materiale/foto}"
ESTENSIONI="${FOTO_ESTENSIONI:-jpg jpeg png gif bmp tif tiff webp heic heif}"

[ -d "$SRC" ] || muori "sorgente non trovata: $SRC (passala come argomento o con FOTO_SRC=)"
mkdir -p "$DST" || muori "destinazione non creabile: $DST"

# rotazione/rinomina: prerequisito esterno al repo con nomi diversi fra le
# macchine (server: ruota_rinomina_immagini.sh in ~/scripts, locale:
# autoRuotaImmagini.sh in ~/Scripts). Vince l'override esplicito
# RUOTA_SCRIPT, altrimenti il primo eseguibile.
trova_ruota() {
  if [ -n "${RUOTA_SCRIPT:-}" ]; then
    [ -x "$RUOTA_SCRIPT" ] || return 2
    printf '%s\n' "$RUOTA_SCRIPT"; return 0
  fi
  local c
  for c in "$HOME"/[Ss]cripts/ruota_rinomina_immagini.sh \
           "$HOME"/[Ss]cripts/autoRuotaImmagini.sh \
           "$HOME"/[Ss]cript/ruota_rinomina_immagini.sh \
           "$HOME"/[Ss]cript/autoRuotaImmagini.sh; do
    [ -x "$c" ] && { printf '%s\n' "$c"; return 0; }
  done
  return 1
}

# con --salta-rotazione la scelta dello script e' irrilevante: niente controlli
RUOTA=""
if [ "$SALTA_ROTAZIONE" -eq 0 ]; then
  rc_ruota=0
  RUOTA="$(trova_ruota)" || rc_ruota=$?
  case $rc_ruota in
    2) muori "RUOTA_SCRIPT e' impostato ma non trovato o non eseguibile: $RUOTA_SCRIPT" ;;
    1) muori "script di rotazione/rinomina non trovato (cercati ruota_rinomina_immagini.sh e autoRuotaImmagini.sh in ~/[Ss]cripts e ~/[Ss]cript, oppure \$RUOTA_SCRIPT)
  (si forza un percorso con RUOTA_SCRIPT=..., si salta con --salta-rotazione)" ;;
  esac
fi

adesso() { date '+%H:%M:%S'; }

# percorsi relativi (delimitati da NUL) delle foto da importare: assenti in dst
# oppure piu' recenti della copia. Solo immagini (ESTENSIONI, case-insensitive):
# il resto lo filtra l'estensione, quindi le cartelle senza immagini non
# compaiono mai in destinazione.
lista_pending() {
  (cd "$SRC" && find . -type f ! -name '.*' -print0) |
  while IFS= read -r -d '' p; do
    rel="${p#./}"
    est="${rel##*.}"; est="${est,,}"
    immagine=0
    for e in $ESTENSIONI; do
      [ "$est" = "$e" ] && { immagine=1; break; }
    done
    [ "$immagine" -eq 1 ] || continue
    d="$DST/$rel"
    if [ ! -f "$d" ] || [ "$SRC/$rel" -nt "$d" ]; then
      printf '%s\0' "$rel"
    fi
  done
}

# 0 = ok (importato, o niente da fare), 2 = errore
passata() {
  local -a pend=()
  mapfile -d '' pend < <(lista_pending)
  if [ "${#pend[@]}" -eq 0 ]; then
    echo "[$(adesso)] nessuna foto nuova o modificata in $SRC"
    return 0
  fi
  echo "[$(adesso)] ${#pend[@]} foto nuove/modificate in $SRC"

  if [ "$SALTA_ROTAZIONE" -eq 0 ]; then
    echo "[$(adesso)] rotazione/rinomina: $RUOTA"
    # return invece di exit: in watch la passata successiva puo' riprovarci
    "$RUOTA" "$SRC" || { echo "ERRORE: rotazione/rinomina fallita: nessuna copia effettuata" >&2; return 2; }
    # la rinomina puo' cambiare i percorsi: ricalcolo l'elenco
    pend=()
    mapfile -d '' pend < <(lista_pending)
    if [ "${#pend[@]}" -eq 0 ]; then
      echo "[$(adesso)] dopo la rotazione non resta nulla da copiare"
      return 0
    fi
  fi

  local rel d ok=0 ko=0
  for rel in "${pend[@]}"; do
    d="$DST/$rel"
    mkdir -p "$(dirname "$d")" || { ko=$((ko+1)); continue; }
    if cp -a -- "$SRC/$rel" "$d"; then
      ok=$((ok+1))
    else
      echo "  copia fallita: $rel" >&2
      ko=$((ko+1))
    fi
  done
  echo "[$(adesso)] copiate $ok foto in $DST${ko:+, $ko fallite}"
  [ "$ko" -eq 0 ] || return 2
}

if [ "$WATCH" -eq 1 ]; then
  echo "[$(adesso)] watch su $SRC -> $DST (controllo ogni ${INTERVAL}s, Ctrl-C per fermare)"
  while :; do
    passata || true
    sleep "$INTERVAL"
  done
else
  passata || exit $?
fi
