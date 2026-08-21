# Proposta: thumb pronte in una sola build + errore logger non mascherato

## Why

Il runbook (§3) istruisce a lanciare `make build` **due volte**: la prima
genera i thumb delle foto, la seconda li renderizza nelle pagine — limite
noto dichiarato ("da evolvere, backlog post-campo"). La causa è che la
scrittura dei thumb è fire-and-forget: la build prosegue verso la fase
metalsmith mentre ImageMagick sta ancora lavorando. Nello stesso identico
pezzo di codice, la callback di scrittura usa `this.logger` dentro una
funzione callback (dove `this` non è il plugin): quando la generazione
fallisce, invece dell'errore reale di ImageMagick compare un crash
"Cannot read property 'logger' of undefined" — emerso dal RED del sandbox.
Il difetto di diagnosità è peggiore del difetto di temporizzazione: durante
il campo, un ImageMagick rotto va riconosciuto subito dal messaggio giusto.

## What Changes

- La generazione dei thumb diventa **attesa**: la build di una sezione
  termina solo quando tutti i thumb della sezione sono scritti; una sola
  `make build` produce il sito completo (thumb inclusi).
- I thumb già presenti non vengono rigenerati (comportamento attuale
  conservato, è ciò che rende accettabile la seconda build di oggi).
- Se la generazione di un thumb fallisce, la build **fallisce** con
  l'errore reale e il nome del file coinvolto: niente più crash su
  `this.logger`, niente build "riuscita" con thumb mancanti scoperti a
  sito aperto.
- Il fix vale per entrambi i punti con lo stesso codice duplicato:
  `dvd/angolisq/index.js` (guidoni, squadriglia, reparto) e
  `dvd/diariofotografico/index.js` (foto del diario).
- Il runbook §3 perde l'istruzione "sì, due volte" e l'avviso di limite
  noto.

Rischio per la build a campo: **basso**. La modifica è confinata ai plugin
montati come volumi (live, niente `make init`), il formato di output non
cambia e il workaround della doppia build smette di essere necessario ma
resta innocuo. L'unico cambiamento comportamentale è che una build con
ImageMagick rotto ora termina male **subito** con il messaggio giusto,
invece di "riuscire" la prima sera e fallire la seconda: è esattamente
ciò che vuoi scoprire la sera stessa.

## Capabilities

### New Capabilities
- `generazione-thumb`: le anteprime (thumb) delle foto vengono generate
  durante la build in modo completo, attendibile e diagnosticabile.

### Modified Capabilities
<!-- Nessuna: `diagnostica-avvio` copre i dati mancanti all'avvio del
     generatore, requisiti non toccati da questo cambiamento. -->

## Impact

- `dvd/angolisq/index.js` (`createThumb` e i tre blocchi
  guidoni/squadriglia/reparto).
- `dvd/diariofotografico/index.js` (stesso pattern copiato).
- `static-dvd-site-generator/index.js` (l'orchestratore attende il termine
  della fase di generazione thumb delle sezioni prima della fase metalsmith
  — tocco piccolo, ma è cotto nell'immagine: richiede `make init`).
- `Readme.md` §3 (runbook: una sola build).
- Fuori scope: ridimensionamento/qualità dei thumb, formato immagini,
  il diario fotografico come sezione, la CI.
