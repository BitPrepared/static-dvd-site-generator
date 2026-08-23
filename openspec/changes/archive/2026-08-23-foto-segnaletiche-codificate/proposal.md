## Why

La modalità anonima attuale è binaria: o i ragazzi compaiono con tutti i dati
(nomi nei filename, nelle URL e nelle pagine) o scompaiono del tutto, foto
segnaletiche comprese. Per il DVD condivisibile serve la via di mezzo: tenere
le foto segnaletiche — l'anima visiva delle pagine squadriglia — senza esporre
nomi e contatti. Oggi non è possibile perché l'identità del ragazzo coincide
col suo nome reale ovunque: chiave del member nel json, nome file della pagina
e della foto.

## What Changes

- Nuovo comando di import delle foto segnaletiche dalla share staff
  (`make segnaletiche`): legge i file nel formato obbligatorio
  `nome_cognome_squadriglia.<ext>`, assegna a ogni ragazzo un codice stabile
  `<iniziali><progressivo>_<squadriglia>` (es. `mr1_blu`), copia la foto
  rinominata in `dvd/angolisq/materiale/reparto/` e aggiorna il registro
  persistente `codice <-> nome_cognome_squadriglia`
  (`anagrafica/registro_segnaletiche.csv`, gitignored).
- **BREAKING** La chiave dei member in `dati/squadriglie.json` passa da
  `nomecognome` (es. `mariorossi`) al codice (es. `mr1_blu`): cambiano di
  conseguenza nome file e URL delle pagine ragazzo, non i loro contenuti.
- `make anagrafica` incrocia registro e CSV completo: i member conservano
  tutti i campi CSV (la modalità reale resta invariata nei contenuti: nomi
  veri, contatti, indirizzi) ma sono chiavi col codice.
- Modalità anonima: il json contiene i soli codici (non più `members` vuoti)
  e la pagina squadriglia mostra una griglia di foto segnaletiche codificate,
  senza pagine individuali né elenchi di nomi.
- File senza il formato riconosciuto (es. `IMG_1234.jpg`) rifiutati
  all'import con messaggio chiaro; foto in `reparto/` senza corrispondenza
  nel json mai pubblicate, solo segnalate (protegge anche dai vecchi sample
  con nomi reali ancora sul disco).
- Nessuna migrazione delle foto d'esempio esistenti (formato vecchio,
  due soli campi): ripartenza pulita al primo import.

## Capabilities

### New Capabilities

- `foto-segnaletiche`: import e codifica delle foto segnaletiche dalla share
  staff — formato filename obbligatorio, assegnazione stabile dei codici,
  registro persistente, incrocio con l'anagrafica CSV, copia rinominata in
  `reparto/`.

### Modified Capabilities

- `anagrafica`: la chiave dei member diventa il codice assegnato all'import
  (invece dell'id derivato da nome+cognome); la modalità anonima produce i
  soli codici (per la griglia foto) invece di members vuoti; la pagina
  ragazzo in modalità reale usa il codice come nome file mantenendo i
  contenuti reali.

## Impact

- `scripts/importa_segnaletiche.sh` (nuovo, sul modello di `importa_foto.sh`)
  e target `make segnaletiche` nel Makefile.
- `anagrafica/genera_anagrafica.js` (+ test): join CSV-registro, chiavi codice.
- `dvd/angolisq/index.js` e template `sq.hbs` / `squadrigliere.hbs`: griglia
  anonima, gestione foto mancante, filename da codice (il generatore usa già
  la chiave del member come filename: cambiata la chiave si allinea da sé).
- Fixture aggiornate al nuovo formato: `dati/squadriglie.example.json`,
  `dati/squadriglie.example-anonima.json`, esempi CSV in `anagrafica/`.
- `Readme.md` (§3): runbook dell'import segnaletiche.
- Privacy: i nomi reali vivono solo nei file già gitignored (CSV anagrafico e
  registro); disco post-import e sito pubblicato contengono solo codici.

## Rischio per la build a campo

Medio-basso, contenuto da una valvola di sicurezza: finché il registro dei
codici non esiste, la pipeline conserva il comportamento attuale (chiavi
`nomecognome`), quindi una build d'emergenza a campo non cambia nulla se
l'import non è mai stato lanciato; il nuovo flusso si attiva solo al primo
import. Le thumb già generate restano valide; le nuove nascono al primo
`make build` post-import e sono attese in serie come oggi. L'import è
incrementale e non distruttivo, stesso patto di `importa_foto.sh`.
