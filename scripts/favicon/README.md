# Favicon — costigiola.bitprepared.it

Cipresso stilizzato monocromatico su tile arrotondato. Due varianti complete:

- **variante del sito** (tile nero #111111, albero bianco) → `assets/img/favicon/`
- **inverted/** (qui accanto allo script: tile bianco, albero nero) — riserva
  per fondi chiari, non viene pubblicata

## Generazione

    python3 generate.py   # richiede Pillow

La variante nera viene scritta direttamente in `../../assets/img/favicon/`,
`inverted/` e `preview.png` qui accanto allo script. L'SVG usa la stessa
funzione di profilo della chioma dei PNG, quindi vettoriale e bitmap sono
coerenti.

Nessuno step di build da ricordarsi: `metalsmith-assets` copia tutto
`assets/` nella root della build, quindi il kit arriva da solo in
`build/img/favicon/` a ogni `make build`.

## Kit del sito (assets/img/favicon/)

| File | Uso |
|---|---|
| `favicon.svg` | Browser moderni (nitido a qualsiasi DPI) |
| `favicon.ico` | Fallback multi-risoluzione 16/32/48 |
| `favicon-16x16.png`, `favicon-32x32.png` | PNG classici |
| `apple-touch-icon.png` | iOS/iPadOS (tile pieno: iOS arrotonda da solo) |
| `android-chrome-192x192.png`, `android-chrome-512x512.png` | Android / PWA |
| `site.webmanifest` | Manifest per icone Android |
| `icon-black-transparent.png` | Solo l'albero nero su trasparente, per header chiari |

I link sono già nel `<head>` di `static-dvd-site-generator/layouts/base.html`
(con prefisso `{{rootPath}}`, così funzionano anche dalle pagine annidate)
e in `partials/common-meta.html`.

## Snippet per il `<head>`

```html
<link rel="icon" href="{{rootPath}}img/favicon/favicon.svg" type="image/svg+xml">
<link rel="icon" href="{{rootPath}}img/favicon/favicon.ico" sizes="48x48">
<link rel="apple-touch-icon" href="{{rootPath}}img/favicon/apple-touch-icon.png">
<link rel="manifest" href="{{rootPath}}img/favicon/site.webmanifest">
<meta name="theme-color" content="#111111">
```

`preview.png` mostra il risultato grande e ingrandito 4× a 64/32/16 px su
sfondo chiaro e scuro.
