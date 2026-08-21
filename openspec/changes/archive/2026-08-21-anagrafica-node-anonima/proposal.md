# Proposta: anagrafica in Node con modalità anonima

## Why

La generazione di `dati/squadriglie.json` avviene oggi tramite uno script PHP
(123 righe) eseguito in un container `php:7.4-cli`: un runtime EOL da novembre
2022, tirato dentro la catena solo per questo, mentre il generatore ha già
Node nell'immagine. Nel frattempo serve una modalità "anagrafica anonima":
un sito pubblicabile/condivisibile senza i dati dei ragazzi (nomi, indirizzi,
contatti, credenziali), con sole foto di squadriglia, urli e hike — che vivono
sul filesystem e non nel json. Il `config.yaml` del progetto elenca già
"anagrafica in node" fra i refactor post-campo: questa proposta la realizza
incontra a metà strada la modalità anonima, così lo script si riscrive una
volta sola invece di due.

## What Changes

- Nuovo script Node `anagrafica/genera_anagrafica.js` che sostituisce
  `anagrafica/anagrafica_da_csv.php` (stesso CSV in ingresso, stesso formato
  json in uscita).
- Modalità anonima (`make anagrafica ANONIMO=1`): il json generato contiene
  solo i nomi delle squadriglie con `members: {}` — nessun dato ragazzo
  entra nel file. Il sito generato da quel json mostra pagine squadriglia
  con foto/urlo/hike e nessuna scheda ragazzo (già oggi handlebars rende
  `each` su members vuoti senza errori; `members` è consumato solo da
  `dvd/angolisq`).
- Le squadriglie smettono di essere hardcoded nello script (oggi
  oro/arancio/blu/rosso): vengono ricavate dal CSV (distinct della colonna
  `squadriglia`), sia in modalità reale che anonima.
- L'identificativo dei ragazzi (chiave del member e filename della pagina)
  viene calcolato una volta sola nello script: oggi il PHP lo calcola con
  transliterazione ASCII ma `dvd/angolisq/index.js:87` lo ricalcola senza
  transliterazione, e con un cognome accentato link e pagina divergono.
- `make anagrafica` gira nell'immagine del generatore (Node) invece che in
  `php:7.4-cli`: un container in meno, e lo script resta montato come volume
  (modifiche live, niente `make init`).
- **BREAKING** (marginale): `anagrafica_da_csv.php` viene rimosso; chi lo
  invocasse direttamente deve usare `make anagrafica`. Il formato del json e
  il CSV in ingresso non cambiano.
- `anagrafica/elenco_ragazzi_example.csv` (dati finti, già esistente ma
  gitignorato da `*.csv`) viene tracciato in git con una negazione nel
  `.gitignore`, insieme a un `dati/squadriglie.example-anonima.json`, così
  lo smoke test copre anche la modalità anonima.
- Aggiornamento del runbook (Readme §2) con le due modalità e la riga
  "build vs init" per il nuovo script.

Rischio per la build a campo, voce per voce:

| Modifica | Rischio a campo | Note |
|---|---|---|
| Script Node al posto del PHP | strutturale, non zero | refactor esplicitamente post-campo (vincolo in `openspec/config.yaml`); dopo la migrazione l'ingest del generatore è identico (stesso json) |
| Modalità anonima | zero | non esiste codice nuovo nel generatore: è solo un json diverso in ingresso; la modalità reale non cambia percorso |
| De-hardcode squadriglie | basso | cambia l'output solo se le squadriglie dell'anno differiscono dalle 4 hardcoded (che andrebbero comunque editate a mano) |
| Id calcolato una volta | basso | allinea due calcoli già presenti; divergenza attuale è un bug latente che si manifesta solo con nomi accentati |
| Makefile senza php:7.4-cli | basso | il target richiede l'immagine del generatore, che è già prerequisito del flusso |
| Example csv/json tracciati | zero | dati finti, nessun impatto runtime |

## Capabilities

### New Capabilities
- `anagrafica`: generazione di `dati/squadriglie.json` a partire dal CSV
  `anagrafica/elenco_ragazzi.csv` — in Node, con modalità anonima, squadriglie
  ricavate dal CSV e identificativi ragazzo calcolati una volta sola.

### Modified Capabilities
<!-- Nessuna: `diagnostica-avvio` resta valida così com'è (squadriglie.json
     rimane un dato obbligatorio con lo stesso aiuto). -->

## Impact

- `anagrafica/` (nuovo script, rimozione PHP, `.gitignore` con eccezione per
  l'example).
- `Makefile` (target `anagrafica`: immagine generatore, env `ANONIMO`).
- `static-dvd-site-generator/package.json` (eventuali dipendenze di parsing
  CSV/transliteration — decisione in design.md) — attenzione: richiede
  `make init` perché cotto nell'immagine.
- `dati/squadriglie.example-anonima.json` (nuovo, dati finti).
- `Readme.md` (runbook §1 e §2).
- Fuori scope: il comportamento del generatore HTML, i template, le altre
  sezioni (l'anonimizzazione sfrutta la tolleranza già esistente).
