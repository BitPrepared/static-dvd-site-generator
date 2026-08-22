# Aggiornamento dipendenze (bump conservativo post-campo)

## Why

Lo strato runtime della pipeline è EOL da oltre un anno: l'immagine base è
pinnata a `node:18.2.0-bullseye` (Node 18 EOL aprile 2025) e `engines`
blocca `node 18.x / npm 8.x`; le ~34 dipendenze npm sono ferme a major del
2016–2021. Non è più manutenibile né coperto da patch di sicurezza, e ogni
update futuro sarà più costoso. L'aggiornamento va eseguito **solo a campo
concluso** (regola del progetto): la spec si scrive ora, si esegue dopo.

Portata deliberatamente conservativa (nessun cambio di API nel codice):
la modernizzazione profonda (plugin `@metalsmith/*`, `gm`→`sharp`, uscita
da `moment`, eventuale migrazione ESM) resta un change separato futuro.

## What Changes

- **Immagine base**: `node:18.2.0-bullseye` → Node LTS corrente su
  **bookworm** (Node 22 o 24, scelta fissata in design). Bookworm mantiene
  ImageMagick 6, quindi il binario `gm`+IM resta accoppiato alla stessa
  major di oggi.
- **Tag immagine**: Makefile `VERSION=bullseye` → `VERSION=bookworm`.
- **engines** coerenti con la nuova base (node/npm aggiornati).
- **Dipendenze npm**: bump alle ultime versioni **CJS-compatibili senza
  cambi di API** (es. chalk 2→4, rimraf 2→3, fs-extra 10→11, shelljs,
  handlebars 4.x latest, metalsmith 2.x latest minor); i plugin Metalsmith
  restano sugli stessi major.
- **Dipendenze non dichiarate ma usate**: aggiungere esplicitamente
  `multimatch` e `debug` (oggi transitive, usate in
  `lib/metalsmith-gallery.js`) — bug latente che qualsiasi pulizia romperebbe.
- **Rimozione dipendenze zombie** mai richieste dal codice: `co`,
  `co-prompt`, `process-env`, `mkdirp`, `metalsmith-handlebars` (verifica
  finale col golden build prima del commit).
- **Rete di sicurezza prima di tutto**: nuovo task "golden build" che cattura
  uno snapshot dell'output attuale e lo confronta dopo l'update, così il
  bump passa da "prega" a "verifica".
- Fuori portata (change futuri): sostituzione plugin Metalsmith, `sharp`,
  rimozione `moment`, migrazione ESM, CI.

## Capabilities

### New Capabilities

- `verifica-regressione-build`: meccanismo di snapshot/confronto dell'output
  della build ("golden build") che permette di verificare meccanicamente che
  un cambio di toolchain produca lo stesso sito; include gestione delle parti
  volatili dell'output (date del campo nell'footer, ecc.).

### Modified Capabilities

Nessuna: le capacità esistenti (`generazione-thumb`, `generazione-footer`,
`diagnostica-avvio`, `anagrafica`) devono comportarsi identicamente a
dopo l'update — è proprio l'obiettivo. Nessun requisito cambia a livello di spec.

## Impact

- **File**: `Dockerfile` (FROM + eventuali pacchetti apt), `Makefile`
  (VERSION), `static-dvd-site-generator/package.json` + `package-lock.json`,
  `lib/metalsmith-gallery.js` (nessuna modifica codice, solo dipendenze
  dichiarate).
- **Codice applicativo**: nessuno toccato per costruzione (bump senza
  cambi API); se il golden build evidenzia una differenza, quella singola
  differenza diventa un task dedicato, non un fix a campi ciechi.
- **Operativo**: chi builda deve rifare `make init` (rebuild immagine);
  podman rootless e montaggi `:U` invariati. Rollback = checkout del commit
  precedente + `make init` (l'immagine vecchia resta taggata separatamente).
- **Sicurezza**: elimina l'esposizione a CVE noti di Node 18/bullseye;
  riduce la superficie installata (dipendenze zombie fuori da node_modules).

## Rischio per la build a campo

**Zero durante il campo**: nessuna modifica di questa spec viene eseguita
prima della conclusione del campo 2026; la pipeline in uso a campo resta
l'attuale, pinnata e intoccata. **A esecuzione avvenuta (post-campo)** il
rischio residuo è basso e contenuto: il golden build verifica l'equivalenza
dell'output prima di dichiarare concluso il work; il fallback footer e le
spec esistenti (thumb, diagnostica) fanno da canarini; il rollback è un
checkout + `make init`. Il giorno di build critico del campo 2027 non
coincide con nessuna fase di questa attività.
