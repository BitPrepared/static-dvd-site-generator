## 1. Pulizia e fixture

- [x] 1.1 Archiviare le foto sample attuali di `dvd/angolisq/materiale/reparto/` (formato vecchio, contenuto del passato) in una cartella fuori dalla pipeline; verificare che `reparto/` resti senza file non codificati prima del primo import
- [x] 1.2 Aggiornare `anagrafica/elenco_ragazzi_example.csv` se necessario e creare `anagrafica/registro_segnaletiche_example.csv`: righe di fantasia per gli STESSI ragazzi finti dell'example CSV (es. `pippo;zoo;oro;pz1_oro`, colonne `nome;cognome;squadriglia;codice`) — nessun dato reale, il registro vero lo genera l'import; eccezione esplicita nel .gitignore come da requirement "Dati di esempio tracciati"; verificare con `git status --porcelain` che i file reali restino ignorati
- [x] 1.3 Rigenerare `dati/squadriglie.example.json` (chiavi codice, campi CSV completi) e `dati/squadriglie.example-anonima.json` (soli codici); verificare che il generatore li legga senza errori (`cp` + `make anagrafica` su clone pulito)

## 2. Import delle foto segnaletiche

- [x] 2.1 Creare `scripts/importa_segnaletiche.sh`: scansione sorgente (variabile d'ambiente sovrascrivibile, default share staff), filtro estensioni come `importa_foto.sh`, parsing filename (primo campo nome, ultimo squadriglia, mezzo cognome, minimo 3 campi) con rifiuto rumoroso dei file fuori formato; verificare con `bash scripts/test_importa_segnaletiche.sh`
- [x] 2.2 Codifica stabile `mr1_blu` (iniziali trasliterate ASCII, progressivo per squadriglia+iniziali) con registro `anagrafica/registro_segnaletiche.csv` in sola appensione; verificare gli scenari della delta spec: primo arrivo, secondo `mr*_blu` -> `mr2_blu`, stessa iniziale in altra sq -> `mr1_oro`, re-import riusa il codice, righe esistenti intoccate
- [x] 2.3 Copia rinominata in `dvd/angolisq/materiale/reparto/<codice>.<ext>`: incrementale (solo nuove/modificate), ritake sovrascrive (last wins), foto rimossa dal remoto non cancella la copia locale; verificare col test bash (passata doppia + rimozione lato sorgente)
- [x] 2.4 Incrocio con `elenco_ragazzi.csv` per nome+cognome+squadriglia: match silenzioso, mismatch -> warning esplicito con file e motivo, import comunque completato (exit 0 se solo warning); verificare col test bash su CSV con un ragazzo in meno
- [x] 2.5 Target `make segnaletiche` nel Makefile (runtime host/container come `make foto`) e gestione errori: sorgente assente -> exit != 0 con messaggio azionabile, passata vuota -> exit 0; verificare con `make segnaletiche` su directory finte
- [x] 2.6 Estendere `scripts/test_importa_segnaletiche.sh` fino a coprire tutti gli scenari del requirement "Comando e diagnostica dell'import"; verificare lanciandolo e controllando exit code

## 3. Anagrafica a chiave codice

- [x] 3.1 Estendere `anagrafica/genera_anagrafica.js`: lettura registro, join CSV-registro per nome+cognome+squadriglia, members chiavi per codice con tutti i campi CSV, ragazzo nel CSV senza foto -> member senza foto; verificare con nuovi casi in `genera_anagrafica.test.js`
- [x] 3.2 Valvola di sicurezza: registro assente -> chiavi legacy `nomecognome` (comportamento attuale invariato), warning per righe di registro senza corrispondenza nel CSV; verificare col test dedicato e confrontando l'output json senza registro con quello attuale
- [x] 3.3 Modalità anonima: `ANONIMO=1` emette per ogni squadriglia i soli codici con foto importata (`{"mr1_blu": {}}`), nessun valore anagrafico; verificare col test e con grep anti-dati sul json prodotto dall'example

## 4. Griglia e pagine in AngoliSq

- [x] 4.1 Griglia foto nella pagina squadriglia (`sq.hbs` + `dvd/angolisq/index.js`): iterazione sui codici verso `thumb_<codice>`, generata anche quando i members non hanno campo `nome`; pagina individuale generata solo se il member ha `nome` (modalità reale, URL `<codice>.html`); verificare con build di prova usando le fixture example (anonima e reale)
- [x] 4.2 Thumb pubblicate solo per i codici noti al json: `creaThumbCartella` filtrata sull'elenco atteso, file estranei in `reparto/` -> warning e nessuna pubblicazione; verificare mettendo un file finto `AlessandroPiazza.JPG` accanto alle fixture e controllando build output e sito generato
- [x] 4.3 Gestione ragazzo senza foto: modalità reale -> pagina senza immagine senza errori, anonimo -> assente dalla griglia; verificare togliendo una foto dalle fixture di prova e rilanciando la build

## 5. Documentazione e regressione

- [x] 5.1 Readme §3: runbook `make segnaletiche` (formato filename obbligatorio, ritake, foto ritirate), correzione manuale guidata del registro per i mismatch, catena import -> anagrafica -> build; sezione dedicata al ciclo di vita del registro: sopravvive a `make clean` e alle build (sola lettura), NON viaggia in git, va sincronizzato/rsync-ato fra macchine come il CSV e non è rigenerabile a posteriori (re-import = progressivi potenzialmente diversi); verificare rileggendo il flusso descritto contro gli script effettivi
- [x] 5.2 Verifica di regressione "rischio zero": clone pulito senza registro -> `make anagrafica` (+ `ANONIMO=1`) e `make build` con output equivalente alla pipeline attuale; usare il confronto golden già presente (`scripts/golden.js`) e documentare l'esito
- [x] 5.3 Smoke end-to-end con dati finti: share di prova -> `make segnaletiche` -> `make anagrafica` -> `make build`, controllo manuale del sito (griglia anonima coi codici, pagine reali con nomi nei contenuti e codici negli URL, zero nomi veri nei filename pubblicati)
