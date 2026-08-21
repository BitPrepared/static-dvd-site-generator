# Design: footer dinamico da SVG

## Context

Stato attuale: `assets/img/footer.png` (760×49, RGBA trasparente) è un raster
fatto a mano in GIMP con testo bianco "CostigioLa 22-26/08/2023"; gli 11
template `.hbs` lo referenziano come `<img>` statica e `metalsmith-assets`
copia l'intera cartella `assets/` dentro il build. La build gira solo nel
container (`node:18.2.0-bullseye`, immagine con npm install già eseguito in
fase di `make init`); sul container sono già presenti `wget` e `unzip`.
Il campo 2026 è imminente: la pipeline non va toccata (vincolo
"rischio zero a campo", vedi `openspec/config.yaml`).

La ricetta è stata identificata sperimentalmente (confronto IoU sull'alpha
binarizzato, validato con render pilota in /tmp durante l'esplorazione):

| Parametro | Valore | Note |
|---|---|---|
| Font | `scripts/star_jedi/Starjout.ttf` (Star Jedi Outline) | scaricato, non committato |
| Dimensione | 42px | |
| Fill | `#ffffff` | |
| `letter-spacing` | `-1px` | |
| Canvas | 760×49, trasparente | invariato |
| Baseline testo | `x=180, y=38` | l'inchiostro parte a (180, 8) |
| Testo | `CostigioLa ` + `gg-gg/mm/aaaa` | casing misto obbligatorio |
| Fedeltà pilota | IoU 0.767 vs originale 2023 | differenze solo su AA dei bordi |

## Goals / Non-Goals

**Goals:**

- Footer generato direttamente da `make build` in `build/img/footer.png`, da
  template SVG + date in `dati/campo.json`.
- Ricetta tipografica interamente nel repo (SVG), niente conoscenza implicita.
- Nessuna PNG del footer in `assets/` (assets = solo asset statici del sito).
- Pipeline Metalsmith e template `.hbs` intoccati (lo step è nel Makefile).
- Sito sempre provvisto di footer, anche a generatore rotto (fallback).
- Font fuori da git, scaricato in fase di `make init` con retry dedicato.

**Non-Goals:**

- Riprodurre byte-per-byte il raster GIMP 2023: la nuova baseline è il render
  resvg (differenze solo sull'anti-aliasing, ≤1px per lato).
- Modificare il markup/uso del footer nel sito (`width=760 height=46` ecc.).
- Hook dentro la pipeline Node/Metalsmith (lo step resta nel Makefile: meno
  superficie di rischio, il container della pipeline non cambia).

## Decisions

### D1: renderer `@resvg/resvg-js` dentro l'immagine del generatore

Aggiunta a `static-dvd-site-generator/package.json` (installato dal `npm
install` del Dockerfile). Alternativa valutata: `sharp`/librsvg (dipendenza
più pesante, caricamento font via fontconfig di sistema, meno deterministico)
e GraphicsMagick (supporto SVG debole, richiede il binario `gm` che non è
provato nell'immagine). resvg-js carica il font **esplicitamente da file**
(`fontFiles`), niente fontconfig: comportamento identico su qualsiasi
macchina. Binario precompilato napi, compatibile node 18 bullseye.

### D2: template e font in `scripts/`, nessuna PNG del footer in `assets/`

`metalsmith-assets` copia tutto `assets/` nel build: SVG e TTF lì finirebbero
nel DVD, e una PNG del footer negli asset sarebbe una copia in più da
tenere allineata (poco lineare). Template
(`scripts/footer_template.svg`, con segnaposto `{{DATE}}`), font
(`scripts/star_jedi/Starjout.ttf`), script e fallback vivono insieme in
`scripts/`: un solo montaggio per la generazione, zero effetti sul copy
degli asset, asset puliti. `assets/img/footer.png` esce dal repo.

### D3: script `scripts/genera_footer.js`, pattern "anagrafica"

Come `make anagrafica`: lo script gira nel container esistente con
`--entrypoint node`, montando `scripts/` (template e font inclusi),
`dati/` e `build/`, working dir `/usr/src/app` (dove risiedono i
`node_modules`). Nessun npm install sull'host.

Flusso: date da argomento (già compatte `gg-gg/mm/aaaa`) o da
`dati/campo.json` (`--config`, campi separati `inizio`/`fine`, ciascuno in
formato `gg/mm/aaaa`) → validazione → ricomposizione nel formato compatto
per il template → lettura template → sostituzione `{{DATE}}` (replaceAll) →
render resvg 760×49 trasparente → self-check del bbox → scrittura atomica
(tmp + rename) di `build/img/footer.png` → aggiornamento della riserva
`scripts/footer_fallback.png` con l'ultima buona generata.

- Validazione date: argomento con regex `^\d{2}-\d{2}/\d{2}/\d{4}$`; per il
  config una regex `^\d{2}/\d{2}/\d{4}` su ciascun campo (`inizio`, `fine`)
  + controlli di plausibilità (giorni 01-31, mese 01-12, fine ≥ inizio).
  Le due date devono cadere nello stesso mese/anno: la ricetta tipografica
  ha canvas a larghezza fissa e un range a cavallo di mesi non è
  rappresentabile nel footer. Input non valido → errore in italiano,
  nessun file toccato.
- Self-check bbox (dai pixel del render, soglia alpha >128): ink left
  180±1, top 8±1, bottom 37-39; larghezza libera (dipende dalle date) ma
  riportata in output. Il self-check blocca la scrittura se sfora.
- Font assente o resvg assente → exit non-zero con messaggio azionabile
  (`make font` / `make init`); in build subentra il fallback (D6).

### D4: download font in `make init` via container-run, fail-soft

Non nel Dockerfile: le cartelle di lavoro sono volumi montati a runtime, un
font "cotto" nell'immagine in `scripts/` verrebbe mascherato dal mount. Il
target `font` fa girare `wget` + `unzip` nel container appena costruito,
scrivendo sull'host tramite il montaggio (stesso pattern `:U`/keep-id del
resto del Makefile):

```
wget --user-agent="Mozilla/5.0" -O /tmp/star_jedi.zip "https://dl.dafont.com/dl/?f=star_jedi"
unzip -o -j /tmp/star_jedi.zip "*.[tT][tT][fF]" -d /usr/src/app/scripts/star_jedi/
```

- User-Agent da browser: dl.dafont.com è noto per rifiutare client "nudi"
  (da verificare in implementazione; se blocca comunque, fallback
  documentato: zip scaricato a mano + `make font ZIP=...` che estrae dal
  file locale).
- `make init` chiama `$(MAKE) font` con `|| warning`: init non si rompe mai
  per il font; `make font` resta il retry standalone.
- `.gitignore`: aggiungere `scripts/star_jedi/`.

### D5: determinismo e verifica di fedeltà

resvg non scrive timestamp nei PNG: stessa input+versione → stessi byte
(verificato nel task dedicato rigenerando due volte). La fedeltà
all'originale 2023 si è verificata una tantum (esito in
`esito-confronto-2023.md`). Il self-check bbox (D3) è la guardia permanente
contro derive del renderer o regressioni del template.

### D6: lo step footer della build non blocca mai: fallback committato

`make build` = **una sola chiamata container**: `bash -c '{ footer ||
fallback } && npm run build'` — il footer si genera PRIMA della pipeline
(metalsmith ha `clean(false)` e il footer non sta negli assets: nulla lo
sovrascrive), così "Build finished!" resta l'ultimo messaggio della build.
La pipeline resta invariata: lo step vive nella riga di comando del
Makefile, non nel codice Node. Se lo step footer fallisce, si
copia `scripts/footer_fallback.png` in `build/img/footer.png` con un
warning: la build termina comunque con successo e il sito ha sempre un
footer (al peggio con le date dell'ultima generazione riuscita). Se è la
pipeline a fallire, la build fallisce come sempre (il footer non maschera
mai un errore del sito). A ogni generazione riuscita lo script
aggiorna la riserva con la PNG appena prodotta (auto-aggiornamento:
la riserva invecchia al massimo di un'edizione del campo). Seed iniziale
della risorsa: l'originale GIMP 2023 (ex backup `footer_orig.png`).
La riserva è una risorsa nostra, committata in `scripts/`: non è un asset
di terzi e non finisce nel sito se non usata.

## Risks / Trade-offs

- [Lo step footer aggiunge una superficie di errore alla build a campo] →
  step a valle, fail-soft con fallback committato: pipeline e sito mai
  bloccati; rischio residuo limitato alle date del footer (vecchie di al
  massimo un campo).
- [dl.dafont.com irraggiungibile o anti-bot] → init fail-soft con warning,
  retry `make font`, fallback zip manuale; senza font la build usa il
  fallback.
- [Il renderer cambia comportamento tra versioni resvg] → dipendenza con
  versione fissata (pin esatto), self-check bbox che blocca rigenerazioni
  fuori tolleranza (e in build attiva il fallback).
- [PNG rigenerata non byte-identica al 2023] → per scelta (Non-Goal): la
  nuova baseline è il render resvg, visivamente sovrapponibile.
- [Date del campo 2026 non ancora note] → si aggiornano in
  `dati/campo.json` (seme 2023 finché non note: identico allo stato attuale
  del sito); `make footer DATE=...` per le prove.

## Migration Plan

1. `make init` (immagine + resvg + font) — **prima del campo**.
2. Verifica di fedeltà con `22-26/08/2023` (fatta: `esito-confronto-2023.md`)
   e seed di `scripts/footer_fallback.png` dall'originale.
3. Rimozione di `assets/img/footer.png` (e `footer_orig.png`): da lì in poi
   il footer esiste solo generato in `build/img/`.
4. Aggiornamento di `dati/campo.json` con le date reali quando note.
5. Rollback d'emergenza: `git revert` del commit; in ogni caso il fallback
   committato tiene il sito funzionante anche con lo step rotto.

## Open Questions

- Le date reali del campo 2026 (si aggiornano in `dati/campo.json`; non
  blocca lo sviluppo).
- Se dl.dafont.com richieda solo lo User-Agent o anche il referer (verifica
  empirica al task del download; il fallback zip manuale copre il caso
  peggiore).
