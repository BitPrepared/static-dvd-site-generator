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
   squadriglie, `members` vuoti (riferimento:
   `dati/squadriglie.example-anonima.json`). Il sito generato mantiene
   le pagine squadriglia con foto, urlo e hike ma nessuna scheda ragazzo:
   si può condividere senza dati dei ragazzi.
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

## 5. Privacy — regole non negoziabili

Foto (`dvd/*/materiale`), pagine di contenuto (`dvd/*/src`),
anagrafica (`dati/squadriglie.json`, `anagrafica/*.csv/xls/xlsx/ods`)
sono gitignored PER SCELTA — unica eccezione `elenco_ragazzi_example.csv`,
dati finti di prova: dati di minori mai in git, mai in release,
mai su servizi esterni. Si muovono solo via scp/rsync fra le macchine
di fiducia. A fine stagione archivia i dati anagrafici fuori dalle
cartelle git.
