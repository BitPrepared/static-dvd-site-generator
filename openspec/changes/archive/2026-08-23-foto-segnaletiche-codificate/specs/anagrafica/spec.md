## MODIFIED Requirements

### Requirement: Generazione del json squadriglie da CSV

Il comando `make anagrafica` SHALL produrre `dati/squadriglie.json`
combinando `anagrafica/elenco_ragazzi.csv` (separatore `;`, prima riga di
intestazione) con il registro dei codici delle foto segnaletiche
(`anagrafica/registro_segnaletiche.csv`), incrociati per nome, cognome e
squadriglia: per ogni squadriglia un oggetto con `name` e `members`, dove la
chiave di ogni member e' il codice del ragazzo (es. `mr1_blu`) e il valore
conserva tutti i campi del CSV. In assenza del registro (import mai
lanciato) la generazione MUST conservare il comportamento precedente:
chiavi `nomecognome` derivate da nome e cognome, cosi' che una build
d'emergenza a campo non cambi nulla. La generazione SHALL avvenire con il
runtime Node dell'immagine del generatore, senza container PHP.

#### Scenario: CSV valido in modalità reale
- **WHEN** si lancia `make anagrafica` con CSV completo e registro
  dell'import
- **THEN** `dati/squadriglie.json` contiene una squadriglia per ogni valore
  distinto della colonna `squadriglia`, con i ragazzi chiavi per codice e
  tutti i campi del CSV invariati nel valore

#### Scenario: ragazzo nel CSV senza foto importata
- **WHEN** il CSV contiene un ragazzo assente dal registro (nessuna foto)
- **THEN** il member esiste comunque nel json con i suoi campi; in
  modalita' reale la pagina non ha immagine, in modalita' anonima il
  ragazzo non appare in griglia

#### Scenario: registro assente (valvola di sicurezza)
- **WHEN** si lancia `make anagrafica` senza
  `registro_segnaletiche.csv`
- **THEN** il json mantiene le chiavi `nomecognome` come oggi e la build
  produce lo stesso sito della pipeline attuale

#### Scenario: CSV di esempio con dati finti
- **WHEN** si lancia `make anagrafica` con `elenco_ragazzi_example.csv`
  copiato come `elenco_ragazzi.csv` e l'esempio di registro
- **THEN** la generazione riesce e l'output e' confrontabile con
  `dati/squadriglie.example.json`

### Requirement: Modalita' anonima

Con `ANONIMO=1` (`make anagrafica ANONIMO=1`) il json generato SHALL
contenere per ogni squadriglia `name` e i soli codici dei ragazzi che hanno
una foto segnaletica importata: nessun nome, cognome, data di nascita,
indirizzo, contatto, username o credenziale di alcun ragazzo MUST comparire
nel file. Il sito generato a partire da questo json SHALL presentare le
pagine squadriglia con una griglia delle foto segnaletiche codificate
(thumb `<codice>`), senza pagine di singoli ragazzi ne' elenchi di nomi.
Senza registro (o senza foto importate) i members restano vuoti, come nella
pipeline precedente.

#### Scenario: json anonimo senza dati sensibili
- **WHEN** si lancia `make anagrafica ANONIMO=1` con registro
- **THEN** il contenuto di `dati/squadriglie.json` non contiene alcun valore
  delle colonne anagrafiche del CSV (nomi, contatti, credenziali) ma solo
  gli identificativi delle squadriglie e i codici dei ragazzi

#### Scenario: sito anonimo con griglia foto
- **WHEN** si esegue `make build` con il json anonimo
- **THEN** le pagine squadriglia mostrano la griglia delle foto
  segnaletiche codificate, non esistono pagine di singoli ragazzi e nessun
  nome compare nel sito

#### Scenario: anonimo senza foto importate
- **WHEN** si lancia `make anagrafica ANONIMO=1` senza registro
- **THEN** i members sono vuoti e il sito coincide con quello anonimo della
  pipeline precedente

### Requirement: Identificativo ragazzo calcolato una volta

L'identificativo di ogni ragazzo (chiave del member nel json e nome file
della pagina ragazzo in modalita' reale) SHALL essere il codice assegnato
una volta sola dall'import delle foto segnaletiche e conservato nel
registro: le rigenerazioni dell'anagrafica MUST NON cambiarlo, cosi' che
link, pagina e foto coincidano sempre anche se l'ordine o il contenuto del
CSV cambia. In assenza di registro vale l'identificativo derivato da nome e
cognome come nella pipeline precedente.

#### Scenario: cognome accentato
- **WHEN** un ragazzo ha nome o cognome con lettere accentate (es. `Però`)
- **THEN** il codice usa le iniziali in forma ASCII (es. `gp1_oro`), il file
  della pagina usa lo stesso identificativo e il link dalla pagina della
  squadriglia porta a quella pagina

#### Scenario: stabilita' al variare del CSV
- **WHEN** l'export CSV viene riesportato con ordine o righe diverse e si
  rilancia `make anagrafica`
- **THEN** i codici gia' assegnati (e quindi URL e foto) restano identici
