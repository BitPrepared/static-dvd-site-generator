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
                 # serve SOLO se cambiano le dipendenze npm o
                 # l'orchestratore (static-dvd-site-generator/):
                 # script, dati e template sono montati come volume,
                 # per tutto il resto basta make build

Smoke test della pipeline:

    cp dati/squadriglie.example.json dati/squadriglie.json
    make build

Test rapidi (nel container: `make bash`, poi):
`node --test anagrafica/ dvd/angolisq/`

Nota permessi: con podman i mount usano `:U` → tutta la cartella della repo
deve essere di proprietà dell'utente che lancia `make` (niente build da root
su cartelle di altri utenti).

## 2. Pre-campo

1. Metti l'elenco ragazzi dell'anno in `anagrafica/elenco_ragazzi.csv`
   (mai in git: vedi §5; per una prova copia `elenco_ragazzi_example.csv`,
   dati finti)
2. `make anagrafica` → genera `dati/squadriglie.json` in modalità reale
   (squadriglie ricavate dal CSV, tutti i campi dei ragazzi)
   `make anagrafica ANONIMO=1` → json anonimo: solo i nomi delle
   squadriglie e, se è presente il registro dei codici, gli identificativi
   di chi ha una foto segnaletica (riferimento:
   `dati/squadriglie.example-anonima.json`). Il sito generato mantiene
   le pagine squadriglia con foto, urlo e hike ma nessuna scheda ragazzo:
   si può condividere senza dati dei ragazzi.
   Per una prova con le foto codificate copia anche
   `anagrafica/registro_segnaletiche_example.csv` come
   `anagrafica/registro_segnaletiche.csv` (dati finti).
3. Aggiorna i dati dell'anno: `dati/categorieDiarioFotografico.json`
   (giorni e categorie del diario) e i `dati/materiale*.json`
4. Prepara le pagine di contenuto `dvd/*/src/*.hbs`

## 3. Durante il campo (il quotidiano)

Le foto arrivano dalla directory condivisa dello staff
(default `~/share_disks/staff/foto`, sovrascrivibile con `FOTO_SRC=`).
Un solo comando fa tutto: rotazione/rinomina con lo script esterno
(prerequisito fuori repo: viene cercato come `ruota_rinomina_immagini.sh`,
nome sul server, oppure `autoRuotaImmagini.sh`, nome in locale, in
`~/scripts`, `~/Scripts`, `~/script` o `~/Script`; percorso forzabile con
`RUOTA_SCRIPT=`) e copia fedele 1:1
che mantiene la struttura `giorno/categoria`. Incrementale: copia solo le
foto nuove o modificate, non cancella mai nulla. Vengono prese solo le
immagini (default: jpg jpeg png gif bmp tif tiff webp heic heif, si amplia
o restringe con `FOTO_ESTENSIONI=`): readme e file vari della share restano
fuori e le cartelle senza immagini non vengono nemmeno create.

    make foto

Import continuo mentre le foto arrivano (controllo ogni 5 minuti,
`Ctrl-C` per fermare):

    make foto-watch                       # oppure: make foto-watch WATCH_INTERVAL=60

Le foto vanno in `dvd/diariofotografico/materiale/foto/giorno/categoria`.
Il sito mostra solo le categorie configurate in
`dati/categorieDiarioFotografico.json`. Se serve il ridimensionamento a
1600px resta disponibile il vecchio passaggio manuale:
`~/scripts/convert_image_smp.sh <sorgente> 1600 dvd/diariofotografico/materiale/foto/ UPDATE`.

Test rapidi dell'import: `bash scripts/test_importa_foto.sh`.

### Foto segnaletiche codificate (`make segnaletiche`)

Le foto segnaletiche arrivano sulla share dello staff (default
`~/share_disks/staff/segnaletiche`, sovrascrivibile con `SEGNALETICHE_SRC=`)
con filename **obbligatorio**:

    nome_cognome_squadriglia.<ext>      # es. mario_rossi_blu.jpg

primo campo = nome, campi intermedi = cognome, ultimo = squadriglia (minimo
3 campi separati da `_`). Un file fuori formato (es. `IMG_1234.jpg`) viene
rifiutato con un messaggio che mostra il formato atteso: niente import
silenziosi. A ogni ragazzo l'import assegna **una volta sola** un codice
stabile `<iniziali><progressivo>_<squadriglia>` (es. `mr1_blu`), copia la
foto rinominata in `dvd/angolisq/materiale/reparto/<codice>.<ext>` e aggiorna
il registro `anagrafica/registro_segnaletiche.csv` (gitignored, vedi sotto).

    make segnaletiche

