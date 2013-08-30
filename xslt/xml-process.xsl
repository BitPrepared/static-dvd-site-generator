<?xml version="1.0" encoding="utf-8"?><!-- DWXMLSource="../../xml/fol.xml" --><!DOCTYPE xsl:stylesheet  [
	<!ENTITY nbsp   "&#160;">
	<!ENTITY copy   "&#169;">
	<!ENTITY reg    "&#174;">
	<!ENTITY trade  "&#8482;">
	<!ENTITY mdash  "&#8212;">
	<!ENTITY ldquo  "&#8220;">
	<!ENTITY rdquo  "&#8221;"> 
	<!ENTITY pound  "&#163;">
	<!ENTITY yen    "&#165;">
	<!ENTITY euro   "&#8364;">

]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:output method="xml" encoding="utf-8"/>
<xsl:preserve-space elements="*" />
<xsl:template match="/">
<fotos>
<xsl:for-each-group select="resultset/row" group-by="NOMEFILE">	<!-- for each row, group by foto -->
		
       <foto>
        <id><xsl:value-of select="IDFOTO" /></id>

        <nomefile><xsl:value-of select="NOMEFILE"/></nomefile>	<!-- nomefile -->
		<rank><xsl:value-of select="RANK"/></rank> <!-- rank -->
        <commenti>
		<xsl:for-each select="current-group()">	<!-- for each module, group by module id -->
			<commento>
				<autore><xsl:value-of select="AUTORE" /></autore>		<!-- autorecommento  -->
				<text><xsl:value-of select="TESTO" /></text>	<!-- testo -->
			</commento>
		</xsl:for-each>
        </commenti>
        <tags>
        	<xsl:for-each select="TAGS/TAG">	<!-- for each photo,group tags -->
					
                    <tag><xsl:value-of select="."/></tag>
            </xsl:for-each>		
	    </tags>
	</foto>
</xsl:for-each-group>
</fotos>
</xsl:template>
</xsl:stylesheet>