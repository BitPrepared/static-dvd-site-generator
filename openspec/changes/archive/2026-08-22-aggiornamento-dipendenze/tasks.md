# Task — Aggiornamento dipendenze

> ESECUZIONE SOLO A CAMPO CONCLUSO 2026 (nessun passo prima di settembre).
> Ogni gruppo termina con `make golden-confronta` verde prima di proporre il
> commit all'utente (committa sempre l'utente, mai l'agente).

## 1. Rete di sicurezza: golden build (sulla toolchain attuale)

- [x] 1.1 Scrivere PRIMA il test fallente `scripts/test_golden.js` (node:test, stile `anagrafica/genera_anagrafica.test.js`): con una directory di fixture verifica che la modalità `salva` produca il manifest (percorsi relativi + hash SHA-256, immagini presence-only) e che `confronta` dia exit 0 su output identico, non-zero con report su file divergente/extra/mancante. Verifica: `node --test scripts/test_golden.js` fallisce perché `scripts/golden.js` non esiste
- [x] 1.2 Implementare `scripts/golden.js` (solo moduli built-in: fs, crypto): modalità `salva`/`confronta`, esclusioni/normalizzazioni dichiarate nel manifest, messaggi in italiano su una schermata, exit code secondo la spec. Verifica: `node --test scripts/test_golden.js` verde
- [x] 1.3 Aggiungere i target `golden-salva`/`golden-confronta` al Makefile (check-executor, script montato a volume come `footer`) e la voce gitignore per `golden/`. Verifica: `make build && make golden-salva && make golden-confronta` → exit 0; seconda `make build` + confronto → exit 0 (scenario "due build consecutive"); `git status` non mostra nulla in `golden/`

## 2. Baseline pre-update

- [x] 2.1 Con la toolchain attuale (node:18.2.0-bullseye): `make init`, `make build`, `make golden-salva`. Verifica: manifest baseline salvato; rilanciando `make build` + `make golden-confronta` l'esito resta verde *(percorso equivalente per assenza container in sandbox: baseline dal `build/` committato della vecchia toolchain + riproduzione indipendente dell'output con le dipendenze nuove su host; l'utente ha poi confermato nel container node24 il confronto verde 4392/4392)*

## 3. Base image (design D1/D2)

- [x] 3.1 Dockerfile: `FROM node:24-bookworm` (pacchetti apt invariati); Makefile `VERSION=bookworm`; `engines` → `node >=24 <25`, `npm >=10`. Verifica: `make init` riuscita, `make build` completa, `make golden-confronta` verde *(verificato dall'utente sulla macchina di build: init+build verdi, confronto 4392/4392 identico; warning DEP0060 notato e documentato in design.md)*
- [x] 3.2 Verifica runtime duale: ripetere `make build` con `EXECUTOR=podman` (se presente) e controllare uid/gid dei file generati. Verifica: build verde con entrambi gli executor, `make golden-confronta` verde, nessun file di proprietà root in `build/` *(verificato dall'utente su podman: init+build verdi, `find build -user root` vuoto)*

## 4. Bump npm conservativo (design D3/D4)

- [x] 4.1 Aggiornare `static-dvd-site-generator/package.json` alla regola D3 (ultima CJS-compatibile della major: chalk 4, rimraf 3, fs-extra 11, shelljs 0.8, handlebars 4.7, metalsmith 2.x latest, moment 2.30, resto ultima della major corrente) e dichiarare `multimatch`+`debug` alle versioni risolte nel lockfile attuale; `npm install` nel container. Verifica: `npm ls` senza conflitti, `make build` completa, `make golden-confronta` verde *(eseguita su host node20/npm10 per assenza container: `npm ls` pulito, pipeline completa, confronto 4392/4392 identico; conferma finale su node24 col runbook)*
- [x] 4.2 Rimuovere le dipendenze zombie `co`, `co-prompt`, `process-env`, `mkdirp`, `metalsmith-handlebars`; `npm install` nel container. Verifica: nessun `require` residuo nel repo, `make build` completa, `make golden-confronta` verde *(stessa modalità dell'4.1)*

## 5. Chiusura

- [x] 5.1 Doppia build di conferma e allineamento documentazione (Readme.md, AlberoDvd.md, commenti) dove citano node 18/bullseye/npm 8. Verifica: `grep -ri "node.*18\|bullseye" Readme.md AlberoDvd.md` senza residui non aggiornati; `make build` + `make golden-confronta` verdi per la terza volta consecutiva *(doc senza residui + §4.1 runbook aggiunta; verdi su host sandbox e nel container dell'utente)*
- [x] 5.2 Proporre all'utente i commit per passo (baseline, golden build, base image, bump npm, rimozione zombie, doc). Verifica: l'utente ha committato; `git log` mostra un commit per passo; nessun commit fatto dall'agente *(scelta dell'utente: UN commit unico della versione finale invece dei quattro proposti — `81f28cc aggiornamento versioni`, 8 file +662/−131, unito in master con PR #10; autore Stefano Tamagnini, nessun commit agente)*
