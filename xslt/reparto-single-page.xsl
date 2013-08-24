<?xml version="1.0" encoding="UTF-8"?>
<!-- DWXMLSource="../xml/reparto.xml" -->
<!DOCTYPE xsl:stylesheet  [
  <!ENTITY tilde "&#130;">
<!ENTITY florin "&#131;">
<!ENTITY elip "&#133;">
<!ENTITY dag "&#134;">
<!ENTITY ddag "&#135;">
<!ENTITY cflex "&#136;">
<!ENTITY permil "&#137;">
<!ENTITY uscore "&#138;">
<!ENTITY OElig "&#140;">
<!ENTITY lsquo "&#145;">
<!ENTITY rsquo "&#146;">
<!ENTITY ldquo "&#147;">
<!ENTITY rdquo "&#148;">
<!ENTITY bullet "&#149;">
<!ENTITY endash "&#150;">
<!ENTITY emdash "&#151;">
<!ENTITY trade "&#153;">
<!ENTITY oelig "&#156;">
<!ENTITY Yuml "&#159;">
<!ENTITY nbsp "&#160;">
<!ENTITY iexcl "&#161;">
<!ENTITY cent "&#162;">
<!ENTITY pound "&#163;">
<!ENTITY curren "&#164;">
<!ENTITY yen "&#165;">
<!ENTITY brvbar "&#166;">
<!ENTITY sect "&#167;">
<!ENTITY uml "&#168;">
<!ENTITY copy "&#169;">
<!ENTITY ordf "&#170;">
<!ENTITY laquo "&#171;">
<!ENTITY not "&#172;">
<!ENTITY shy "&#173;">
<!ENTITY reg "&#174;">
<!ENTITY macr "&#175;">
<!ENTITY deg "&#176;">
<!ENTITY plusmn "&#177;">
<!ENTITY sup2 "&#178;">
<!ENTITY sup3 "&#179;">
<!ENTITY acute "&#180;">
<!ENTITY micro "&#181;">
<!ENTITY para "&#182;">
<!ENTITY middot "&#183;">
<!ENTITY cedil "&#184;">
<!ENTITY sup1 "&#185;">
<!ENTITY ordm "&#186;">
<!ENTITY raquo "&#187;">
<!ENTITY frac14 "&#188;">
<!ENTITY frac12 "&#189;">
<!ENTITY frac34 "&#190;">
<!ENTITY iquest "&#191;">
<!ENTITY Agrave "&#192;">
<!ENTITY Aacute "&#193;">
<!ENTITY Acirc "&#194;">
<!ENTITY Atilde "&#195;">
<!ENTITY Auml "&#196;">
<!ENTITY Aring "&#197;">
<!ENTITY AElig "&#198;">
<!ENTITY Ccedil "&#199;">
<!ENTITY Egrave "&#200;">
<!ENTITY Eacute "&#201;">
<!ENTITY Ecirc "&#202;">
<!ENTITY Euml "&#203;">
<!ENTITY Igrave "&#204;">
<!ENTITY Iacute "&#205;">
<!ENTITY Icirc "&#206;">
<!ENTITY Iuml "&#207;">
<!ENTITY ETH "&#208;">
<!ENTITY Ntilde "&#209;">
<!ENTITY Ograve "&#210;">
<!ENTITY Oacute "&#211;">
<!ENTITY Ocirc "&#212;">
<!ENTITY Otilde "&#213;">
<!ENTITY Ouml "&#214;">
<!ENTITY times "&#215;">
<!ENTITY Oslash "&#216;">
<!ENTITY Ugrave "&#217;">
<!ENTITY Uacute "&#218;">
<!ENTITY Ucirc "&#219;">
<!ENTITY Uuml "&#220;">
<!ENTITY Yacute "&#221;">
<!ENTITY THORN "&#222;">
<!ENTITY szlig "&#223;">
<!ENTITY agrave "&#224;">
<!ENTITY aacute "&#225;">
<!ENTITY acirc "&#226;">
<!ENTITY atilde "&#227;">
<!ENTITY auml "&#228;">
<!ENTITY aring "&#229;">
<!ENTITY aelig "&#230;">
<!ENTITY ccedil "&#231;">
<!ENTITY egrave "&#232;">
<!ENTITY eacute "&#233;">
<!ENTITY ecirc "&#234;">
<!ENTITY euml "&#235;">
<!ENTITY igrave "&#236;">
<!ENTITY iacute "&#237;">
<!ENTITY icirc "&#238;">
<!ENTITY iuml "&#239;">
<!ENTITY eth "&#240;">
<!ENTITY ntilde "&#241;">
<!ENTITY ograve "&#242;">
<!ENTITY oacute "&#243;">
<!ENTITY ocirc "&#244;">
<!ENTITY otilde "&#245;">
<!ENTITY ouml "&#246;">
<!ENTITY oslash "&#248;">
<!ENTITY ugrave "&#249;">
<!ENTITY uacute "&#250;">
<!ENTITY ucirc "&#251;">
<!ENTITY uuml "&#252;">
<!ENTITY yacute "&#253;">
<!ENTITY thorn "&#254;">
<!ENTITY yuml "&#255;">
]>
<xsl:stylesheet version="2.0"  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"  xmlns:saxon="http://saxon.sf.net/" extension-element-prefixes="saxon" >

  <xsl:import href="header.xsl"/>
  <xsl:variable name="profondita">../</xsl:variable>

  <xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
  <xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
  <xsl:variable name="euroletters">äÄöÖüÜßáÁàÀâÂéÉèÈêÊíÍìÌîÎóÓòÒôÔúÚùÙûÛ'</xsl:variable>
  <xsl:variable name="normletters">aAoOuUsaAaAaAeEeEeEiIiIiIoOoOoOuUuUuU_</xsl:variable>

  <xsl:output method="html" encoding="utf-8" name="html" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>

  <xsl:preserve-space elements="*" />
  <xsl:template match="/">

    <xsl:for-each select="reparto/sq/componenti/toso">

      <xsl:variable name="cognome">
        <xsl:value-of select="translate(translate(translate(translate(translate(normalize-space(cognome),$ucletters,$lcletters),'  ','__'),$euroletters,$normletters),' ','_'),'&amp;','_')"/>
      </xsl:variable>
      <xsl:variable name="nome">
        <xsl:value-of select="translate(translate(translate(translate(translate(normalize-space(nome),$ucletters,$lcletters),'  ','__'),$euroletters,$normletters),' ','_'),'&amp;','_')"/>
      </xsl:variable>
      <xsl:variable name="sq">
        <xsl:value-of select="../../nome"/>
      </xsl:variable>

      <xsl:result-document href="{$nome}{$cognome}.html" format="html"  >

        <html xmlns="http://www.w3.org/1999/xhtml">
