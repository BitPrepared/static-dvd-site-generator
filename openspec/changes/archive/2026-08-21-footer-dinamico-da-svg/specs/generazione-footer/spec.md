## Purpose

Il footer del sito (località e date del campo) diventa un asset generato
durante la build da un sorgente SVG versionato e dalle date in
`dati/campo.json`: la ricetta tipografica smette di vivere solo in chi apre
GIMP una volta l'anno e il rinnovo annuale si riduce ad aggiornare un dato;
la pipeline Metalsmith resta intoccata e un fallback garantisce il footer
anche a generatore rotto.

## ADDED Requirements

### Requirement: Ricetta tipografica codificata nel sorgente SVG

Il repository DEVE contenere un template SVG che codifica integralmente la
ricetta del footer, così come identificata dall'immagine 2023:

- font: Star Jedi Outline, file locale `scripts/star_jedi/Starjout.ttf`
  (accanto allo script di generazione, NON committato, vedi requisito di
  provenienza);
- dimensione: 42px, riempimento bianco, `letter-spacing` di -1px;
- canvas: 760×49 pixel, sfondo trasparente;
- posizionamento: il testo comincia a x=180, y=8 (bbox dell'inchiostro
  dell'originale 2023: da (180,8) a (751,38));
- testo: la località è scritta `CostigioLa` con quel preciso casing misto —
  il minuscolo attiva i glifi alternativi "piccoli" del font, il maiuscolo C
  e L quelli grandi — seguita dalle date nel formato `gg-gg/mm/aaaa`
  (es. `CostigioLa 22-26/08/2023`).

Il casing della località NON DEVE essere modificato: scriverlo tutto
maiuscolo produce glifi diversi e rompe la fedeltà visiva.

#### Scenario: template renderizzato con le date 2023

- **WHEN** il template SVG viene rasterizzato con il testo
  `CostigioLa 22-26/08/2023`
- **THEN** la PNG prodotta ha canvas 760×49 trasparente e il bbox
  dell'inchiostro coincide con quello dell'originale 2023 entro 1 pixel per
  lato

#### Scenario: template con date di un anno nuovo

- **WHEN** il template viene rasterizzato con date diverse (es.
  `21-25/08/2026`)
- **THEN** canvas, origine del testo (x=180, y=8), font, dimensione e spaziatura
  restano identici; cambia solo la parte data del testo

### Requirement: Build genera il footer direttamente in build/img/

La PNG del footer DEVE essere prodotta da `make build` stessa, come ultimo
step (a valle della pipeline Metalsmith, che resta invariata), scrivendo
`build/img/footer.png` partendo dal template SVG e dal TTF locale. Le date
del campo provengono dal dato di struttura committato `dati/campo.json`, che
le tiene separate nei campi `inizio` e `fine` (ciascuno in formato
`gg/mm/aaaa`); per il template vengono ricomposte nel formato compatto
`gg-gg/mm/aaaa`. Un target manuale `make footer DATE=...` DEVE permettere di
generare fuori dalla build per prove (con le date già in formato compatto),
con lo stesso identico meccanismo. La generazione DEVE essere deterministica:
stesse date in input producono byte identici in output. In `assets/` NON
DEVE esistere alcuna PNG del footer: assets contiene solo asset statici.

#### Scenario: build completa con footer

- **WHEN** si lancia `make build` con `dati/campo.json` che indica
  `{"inizio": "22/08/2023", "fine": "26/08/2023"}`
- **THEN** `build/img/footer.png` esiste ed è sovrapponibile all'originale
  2023 (stesso bbox dell'inchiostro; differenze ammesse solo sull'anti-aliasing
  dei bordi); gli 11 template `.hbs` che referenziano `img/footer.png` restano
  invariati e il footer appare nel sito

#### Scenario: date aggiornate per il nuovo anno

- **WHEN** si aggiorna `dati/campo.json` con le date del campo nuovo e si
  rilancia `make build`
- **THEN** il footer del sito mostra le nuove date, senza toccare immagini
  né fare opzioni manuali

#### Scenario: due generazioni con le stesse date

- **WHEN** si lancia due volte la generazione con le stesse date
- **THEN** le due PNG sono identiche byte per byte

#### Scenario: generazione manuale di prova

- **WHEN** si lancia `make footer DATE=21-25/08/2026`
- **THEN** viene generata la PNG con quelle date (stessa ricetta e self-check
  della build), senza bisogno di modificare `dati/campo.json`

### Requirement: Font scaricato da dafont durante make init, mai committato

I file TTF di Star Jedi NON DEVE essere committato nel repository. Il
download DEVE avvenire durante `make init`, subito dopo la costruzione
dell'immagine: il download gira nel container (wget + unzip già presenti
nell'immagine) e scrive **solo i file .ttf** estratti dallo zip originale
(https://www.dafont.com/star-jedi.font — zip
https://dl.dafont.com/dl/?f=star_jedi) nella posizione fissata
`scripts/star_jedi/`, accanto allo script di generazione (la cartella
`assets/` resta riservata ai soli asset del sito: viene copiata interamente
nel build e il font non deve finirvi). La cartella DEVE essere gitignorata.

Se il download fallisce (sito irraggiungibile, rete con allowlist), `make
init` DEVE comunque completare con un warning chiaro che spieghi come
riprovare con il make target dedicato (`make font`): né la build del sito né
l'immagine si bloccano per il font — in sua assenza la build usa il footer di
riserva. Il download DEVE richiedere la rete una sola volta: il font resta su
disco e le build successive funzionano senza rete.

#### Scenario: prima configurazione su una macchina nuova

- **WHEN** si lancia `make init` su un clone fresco (cartella
  `scripts/star_jedi/` assente) con rete accessibile
- **THEN** l'immagine viene costruita, poi lo zip viene scaricato da
  dl.dafont.com dentro il container e i soli file .ttf vengono estratti in
  `scripts/star_jedi/` sulla macchina host; nessun altro file dello zip
  (doc, sample, ecc.) viene salvato

#### Scenario: download fallito durante init

- **WHEN** si lancia `make init` e dl.dafont.com non è raggiungibile
- **THEN** init completa con un warning che indica `make font` come retry,
  l'immagine è funzionante e la build del sito non ne risente

#### Scenario: controllo che il font non finisca in git

- **WHEN** si lancia `git status` dopo il download del font
- **THEN** la cartella `scripts/star_jedi/` non compare tra i file
  tracciabili (gitignore attivo)

### Requirement: Fallimento isolato, fallback sempre disponibile

Se la generazione fallisce (font assente, renderer non installato, date in
formato non valido), il comando DEVE terminare con exit code non-zero e un
messaggio d'errore in italiano che indichi la causa e come rimediare. Il
fallimento NON DEVE mai lasciare una PNG parziale o corrotta: la scrittura è
atomica.

Durante `make build` lo step del footer NON DEVE mai bloccare la build: al
fallimento DEVE subentrare la PNG di riserva committata
`scripts/footer_fallback.png`, copiata come `build/img/footer.png` con un
warning evidente su stderr. A ogni generazione riuscita la riserva DEVE
essere aggiornata con la PNG appena generata (ultima buona nota), così il
fallback invecchia al massimo di una edizione del campo.

#### Scenario: renderer non disponibile durante la build

- **WHEN** si lancia `make build` e il renderer SVG non è installato
- **THEN** la pipeline del sito completa regolarmente, in `build/img/` c'è il
  footer di riserva e su stderr compare un warning che spiega come rimediare

#### Scenario: font assente

- **WHEN** si lancia la generazione senza `scripts/star_jedi/Starjout.ttf`
  (es. init con download fallito e retry non ancora fatto)
- **THEN** il comando fallisce con exit code != 0 e un messaggio che indica
  `make font` come comando per scaricarlo; in build subentra il fallback

#### Scenario: formato date errato

- **WHEN** le date passate non corrispondono al formato atteso: argomento
  fuori da `gg-gg/mm/aaaa`, oppure campo `inizio`/`fine` di
  `dati/campo.json` fuori da `gg/mm/aaaa`
- **THEN** il comando rifiuta l'input con un messaggio chiaro prima di
  toccare qualunque file

#### Scenario: range a cavallo di mesi diversi

- **WHEN** `dati/campo.json` indica `inizio` e `fine` in mesi (o anni)
  diversi (es. `28/08/2026` → `02/09/2026`)
- **THEN** il comando rifiuta l'input spiegando che il footer supporta un
  solo mese/anno (ricetta tipografica a larghezza fissa), prima di toccare
  qualunque file

#### Scenario: fine precedente a inizio nel config

- **WHEN** `dati/campo.json` indica una `fine` anteriore all'`inizio`
- **THEN** il comando rifiuta l'input con un messaggio chiaro prima di
  toccare qualunque file

#### Scenario: aggiornamento della riserva

- **WHEN** una generazione ha successo
- **THEN** `scripts/footer_fallback.png` risulta uguale alla PNG appena
  generata
