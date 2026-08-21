## 1. Diagnostica di avvio

- [x] 1.1 In `static-dvd-site-generator/index.js` introdurre la lettura
  centralizzata dei sette JSON obbligatori con messaggio azionabile in
  italiano (file mancante + `make anagrafica` o copia dell'example) ed uscita
  con codice 1, come da design.md §1
- [x] 1.2 Rimuovere il dump `console.log(process.env)` da
  `static-dvd-site-generator/index.js`
- [x] 1.3 Verificare i due scenari della spec `diagnostica-avvio`: build senza
  `dati/squadriglie.json` (messaggio + exit non-zero, nessuno stack trace) e
  build con example (esito invariato, output senza variabili d'ambiente)

## 2. Runbook (Readme.md)

- [x] 2.1 Definire con lo staff il contenuto dettagliato del runbook: flusso
  reale quotidiano del campo (chi porta le foto, quando si builda, doppia
  build dei thumb), flusso pre-campo e fine campo
- [x] 2.2 Riscrivere `Readme.md` nelle cinque sezioni del design (setup
  macchina con tabella docker/podman, pre-campo, durante il campo, fine
  campo, regole privacy), documentando gli script foto come prerequisiti
  esterni non presenti nel repo
- [x] 2.3 Verificare ogni comando scritto nel runbook su una macchina reale
  (blackhole, con podman) prima di chiudere il change

## 3. Chiusura

- [x] 3.1 `openspec validate` del change e, dopo apply verificata, archiviazione
