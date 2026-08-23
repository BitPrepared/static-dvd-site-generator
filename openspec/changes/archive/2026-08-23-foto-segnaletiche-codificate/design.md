## Context

Oggi l'identità del ragazzo coincide col suo nome reale in ogni artefatto:
chiave del member in `dati/squadriglie.json` (`mariorossi`, calcolata da
`idRagazzo()` a ogni generazione), filename della pagina (`mariorossi.html`)
e della foto segnaletica (`reparto/mariorossi.jpg`). La modalità anonima
(`ANONIMO=1`) svuota i members e fa sparire tutto, foto comprese. La
motivazione del cambio è nella proposal (§ Why); qui si decide come.

Vincoli che plasmano le scelte: dati di minori mai in git (CSV e materiale
già gitignored), build eseguibili la sera stessa durante il campo, runtime
Node dell'immagine del generatore, convenzione degli script bash
incrementali e non distruttivi (`importa_foto.sh`).

## Goals / Non-Goals

**Goals:**

- Foto segnaletiche presenti nel sito sia anonimo che reale, sempre
  identificative per codice, mai per nome.
- Codici stabili nel tempo: URL e foto non cambiano quando il CSV cambia.
- Un solo formato di ingresso per le foto (`nome_cognome_squadriglia.<ext>`),
  validato all'import.
- Valvola di sicurezza: senza import la pipeline produce esattamente il sito
  di oggi (rischio zero a campo finché non si attiva il nuovo flusso).

**Non-Goals:**

- Nessuna migrazione delle foto sample già in `reparto/` (formato vecchio,
  contenuto del passato): si archivia e riparte puliti.
- Nessuna versione intermedia "solo interna" coi nomi veri nei filename:
  le due modalità si differenziano solo per contenuti (reale) vs griglia
  (anonimo), non per schema di denominazione.
- Niente cifratura/offuscamento oltre al codice: il DVD mostra i volti,
  il codice serve alla navigazione non alla protezione crittografica.

## Decisions

### D1 — Codice `<iniziali><progressivo>_<squadriglia>`, progressivo per squadriglia

Es. `mr1_blu`, `mr2_blu`, `mr1_oro`. Il progressivo conta le identità con le
stesse iniziali *dentro la stessa squadriglia*: collisioni rare e campo di
slittamento minimo. Alternativa scartata: progressivo globale (codici meno
legibili, slittamenti che attraversano le squadriglie). Alternativa
scartata: squadriglia come cartella (`reparto/blu/mr1.jpg`) — separa la
foto dal codice e obbliga il template a ricomporre il percorso; il suffisso
tiene insieme codice e file. Minuscolo ASCII ovunque, coerente con
`idRagazzo()` e con i nomi squadriglia già minuscoli nel json.

### D2 — Registro persistente in appensione, non derivazione dal CSV

Il mapping `codice <-> nome;cognome;squadriglia` vive in
`anagrafica/registro_segnaletiche.csv` (gitignored, stesso regime del CSV
anagrafico), scritto dall'import **solo in appensione**. È l'unica scelta
che rende "mr1 è sempre Mario" un invariante: qualunque derivazione
dall'ordine (nel CSV o nell'arrivo delle foto) slitta al primo inserimento.
L'alternativa senza registro richiederebbe di ricostruire il mapping da
filename codificati che per costruzione non contengono più il nome:
impossibile. Il registro resta un CSV a colonne `;` leggibile e
correggibile a mano: se lo staff corregge una squadriglia nel CSV, si
sistema la riga di registro con un editor, non con una migrazione.

