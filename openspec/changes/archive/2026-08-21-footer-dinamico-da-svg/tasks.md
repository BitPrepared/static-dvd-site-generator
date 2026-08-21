# Tasks: footer dinamico da-svg

Ogni task segue il flusso TDD indicato in `openspec/config.yaml`: prima la
verifica che fallisce, poi l'implementazione fino al verde.

## 1. Preparazione repo

- [x] 1.1 Aggiungere `scripts/star_jedi/` al `.gitignore` e verificare con
  `git status` che la cartella non risulti tracciabile; spostare i TTF
  esistenti da `assets/img/star_jedi/` alla nuova posizione (solo i .ttf, i
  doc/sample restano fuori) e rimuovere la vecchia cartella da assets;
  ripulire i PNG temporanei di confronto dalla root
  (`confronto_footer_starjout.png`, `diff_footer.png`,
  `footer_starjout_test.png`)

## 2. Dipendenza renderer

- [x] 2.1 Aggiungere `@resvg/resvg-js` (versione pinnata) a
  `static-dvd-site-generator/package.json`, rilanciare `make init` e
  verificare nel container un render minimale (SVG 10×10 → PNG) come smoke
  test
  - Nota: dipendenza installata (2.6.2 esatta, lockfile + binario
    linux-x64-gnu) e smoke test verificato con node dell'host (sandbox senza
    docker); `make init` va rilanciato sulla macchina con docker/podman per
    cuocere la dipendenza nell'immagine

## 3. Template e script di generazione

- [x] 3.1 Creare `scripts/footer_template.svg` (760×49, testo `CostigioLa
  {{DATE}}`, font 42px, letter-spacing -1px, fill bianco, baseline x=180
  y=38). Verifica prima: il check di alimentazione dello script (3.3) deve
  fallire con template assente
- [x] 3.2 Implementare `scripts/genera_footer.js`: parsing e validazione di
  `DATE` (regex `gg-gg/mm/aaaa`, giorni 01-31, mese 01-12, fine ≥ inizio).
  Verifica: input invalidi e assenti → exit != 0 con messaggio in italiano,
  nessun file scritto
- [x] 3.3 Completare lo script: sostituzione `{{DATE}}`, render resvg con
  `fontFiles` su `scripts/star_jedi/Starjout.ttf` (niente font di sistema),
  self-check bbox (ink left 180±1, top 8±1, bottom 37-39) e scrittura
  atomica di `assets/img/footer.png`. Verifica: PNG 760×49 trasparente
  generata; errori font/resvg assenti → messaggio azionabile (`make font` /
  `make init`)
- [x] 3.4 Verifica determinismo: due generazioni con le stesse date
  producono PNG byte-identiche (`cmp`)

## 4. Fedeltà all'originale 2023

- [x] 4.1 Rigenerare con `DATE=22-26/08/2023`, confrontare bbox e immagine
  di sovrapposizione con l'originale (tolleranza ±1px per lato, larghezza
  attesa 572px) e salvare l'esito del confronto nella change

## 5. Makefile

- [x] 5.1 Target `font`: container-run con wget (User-Agent browser) +
  unzip dei soli `.ttf` da dl.dafont.com in `scripts/star_jedi/`.
  Verifica: cartella popolata da zero; se dafont blocca, provare referer e
  documentare il fallback `ZIP=` locale
  - Nota: pattern di estrazione verificato con zip finto (solo .ttf, -j);
    fallback `make font ZIP=...` implementato e dry-run verificato; il
    download reale da dl.dafont.com va provato su macchina con docker
    (sandbox: niente docker e allowlist di rete che esclude dafont)
- [x] 5.2 Collegare il target `font` a `make init` in modalità fail-soft
  (warning + init completa). Verifica: simulando il fallimento del download,
  init termina comunque con successo
- [x] 5.3 Target `footer` (`make footer DATE=...`): container-run node con
  montaggi `scripts/` e `assets/` sul pattern di `make anagrafica`.
  Verifica: end-to-end su una copia temporanea della PNG
  - Nota: target, uso e errore senza DATE verificati (make -n + exit != 0);
    equivalente end-to-end verificato in locale con NODE_PATH (stesso script
    e argomenti); la run nel container va confermata con `make footer DATE=...`
    sulla macchina con docker

## 6. Chiusura

