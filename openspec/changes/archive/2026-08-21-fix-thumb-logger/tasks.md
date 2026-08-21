## 1. Test rossi (TDD, nel container con immagini vere)

- [x] 1.1 Preparare fixture di test: PNG 1×1 valido, immagine corrotta
  apposta, cartella thumb temporanea (test con `node:test`)
- [x] 1.2 Test: il build della sezione non termina prima che i thumb
  promessi siano effettivamente su disco (oggi rosso)
- [x] 1.3 Test: con immagine corrotta il fallimento riporta l'errore reale
  di gm + nome file, non un crash su logger (oggi rosso)

## 2. Fix (dove i test diventano verdi)

- [x] 2.1 Sostituire `this.logger` con `loggerParent` nelle callback di
  scrittura thumb in `dvd/angolisq/index.js` e
  `dvd/diariofotografico/index.js`
- [x] 2.2 `createThumb` restituisce una Promise in entrambi i plugin
- [x] 2.3 Attesa seriale dei thumb in `dvd/angolisq/index.js`
  (guidoni, squadriglia, reparto, fotogruppo)
- [x] 2.4 Attesa seriale dei thumb in `dvd/diariofotografico/index.js`
- [x] 2.5 Fail loud: rigetto → `logger.error(errore, file)` + exit code 1
- [x] 2.6 Se serve, un one-liner nell'orchestratore per attendere i build
  delle sezioni (valutare se evitabile per non richiedere `make init`
  a campo in corso)

## 3. Verifica e runbook

- [x] 3.1 Smoke end-to-end: `make clean && make build` (una sola volta) con
  dati example → sito completo con tutte le anteprime
- [x] 3.2 Smoke: build successiva senza materiale nuovo → nessun thumb
  rigenerato (idempotenza conservata)
- [x] 3.3 Runbook §3: rimuovere "sì, due volte" e l'avviso di limite noto;
  documentare la nuova semantica di fallimento (errore reale + file)
