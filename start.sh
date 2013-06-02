#!/bin/bash

echo "Homepage"
java -jar ./saxon9he.jar -o output src/homepage.xml xslt/homepage.xsl