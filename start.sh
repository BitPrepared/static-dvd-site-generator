#!/bin/bash

echo "clean"
rm -rf output

echo "copy resources"
mkdir -p output/img output/js
cp -rv src/js/ output/js/

echo "resize image"
elenco=$(ls ./src/img/)
for i in $elenco
do
	if [ -d "./src/img/$i" ]; then
		if [ ! -d "./output/img/$i" ]; then
			mkdir ./output/img/$i
			chmod 755 ./output/img/$i
		fi
		elenco_interno=$(ls ./src/img/$i)
		for f in $elenco_interno
		do		
			echo ./output/img/$i/$f;
			
			c=$(identify ./src/img/$i/$f | awk '{print $2;}' | grep PNG | wc -l)
			if [ $c = 1 ]; then
				pngcrush -fix ./src/img/$i/$f /tmp/$f
				if [ "$i" == "menu" ]; then
					echo "skip"
				else
					convert /tmp/$f -resize 400 ./output/img/$i/$f				
				fi
				rm /tmp/$f
			else
				convert ./src/img/$i/$f -resize 200 ./output/img/$i/$(basename $f .jpg)_200.jpg
				convert ./src/img/$i/$f -resize 400 ./output/img/$i/$(basename $f .jpg)_400.jpg
				convert ./src/img/$i/$f -resize 800 ./output/img/$i/$(basename $f .jpg)_800.jpg
				convert ./src/img/$i/$f -resize 1000 ./output/img/$i/$(basename $f .jpg)_1000.jpg
			fi

		done
	fi
done

echo "copy menu"
cp -rv src/img/menu/* output/img/menu/

echo "Css Generation"
compass compile

echo "Homepage"
java -jar ./lib/saxon9he.jar -o output/index.html src/homepage.xml xslt/homepage.xsl

echo "Indice Fol"
java -jar ./lib/saxon9he.jar -o output/fol.html src/fol_data.xml xslt/fol_index.xsl

echo "Singole Pagine delle immagini di Fol"
java -jar ./lib/saxon9he.jar -o output/fol/nonesiste.html src/commenti.xml xslt/fol-single-foto.xsl

echo "Singole Pagine delle attivita'/tag di Fol"
java -jar ./lib/saxon9he.jar -o output/fol/nonesiste.html src/tag.xml xslt/fol-tags.xsl
