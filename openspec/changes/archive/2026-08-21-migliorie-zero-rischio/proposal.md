# Migliorie a rischio zero (fase campo 2026)

## Why

Il Readme.md attuale dice cose sbagliate (`make init` descritto come rimozione
immagine), dipende da script che non stanno nel repo e non copre podman né le
regole di privacy. In più, chi lancia la build senza `dati/squadriglie.json`
(Esperienza vissuta a campo 2026) si ritrova 20 righe di stack Node invece di
un consiglio utile, e ogni build stampa l'intero `process.env` del container.

## What Changes

- **Readme.md riscritto come runbook annuale** ("come si fa il DVD"):
  setup macchina (docker/podman), flusso pre-campo (anagrafica), flusso
  quotidiano (foto → script → build), fine campo (commit/archivio), regole
  privacy. Corretta la documentazione errata su `make init`/`clean-docker`.
- **Rimozione `console.log(process.env)`** da `static-dvd-site-generator/index.js`
  (stampa informazioni d'ambiente non necessarie ad ogni build).
- **Errore azionabile se `dati/squadriglie.json` manca**: il generatore termina
  subito con un messaggio in italiano che suggerisce `make anagrafica` oppure
  la copia dell'example per test, invece dello stack trace.

Valutazione rischio per la build a campo: **zero per tutti e tre**. La
pipeline non viene toccata: il primo è solo documentazione; il secondo rimuove
una stampa; il terzo intercetta un caso che oggi finisce in crash comunque
(cambiare il testo dell'errore non può peggiorare la serata).

## Capabilities

### New Capabilities

- `diagnostica-avvio`: segnalazione chiara e azionabile dei dati mancanti
  all'avvio del generatore (estende il comportamento esistente dei warning
  `check()` ai file la cui assenza è fatale per la build).

### Modified Capabilities

(nessuna: non esistono altre spec in `openspec/specs/`)

## Impact

- `Readme.md` (riscrittura completa)
- `static-dvd-site-generator/index.js` (rimozione stampa env; guardia su
  lettura `dati/squadriglie.json`)
- Nessuna modifica a pipeline, template, Makefile o Dockerfile
- Nessuna nuova dipendenza