<head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
          <meta name="description" content=""/>
          <meta name="viewport" content="width=device-width"/>
          <title><xsl:value-of select="nome"/>
            &nbsp;
            <xsl:value-of select="cognome"/>
            :::
            <xsl:value-of select="homepage/nomeEvento"/>
            :::
            <xsl:value-of select="homepage/anno"/></title> 
          <link rel="stylesheet" type="text/css" media="(min-width: 800px)" href="../css/styles.css"/>
          <link rel="stylesheet" type="text/css" media="(max-width: 320px)" href="../css/styles-320.css" />
          <link rel="stylesheet" type="text/css" media="(min-width: 480px) and (max-width: 800px)" href="../css/styles-480.css" />
</head>
<body>

          <!-- Header -->
          <xsl:call-template name="header"/>

          <div style="clear:both;"></div>

          <div role="container">

            <div role="main" class="main-content">

              <table width="100%" border="0">
                <tr valign="middle">
                  <td valign="top">
                    <a href="../img/ragazzi/{$cognome}{$nome}.JPG">
                      <img src="../img/ragazzi/{$cognome}{$nome}_thu.JPG" border="1" />
                    </a>
                  </td>

                  <td> <font size="3"><strong>Nominativo</strong>
                      :
                      <xsl:value-of select="cognome"/>
                      &nbsp;
                      <xsl:value-of select="nome"/>
                      <br /> <strong>Data di Nascita</strong>
                      :
                      <xsl:value-of select="datanascita"/>
                      <br />
                      <strong>Indirizzo</strong>
                      :
                      <br />
                      <dl>
                        <dd>
                          <xsl:value-of select="indirizzo"/>
                        </dd>

                        <dt>
                          <br />
                          <strong>Telefono</strong>
                          :
                          <xsl:value-of select="telefono"/>
                          <br />
                          <strong>Email</strong>
                          :
                          <a
                        href="mailto:{email}">
                            <xsl:value-of select="email"/>
                          </a>
                          <br />
                          <strong>Squadriglia</strong>
                          :
                          <xsl:value-of select="$sq"/>
                          <br />

                          <strong>Totem</strong>
                          :
                          <xsl:value-of select="totem"/>
                          <br />
                          <strong>Specialit&agrave;</strong>
                          :
                          <xsl:if test="specialita != '0'">
                            <xsl:value-of select="specialita"/>
                          </xsl:if>
                          <br />
                        </dt>
                      </dl></font> 
                  </td>
                </tr>
                <tr align="left">
                  <td height="10" colspan="5" valign="middle">
                    Torna alla
                    <a href="{$sq}.html">
                      Squadriglia
                      <xsl:value-of select="$sq"/>
                    </a>
                  </td>
                </tr>
                <tr align="left">
                  <td height="1" colspan="5" valign="middle"></td>
                </tr>
      </table>

    </div>
  </div>
</body>
</html>

<!-- fine del layout della singola pagina tag - output format -->
</xsl:result-document>

</xsl:for-each>
</xsl:template>
</xsl:stylesheet>