- [x] 6.1 Quando saranno note le date reali del campo 2026: aggiornare
  `dati/campo.json`, controllare il sito con `make build` + `make open`,
  committare codice e dati (commit in italiano, niente font nel commit)
  - Nota: date 21-25/08/2026 inserite, footer 2026 generato e verificato
    localmente (bbox 180,8-748,37, risorsa aggiornata); tutto pronto in
    stage, il commit lo fa l'utente (niente font, niente build nel commit).
    Il controllo visivo completo con `make build` + `make open` resta da
    fare sulla macchina con docker

## 7. Revisione: footer generato direttamente dalla build (decisione utente)

Sostituisce l'approccio "PNG committata in assets": niente PNG del footer in
assets, la build la genera in `build/img/footer.png` con fallback.

- [x] 7.1 Script `genera_footer.js`: output di default `build/img/footer.png`,
  modalità `--config dati/campo.json` (legge il campo `date`; senza argomenti
  usa il config standard), refresh della risorsa `scripts/footer_fallback.png`
  solo per output di default o `--fallback` esplicito. Verifica: harness
  aggiornata (config valida/invalida/non-json, fallback aggiornato/non
  inquinato) — 21 PASS
- [x] 7.2 Dato di struttura `dati/campo.json` con `{"date": "22-26/08/2023"}`
  (seme, finché le date 2026 non sono note)
- [x] 7.3 Makefile: `make build` esegue lo step footer dopo la pipeline
  (fail-soft: al fallimento copia `scripts/footer_fallback.png` in
  `build/img/footer.png` con warning); `make footer [DATE=...]` diventa la
  variante manuale. Verifica: `make -n build`/`make -n footer` e simulazione
  del fallimento (warning + fallback + exit 0)
- [x] 7.4 Rimozione di `assets/img/footer.png` e `assets/img/footer_orig.png`;
  seed di `scripts/footer_fallback.png` dall'originale 2023. Verifica:
  `make -n build` non referenzia più la PNG negli asset; harness verde
- [x] 7.5 Aggiornare la suite `test_genera_footer.sh` ai nuovi default e
  rieseguire tutta verde
- [x] 7.6 Accorpamento su richiesta utente: `make build` = una sola
  chiamata container (`bash -c 'npm run build && { footer || fallback }'`,
  mount di `scripts/` aggiunto); nessuna seconda run docker. Verifica:
  `make -n build` mostra una sola run, sintassi bash ok, simulazione
  fail-soft (fallback + exit 0) e fallimento pipeline (exit != 0)
- [x] 7.7 Riordino su richiesta utente: il footer si genera PRIMA della
  pipeline nella stessa run container, così "[Build finished!]" è di nuovo
  l'ultimo messaggio. Verifica: `make -n build` (una run, footer in testa),
  simulazioni ordine/fail-soft/pipeline-KO
- [x] 7.8 Log dello script nello stile della pipeline (lib/logger.js):
  "[ INFO ] --- Footer @ generazione ---" + riga dettaglio, su stderr, chalk
  opzionale (senza colori se assente o senza TTY). Harness aggiornata al
  nuovo stream (22 PASS)

## 8. Revisione: date del campo separate in inizio/fine (decisione utente)

Il dato di struttura passa da `{"date": "21-25/08/2026"}` a due campi
separati `{"inizio": "gg/mm/aaaa", "fine": "gg/mm/aaaa"}`; lo script li
ricompone nel formato compatto del template (che resta `CostigioLa
{{DATE}}` con `gg-gg/mm/aaaa`). I range a cavallo di mesi/anni diversi
vengono rifiutati: la ricetta tipografica ha canvas a larghezza fissa e un
solo mese/anno è rappresentabile nel footer.

- [x] 8.1 `dati/campo.json`: campi `inizio`/`fine` separati (stesse date
  del campo 2026, 21-25/08/2026); nota interna aggiornata al nuovo formato
- [x] 8.2 Script `genera_footer.js`: lettura config dai nuovi campi,
  validazione per singola data (`gg/mm/aaaa`, giorni 01-31, mese 01-12) e
  ricomposizione nel formato compatto; errore dedicato se le due date
  cadono in mesi/anni diversi o la fine precede l'inizio. L'argomento
  posizionale resta nel formato compatto (`make footer DATE=...`).
  Verifica: generazione dal config reale → `date 21-25/08/2026`, PNG
  byte-identica alla riserva committata
- [x] 8.3 Harness `test_genera_footer.sh`: casi config aggiornati ai nuovi
  campi e nuove coperture (inizio/fine invalide, range a cavallo di mesi,
  fine prima di inizio nel config) — 25 PASS
