IMAGE_NAME="bitprepared/dvd-site-generator"
VERSION=bullseye

# esistono cartelle con nomi di comando, quindi automaticamente viene skippato il comando pensando
# sia stata fatta gia la compilazione, cosi le si ignora.
.PHONY: build clean anagrafica

build:
	docker run --rm -i -v "${PWD}/dvd:/usr/src/app/dvd" -v "${PWD}/dati:/usr/src/app/dati" -v "${PWD}/lib:/usr/src/app/lib" -v "${PWD}/assets:/usr/src/app/assets" -v "${PWD}/build:/usr/src/app/build" -t $(IMAGE_NAME):$(VERSION) run build

init:
	docker buildx build --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .

anagrafica:
	docker run --rm -i -t -v "${PWD}/anagrafica:/usr/src/myapp" -w /usr/src/myapp php:7.4-cli php anagrafica_da_csv.php > dati/squadriglie.json

clean-docker:
	docker buildx prune
	docker rmi $(IMAGE_NAME)
	docker rmi $(IMAGE_NAME):$(VERSION)

clean:
	rm -rf build

open:
	qutebrowser file://${PWD}/build/index.html


# 

# composer:
# 	docker run --rm -i -t yoghi/php:latest composer 

# php:
# 	docker run --rm -i -t yoghi/php:latest php -i

# interactive:
# 	docker run --rm -i -t yoghi/php:latest php -a
