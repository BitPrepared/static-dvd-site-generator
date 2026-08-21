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
