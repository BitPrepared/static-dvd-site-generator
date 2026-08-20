IMAGE_NAME="bitprepared/dvd-site-generator"
VERSION=bullseye
EXECUTOR=docker
ifeq ($(EXECUTOR),podman)
MOUNT_OPTION = :U
else
MOUNT_OPTION =
endif
DEBUG=False

# esistono cartelle con nomi di comando, quindi automaticamente viene skippato il comando pensando
# sia stata fatta gia la compilazione, cosi le si ignora.
.PHONY: build clean anagrafica

build:
	${EXECUTOR} run --rm -i --userns=keep-id -v "${PWD}/dvd:/usr/src/app/dvd$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -v "${PWD}/lib:/usr/src/app/lib$(MOUNT_OPTION)" -v "${PWD}/assets:/usr/src/app/assets$(MOUNT_OPTION)" -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" -e DEBUG=$(DEBUG) -t $(IMAGE_NAME):$(VERSION) npm run build

bash:
	${EXECUTOR} run --rm -i --userns=keep-id --entrypoint /bin/bash -v "${PWD}/dvd:/usr/src/app/dvd$(MOUNT_OPTION)" -v "${PWD}/dati:/usr/src/app/dati$(MOUNT_OPTION)" -v "${PWD}/lib:/usr/src/app/lib$(MOUNT_OPTION)" -v "${PWD}/assets:/usr/src/app/assets$(MOUNT_OPTION)" -v "${PWD}/build:/usr/src/app/build$(MOUNT_OPTION)" -t $(IMAGE_NAME):$(VERSION)

init:
	${EXECUTOR} build --build-arg USER_ID=$(shell id -u) --build-arg GROUP_ID=$(shell id -g) -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .

anagrafica:
	${EXECUTOR} run --rm -i -t -v "${PWD}/anagrafica:/usr/src/myapp$(MOUNT_OPTION)" -w /usr/src/myapp php:7.4-cli php anagrafica_da_csv.php > dati/squadriglie.json

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