Nota: col registro l'import non "popola l'anagrafica" ma la *incrocia*: il
CSV completo resta la fonte dei dati, il registro fa da ponte sulle
identità (delta spec `anagrafica`, requirement "Generazione del json
squadriglie da CSV").

### D3 — Codifica all'import (opzione A)

La rinomina avviene una volta sola, al passaggio dalla share: dopo l'import
il disco locale non ha filename con nomi reali prodotti dal nuovo flusso.
Alternativa scartata (traduzione alla build): avrebbe lasciato per sempre
nomi veri nei filename di `reparto/`, con un solo punto di filtro tra loro
e il sito pubblicato. L'import è idempotente grazie a D2: ri-presentando la
stessa identità si ritrova il proprio codice; un ritake sovrascrive la copia
(last wins); una foto ritirata dal remoto non cancella nulla.

### D4 — Parsing: primo campo = nome, ultimo = squadriglia, mezzo = cognome

Regola minima che assorbe i nomi composti (`maria_chiara_dei_rossi_blu`) e
non richiede convenzioni nuove allo staff: il formato è quello che hanno
già detto di usare. Meno di tre campi = rifiuto rumoroso con messaggio che
mostra il formato atteso (niente import silenziosi di `IMG_1234.jpg`).
Trasliterazione accentate/apostrofi riusata da `idRagazzo()` (una sola
implementazione del concetto "ASCII minuscolo").

### D5 — Script dedicato `scripts/importa_segnaletiche.sh` + `make segnaletiche`

Stesso patto operativo di `importa_foto.sh` (incrementale, non distruttivo,
diagnostica azionabile, sorgente sovrascrivibile da variabile d'ambiente,
test rapidi bash). Alternativa scartata: una modalità di `importa_foto.sh`
— contratti troppo diversi (categorie/giorni vs identità/codifica) e rischio
di regressioni sul comando che gira ogni giorno a campo.

### D6 — Json: chiavi codice, griglia senza pagine quando non c'è `nome`

In modalità reale i members restano come oggi (tutti i campi CSV, nomi veri
nei contenuti) ma chiavi per codice: il generatore usa già la chiave del
member come filename (`dvd/angolisq/index.js:106`), quindi pagine e link si
allineano da soli. In modalità anonima il json porta i soli codici
(`{"mr1_blu": {}}`): la pagina squadriglia costruisce la griglia iterando
le chiavi verso `thumb_<codice>`; la pagina individuale viene generata solo
se il member ha il campo `nome` — criterio unico, senza flag aggiuntivi,
compatibile con il comportamento attuale (members vuoti ⇒ né griglia né
pagine).

### D7 — Pubblicità selettiva delle thumb in AngoliSq

`creaThumbCartella` oggi genera thumb di *tutto* quanto in `reparto/`. Con
il cambio genera solo per i codici noti al json e segnala (warning) i file
non riconosciuti senza pubblicarli: protegge dai vecchi sample con nomi
reali rimasti sul disco e da qualsiasi file estraneo futuro. La foto
mancante per un ragazzo del CSV (member senza foto) non è un errore: pagina
senza immagine in reale, assenza dalla griglia in anonimo.

## Risks / Trade-offs

- [Il progressivo dipende dall'ordine di arrivo all'import] → il registro in
  appensione (D2) congela l'assegnazione alla prima volta; nessun percorso
  di codice riassegna numeri esistenti.
- [Filename con typo → foto fuori sito] → warning esplicito all'incrocio con
  il CSV; la foto resta in `reparto/` ma non pubblicata finché non si
  corregge il filename (o il CSV) e si rilancia import + anagrafica + build.
- [Registro e CSV possono divergere (es. squadriglia corretta a mano)]
  → warning all'incrocio anche per i ragazzi del registro assenti dal CSV;
  il registro è testo leggibile: la correzione è una modifica manuale guidata
  dal messaggio, documentata nel Readme.
- [Registro perso o mai sincronizzato (fresh clone, git clean -fdx)]
  → resiste a tutto il normale ciclo di build (`make clean` tocca solo
  `build/`, i target lo leggono senza riscriverlo); NON viaggia in git perché
  contiene nomi reali: segue il regime del CSV (rsync/scp fra macchine di
  fiducia). Non è rigenerabile a posteriori: un re-import dopo perdita
  riassegna i progressivi secondo l'ordine di scansione, con codici
  potenzialmente diversi → il runbook deve indicarlo tra i file da
  sincronizzare e da presidiare (backup insieme al CSV).
- [Vecchi sample con nomi veri ancora in `reparto/`] → pulizia una-tantum
  prima del primo import (archiviazione, task dedicato); comunque coperti da
  D7 anche se qualcuno li rimette.
- [Rischio per la build a campo] → medio-basso: finché `registro_segnaletiche.csv`
  non esiste, `make anagrafica` e `make build` producono l'output di oggi
  (valvola D4/D6 del delta spec anagrafica). Il nuovo flusso si attiva solo
  al primo `make segnaletiche`; rollback = rimuovere il registro.

## Migration Plan

1. Archiviare le foto sample attuali in `reparto/` (contenuto del passato,
   formato vecchio): nessuna migrazione al nuovo schema.
2. Atterrare codice e fixture; verificare su clone pulito che senza registro
   `make anagrafica` (+ `ANONIMO=1`) e `make build` siano byte-a-byte come
   oggi (golden build di regressione già presente nel repo).
3. Popolare la share staff con le foto nel formato nuovo, lanciare
   `make segnaletiche`, sistemare gli eventuali warning di incrocio.
4. `make anagrafica`, `make build`: controllo del sito (griglia anonima,
   pagine reali coi codici negli URL).
5. Rollback: cancellare `registro_segnaletiche.csv` e tornare alle chiavi
   legacy; le foto rinominate restano ma non vengono pubblicate (D7) finché
   non si re-importa.

## Open Questions

Nessuna: le scelte residue (caption col codice tal quale, estensioni
accettate = stesso set di `importa_foto.sh`) sono state decise in
esplorazione e sono riflesse nelle scenario delle delta spec.
