IMAGE_NAME="bitprepared/dvd-site-generator"
VERSION=bookworm
# runtime container: autodetect (docker, altrimenti podman), sovrascrivibile
# da ambiente o riga di comando: EXECUTOR=podman make build
ifeq ($(origin EXECUTOR),undefined)
EXECUTOR := $(shell if command -v docker >/dev/null 2>&1; then echo docker; elif command -v podman >/dev/null 2>&1; then echo podman; fi)
endif
ifeq ($(EXECUTOR),podman)
MOUNT_OPTION = :U
USERNS_OPTION = --userns=keep-id
else
MOUNT_OPTION =
USERNS_OPTION =
endif
DEBUG=False
# 1 = anagrafica anonima: solo i nomi delle squadriglie, nessun dato ragazzo
# nel json (make anagrafica ANONIMO=1)
ANONIMO ?= 0

.PHONY: help build clean anagrafica font footer golden-salva golden-confronta check-executor foto foto-watch segnaletiche reset

# aiuto: elenco dei comandi disponibili, estratto dai commenti ## accanto a
# ogni target (primo target del file: anche un "make" nudo mostra l'aiuto)
help:
	@echo "DVD del Campo — comandi disponibili:"
	@grep -E '^[a-zA-Z][a-zA-Z0-9_-]*:.*## ' $(MAKEFILE_LIST) | awk -F' ## ' '{ sub(/:.*/, "", $$1); printf "  make %-17s %s\n", $$1, $$2 }'
	@echo ""
	@echo "Variabili utili: EXECUTOR=docker|podman  ANONIMO=1  DEBUG=True  FOTO_SRC=...  SEGNALETICHE_SRC=..."
	@echo "Dettagli e flussi completi: Readme.md"

# primo controllo di ogni target che usa il container: runtime presente?
check-executor:
	@test -n "$(EXECUTOR)" || { echo "Nessun runtime container trovato (docker o podman)." >&2; echo "Installane uno, oppure forza con: make <target> EXECUTOR=/percorso/del/runtime" >&2; exit 1; }
	@echo "runtime container: $(EXECUTOR)"

# build: footer + pipeline nell'unica run container. Il footer si genera
# PRIMA della pipeline (metalsmith ha clean(false) e il footer non sta negli
# assets: nulla lo sovrascrive), così "Build finished!" resta l'ultimo
# messaggio. Lo step footer e' fail-soft (change footer-dinamico-da-svg):
# se fallisce subentra la riserva committita', se fallisce la pipeline la
# build fallisce come sempre
build: check-executor ## genera il sito completo in build/ (footer + pipeline)
	${EXECUTOR} run --rm -i $(USERNS_OPTION) -v "${PWD}/dvd:/usr/src/app/dvd$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -v "${PWD}/lib:/usr/src/app/lib$(MOUNT_OPTION)" -v "${PWD}/assets:/usr/src/app/assets$(MOUNT_OPTION)" -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" -v "${PWD}/scripts:/usr/src/app/scripts$(MOUNT_OPTION)" -e DEBUG=$(DEBUG) -t $(IMAGE_NAME):$(VERSION) bash -c '{ node scripts/genera_footer.js || { echo "WARNING: generazione footer fallita, uso la riserva scripts/footer_fallback.png" >&2; mkdir -p build/img; cp scripts/footer_fallback.png build/img/footer.png; } } && npm run build'

bash: check-executor ## shell interattiva nel container del generatore
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint /bin/bash -v "${PWD}/dvd:/usr/src/app/dvd$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -v "${PWD}/lib:/usr/src/app/lib$(MOUNT_OPTION)" -v "${PWD}/assets:/usr/src/app/assets$(MOUNT_OPTION)" -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" -t $(IMAGE_NAME):$(VERSION)

init: check-executor ## costruisce l'immagine container col tuo uid/gid (serve solo se cambiano le dipendenze npm)
	${EXECUTOR} build --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .
	@# download del font del footer (change footer-dinamico-da-svg): fail-soft,
	@# per il resto del sito non serve; retry dedicato con: make font
	@$(MAKE) --no-print-directory font || echo "WARNING: download del font fallito (dl.dafont.com). retry: make font — la build del sito NON ne dipende"

