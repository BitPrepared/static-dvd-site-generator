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

# esistono cartelle con nomi di comando, quindi automaticamente viene skippato il comando pensando
# sia stata fatta gia la compilazione, cosi le si ignora.
.PHONY: build clean anagrafica font footer golden-salva golden-confronta check-executor

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
build: check-executor
	${EXECUTOR} run --rm -i $(USERNS_OPTION) -v "${PWD}/dvd:/usr/src/app/dvd$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -v "${PWD}/lib:/usr/src/app/lib$(MOUNT_OPTION)" -v "${PWD}/assets:/usr/src/app/assets$(MOUNT_OPTION)" -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" -v "${PWD}/scripts:/usr/src/app/scripts$(MOUNT_OPTION)" -e DEBUG=$(DEBUG) -t $(IMAGE_NAME):$(VERSION) bash -c '{ node scripts/genera_footer.js || { echo "WARNING: generazione footer fallita, uso la riserva scripts/footer_fallback.png" >&2; mkdir -p build/img; cp scripts/footer_fallback.png build/img/footer.png; } } && npm run build'

bash: check-executor
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint /bin/bash -v "${PWD}/dvd:/usr/src/app/dvd$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -v "${PWD}/lib:/usr/src/app/lib$(MOUNT_OPTION)" -v "${PWD}/assets:/usr/src/app/assets$(MOUNT_OPTION)" -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" -t $(IMAGE_NAME):$(VERSION)

init: check-executor
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

font: check-executor
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

footer: check-executor
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

golden-salva: check-executor
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint node \
	  -v "${PWD}/scripts:/usr/src/app/scripts$(MOUNT_OPTION)" \
	  -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" \
	  -v "${PWD}/golden:/usr/src/app/golden$(MOUNT_OPTION)" \
	  -w /usr/src/app -t $(IMAGE_NAME):$(VERSION) scripts/golden.js salva build $(GOLDEN_MANIFEST)

golden-confronta: check-executor
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint node \
	  -v "${PWD}/scripts:/usr/src/app/scripts$(MOUNT_OPTION)" \
	  -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" \
	  -v "${PWD}/golden:/usr/src/app/golden$(MOUNT_OPTION)" \
	  -w /usr/src/app -t $(IMAGE_NAME):$(VERSION) scripts/golden.js confronta build $(GOLDEN_MANIFEST)

# anagrafica: gira nell'immagine del generatore (Node), script montato come
# volume: modifiche live senza rifare make init (serve solo se cambiano le
# dipendenze npm in static-dvd-site-generator/package.json).
ANAGRAFICA_SCRIPT=anagrafica/genera_anagrafica.js

anagrafica: check-executor
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint node -v "${PWD}/anagrafica:/usr/src/app/anagrafica$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -w /usr/src/app -e ANONIMO=$(ANONIMO) -t $(IMAGE_NAME):$(VERSION) $(ANAGRAFICA_SCRIPT)

clean-docker: check-executor
	${EXECUTOR} buildx prune
	${EXECUTOR} rmi $(IMAGE_NAME)
	${EXECUTOR} rmi $(IMAGE_NAME):$(VERSION)

clean:
	rm -rf build
	mkdir build

open:
	qutebrowser file://${PWD}/build/index.html


# 

# composer:
# 	docker run --rm -i -t yoghi/php:latest composer 

# php:
# 	docker run --rm -i -t yoghi/php:latest php -i

# interactive:
# 	docker run --rm -i -t yoghi/php:latest php -a
