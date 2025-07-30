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

### Foto
Le foto vanno nella cartella `dvd/diariofotografico/materiale/foto` e devono essere nella forma "giorno/categoria" in modo da dividerle correttamente. A livello grafico vedra' solo quello configurato in `dati/categorieDiarioFotografico.json`. Il processo di build dei thumb richiede due build, la prima genera le thumb la seconda le renderizza. 

### Preparazione Foto
1. per sistemare i nomi
```
./ruota_rinomina_immagini.sh .
```
quindi `~/scripts/ruota_rinomina_immagini.sh ~/share_disks/staff/foto`
2. Per sistemare la dimensione delle foto
```
./convert_image_smp.sh 
Usage: ./convert_image_smp.sh sourceDirectory [imageLongEdge] [destinationDirectory] [UPDATE]
  Please specify sourceDirectory and destinationDirectory without trailing slash.
	DEFAULTS: imageLongEdge=1600, destinationDirectory=sourceDirectory_1600
  Typing UPDATE, will upgrade files if necessary. This will work only if destinationDirectory is specified
```
quindi `~/scripts/convert_image_smp.sh ~/share_disks/staff/foto 1600 ~/static-dvd-site-generator/dvd/diariofotografico/materiale/foto/ UPDATE`

# Clean
Per pulire la build `make clean`.

## Cambi index.js principale 
Per rimuovere la immagine docker di base basta `make init`. Se si vuole cancellare l'immagine `make clean-docker`. 

# Debug
Per attivare il debug basta nel Makefile settare DEBUG a True

