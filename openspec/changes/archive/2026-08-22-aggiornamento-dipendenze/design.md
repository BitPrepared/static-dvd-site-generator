# Design — Aggiornamento dipendenze (bump conservativo post-campo)

## Context

Motivazione e portata in `proposal.md`; il contratto della rete di sicurezza
in `specs/verifica-regressione-build/spec.md`. Stato che condiziona le
scelte tecniche:

- Immagine pinnata a patch precisa (`node:18.2.0-bullseye`), `engines`
  `node 18.x / npm 8.x`, lockfile v3 già presente.
- Il codice è interamente CommonJS; `rimraf` è chiamato solo come
  `rimraf.sync()`; `chalk` in `scripts/genera_footer.js` è già caricato in
  modo difensivo (try/catch, fallback senza colori).
- `gm` lavora via `subClass({imageMagick: true})` sul binario ImageMagick
  installato con `libmagick++-dev` dalla base Debian: la versione del
  container e quella della libreria sono accoppiate di fatto.
- `@resvg/resvg-js` usa binari precompilati N-API: non dipende dall'ABI di
  Node, solo da glibc.
- Runtime duale docker/podman (rootless, `--userns=keep-id`, montaggi `:U`).

## Goals / Non-Goals

**Goals:**

- Uscire dall'EOL (Node 18 / bullseye) mantenendo identico il comportamento
  della pipeline, verificato col golden build.
- Rendere esplicite nel manifest le dipendenze realmente richieste dal codice.
- Lasciare ogni passo di update attribuibile a un commit (e reversibile).

**Non-Goals:**

- Migrazione dei plugin Metalsmith alle major moderne (`@metalsmith/*`).
- Sostituzione di `gm` (es. con `sharp`), uscita da `moment`, da `npm-run-all`.
- Qualunque migrazione ESM o riscrittura di codice applicativo.
- CI: resta nel perimetro di un change futuro.

## Decisions

### D1 — Base image: `node:24-bookworm`, tag non pinnato alla patch

Node 24 è l'LTS con supporto fino ad aprile 2028; Node 22 (alternativa più
"vicina") va in manutenzione fino ad aprile 2027, cioè sarebbe di nuovo a
fine vita al prossimo ciclo annuale di update — per un progetto che si
tocca una volta l'anno, il salto a 24 non è più rischioso di quello a 22
(nessun modulo nativo compilato: resvg è N-API precompilato, gm spawna il
binario IM). Il tag resta su major+codename (`node:24-bookworm`) invece
della patch esatta `18.2.0`: riceve le patch di sicurezza a ogni
`make init` senza richiedere edit del Dockerfile. Alternativa scartata:
pinnare la patch (riproducibilità massima) — scartata perché l'obiettivo
della spec è proprio smettere di restare fermi su build senza patch.

`engines` coerente: `"node": ">=24 <25"`, `"npm": ">=10"`.

### D2 — Restare su bookworm (non trixie) finché c'è `gm`

bookworm mantiene ImageMagick 6 (come bullseye): l'accoppiata
`gm`+`convert` resta sulla stessa major. trixie porta ImageMagick 7, con
cui il binding `gm` non è compatibile: passare base image e sostituire `gm`
nello stesso change violerebbe la portata conservativa. La migrazione
`sharp` (change futuro) sarà il momento giusto per rivalutare la base.

### D3 — Bump npm: ultima versione CJS-compatibile della major corrente

Regola unica per tutte le dipendenze che restano: avanzare alla versione
più recente che (a) resta CommonJS e (b) non cambia l'API usata dal codice.
Tabella dei punti noti:

| Pacchetto | Oggi | Target | Nota |
|---|---|---|---|
| chalk | ^2 | 4.x | 5+ è ESM-only; API usata identica |
| rimraf | ^2 | 3.x | solo `rimraf.sync()`; 4+ cambia modello ed è ESM |
| fs-extra | ^10 | 11.x | CJS, API stabile |
| shelljs | ^0.7 | 0.8.x | |
| handlebars | ^4.0 | 4.7.x | stessa major |
| metalsmith | ^2.3 | ultima 2.x | API plugin stabile; plugin vecchi restano |
| moment | ^2.18 | 2.30.x | ultima release (maintenance); uscita = change B |
| npm-run-all | ^4 | invariato | non mantenuto ma funzionante; `npm-run-all2` valutato nel change B |
| csv-parse / transliteration / @resvg/resvg-js / gm / directory-tree | | ultima della major corrente | già attuali o senza salto utile |

I numeri esatti si fissano al momento dell'esecuzione leggendo il registry;
la regola (CJS + API invariata) prevale sul numero.

### D4 — Dichiarare `multimatch` e `debug`, pinnate alle transitive attuali

`lib/metalsmith-gallery.js` le usa direttamente ma oggi arrivano come
dipendenze transitive. Vanno aggiunte a `dependencies` alle versioni
effettivamente risolte nel lockfile attuale, così il passaggio non cambia
nemmeno la versione in node_modules.

