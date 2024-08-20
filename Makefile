IMAGE_NAME="bitprepared/dvd-site-generator"
VERSION=bullseye

.PHONY: build clean

build:
	docker run --rm -i -v "${PWD}/dvd:/usr/src/app/dvd" -v "${PWD}/dati:/usr/src/app/dati" -v "${PWD}/lib:/usr/src/app/lib" -v "${PWD}/assets:/usr/src/app/assets" -v "${PWD}/build:/usr/src/app/build" -t $(IMAGE_NAME):$(VERSION) run build

init:
	docker buildx build --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .

generate-anagrafica:
	docker run --rm -i -t -v "${PWD}/anagrafica:/usr/src/myapp" -w /usr/src/myapp php:7.4-cli php anagrafica_da_csv.php > dati/squadriglie.json

clean:
	rm -rf build

open:
	qutebrowser file://build/index.html


# 

# composer:
# 	docker run --rm -i -t yoghi/php:latest composer 

# php:
# 	docker run --rm -i -t yoghi/php:latest php -i

# interactive:
# 	docker run --rm -i -t yoghi/php:latest php -a