# font: scarica i TTF di Star Jedi da dafont e li estrae in scripts/star_jedi/
# (solo i .ttf, niente doc/sample). Il font non va committato (gitignore) e
# assets/ resta per i soli asset del sito: il download gira nel container
# (wget+unzip nell'immagine) e scrive sull'host via montaggio.
# Se dl.dafont.com blocca il download automatico: scaricare lo zip dal browser
# (https://www.dafont.com/star-jedi.font) e usare: make font ZIP=percorso/star_jedi.zip
DAFONT_STAR_JEDI=https://dl.dafont.com/dl/?f=star_jedi
ZIP ?=

font: check-executor ## scarica i TTF Star Jedi per il footer (ZIP=... se dafont blocca)
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint /bin/bash \
	  -v "${PWD}/scripts:/usr/src/app/scripts$(MOUNT_OPTION)" \
	  $(if $(ZIP),-v "$(ZIP):/tmp/star_jedi.zip:ro",) \
	  -t $(IMAGE_NAME):$(VERSION) -c \
	  'set -e; mkdir -p /usr/src/app/scripts/star_jedi; \
	   if [ -z "$(ZIP)" ]; then wget -q --user-agent="Mozilla/5.0 (X11; Linux x86_64)" -O /tmp/star_jedi.zip "$(DAFONT_STAR_JEDI)"; fi; \
	   unzip -o -j /tmp/star_jedi.zip "*.[tT][tT][fF]" -d /usr/src/app/scripts/star_jedi/; \
	   ls /usr/src/app/scripts/star_jedi/'

# footer: genera build/img/footer.png dal template SVG + date del campo
# (change footer-dinamico-da-svg). La build lo chiama da sola leggendo
# dati/campo.json; DATE=... serve solo per le prove manuali:
#   make footer DATE="22-26/08/2023"
DATE ?=

footer: check-executor ## rigenera build/img/footer.png dal template SVG (DATE=... per le prove)
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint node \
	  -v "${PWD}/scripts:/usr/src/app/scripts$(MOUNT_OPTION)" \
	  -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" \
	  -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" \
	  -w /usr/src/app -t $(IMAGE_NAME):$(VERSION) scripts/genera_footer.js $(if $(DATE),"$(DATE)",)

# golden build (change aggiornamento-dipendenze, spec verifica-regressione-build):
# snapshot/confronto dell'output per verificare che un cambio di toolchain
# produca lo stesso sito. Tool ausiliario FUORI dal percorso di make build;
# script montato a volume come footer/anagrafica (modifiche live senza make
# init). Lo snapshot va in golden/ (gitignored: contiene l'elenco di tutto
# il sito generato, materiale ragazzi compreso). Uso:
#   make golden-salva      dopo una build di riferimento
#   make golden-confronta  dopo ogni passo di update
GOLDEN_MANIFEST=golden/manifest.json

golden-salva: check-executor ## salva lo snapshot golden dell'output corrente
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint node \
	  -v "${PWD}/scripts:/usr/src/app/scripts$(MOUNT_OPTION)" \
	  -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" \
	  -v "${PWD}/golden:/usr/src/app/golden$(MOUNT_OPTION)" \
	  -w /usr/src/app -t $(IMAGE_NAME):$(VERSION) scripts/golden.js salva build $(GOLDEN_MANIFEST)

golden-confronta: check-executor ## confronta l'output con lo snapshot golden (exit 0 = identico)
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint node \
	  -v "${PWD}/scripts:/usr/src/app/scripts$(MOUNT_OPTION)" \
	  -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" \
	  -v "${PWD}/golden:/usr/src/app/golden$(MOUNT_OPTION)" \
	  -w /usr/src/app -t $(IMAGE_NAME):$(VERSION) scripts/golden.js confronta build $(GOLDEN_MANIFEST)

# anagrafica: gira nell'immagine del generatore (Node), script montato come
# volume: modifiche live senza rifare make init (serve solo se cambiano le
# dipendenze npm in static-dvd-site-generator/package.json).
ANAGRAFICA_SCRIPT=anagrafica/genera_anagrafica.js

