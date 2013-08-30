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
<reparto>
<xsl:for-each-group select="fol2013/custom/row" group-by="squadriglia">	<!-- for each row, group by squadriglia -->

   <sq>
      	<nome><xsl:value-of select="squadriglia" /></nome>
      	<genere />
      	<componenti>

		<xsl:for-each select="current-group()">	<!-- for each module, group by module id -->
			<toso>
				<nome><xsl:value-of select="nome" /></nome>
	            <cognome><xsl:value-of select="cognome" /></cognome>
	            <datanascita><xsl:value-of select="data_nascita" /></datanascita>
	            <indirizzo>
	            	Via <xsl:value-of select="via" />, <xsl:value-of select="ncivico" /> - <xsl:value-of select="cap" /> - <xsl:value-of select="citta" /> (<xsl:value-of select="provincia" />)
	            </indirizzo>
	            <telefono><xsl:value-of select="recapito_telefonico" /></telefono>
	            <email><xsl:value-of select="email" /></email>
	            <totem><xsl:value-of select="totem" /></totem>
	            <specialita><xsl:value-of select="specialita" /></specialita>
	            <indice>##DAFARE_A_MANO##</indice>
			</toso>
		</xsl:for-each>

        </componenti>	

	</sq>
</xsl:for-each-group>
</reparto>
</xsl:template>
</xsl:stylesheet>