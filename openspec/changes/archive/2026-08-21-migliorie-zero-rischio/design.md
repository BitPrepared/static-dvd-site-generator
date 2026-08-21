## Context

Il generatore legge sette file JSON obbligativi in testa a
`static-dvd-site-generator/index.js` (righe 19-25) con `fs.readJsonSync`
sincrono: se uno manca, Node interrompe con stack trace criptico. L'output di
build include inoltre un dump di `process.env` (riga 127) residuo di debug.
Il Readme.md descrive comandi errati e workflow non riproducibili da chi non
ha gli script foto sulle proprie macchine. Vincolo: siamo a campo 2026 in
corso, la pipeline non si tocca.

## Goals / Non-Goals

**Goals:**
- Messaggio d'errore unico, in italiano, azionabile, per qualunque JSON
  obbligatorio mancante (non solo `squadriglie.json`)
- Output di build pulito da dati di ambiente
- Readme trasformato in runbook annuale riproducibile

**Non-Goals:**
- Refactor della pipeline di generazione (post-campo)
- Validazione dei contenuti dei JSON (solo presenza/leggibilità)
- Portare `ruota_rinomina_immagini.sh` e `convert_image_smp.sh` dentro il
  repo: nel runbook restano documentati come prerequisiti esterni (backlog)
- CI/smoke test (change separato, post-campo)

## Decisions

### 1. Guardia centralizzata sui JSON obbligatori

Un'unica funzione all'inizio di `index.js` (es. `leggiDatiObbligatori`) che
legge i sette JSON in un loop con elenco `{percorso, come rigenerarlo}`; al
primo file mancante/illeggibile stampa il messaggio azionabile (comando
`make anagrafica` dove pertinente, percorso example per i test) ed esce con
`process.exit(1)`.

*Alternative scartate:* try/catch attorno ai singoli readJsonSync (sette
messaggi da mantenere, stesso risultato); lasciare il crash e filtrare lo
stack via Makefile (fragile, nasconde errori veri).

### 2. Rimozione secca del dump environment

`console.log(process.env)` si elimina senza sostituirlo: nessun caso d'uso
noto, il flag DEBUG esistente copre già la diagnostica utile.

### 3. Readme come runbook a flusso, non a comando

Struttura: setup macchina (docker/podman con tabella EXECUTOR) → pre-campo
(anagrafica) → durante il campo (foto → script → build, inclusa la spiegazione
della doppia build per i thumb) → fine campo (cosa committare, cosa archiviare)
→ regole privacy. Gli script foto esterni vengono documentati con percorso
tipico `~/scripts/` ed etichettati esplicitamente come non nel repo.

## Risks / Trade-offs

- [Il messaggio copre solo l'assenza, non JSON malformati con schema errato]
  → Accettato: lo scenario malformato è già coperto da errore di parse leggibile
  di jsonfile; la validazione semantica è backlog post-campo.
- [Runbook scritto ad agosto rischia di diventare stale] → Mitigazione: le
  sezioni seguono le fasi del campo (riviste naturalmente ogni anno durante
  l'uso) e ogni comando nel runbook è verificato su blackhole in questi giorni.

## Open Questions

Nessuna bloccante. Il contenuto testuale dettagliato del runbook si definisce
in discussione con lo staff e si concretizza in fase di apply.

## Appendice — Contenuto runbook approvato (fonte per il task 2.2)

Approvato dallo staff con queste decisioni: apertura del sito con comando
generico (niente riferimento a `qutebrowser`); tag + release GitHub confermati
come chiusura standard a fine/post campo; script di preparazione foto
documentati come prerequisiti esterni, non inclusi nel repo.

````markdown
# DVD del Campo — Runbook annuale

Generatore del sito del Campo di Competenza Informatica e Tecniche Scout.
Il sito nasce durante il campo: foto e materiali arrivano ogni giorno e la
build deve funzionare la sera stessa.

## 1. Setup macchina (una volta)

Requisiti: docker **o** podman, make, bash.

    git clone git@github.com:BitPrepared/static-dvd-site-generator.git
    cd static-dvd-site-generator

Con docker è tutto default. Con podman: `export EXECUTOR=podman`
(nel .bashrc, o `make EXECUTOR=podman ...` ogni volta).

    make init    # costruisce l'immagine con il tuo uid/gid
                 # (compatibile podman rootless --userns=keep-id)

Smoke test della pipeline:

    cp dati/squadriglie.example.json dati/squadriglie.json
    make build

Nota permessi: con podman i mount usano `:U` → tutta la cartella della repo
deve essere di proprietà dell'utente che lancia `make` (niente build da root
su cartelle di altri utenti).

## 2. Pre-campo

1. Metti l'elenco ragazzi dell'anno in `anagrafica/elenco_ragazzi.csv`
   (mai in git: vedi §5)
2. `make anagrafica` → genera `dati/squadriglie.json`
3. Aggiorna i dati dell'anno: `dati/categorieDiarioFotografico.json`
   (giorni e categorie del diario) e i `dati/materiale*.json`
4. Prepara le pagine di contenuto `dvd/*/src/*.hbs`

## 3. Durante il campo (il quotidiano)

Le foto arrivano dalla directory condivisa dello staff. Preparazione
(script di preparazione, prerequisito esterno in `~/scripts/`, non nel repo):

    ~/scripts/ruota_rinomina_immagini.sh ~/share_disks/staff/foto
    ~/scripts/convert_image_smp.sh ~/share_disks/staff/foto 1600 \
        ~/.../dvd/diariofotografico/materiale/foto/ UPDATE

Le foto vanno in `dvd/diariofotografico/materiale/foto/giorno/categoria`.
Il sito mostra solo le categorie configurate in
`dati/categorieDiarioFotografico.json`.

    make build
    make build    # sì, due volte: la prima genera i thumb, la seconda
                  # li renderizza nelle pagine
                  # ⚠ limite noto, da evolvere (backlog post-campo)

Per l'output verboso: `DEBUG=True` nel Makefile (o `make DEBUG=True build`).

## 4. Fine campo

1. Verifica finale del sito (apri `build/index.html` nel browser)
2. Committa codice e `dati/*.json` (il `git status` ti mostra i soli
   tracciati), push, tag `v<anno>` + release GitHub a fine/post campo
   (solo sorgenti: mai allegati con foto)
3. Distribuzione: copia `build/` su chiavetta USB (sito statico,
   parte da `index.html`)
4. Archivia il materiale dell'anno (foto/video) dove archivi di norma:
   in git non va mai

## 5. Privacy — regole non negoziabili

Foto (`dvd/*/materiale`), pagine di contenuto (`dvd/*/src`),
anagrafica (`dati/squadriglie.json`, `anagrafica/*.csv/xls/xlsx/ods`)
sono gitignored PER SCELTA: dati di minori mai in git, mai in release,
mai su servizi esterni. Si muovono solo via scp/rsync fra le macchine
di fiducia. A fine stagione archivia i dati anagrafici fuori dalle
cartelle git.
````

Nota per l'apply: l'appendice è la fonte del task 2.2; la stesura definitiva
del `Readme.md` può ritoccare la forma ma non le decisioni prese (browser
generico, tag+release a fine campo, script esterni, doppia build marcata
come limite noto).

