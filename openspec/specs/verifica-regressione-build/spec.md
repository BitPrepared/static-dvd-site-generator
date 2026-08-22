# verifica-regressione-build Specification

## Purpose

Fornisce una verifica di regressione ("golden build") che cattura uno
snapshot dell'output della build e lo riconfronta dopo un cambio di
toolchain, così l'equivalenza del sito generato è un fatto meccanico e non
un giudizio a occhio. Nata col bump conservativo post-campo 2026
(node:18-bullseye → node:24-bookworm, bump npm), resta il meccanismo di
riferimento per gli update annuali della toolchain.

## Requirements

### Requirement: Cattura dello snapshot della build

Il progetto DEVE offrire un comando (`make golden-salva`) che, dopo una
build riuscita, salvi un manifest dell'output corrente: elenco dei percorsi
relativi dei file generati più hash del contenuto di ciascuno. Il manifest
DEVE essere scritto in una directory dedicata fuori dall'output del sito.

#### Scenario: snapshot dopo build

- **WHEN** esiste una build completata in `build/` e si lancia
  `make golden-salva`
- **THEN** viene creato/aggiornato il manifest nella directory dedicata e
  il comando termina con codice zero

#### Scenario: snapshot senza build precedente

- **WHEN** si lancia `make golden-salva` senza una build precedente valida
- **THEN** il comando termina con codice non-zero stampando un messaggio in
  italiano che indica di lanciare prima `make build`

### Requirement: Confronto meccanico con esito chiaro

Il progetto DEVE offrire un comando (`make golden-confronta`) che confronti
l'output attuale con l'ultimo snapshot salvato: terminare con codice zero se
identici; con codice non-zero altrimenti, stampando un report in italiano su
una sola schermata che distingua file mancanti, file inattesi e file con
contenuto divergente.

#### Scenario: output identico

- **WHEN** l'output attuale coincide con lo snapshot per ogni file
- **THEN** `make golden-confronta` termina con codice zero confermando
  l'equivalenza

#### Scenario: differenza reale

- **WHEN** almeno un file risulta mancante, inatteso o con hash diverso
- **THEN** il comando termina con codice non-zero e il report elenca ogni
  file problematico con la sua categoria (mancante/inatteso/divergente)

#### Scenario: snapshot assente

- **WHEN** si lancia `make golden-confronta` senza uno snapshot salvato
- **THEN** il comando termina con codice non-zero suggerendo in italiano
  `make golden-salva`

### Requirement: Nessun falso positivo da contenuto volatile

L'output contiene parti legittimamente variabili a parità di input (es. le
date del campo nel footer generate da `dati/campo.json`, eventuali
timestamp). Il confronto DEVE trattarle in modo esplicito — tramite un
elenco di esclusioni/normalizzazioni documentato — cosicché due build
consecutive dello stesso input producano sempre esito positivo.

#### Scenario: due build consecutive dello stesso input

- **WHEN** si lanciano due `make build` ravvicinate senza modifiche
  all'input e poi `make golden-salva` + `make golden-confronta`
- **THEN** il confronto termina con codice zero (nessun falso positivo)

#### Scenario: modifica reale di contenuto

- **WHEN** tra snapshot e confronto cambia davvero il contenuto generato di
  una pagina (non una parte volatile)
- **THEN** il confronto segnala quel file come divergente

### Requirement: Verifica isolata dalla pipeline e dalla privacy

La verifica DEVE restare un tool ausiliario separato: NON DEVE essere
invocata da `make build`, NON DEVE modificare l'output del sito, e lo
snapshot — che contiene materiale dei ragazzi — DEVE restare escluso da git
come il resto del contenuto generato.

#### Scenario: la build normale non cambia

- **WHEN** si usa `make golden-salva` o `make golden-confronta`
- **THEN** il contenuto di `build/` resta identico e `make build` si
  comporta come sempre

#### Scenario: snapshot fuori da git

- **WHEN** lo snapshot viene salvato
- **THEN** `git status` non mostra nulla di nuovo da committare (directory
  coperta da gitignore)
