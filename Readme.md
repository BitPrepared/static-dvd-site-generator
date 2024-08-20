# Installazione

## Requirements

 - docker 
 - bash 

## Creazione Enviroment
dare `make init` per creare l'ambiente di base.

# Config
per generare l'anagrafica una volta posizionato il file `elenco_ragazzi.csv` nella directory anagrafica , lanciare il `make anagrafica`.

# Test
Per fare dei test esiste gia un file generato che si chiama `dati/squadriglie.example.json` basta rinominarlo in `dati/squadriglie.json`.

# Build 
Per generare il dvd nella cartella dvd basta dare `make` o `make build`.

# Clean
Per rimuovere la immagine docker di base basta `make clean-docker`. Per pulire la build `make clean`.