### D5 — Golden build: script Node senza nuove dipendenze, snapshot in `golden/`

Implementazione di `verifica-regressione-build`:

- Un unico script (`scripts/golden.js`) con due modalità (`salva`,
  `confronta`), solo moduli built-in (`fs`, `crypto` per SHA-256): nessuna
  dipendenza nuova da aggiungere proprio quando stiamo misurando le
  dipendenze.
- Manifest: percorsi relativi + hash SHA-256, scritto in `golden/` (root
  progetto, gitignored). Fuori da `build/` perché le `clean()` della
  pipeline cancellano `build/`, e la verifica non deve morire con essa.
- Esclusioni/normalizzazioni: elenco esplicito nel manifest stesso. Default
  prudente: per le immagini generate (foto/thumb) si confronta la presenza,
  non l'hash — una versione patch di ImageMagick può cambiare i byte JPEG a
  parità di immagine, e i thumb esistenti non vengono comunque rigenerati
  (spec `generazione-thumb`). Il footer è deterministico da
  `dati/campo.json`: nessuna esclusione necessaria a parità di input.
- Make targets `golden-salva` / `golden-confronta` con `check-executor`,
  script montato a volume come già si fa per `anagrafica` e `footer`
  (modifiche live senza rifare `make init`).
- Il tool non è nel percorso di `make build`: la sera del campo non c'entra
  nulla.

### D6 — Sequenza di update: un passo, un confronto, un commit

L'ordine minimizza l'attribuzione dei problemi; ogni passo finisce con
`make golden-confronta` verde prima di proporre il commit all'utente
(l'utente committa, mai l'agente):

1. Baseline sulla toolchain attuale: `make init` + `make build` +
   `golden-salva`.
2. Base image + Makefile VERSION + engines → `make init` → `make build` →
   confronto.
3. Bump npm conservativo (D3) + dichiarazione esplicite (D4) →
   `npm install` nel container → confronto.
4. Rimozione zombie (`co`, `co-prompt`, `process-env`, `mkdirp`,
   `metalsmith-handlebars`) → confronto. Separata dal passo 3: se qualcosa
   si rompe si sa subito se la colpa è dei bump o di una rimozione.

## Risks / Trade-offs

- [Una patch IM6 di bookworm cambia i byte dei thumb rigenerati] → i thumb
  esistenti non vengono rigenerati e nel manifest le immagini sono
  presence-only (D5); eventuali thumb nuovi si validano a occhio una volta.
- [`@resvg/resvg-js` senza binario per la nuova piattaforma] → fallirebbe
  rumorosamente a `make init`/prima build; il footer ha già il fallback
  fail-soft (`footer_fallback.png`) e il problema emergerebbe nel passo 2,
  prima di toccare npm.
- [Node 24 più severo su API rimosse/deprecate] → la build fallirebbe in
  modo evidente al passo 2; fix puntuali o, in extremis, rollback a
  `node:22-bookworm` (stessa procedura, D1 resta valida).
- [`npm install` nel container con uid/gid di chi builda su bookworm] →
  meccanismo uid/gid e podman `:U`/keep-id invariati; si verifica con
  `make init` + `make build` con entrambi gli executor al passo 2.
- [Golden build dà falsi negativi su contenuti volatili non previsti] →
  l'elenco esclusioni è parte del manifest e si estende senza toccare codice
  di verifica; lo scenario "due build consecutive" della spec è il test di
  regressione del tool stesso.
- [Trade-off: tag non pinnato alla patch] → build meno riproducibile al
  byte, ma patch di sicurezza automatica a ogni `make init`; è il
  compromesso voluto (D1).
- [Nota post-esecuzione: warning DEP0060 su Node 24] → `util._extend` è
  usato da `hosted-git-info@2.8.9`, transitiva di `npm-run-all` →
  `read-pkg@3` → `normalize-package-data@2`: Node 24 ha reso udibile una
  deprecazione che in Node 18 taceva. Cosmetico (solo stderr del runner,
  output ed exit code intatti — confronto golden 4392/4392 identico).
  Sparisce con lo switch `npm-run-all2` già previsto per il change futuro;
  un override della transitive violerebbe la portata conservativa.

## Migration Plan

Esecuzione interamente **post-campo 2026** (nessun passo è eseguibile in
agosto): vedi D6. Rollback a ogni passo: checkout del commit precedente +
`make init` (l'immagine precedente resta disponibile finché non si lancia
`clean-docker`). Il campo 2027 parte con la toolchain nuova già validata
dal golden build, non con l'update in corso.

## Open Questions

Nessuna che blocchi: la scelta Node 24 vs 22 è decisa in D1, la lista
esclusioni del golden build si completa all'atto della baseline (passo 1)
senza cambiare spec né approccio.
