IMAGE_NAME="bitprepared/dvd-site-generator"
VERSION=bullseye

build-image:
	docker buildx build --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .

build-dvd:
	docker run --rm -i -v "${PWD}/dvd:/usr/src/app/dvd" -v "${PWD}/dati:/usr/src/app/dati" -v "${PWD}/lib:/usr/src/app/lib" -v "${PWD}/assets:/usr/src/app/assets" -v "${PWD}/build:/usr/src/app/build" -t $(IMAGE_NAME):$(VERSION) run build

clean:
	rm -rf build/*

open:
	qutebrowser file://build/index.html

