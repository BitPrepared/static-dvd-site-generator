# Proposal: footer dinamico da SVG

## Why

Il footer del sito contiene cementate nel raster la località e le date del
campo ("CostigioLa 22-26/08/2023"): ogni anno va rifatto a mano in GIMP e la
ricetta (font, dimensione, spaziatura, caso misto dei glifi) vive solo nella
testa di chi l'ha fatto. Il campo 2026 è già alle porte e l'immagine dice
ancora 2023. Salvando la ricetta in un SVG sorgente e facendo generare la
PNG direttamente dalla build, il rinnovo annuale diventa: aggiornare le date
in un dato di struttura.

## What Changes

- Nuovo sorgente `scripts/footer_template.svg`: template con font, testo,
  dimensione, spaziatura e posizionamento esatti del footer (la "spec
  visiva"), accanto allo script e ai font di generazione.
- `make build` **genera il footer direttamente in `build/img/footer.png`**
  (step nel Makefile dopo la pipeline Metalsmith: script Node con renderer
  `@resvg/resvg-js`, font caricato dal file TTF locale). Override manuale per
  prove con `make footer DATE=...`.
- **Nessuna PNG del footer in `assets/`**: `assets/img/footer.png` esce dal
  repo (assets = solo asset statici copiati integralmente nel sito). Un PNG
  di riserva committato `scripts/footer_fallback.png` (fuori da assets) viene
  usato se la generazione fallisce, così il sito ha sempre un footer; a ogni
  generazione riuscita la riserva viene aggiornata con l'ultima buona.
- Le date del campo vivono nel dato di struttura committato
  `dati/campo.json`: build le legge da lì.
- **Il font NON entra in git**: i TTF di Star Jedi si scaricano da dafont
  (pagina https://www.dafont.com/star-jedi.font, zip
  https://dl.dafont.com/dl/?f=star_jedi) ed estraendo **solo i file .ttf** in
  `scripts/star_jedi/`. Il download avviene **durante `make init`**, dopo la
  build dell'immagine: gira nel container (wget + unzip già nell'immagine) e
  scrive sull'host via montaggio; se fallisce, init prosegue con un warning e
  resta il retry `make font`. Lo script di generazione verifica la presenza
  del font e altrimenti stampa l'istruzione di download.

Nessuna modifica ai template `.hbs` (l'`<img>` resta uguale) e nessuna
modifica alla pipeline Metalsmith: lo step del footer è nel Makefile, a valle.

## Capabilities

### New Capabilities

- `generazione-footer`: generazione riproducibile del footer durante la build
  in `build/img/footer.png` da sorgente SVG + `dati/campo.json`; requisiti su
  ricetta tipografica, fallback e verifica di fedeltà.

### Modified Capabilities

(nessuna: `generazione-thumb`, `anagrafica` e `diagnostica-avvio` non cambiano)

## Impact

- **File nuovi**: `scripts/footer_template.svg`, `scripts/genera_footer.js`,
  `scripts/footer_fallback.png` (risorsa nostra, seed dall'originale 2023),
  `dati/campo.json`, step nel target `build` + target `font`/`footer` nel
  Makefile, voce `.gitignore` per `scripts/star_jedi/`.
- **File rimossi**: `assets/img/footer.png` (e il backup temporaneo
  `assets/img/footer_orig.png`): nessuna PNG del footer più in assets.
- **Dipendenze**: `@resvg/resvg-js` nel generatore (binario precompilato
  linux x64, compatibile con node:18-bullseye); richiede un `make init` una
  tantum **prima del campo**. Download font: rete richiesta una sola volta.
- **Rischio per la build a campo**: **basso** (era "zero" con la PNG
  committata; la linearità richiesta vale il cambio). Lo step footer è a
  valle della pipeline Metalsmith e NON la blocca mai: se la generazione
  fallisce, subentra il fallback committato e la build prosegue con un
  warning. Il sito resta comunque completo di footer. Il font scaricato non
  viaggia in git (scelta deliberata: niente asset di terzi nel repo).
