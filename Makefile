IMAGE_NAME="bitprepared/dvd-site-generator"
VERSION=bullseye
# sovrascrivibile da ambiente o riga di comando: EXECUTOR=podman make build
EXECUTOR ?= docker
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
.PHONY: build clean anagrafica

build:
	${EXECUTOR} run --rm -i $(USERNS_OPTION) -v "${PWD}/dvd:/usr/src/app/dvd$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -v "${PWD}/lib:/usr/src/app/lib$(MOUNT_OPTION)" -v "${PWD}/assets:/usr/src/app/assets$(MOUNT_OPTION)" -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" -e DEBUG=$(DEBUG) -t $(IMAGE_NAME):$(VERSION) npm run build

bash:
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint /bin/bash -v "${PWD}/dvd:/usr/src/app/dvd$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -v "${PWD}/lib:/usr/src/app/lib$(MOUNT_OPTION)" -v "${PWD}/assets:/usr/src/app/assets$(MOUNT_OPTION)" -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" -t $(IMAGE_NAME):$(VERSION)

init:
	${EXECUTOR} build --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .

# anagrafica: gira nell'immagine del generatore (Node), script montato come
# volume: modifiche live senza rifare make init (serve solo se cambiano le
# dipendenze npm in static-dvd-site-generator/package.json).
ANAGRAFICA_SCRIPT=anagrafica/genera_anagrafica.js

anagrafica:
	${EXECUTOR} run --rm -i $(USERNS_OPTION) --entrypoint node -v "${PWD}/anagrafica:/usr/src/app/anagrafica$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -w /usr/src/app -e ANONIMO=$(ANONIMO) -t $(IMAGE_NAME):$(VERSION) $(ANAGRAFICA_SCRIPT)

clean-docker:
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
