## Context

Oggi `make anagrafica` esegue `php:7.4-cli` su `anagrafica/anagrafica_da_csv.php`
e redirige lo stdout su `dati/squadriglie.json`. Lo script ha 4 squadriglie
hardcoded, un `array_filter` finale che scarta le squadriglie senza members
(la trappola per la modalità anonima: produrrebbe un json vuoto), un
`$app_suddivisione` mai emesso, e una fallback map di transliterazione
incompleta (`// etc.`). Il member key è calcolato in PHP con transliterazione
ASCII ma `dvd/angolisq/index.js:87` ricalcola il filename senza transliterare:
divergono con nomi accentati. `members` è consumato solo da `dvd/angolisq`
(loop pagine ragazzo, lista nomi in `sq.hbs`, `squadrigliere.hbs` istanziato
solo dal loop): handlebars e il `for...in` JS tollerano `members: {}` senza
errori. Il vincolo di progetto impone l'applicazione a campo concluso.

## Goals / Non-Goals

**Goals:**
- Un solo runtime (Node) nella catena `make anagrafica`, script montato come
  volume (modifiche live, niente `make init` per cambiare lo script).
- Compatibilità di formato: il json in modalità reale è indistinguibile da
  quello odierno (stesse chiavi, stessi campi), così il generatore HTML non
  cambia ingest.
- Id ragazzo con una sola fonte di verità.

**Non-Goals:**
- Toccare il generatore HTML oltre all'uso della chiave già presente nel json
  (una riga in `dvd/angolisq/index.js`).
- Il lockfile di npm e la CI (change separato nel backlog).
- Modifiche ai template: la modalità anonima sfrutta la tolleranza esistente.
- Migrazione del formato CSV o dei xls/ods (restano sorgenti da esportare a
  mano in CSV come oggi).

## Decisions

### D1 — Lo script vive in `anagrafica/` ed è eseguito dall'immagine generatore

`anagrafica/genera_anagrafica.js`, invocato dal target `make anagrafica` con
`${EXECUTOR} run` dell'immagine del generatore (`--entrypoint node`), montando
`anagrafica/` e `dati/` con le stesse regole degli altri mount (`:U` su podman).
Alternativa scartata: metterlo in `static-dvd-site-generator/` (nominale "casa"
del codice sorgente dell'immagine) — verrebbe cotto nell'immagine e ogni ritocco
richiederebbe `make init`, contro lo stile del runbook.

### D2 — Dipendenze: `csv-parse` + `transliteration`, test con `node:test`

Il CSV è separato da `;` con possibilità di campi quoted: il parsing a mano è
fragile. La translitterazione italiana (à è é ì ò ù e maiuscole) merita una
libreria collaudata quanto lo era `iconv` in PHP. Le dipendenze nuove si
aggiungono a `static-dvd-site-generator/package.json` (richiede `make init`,
dichiarato). Alternativa zero-dipendenze considerata e scartata: risparmia
poco e reintroduce la fallback map incompleta. I test usano `node:test`
(built-in, nessuna dipendenza nuova) coerentemente con la guida TDD di apply.

### D3 — Output scritto direttamente dallo script, atomico

Lo script scrive `dati/squadriglie.json` (path configurabile via argv, default
rispetto al CSV) dopo aver validato tutto: scrittura su `.tmp` e `rename`.
Alternativa scartata: mantenere il redirect stdout del Makefile — impedirebbe
la scrittura atomica e mescolerebbe log diagnostici al json (oggi il PHP deve
stampare solo json su stdout per questo). Stdout resta per i log stile logger.

### D4 — Modalità anonima via env `ANONIMO=1`

Passato dal Makefile con `-e ANONIMO=$(ANONIMO)`, come già fa `DEBUG`:
coerente con le convenzioni del repo. In questa modalità lo script raccoglie
solo i valori distinti di `squadriglia` e non porta alcun campo riga nel json.
Il `filter` finale del PHP (scarta sq senza members) non ha equivalente:
in modalità reale una squadriglia esiste solo se ha ragazzi nel CSV, in
modalità anonima esiste se appare nel CSV.

### D5 — Id ragazzo: la chiave del member è la sola fonte di verità

Lo script calcola l'id (traslitterato, minuscolo, senza spazi/apostrofi) e lo
usa come chiave del member. Il fix lato generatore è minimale: in
`dvd/angolisq/index.js` il loop `for keyM in members` ha già la chiave corretta
in mano e oggi la spreca ricalcolando da nome+cognome — userà `keyM` come
filename. `desc_name` continua a venire da nome+cognome (serve il display).

### D6 — Ordine squadriglie: prima apparizione nel CSV

L'index degli angoli itera il json in ordine di chiave: mantenere l'ordine di
prima apparizione nel CSV preserva l'ordinamento "per età/anzianità" che oggi
dà la lista hardcoded.

## Risks / Trade-offs

- [Le nuove dipendenze npm non sono riproducibili senza lockfile] → le versioni
  vengono pinnate nel package.json; la cura definitiva (lockfile) è nel change
  CI del backlog, che resta prerequisito naturale per l'aggiornamento toolchain.
- [Typo nella colonna `squadriglia` crea una squadriglia fantasma con un solo
  ragazzo] → diagnostica: warning su squadriglie con un solo membro e su nomi
  di squadriglia mai visti rispetto a un anno precedente non è possibile senza
  dati storici tracciati; ci si limita al warning sul singleton.
- [Regressioni invisibili sul CSV reale] → durante la migrazione si eseguono
  PHP e Node sugli stessi CSV (in `anagrafica/` ce ne sono di reali, non
  tracciati) e si confrontano gli output: uguaglianza semantica tranne l'id
  ASCII (migliorato di proposito).
- [Runbook stampato/abituale che invoca il PHP] → la rimozione del PHP arriva
  solo a migrazione verificata; il runbook §2 viene aggiornato nello stesso
  commit.

## Migration Plan

1. aggiungere lo script Node + dipendenze (`make init`), tenendo il PHP;
2. confronto output su CSV 2024/2025 e su example (parità, vedi rischi);
3. switch del target `make anagrafica` al nuovo script;
4. rimozione di `anagrafica_da_csv.php` e del riferimento a `php:7.4-cli`;
5. runbook: riga "build vs init", modalità anonima nel §2.
Rollback: ripristino del target Makefile precedente (il PHP, finché non
rimosso al passo 4, è il backup naturale).

## Open Questions

- Il warning su squadriglie singleton (D-rischi) va in stdout o stderr?
  Dettaglio di diagnostica, decidibile in implementazione.