anagrafica: check-executor ## genera dati/squadriglie.json dal CSV (+ ANONIMO=1 per la versione anonima)
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint node -v "${PWD}/anagrafica:/usr/src/app/anagrafica$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -w /usr/src/app -e ANONIMO=$(ANONIMO) -t $(IMAGE_NAME):$(VERSION) $(ANAGRAFICA_SCRIPT)

clean-docker: check-executor ## rimuove immagine e cache buildx del runtime container
	${EXECUTOR} buildx prune
	${EXECUTOR} rmi $(IMAGE_NAME)
	${EXECUTOR} rmi $(IMAGE_NAME):$(VERSION)

clean: ## svuota la cartella build/
	rm -rf build
	mkdir build

open: ## apre build/index.html nel browser (qutebrowser)
	qutebrowser file://${PWD}/build/index.html

# foto: importa le foto dello staff dalla share (Readme.md §3): rotazione/
# rinomina con lo script esterno + copia fedele in
# dvd/diariofotografico/materiale/foto/giorno/categoria. Incrementale: solo
# le foto nuove o modificate. Gira sull'host, NON usa il container.
# Lo script di rotazione ha nomi diversi fra le macchine (server:
# ruota_rinomina_immagini.sh, locale: autoRuotaImmagini.sh): importa_foto.sh
# li prova entrambi; RUOTA_SCRIPT= forza un percorso preciso.
FOTO_SRC ?= $(HOME)/share_disks/staff/foto
WATCH_INTERVAL ?= 300

foto: ## importa le foto del diario dalla share staff (incrementale, host)
	@env $(if $(RUOTA_SCRIPT),RUOTA_SCRIPT="$(RUOTA_SCRIPT)") $(if $(FOTO_ESTENSIONI),FOTO_ESTENSIONI="$(FOTO_ESTENSIONI)") bash scripts/importa_foto.sh "$(FOTO_SRC)"

foto-watch: ## import continuo delle foto mentre arrivano (Ctrl-C per fermare)
	@env $(if $(RUOTA_SCRIPT),RUOTA_SCRIPT="$(RUOTA_SCRIPT)") $(if $(FOTO_ESTENSIONI),FOTO_ESTENSIONI="$(FOTO_ESTENSIONI)") WATCH_INTERVAL="$(WATCH_INTERVAL)" bash scripts/importa_foto.sh --watch "$(FOTO_SRC)"

# segnaletiche: importa e codifica le foto segnaletiche dalla share dello
# staff (change foto-segnaletiche-codificate, Readme.md §3): filename
# obbligatorio nome_cognome_squadriglia.<ext>, codici stabili registrati in
# anagrafica/registro_segnaletiche.csv (gitignored), copia rinominata in
# dvd/angolisq/materiale/reparto/<codice>.<ext>. Incrementale e non
# distruttivo; gira sull'host, NON usa il container (come make foto).
# Se anagrafica/elenco_ragazzi.csv manca, viene generato dal registro a fine
# passata (solo creazione, mai aggiornamento): non serve prepararlo a mano.
SEGNALETICHE_SRC ?= $(HOME)/share_disks/staff/segnaletiche

segnaletiche: ## importa e codifica le foto segnaletiche dalla share staff (incrementale, host)
	@env $(if $(SEGNALETICHE_ESTENSIONI),SEGNALETICHE_ESTENSIONI="$(SEGNALETICHE_ESTENSIONI)") bash scripts/importa_segnaletiche.sh "$(SEGNALETICHE_SRC)"

# reset d'annata (Readme.md §6): riporta il repo allo stato di fresh clone
# rimuovendo i dati dell'annata e l'output generato. Il backup esterno va
# fatto PRIMA: la rimozione e' irreversibile. Script dedicato per restare
# testabile da solo, stesso patto di foto/segnaletiche.
reset: ## riporta il repo allo stato di fresh clone (backup esterno PRIMA! vedi Readme §6)
	FORCE=$(FORCE) bash scripts/reset_annata.sh


# 

# composer:
# 	docker run --rm -i -t yoghi/php:latest composer 

# php:
# 	docker run --rm -i -t yoghi/php:latest php -i

# interactive:
# 	docker run --rm -i -t yoghi/php:latest php -a
