## Purpose

Le anteprime (thumb) delle foto usate dalle pagine del sito vengono generate
durante la build in modo completo e diagnosticabile: una sola build produce
il sito finito e un fallimento si presenta con il suo errore reale.

## ADDED Requirements

### Requirement: Thumb pronti in una sola build

La generazione dei thumb SHALL completarsi prima che la build della sezione
prosegua verso la fase di rendering: alla prima `make build` con materiale
nuovo (thumb assenti) il sito in `build/` MUST già contenere le pagine con
le anteprime corrette. I thumb già presenti su disco MUST NON essere
rigenerati.

#### Scenario: prima build con foto senza thumb
- **WHEN** arriva materiale nuovo (foto senza `thumb_*` corrispondenti) e si
  lancia una singola `make build`
- **THEN** i thumb vengono generati e le pagine generate nella stessa
  esecuzione li referenziano correttamente

#### Scenario: build successiva senza materiale nuovo
- **WHEN** si rilancia la build senza nuove foto
- **THEN** i thumb esistenti non vengono rigenerati e la build produce lo
  stesso output

### Requirement: Fallimento thumb visibile e diagnosticabile

Se la generazione di un thumb fallisce (es. tool di elaborazione immagini
non disponibile o file corrotto), la build SHALL terminare con exit code
diverso da zero, riportando su stderr l'errore reale della libreria di
elaborazione e il percorso del file che l'ha causato. La build MUST NON
crashare con errori indiretti (riferimenti a logger non definiti) e MUST
NON completare "con successo" lasciando thumb mancanti.

#### Scenario: tool di elaborazione immagini rotto
- **WHEN** la generazione di un thumb fallisce per un errore della
  libreria di immagini
- **THEN** la build termina con exit code != 0, il messaggio riporta
  l'errore originale e il file coinvolto, e nessun crash su riferimenti
  interni lo sostituisce

#### Scenario: file immagine corrotto
- **WHEN** una foto del materiale è corrotta o illeggibile
- **THEN** la build fallisce indicando quel file, senza fermarsi in
  silenzio su thumb mancanti
