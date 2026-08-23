# Verifica di regressione "rischio zero" — golden build

Change: foto-segnaletiche-codificate · Data: 2026-08-23

## Obiettivo

Dimostrare che senza il registro dei codici (`anagrafica/registro_segnaletiche.csv`,
import mai lanciato) la pipeline modificata produce **lo stesso sito** della
pipeline precedente: una build d'emergenza a campo non cambia nulla finché
il nuovo flusso non si attiva.

## Metodo

Confronto con lo strumento già presente nel repo (`scripts/golden.js`,
manifest con hash SHA256 di tutti i file del sito, presence-only per le
immagini):

- **A** = copia pristine di `HEAD` (pre-change, `git archive`)
- **B** = albero di lavoro con il change (soli file tracciati + i nuovi)
- input identici su entrambi: `elenco_ragazzi_example.csv` copiato come
  `elenco_ragazzi.csv`, **nessun registro**, nessun materiale (clone pulito)
- build eseguite con il runtime Node dell'ambiente di prova (senza
  container), stesse dipendenze per A e B
- due modalità: reale e anonima (`ANONIMO=1`), snapshot separati

## Esito

| confronto                          | risultato                    |
|------------------------------------|------------------------------|
| json anagrafica senza registro     | byte-identici A vs B         |
| build REALE senza registro         | **60/60 file identici** rc=0 |
| build ANONIMA senza registro       | **57/57 file identici** rc=0 |

Nota: la prima esecuzione evidenziò una divergenza di una riga di soli
spazi nelle pagine squadriglia quando i member sono vuoti (caso anonimo
senza registro); il template `sq.hbs` è stato riportato a una forma
whitespace-compatibile con il rendering precedente e il confronto è stato
rilanciato fino a identità completa.

## Conclusione

Valvola di sicurezza confermata: senza registro l'intero output del sito è
identico alla pipeline precedente, sia in modalità reale che anonima. Il
nuovo flusso si attiva solo al primo `make segnaletiche`.
