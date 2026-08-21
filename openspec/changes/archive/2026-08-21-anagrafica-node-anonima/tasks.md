## 1. Script Node (TDD: test rosso prima di ogni implementazione)

- [x] 1.1 Aggiungere `csv-parse` e `transliteration` (versioni pinnate) a
  `static-dvd-site-generator/package.json` e rifare `make init`
- [x] 1.2 Test `node:test` del parsing CSV: separatore `;`, intestazione,
  campi quoted, riga vuota tollerata
- [x] 1.3 Implementare il parsing con diagnostica: CSV assente, illeggibile,
  colonna `squadriglia`/`nome`/`cognome` mancante → exit != 0, messaggio
  azionabile, nessun json scritto
- [x] 1.4 Test della generazione in modalità reale: squadriglie dai valori
  distinti in ordine di prima apparizione, members con tutti i campi del CSV
- [x] 1.5 Test dell'id ragazzo: traslitterazione ASCII, minuscolo, senza
  spazi né apostrofi; la chiave del member È l'id
- [x] 1.6 Test della modalità anonima (`ANONIMO=1`): solo `name` e
  `members: {}`, nessun valore delle colonne anagrafiche nel json
- [x] 1.7 Implementare scrittura atomica (`dati/squadriglie.json` via `.tmp`
  + rename) e log diagnostici su stdout/stderr
- [x] 1.8 Warning per squadriglie con un solo ragazzo (possibile typo nel CSV)

## 2. Integrazione pipeline

- [x] 2.1 Nuovo target `make anagrafica`: immagine generatore con
  `--entrypoint node`, mount di `anagrafica/` e `dati/`, env `ANONIMO`
  passante (PHP non ancora rimosso)
- [x] 2.2 Comparazione PHP vs Node sugli stessi input: `elenco_ragazzi.csv`
  2025, `elenco_ragazzi_2024.csv`, example — parità semantica (eccezione
  attesa: id ASCII su nomi accentati)
- [x] 2.3 Usare la chiave del member come filename pagina in
  `dvd/angolisq/index.js` (addio ricalcolo da nome+cognome); test di
  coerenza link→pagina con un cognome accentato nell'example
- [x] 2.4 Smoke test `make build` con json anonimo: pagine squadriglia con
  foto/urlo/hike, zero pagine ragazzo, liste nomi vuote

## 3. Example, pulizia, documentazione

- [x] 3.1 Tracciare `anagrafica/elenco_ragazzi_example.csv` (negazione nel
  `.gitignore`) e aggiungere `dati/squadriglie.example-anonima.json`
- [x] 3.2 Rimuovere `anagrafica/anagrafica_da_csv.php` e il riferimento a
  `php:7.4-cli` dal Makefile (solo dopo 2.2 verificato)
- [x] 3.3 Runbook (Readme): riga "build vs init" nel §1, le due modalità
  del §2 con `make anagrafica ANONIMO=1`
