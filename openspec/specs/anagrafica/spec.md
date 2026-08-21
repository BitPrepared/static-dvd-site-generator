# anagrafica Specification

## Purpose

Generazione di `dati/squadriglie.json` a partire dal CSV dell'anagrafica
(`anagrafica/elenco_ragazzi.csv`): stessa pipeline in Node, con una modalità
anonima che produce un json senza alcun dato dei ragazzi.

## Requirements

### Requirement: Generazione del json squadriglie da CSV

Il comando `make anagrafica` SHALL produrre `dati/squadriglie.json` a partire
da `anagrafica/elenco_ragazzi.csv` (separatore `;`, prima riga di intestazione),
con lo stesso formato atteso dal generatore: per ogni squadriglia un oggetto
con `name` e `members`, dove ogni member conserva tutti i campi del CSV.
La generazione SHALL avvenire con il runtime Node dell'immagine del
generatore, senza container PHP.

#### Scenario: CSV valido in modalità reale
- **WHEN** si lancia `make anagrafica` con un CSV completo di ragazzi
- **THEN** `dati/squadriglie.json` contiene una squadriglia per ogni valore
  distinto della colonna `squadriglia`, con tutti i ragazzi nei rispettivi
  `members` e i campi del CSV invariati

#### Scenario: CSV di esempio con dati finti
- **WHEN** si lancia `make anagrafica` con `elenco_ragazzi_example.csv`
  copiato come `elenco_ragazzi.csv`
- **THEN** la generazione riesce e l'output è confrontabile con
  `dati/squadriglie.example.json`

### Requirement: Modalità anonima

Con `ANONIMO=1` (`make anagrafica ANONIMO=1`) il json generato SHALL contenere
per ogni squadriglia solo `name` e `members: {}`: nessun nome, cognome, data
di nascita, indirizzo, contatto, username o credenziale di alcun ragazzo
MUST comparire nel file. Il sito generato a partire da questo json SHALL
presentare le pagine squadriglia (foto, urlo, hike) senza schede ragazzo né
elenchi di nomi.

#### Scenario: json anonimo senza dati sensibili
- **WHEN** si lancia `make anagrafica ANONIMO=1`
- **THEN** il contenuto di `dati/squadriglie.json` non contiene alcun valore
  delle colonne anagrafiche del CSV (nomi, contatti, credenziali) ma solo gli
  identificativi delle squadriglie

#### Scenario: sito anonimo navigabile
- **WHEN** si esegue `make build` con il json anonimo
- **THEN** le pagine squadriglia esistono con foto, urlo e hike, non esistono
  pagine di singoli ragazzi e la lista nomi nelle pagine squadriglia è vuota

### Requirement: Squadriglie ricavate dal CSV

L'elenco delle squadriglie SHALL essere derivato dai valori distinti della
colonna `squadriglia` del CSV (nell'ordine di prima apparizione), non da un
elenco fisso nello script.

#### Scenario: squadriglia con nome nuovo
- **WHEN** il CSV contiene una squadriglia mai vista (es. `falchi`)
- **THEN** il json include `falchi` senza alcuna modifica al codice

### Requirement: Identificativo ragazzo calcolato una volta

L'identificativo di ogni ragazzo (chiave del member nel json) SHALL essere
calcolato una volta sola, in forma ASCII minuscola senza spazi né apostrofi,
e la pagina del ragazzo generata dal sito MUST usare quell'identificativo
come nome file, così che link e pagina coincidano sempre.

#### Scenario: cognome accentato
- **WHEN** un ragazzo ha nome o cognome con lettere accentate (es. `Però`)
- **THEN** la chiave del member nel json è la forma ASCII (es. `pero`),
  il file della pagina usa lo stesso identificativo e il link dalla pagina
  della squadriglia porta a quella pagina

### Requirement: Diagnostica errori di input

Se il CSV manca, non è leggibile o non contiene le colonne attese, la
generazione SHALL terminare con exit code diverso da zero e un messaggio
d'errore azionabile su stderr (nello stile della diagnostica di avvio del
generatore), senza scrivere un `squadriglie.json` parziale.

#### Scenario: CSV assente
- **WHEN** si lancia `make anagrafica` senza `anagrafica/elenco_ragazzi.csv`
- **THEN** il comando esce con errore e un messaggio che indica il file
  atteso e dove mettere l'elenco dei ragazzi

#### Scenario: colonna obbligatoria mancante
- **WHEN** il CSV non ha la colonna `squadriglia` (o `nome`/`cognome`)
- **THEN** il comando esce con errore indicando la colonna mancante, senza
  scrivere il json

### Requirement: Dati di esempio tracciati

Il repository SHALL includere dati di esempio finti per la generazione:
`anagrafica/elenco_ragazzi_example.csv` (oggi gitignorato da `*.csv`) e un
json di riferimento della modalità anonima, mantenuti nel gitignore come
eccezioni esplicite. Nessun dato reale di ragazzi MUST mai essere tracciato.

#### Scenario: clone pulito e smoke test
- **WHEN** si clona il repo e si copia l'example come CSV di lavoro
- **THEN** `make anagrafica` e `make anagrafica ANONIMO=1` funzionano senza
  alcun dato reale
