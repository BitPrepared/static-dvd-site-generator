#!/bin/bash

echo "clean"
rm -rf output

echo "copy resources"
mkdir -p output/img output/js
cp -rv src/img/ output/img/
cp -rv src/js/ output/js/

echo "Css Generation"
compass compile

echo "Homepage"
java -jar ./lib/saxon9he.jar -o output/index.html src/homepage.xml xslt/homepage.xsl
