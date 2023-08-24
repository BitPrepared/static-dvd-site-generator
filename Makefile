IMAGE_NAME="bitprepared/dvd-site-generator"
VERSION=bullseye

build-image:
	docker buildx build --build-arg USER_ID=1000 --build-arg GROUP_ID=1000 -t $(IMAGE_NAME):$(VERSION) -t $(IMAGE_NAME):latest .

build-dvd:
	docker run --rm -i -v "${PWD}/dvd:/usr/src/app/dvd" -v "${PWD}/dati:/usr/src/app/dati" -v "${PWD}/static/index.js:/usr/src/app/index.js" -v "${PWD}/lib:/usr/src/app/lib" -v "${PWD}/assets:/usr/src/app/assets" -v "${PWD}/build:/usr/src/app/build" -t $(IMAGE_NAME):$(VERSION) run build

build-dvd-mounted:
	docker run --rm -i -v "${PWD}/dvd:/usr/src/app/dvd" -v "${PWD}/dati:/usr/src/app/dati" -v "${PWD}/static/index.js:/usr/src/app/index.js" -v "${PWD}/lib:/usr/src/app/lib" -v "${PWD}/assets:/usr/src/app/assets" -v "/home/yoghi/blackhole/dvd:/usr/src/app/build" -t $(IMAGE_NAME):$(VERSION) run build

riduci-foto:
	$(shell ~/Script/convert_image_smp.sh dvd/diariofotografico/materiale/foto_originali 1600 dvd/diariofotografico/materiale/foto UPDATE)

jpg-rename:
	$(shell find -name '*.JPG' -exec rename .JPG .jpg {} \;)

clean:
	rm -rf build/*

outdated:
	docker run --rm -i -v "${PWD}/dvd:/usr/src/app/dvd" -v "${PWD}/dati:/usr/src/app/dati" -v "${PWD}/static/index.js:/usr/src/app/index.js" -v "${PWD}/lib:/usr/src/app/lib" -v "${PWD}/assets:/usr/src/app/assets" -v "${PWD}/build:/usr/src/app/build" -t $(IMAGE_NAME):$(VERSION) outdated

open:
	qutebrowser file://${PWD}/build/index.html &