Incrementale e non distruttivo, lo stesso patto di `make foto`:

- un **re-import** della stessa persona riusa il suo codice (nessuna riga
  doppia nel registro);
- un **ritake** (foto rifatta e rimessa sulla share) sovrascrive la copia
  locale: last wins;
- una foto **ritirata** dalla share non cancella né la copia in `reparto/`
  né la riga di registro;
- l'incrocio con l'anagrafica (`elenco_ragazzi.csv`, per nome+cognome+
  squadriglia) è silenzioso quando torna; in caso di mismatch arriva un
  warning con il file coinvolto ma l'import comunque si completa.

Correggere un mismatch: tipicamente è un typo nel filename (`mario_rossii_blu`)
o un ragazzo mancante nell'export CSV. Si sistema la causa (filename sulla
share oppure export CSV); se era stato creato un codice sbagliato, si
rimuovono la copia in `reparto/` e la relativa riga dal registro con un
editor di testo, poi si rilancia l'import: il ragazzo riparte con il codice
giusto. Test rapidi: `bash scripts/test_importa_segnaletiche.sh`.

Dopo l'import la catena è sempre:

    make segnaletiche && make anagrafica && make build

In modalità anonima (`make anagrafica ANONIMO=1`) le pagine squadriglia
mostrano la griglia delle foto segnaletiche per **codice**: nessun nome, URL
e filename parlano la lingua dei codici. In modalità reale i contenuti restano
quelli del CSV; anche lì URL e foto usano il codice, non il nome.

#### Il registro dei codici (`anagrafica/registro_segnaletiche.csv`)

Il registro rende eterno il legame "codice = ragazzo": colonne
`nome;cognome;squadriglia;codice`, una riga per ragazzo, scritta dall'import
solo in appensione.

- **Sopravvive** a `make clean` e alle build: i target lo leggono, solo
  l'import lo scrive.
- **Non viaggia in git** (contiene nomi veri, come il CSV): va sincronizzato
  via rsync/scp fra le macchine di fiducia ESATTAMENTE come
  `elenco_ragazzi.csv`.
- **Non è rigenerabile a posteriori**: se lo si perde, un re-import riassegna
  i progressivi secondo l'ordine delle foto presenti, con codici
  potenzialmente diversi (cambiano URL, pagine e nomi dei file). Backup
  insieme al CSV.
- Le correzioni a mano sono previste e sicure: si modifica una riga con un
  editor, si rilancia `make anagrafica`.

    make build    # una sola volta: i thumb delle foto sono attesi
                  # prima del rendering, il sito esce completo

Se la generazione di un'anteprima fallisce (immagine corrotta,
ImageMagick/Gm assente) la build si ferma subito: exit code 1, errore
reale della libreria immagini e file coinvolto. Niente build "riuscita"
con anteprime mancanti scoperte a sito aperto.

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

### 4.1 Update della toolchain (solo post-campo)

Base image, dipendenze npm e simili si toccano SOLO a campo concluso,
un passo per volta. Prima di ogni update si salva il riferimento:

    make build && make golden-salva

e dopo OGNI passo (base image, bump npm, rimozioni):

    make build && make golden-confronta    # exit 0 = sito identico

Lo snapshot sta in `golden/` (gitignored: contiene l'elenco di tutto il
sito generato). Se una differenza è voluta, rigenera lo snapshot con
`make golden-salva`. Dettagli nell'intestazione di `scripts/golden.js`.

## 5. Privacy — regole non negoziabili

Foto (`dvd/*/materiale`), pagine di contenuto (`dvd/*/src`),
anagrafica (`dati/squadriglie.json`, `anagrafica/*.csv/xls/xlsx/ods`)
sono gitignored PER SCELTA — unica eccezione `elenco_ragazzi_example.csv`,
dati finti di prova: dati di minori mai in git, mai in release,
mai su servizi esterni. Si muovono solo via scp/rsync fra le macchine
di fiducia. A fine stagione archivia i dati anagrafici fuori dalle
cartelle git.
