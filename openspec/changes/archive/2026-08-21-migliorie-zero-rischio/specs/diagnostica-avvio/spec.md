## Purpose

La diagnostica di avvio garantisce che chi lancia la build del sito riceva
messaggi chiari e azionabili quando i dati obbligatori mancano, e che l'output
della build non esponga informazioni di ambiente non necessarie.

## ADDED Requirements

### Requirement: Errore azionabile su dati obbligatori mancanti

All'avvio, se un file di dati obbligatorio (in particolare
`dati/squadriglie.json`) non esiste, il generatore DEVE terminare
immediatamente con codice non-zero e un messaggio in italiano, su una sola
schermata, che indichi: il file mancante, il comando per rigenerarlo
(`make anagrafica`) e l'alternativa per i test (copiare
`dati/squadriglie.example.json`). Il messaggio NON DEVE contenere uno stack
trace del runtime.

#### Scenario: squadriglie.json assente

- **WHEN** si lancia la build senza `dati/squadriglie.json`
- **THEN** il generatore termina con codice non-zero stampando un messaggio
  che cita il file mancante, suggerisce `make anagrafica` e la copia
  dell'example, senza stack trace

#### Scenario: dati tutti presenti

- **WHEN** si lancia la build con tutti i file di dati obbligari presenti
- **THEN** il comportamento della build resta invariato rispetto allo stato
  attuale (nessun nuovo messaggio, nessun'interruzione)

### Requirement: Output di build senza dati di ambiente

L'output della build NON DEVE includere il contenuto delle variabili d'ambiente
del processo (dump di `process.env` o equivalente).

#### Scenario: build con ambiente popolato

- **WHEN** la build viene lanciata in un container con variabili d'ambiente
  impostate (es. `DEBUG=False`)
- **THEN** l'output standard non contiene né il nome né il valore delle
  variabili d'ambiente del processo
