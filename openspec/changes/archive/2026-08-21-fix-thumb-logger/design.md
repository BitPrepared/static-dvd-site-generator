## Context

`createThumb` esiste in due copie (quasi identiche) in
`dvd/angolisq/index.js` e `dvd/diariofotografico/index.js`. In entrambe:
`gm(...).resize(...).write(out, cb)` è fire-and-forget, il chiamante non
attende; la callback usa `this.logger` dove `this` non è il plugin (il
logger corretto è già disponibile in closure come `loggerParent`). Il
runbook oggi gestisce il sintomo con la doppia build. Il plugin espone
`build()` sincrona chiamata dall'orchestratore `static-dvd-site-generator/index.js`.
Vincolo: durante il campo si tocca solo codice montato come volume
(`dvd/`, `lib/`); l'orchestratore è cotto nell'immagine (`make init`).

## Goals / Non-Goals

**Goals:**
- Una sola `make build` produce il sito completo.
- Un fallimento ImageMagick produce il messaggio reale + file, subito.
- Modifica confinata al codice già montato, dove possibile.

**Non-Goals:**
- Deduplicare le due copie di `createThumb` in `lib/` (rifattorizzo solo se
  costa zero; l'idioma del repo è sezione autosufficiente).
- Cambiare formati, dimensioni o policy di denominazione dei thumb.
- La concorrenza fine della generazione (vedi D3).

## Decisions

### D1 — `createThumb` restituisce una Promise; il chiamante attende

Wrapper minimo della callback di `gm.write` in una Promise; i blocchi
guidoni/squadriglia/reparto e il loop foto del diario raccolgono le promise
e la sezione attende il tutto prima di restituire il controllo. Il
`build()` del plugin passa a restituire una promise (semantica async),
l'orchestratore la attende. Alternativa scartata: far spawnare il comando
`convert` in sincrono — cambia tool invocato e serrature di errore peggiori.

### D2 — Fail loud

La promise rigetta con l'errore originale di gm; il layer più esterno fa
`logger.error(errore, file)` ed esce con code 1, nello stile della
diagnostica di avvio. Alternativa scartata: warning e sito senza thumb —
ripristina il problema attuale (build "verde" con buchi scoperti dopo).

### D3 — Generazione seriale, non parallela

Le thumb di una serata di campo sono decine/centinaia: si generano in coda
(un `for...of` con `await`) invece che tutte in parallelo come accade ora
per effetto del fire-and-forget. Prevedibilità di memoria e tempi sul
laptop di campo vale più del picco di velocità; una pool con concorrenza
limitata è follow-up opzionale se la generazione seriale si rivelasse
lenta (stima: ~200ms/foto, una serata da 300 foto ≈ 1 minuto).

### D4 — Il logger nelle callback è `loggerParent` per closure

Fix del `this.logger`: nelle callback si usa la variabile già catturata
(`const loggerParent = this.logger` in angolisq già esiste; nel diario si
introduce l'equivalente). Nessuna modifica alle firme.

### D5 — I test girano nel container con immagini vere

I moduli richiedono `gm` direttamente: niente DI per mockarlo (costo di
rifattorizzo non giustificato). I test usano `node:test` nel container
(gm/ImageMagick presenti nell'immagine) con immagini di test piccole reali
(es. PNG 1×1) e un file corrotto apposta per il caso d'errore.

## Risks / Trade-offs

- [Build serale un po' più lunga per la serialità] → stima al paragrafo D3;
  pool come follow-up; il tempo era già speso, solo reso visibile.
- [Il passaggio di `build()` ad async tocca l'orchestratore cotto
  nell'immagine] → l'attesa si può introdurre anche solo nei plugin
  (bloccanti fino a fine coda thumb, poi il resto del build procede
  com'è); il tocco all'orchestratore resta un one-liner con `make init`,
  oppure si evita del tutto: in fase apply si sceglie la variante che non
  richiede `make init` se il campo è in corso.
- [Comportamento nuovo: la build ora può fallire dove prima "riusciva"] →
  è il punto della proposta; il messaggio d'errore è azionabile e il
  runbook documenta la nuova semantica.

## Migration Plan

1. test rossi nel container (thumb attesi; errore reale su file corrotto);
2. fix `loggerParent` nelle due copie;
3. `createThumb` promise + attesa serale nei due plugin;
4. orchestratore (solo se serve e non a campo in corso);
5. runbook §3: via "due volte" e limite noto.
Rollback: revert dei singoli commit — nessuno stato persistente coinvolto.

## Open Questions

- Tagliare le thumb parallelo o seriale è già deciso (D3); la dimensione
  eventuale della pool è un dettaglio post-misura, non blocca nulla.
