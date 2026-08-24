#!/usr/bin/env bash
# Verifica per scripts/reset_annata.sh (reset d'annata, Readme.md §6).
# Costruisce un albero finto con tutti i tipi di dato (tracciati, generati,
# foto, anagrafica reale e example, output) ed esercita conferma, rifiuto,
# FORCE=1, idempotenza, eccezioni e smoke post-reset con gli example.
# Uso: scripts/test_reset_annata.sh   (oppure bash scripts/test_reset_annata.sh)
set -u

DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$DIR/reset_annata.sh"
ECCEZIONI="$DIR/reset_annata.eccezioni"
REALE="$DIR/.."
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
REPO="$TMP/repo"
# guardia anti-disastro: la suite lavora SOLO sull'albero finto
case "$REPO" in "$REALE"|"$REALE"/*)
  echo "FALLITO: il repo finto coincide col repository vero ($REPO)"; exit 1 ;;
esac

PASS=0; FAIL=0
ok()   { echo "PASS: $1"; PASS=$((PASS+1)); }
no()   { echo "FAIL: $1"; FAIL=$((FAIL+1)); }

# lancia lo script nel repo finto leggendo la risposta da un pty: dentro make
# (e in questa suite) stdin non e' il terminale, come nella vita reale.
# SEMPRE la copia dentro il repo finto, con percorso RELATIVO: lo script
# risolve il repo da $0, un percorso assoluto verso questo file lo punterebbe
# al repository vero con esiti distruttivi.
lancia_con_risposta() { # $1 risposta
  (cd "$REPO" && printf '%s\n' "$1" | script -qec "bash scripts/reset_annata.sh" /dev/null)
}
lancia_forzato() {
  (cd "$REPO" && FORCE=1 bash scripts/reset_annata.sh </dev/null 2>&1)
}

# albero finto: prima i tracciati (un solo commit), poi il dato d'annata non
# tracciato. Nessuna regola di gitignore: il reset guarda l'indice, non le
# regole, quindi l'albero resta minimo ma fedele ai casi reali.
# ogni scenario parte da zero: i residui del precedente finirebbero tracciati
crea_albero() { # $1 = radice
  local R="$1"
  rm -rf "$R"
  mkdir -p "$R"/scripts \
           "$R"/dvd/varie/src "$R"/dvd/documenti/src "$R"/dvd/diariofotografico/src \
           "$R"/dvd/diariofotografico/materiale/foto/giorno1 \
           "$R"/dvd/home/src "$R"/dvd/home/materiale/lettera \
           "$R"/dati "$R"/anagrafica "$R"/golden \
           "$R"/materiale_archiviato/reparto_pre-codifica \
           "$R"/build/img "$R"/scripts/star_jedi
  # --- file tracciati (quelli che il reset non deve MAI toccare)
  echo "tpl varie"    > "$R/dvd/varie/src/index.hbs"
  echo "utility"      > "$R/dvd/varie/src/utility_scout.hbs"
  echo "tpl documenti"> "$R/dvd/documenti/src/index.hbs"
  # fixture example e generatore VERI del repo: servono allo smoke post-reset
  cp "$REALE/anagrafica/elenco_ragazzi_example.csv" "$R/anagrafica/"
  cp "$REALE/anagrafica/registro_segnaletiche_example.csv" "$R/anagrafica/"
  cp "$REALE/anagrafica/genera_anagrafica.js" "$R/anagrafica/"
  echo '{"anno": 2026}' > "$R/dati/campo.json"
  cp "$SCRIPT" "$R/scripts/"
  cp "$ECCEZIONI" "$R/scripts/"
  (cd "$R" && git init -q . && git add -A \
     && git -c user.email=test@locale -c user.name=test commit -qm init)
  # --- dato d'annata non tracciato (tutto nel perimetro tranne le eccezioni)
  echo "staff pagina" > "$R/dvd/documenti/src/staff.hbs"        # eccezione attiva
  echo "pagina generata" > "$R/dvd/diariofotografico/src/giorno1.hbs"
  echo "home generata"   > "$R/dvd/home/src/index.hbs"
  echo "foto giorno uno" > "$R/dvd/diariofotografico/materiale/foto/giorno1/a.jpg"
  echo "lettera reparto" > "$R/dvd/home/materiale/lettera/b.png" # eccezione attiva
  echo "sample passato"  > "$R/materiale_archiviato/reparto_pre-codifica/c.jpg"
  echo '{"manifest": true}' > "$R/golden/manifest.json"
  echo "<html>sito</html>"  > "$R/build/index.html"
  echo "footer"             > "$R/build/img/footer.png"
  echo "font scaricabile"   > "$R/scripts/star_jedi/StarJedi.ttf"   # fuori perimetro
  echo "ragazzi veri"       > "$R/anagrafica/elenco_ragazzi.csv"
  echo "vecchio elenco"     > "$R/anagrafica/elenco_ragazzi.old.csv"
  echo "codici veri"        > "$R/anagrafica/registro_segnaletiche.csv"
  echo '{"squadriglie": []}' > "$R/dati/squadriglie.json"
}

# sopravvivenza dei tracciati, delle fixture example e di star_jedi:
# condivisa fra gli scenari di conferma e FORCE
controlla_sopravvissuti() { # $1 etichetta scenario
  local tag="$1" f
  for f in dvd/varie/src/index.hbs dvd/varie/src/utility_scout.hbs \
           dvd/documenti/src/index.hbs dvd/documenti/src/staff.hbs \
           dvd/home/materiale/lettera/b.png \
           anagrafica/elenco_ragazzi_example.csv anagrafica/registro_segnaletiche_example.csv \
           anagrafica/genera_anagrafica.js dati/campo.json scripts/star_jedi/StarJedi.ttf; do
    [ -e "$REPO/$f" ] && ok "$tag: sopravvive $f" || no "$tag: sopravvive $f"
  done
}

echo "== prerequisiti =="
[ -x "$SCRIPT" ] && ok "script esiste ed e' eseguibile" || no "script esiste ed e' eseguibile"
bash -n "$SCRIPT" && ok "sintassi bash dello script" || no "sintassi bash dello script"
[ -f "$ECCEZIONI" ] && ok "file delle eccezioni presente" || no "file delle eccezioni presente"
git -C "$REALE" check-ignore -q scripts/reset_annata.eccezioni
[ $? -eq 1 ] && ok "le eccezioni sono tracciabili in git (non ignorate)" || no "le eccezioni sono tracciabili in git"

if ! command -v script >/dev/null 2>&1; then
  echo "SKIP: scenari interattivi (comando script non disponibile)"
fi

if command -v script >/dev/null 2>&1; then
  echo "== rifiuto: nessuna rimozione, exit 0 =="
  crea_albero "$REPO"
  out=$(lancia_con_risposta "no" bash "$SCRIPT"); rc=$?
  grep -q "Annullato" <<<"$out" && [ $rc -eq 0 ] \
    && ok "rifiuto dichiarato con exit 0" || no "rifiuto dichiarato con exit 0 (rc=$rc)"
  for f in build/index.html golden/manifest.json anagrafica/elenco_ragazzi.csv \
           dati/squadriglie.json dvd/diariofotografico/materiale/foto/giorno1/a.jpg; do
    [ -e "$REPO/$f" ] && ok "rifiuto: intatto $f" || no "rifiuto: intatto $f"
  done

  echo "== conferma: perimetro rimosso, tracciati ed eccezioni salvati =="
  out=$(lancia_con_risposta "si" bash "$SCRIPT"); rc=$?
  [ $rc -eq 0 ] && grep -q "Rimozione completata" <<<"$out" \
    && ok "rimozione completata con exit 0" || no "rimozione completata con exit 0 (rc=$rc: $out)"
  controlla_sopravvissuti "conferma"
  grep -q "Eccezioni applicate.*staff.hbs" <<<"$out" \
    && ok "riepilogo dichiara l'eccezione staff.hbs" || no "riepilogo dichiara l'eccezione staff.hbs ($out)"
  for f in dvd/diariofotografico/src/giorno1.hbs dvd/home/src/index.hbs \
           dvd/diariofotografico/materiale/foto/giorno1/a.jpg \
           golden materiale_archiviato anagrafica/elenco_ragazzi.csv \
           anagrafica/elenco_ragazzi.old.csv anagrafica/registro_segnaletiche.csv \
           dati/squadriglie.json build/index.html build/img/footer.png; do
    [ ! -e "$REPO/$f" ] && ok "rimosso $f" || no "rimosso $f"
  done
  [ -d "$REPO/build" ] && [ -z "$(ls -A "$REPO/build")" ] \
    && ok "build/ ricreata vuota come make clean" || no "build/ ricreata vuota come make clean"
  [ -d "$REPO/dvd/diariofotografico/materiale" ] && [ -z "$(ls -A "$REPO/dvd/diariofotografico/materiale")" ] \
    && ok "cartelle materiale restano, vuote" || no "cartelle materiale restano, vuote"
fi

echo "== FORCE=1: procede senza alcuna richiesta =="
crea_albero "$REPO"
out=$(lancia_forzato); rc=$?
[ $rc -eq 0 ] && ! grep -qE "Confermi|terminale" <<<"$out" && [ ! -e "$REPO/golden" ] \
  && ok "FORCE=1 rimuove senza domande" || no "FORCE=1 rimuove senza domande (rc=$rc: $out)"

echo "== idempotenza: secondo lancio non ha nulla da fare =="
out=$(lancia_forzato); rc=$?
grep -q "Nulla da rimuovere" <<<"$out" && [ $rc -eq 0 ] \
  && ok "repo gia' pulito: exit 0 dichiarandolo" || no "repo gia' pulito (rc=$rc: $out)"

echo "== fresh clone: nessun errore su albero senza dati =="
mkdir -p "$TMP/repo2/scripts"
cp "$SCRIPT" "$ECCEZIONI" "$TMP/repo2/scripts/"
(cd "$TMP/repo2" && git init -q . && git add scripts \
   && git -c user.email=test@locale -c user.name=test commit -qm init)
out=$(cd "$TMP/repo2" && FORCE=1 bash scripts/reset_annata.sh </dev/null 2>&1); rc=$?
[ $rc -eq 0 ] && grep -q "Nulla da rimuovere" <<<"$out" \
  && ok "fresh clone: exit 0 senza rompere nulla" || no "fresh clone: exit 0 (rc=$rc: $out)"

echo "== eccezione senza corrispondenza: warning anti-typo e prosegue =="
crea_albero "$REPO"
printf '\n# una voce sbagliata\npercorso/inesistente.txt\n' >> "$REPO/scripts/reset_annata.eccezioni"
out=$(lancia_forzato); rc=$?
grep -q "WARNING.*percorso/inesistente.txt" <<<"$out" && [ $rc -eq 0 ] \
  && ok "voce senza match: warning nominante, reset prosegue" \
  || no "voce senza match: warning nominante (rc=$rc: $out)"
[ ! -e "$REPO/golden" ] && ok "il reset prosegue malgrado il warning" || no "il reset prosegue"

echo "== smoke post-reset: gli example bastano per rigenerare l'anagrafica =="
if [ -d "$REALE/static-dvd-site-generator/node_modules" ] && command -v node >/dev/null 2>&1; then
  cp "$REPO/anagrafica/elenco_ragazzi_example.csv" "$REPO/anagrafica/elenco_ragazzi.csv"
  cp "$REPO/anagrafica/registro_segnaletiche_example.csv" "$REPO/anagrafica/registro_segnaletiche.csv"
  out=$(cd "$REPO" && NODE_PATH="$REALE/static-dvd-site-generator/node_modules" \
        node anagrafica/genera_anagrafica.js --output dati/squadriglie.json 2>&1); rc=$?
  [ $rc -eq 0 ] && [ -s "$REPO/dati/squadriglie.json" ] \
    && ok "generazione riuscita senza alcun dato reale" \
    || no "generazione riuscita senza alcun dato reale (rc=$rc: $out)"
else
  echo "SKIP: smoke anagrafica (node o node_modules del generatore non disponibili)"
fi

echo
echo "Risultato: $PASS pass, $FAIL fail"
[ "$FAIL" -eq 0 ]
