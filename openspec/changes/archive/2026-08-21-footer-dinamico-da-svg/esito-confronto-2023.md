# Esito confronto fedeltà — rigenerazione 22-26/08/2023 (task 4.1)

Confronto tra l'originale GIMP 2023 (`assets/img/footer_orig.png`, backup
byte-identico del footer storico) e la rigenerazione resvg
(`scripts/genera_footer.js "22-26/08/2023"`).

## Bbox dell'inchiostro (alpha > 128)

| | left | top | right | bottom | larghezza | altezza |
|---|---|---|---|---|---|---|
| Originale GIMP | 179 | 8 | 750 | 38 | 572 | 31 |
| Rigenerata resvg | 180 | 8 | 751 | 37 | 572 | 30 |

Entro ±1px per lato ✓ — larghezza identica (572px) ✓

## Sovrapposizione

- IoU binarizzato con allineamento ottimale: **0.767** (threshold 100/96),
  0.705 a threshold simmetrico 128/128 — coerente con il pilota
  dell'esplorazione (0.767): il rendering è stabile.
- Differenze residue concentrate sull'anti-aliasing dei bordi (rasterizer
  GIMP/cairo vs resvg), invisibili a dimensione reale.

## Immagini

- `confronto_2023.png` — originale vs rigenerata su fondo nero (1:1)
- `diff_2023_3x.png` — overlay a 3x (grigio = match, verde = solo originale,
  blu = solo rigenerata)

## Nota di implementazione (regressione trovata e corretta)

Prima versione: il segnaposto `{{DATE}}` compariva anche nel commento del
template e `String.replace` (una sola occorrenza) sostituiva quello, non il
testo → render largo 385px. Corretto con `replaceAll` + segnaposto rimosso
dal commento + self-check sulla larghezza attesa (540-620px) + test di
regressione nella harness (`larghezza inchiostro 2023 ~572`).

Esito: **fedeltà verificata, requisito della spec soddisfatto** (bbox entro
±1px, differenze solo su AA dei bordi come da Non-Goal del design).
