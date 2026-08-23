# foto-segnaletiche Specification

## Purpose

Import e codifica delle foto segnaletiche dei ragazzi dalla share dello staff:
ogni foto arriva come `nome_cognome_squadriglia.<ext>` (nomi reali solo nel
filename di origine), viene rinominata con il codice stabile del ragazzo e
copiata in `dvd/angolisq/materiale/reparto/`, alimentando un registro
persistente `codice <-> nome_cognome_squadriglia` che fa da ponte con
l'anagrafica CSV.

## Requirements

### Requirement: Formato obbligatorio del filename

L'import SHALL accettare solo immagini il cui nome (senza estensione) ha
almeno tre campi separati da underscore, interpretati come: primo campo =
nome, campi intermedi = cognome, ultimo campo = squadriglia. Un file che non
rispetta il formato MUST essere rifiutato con un messaggio d'errore chiaro,
senza alcuna copia.

#### Scenario: filename canonico
- **WHEN** la share contiene `mario_rossi_blu.jpg`
- **THEN** l'import lo elabora come nome `mario`, cognome `rossi`,
  squadriglia `blu`

#### Scenario: nome composto
- **WHEN** la share contiene `maria_chiara_dei_rossi_blu.jpg`
- **THEN** l'import lo elabora come nome `maria`, cognome `chiara dei rossi`,
  squadriglia `blu`

#### Scenario: file fuori formato
- **WHEN** la share contiene `IMG_1234.jpg` (solo un campo)
- **THEN** il file viene rifiutato con un messaggio che indica il formato
  atteso e nessuna foto viene copiata per quel file

### Requirement: Codifica stabile e registro persistente

L'import SHALL assegnare a ogni ragazzo un codice ASCII minuscolo
`<iniziali><progressivo>_<squadriglia>` (es. `mr1_blu`), dove le iniziali
sono le prime lettere trasliterate di nome e cognome e il progressivo conta
le identita' con le stesse iniziali *nella stessa squadriglia*. Il codice
SHALL essere assegnato una volta sola al primo import e MAI piu' cambiato:
il mapping `codice <-> nome;cognome;squadriglia` viene tenuto in
`anagrafica/registro_segnaletiche.csv` (gitignored, colonne separate da `;`)
aggiornato solo in appensione. Una identita' gia' registrata MUST riusare il
suo codice a ogni import successivo.

#### Scenario: primo ragazzo con certe iniziali in una squadriglia
- **WHEN** arriva `mario_rossi_blu.jpg` e nessun `mr*_blu` e' registrato
- **THEN** al ragazzo viene assegnato `mr1_blu`

#### Scenario: secondo ragazzo con le stesse iniziali nella stessa squadriglia
- **WHEN** dopo `mario_rossi_blu.jpg` arriva `marta_riva_blu.jpg`
- **THEN** al nuovo ragazzo viene assegnato `mr2_blu`, mentre `mr1_blu`
  resta di Mario Rossi

#### Scenario: stessa iniziale in squadriglie diverse
- **WHEN** arriva `marco_rossi_oro.jpg` dopo `mario_rossi_blu.jpg`
- **THEN** al nuovo ragazzo viene assegnato `mr1_oro`: il progressivo e'
  indipendente per squadriglia

#### Scenario: identita' accentata
- **WHEN** arriva `ginevra_pero'_oro.jpg` (o `ginevra_però_oro.jpg`)
- **THEN** il codice usa la forma ASCII delle iniziali (es. `gp1_oro`),
  stesso criterio di trasliterazione dell'anagrafica

#### Scenario: re-import della stessa identita'
- **WHEN** `mario_rossi_blu.jpg` torna sulla share (anche settimane dopo)
- **THEN** l'import riusa `mr1_blu` senza crearne uno nuovo

#### Scenario: registro mai riscritto
- **WHEN** un nuovo import aggiunge ragazzi
- **THEN** le righe gia' presenti nel registro restano identiche (solo
  appensione)

### Requirement: Copia rinominata incrementale e non distruttiva

Per ogni foto accettata l'import SHALL copiare il contenuto fedele in
`dvd/angolisq/materiale/reparto/<codice>.<ext>`. Un re-import dello stesso
ragazzo con immagine nuova MUST sovrascrivere la copia locale (last wins).
La scomparsa di una foto dalla share MUST NON cancellare la copia locale ne'
la riga di registro: l'import e' incrementale, non distruttivo, nello stesso
patto di `importa_foto.sh`.

#### Scenario: primo import
- **WHEN** l'import elabora `mario_rossi_blu.jpg`
- **THEN** esiste `dvd/angolisq/materiale/reparto/mr1_blu.jpg` con lo stesso
  contenuto dell'originale

#### Scenario: ritake
- **WHEN** una versione nuova di `mario_rossi_blu.jpg` arriva sulla share
- **THEN** `reparto/mr1_blu.jpg` viene aggiornata al nuovo contenuto

#### Scenario: foto ritirata dal remoto
- **WHEN** `mario_rossi_blu.jpg` sparisce dalla share
- **THEN** `reparto/mr1_blu.jpg` e la riga di registro restano al loro posto

#### Scenario: disco pulito dopo l'import
- **WHEN** l'import termina
- **THEN** i file creati in `reparto/` hanno nomi solo di codici: nessun nome
  o cognome compare nei filename prodotti dall'import

### Requirement: Incrocio con l'anagrafica CSV

Per ogni foto accettata l'import SHALL cercare il ragazzo nell'anagrafica
(`anagrafica/elenco_ragazzi.csv`) per nome, cognome e squadriglia. Una foto
senza corrispondenza MUST essere segnalata con un warning esplicito (tipico:
typo nel filename o ragazzo mancante nell'export) e importata comunque: la
foto resta fuori dal sito finché l'incrocio non si risolve.

#### Scenario: foto coerente con l'anagrafica
- **WHEN** `mario_rossi_blu.jpg` trova la sua riga nel CSV
- **THEN** l'import procede senza segnalazioni per quel file

#### Scenario: foto senza corrispondenza
- **WHEN** `mario_rossii_blu.jpg` (cognome sbagliato) non trova nessuna riga
- **THEN** l'import emette un warning che indica il file e il motivo, e la
  foto non compare nel sito finché filename o CSV non vengono corretti

### Requirement: Pubblicita' selettiva delle foto

Il sito generato SHALL pubblicare (thumb comprese) solo le foto segnaletiche
che corrispondono a un codice presente nel json delle squadriglie. Un file
estraneo in `reparto/` (es. un vecchio sample col nome vero nel filename)
MUST NON essere mai pubblicato e MUST essere segnalato con un warning.

#### Scenario: sample del passato sul disco
- **WHEN** la build gira con in `reparto/` un file `AlessandroPiazza.JPG`
  che non corrisponde a nessun codice
- **THEN** il file non finisce nel sito e la build segnala il file non
  riconosciuto

### Requirement: Comando e diagnostica dell'import

L'import SHALL essere invocabile con `make segnaletiche` (script dedicato
sul modello di `importa_foto.sh`, sorgente sovrascrivibile da variabile
d'ambiente). Se la sorgente manca o non e' leggibile, SHALL terminare con
exit code diverso da zero e un messaggio azionabile. Una passata senza
novita' SHALL terminare con exit 0.

#### Scenario: sorgente assente
- **WHEN** si lancia `make segnaletiche` senza la directory remota
- **THEN** il comando esce con errore indicando dove aspettarsi le foto

#### Scenario: passata senza novita'
- **WHEN** si rilancia `make segnaletiche` senza foto nuove
- **THEN** il comando esce con exit 0 dichiarando che non c'e' nulla da fare
