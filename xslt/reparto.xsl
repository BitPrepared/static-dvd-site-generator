<?xml version="1.0" encoding="utf-8"?>
<!-- DWXMLSource="../xml/reparto.xml" -->
<!DOCTYPE xsl:stylesheet  [
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
<!ENTITY eacute "&#233;">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:import href="header.xsl"/>
  <xsl:variable name="profondita">../</xsl:variable>

  <xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
  <xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
  <xsl:variable name="euroletters">äÄöÖüÜßáÁàÀâÂéÉèÈêÊíÍìÌîÎóÓòÒôÔúÚùÙûÛ'</xsl:variable>
  <xsl:variable name="normletters">aAoOuUsaAaAaAeEeEeEiIiIiIoOoOoOuUuUuU_</xsl:variable>

  <xsl:output method="html" encoding="utf-8" name="html" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>

  <xsl:preserve-space elements="*" />

  <xsl:template match="/">

    <xsl:for-each select="reparto/sq">

      <xsl:variable name="sq">
        <xsl:value-of select="nome"/>
      </xsl:variable>

      <xsl:result-document href="{nome}.html" format="html"  >

        <html xmlns="http://www.w3.org/1999/xhtml">
<head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
          <meta name="description" content=""/>
          <meta name="viewport" content="width=device-width"/>
          <title>Squadriglia&nbsp;
            <xsl:value-of select="nome"/>
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

              <table width="100%" border="0" cellpadding="0" cellspacing="0" class="main">
                <tr>
                  <td align="center" valign="top">
                    <div id="bone">
                      <div iD="content">
                        <table width="760" border="0" align="center">
                          <tr align="left">
                            <td height="128" colspan="5" valign="middle" class="menu">
                              <p> <font size="3"><b>Squadriglia:&nbsp;</b>
                                  <xsl:value-of select="$sq"/></font> 
                              </p>
                              <ul>
                                <xsl:for-each select="componenti/toso">

                                  <xsl:variable name="cognome">
                                    <xsl:value-of select="translate(translate(translate(translate(translate(normalize-space(cognome),$ucletters,$lcletters),'  ','__'),$euroletters,$normletters),' ','_'),'&amp;','_')"/>
                                  </xsl:variable>
                                  <xsl:variable name="nome">
                                    <xsl:value-of select="translate(translate(translate(translate(translate(normalize-space(nome),$ucletters,$lcletters),'  ','__'),$euroletters,$normletters),' ','_'),'&amp;','_')"/>
                                  </xsl:variable>

                                  <li>
                                    <a href="{$nome}{$cognome}.html">
                                      <xsl:value-of select="nome"/>
                                      &nbsp;
                                      <xsl:value-of select="cognome"/>
                                    </a>
                                  </li>
                                </xsl:for-each>
                              </ul>
                              <p> <font size="2">URLO DI SQ.</font>
                              </p>
                            </td>

                            <xsl:variable name="sqstripped" select="translate(normalize-space(nome), ' ','')"></xsl:variable>

                            <td rowspan="2" align="center">
                              <a href="../img/sq/sq_{$sqstripped}.jpg">
                                <img src="../img/sq/sq_{$sqstripped}_w.jpg" width="450"/>
                              </a>
                            </td>

                            <xsl:if test="document('../src/impostazioni.xml')/impostazioni/versione != 'lancampo'">
                              <tr>
                                <td colspan="5">
                                  <br/>
                                  <div>
                                    <a title="urlo di squadriglia 1" href="../../dati/urli/{$sq}1.avi">Urlo di Sq. 1</a>
                                    |
                                    <a title="urlo di squadriglia 2" href="../../dati/urli/{$sq}2.avi">Urlo di Sq. 2</a>

                                    <p> <strong>Carta campo</strong>
                                    </p>
                                    <ul>
                                      <li>
                                        PC 1 (
                                        <a href="../../esercitazioni/carta_del_campo/legacy/io.dwg">dwg</a>
                                        |
                                        <a href="../../../../../www.local.costigiola.net/esercitazioni_e_programmi/esercitazioni/carta_del_campo/legacy/io.pdf">pdf</a>
                                        )
                                      </li>
                                      <li>
                                        PC 2 (
                                        <a href="../../../../../www.local.costigiola.net/esercitazioni_e_programmi/esercitazioni/carta_del_campo/legacy/mercurio.dwg">dwg</a>
                                        |
                                        <a href="../../../../../www.local.costigiola.net/esercitazioni_e_programmi/esercitazioni/carta_del_campo/legacy/mercurio.pdf">pdf</a>
                                        )
                                      </li>
                                    </ul>

                                    <p>
                                      PRBM
                                      <ul>
                                        <li>
                                          <a href="../../dati/esercitazioni/prbm/{$sq}/index.html">PRBM finale</a>
                                        </li>
                                        <li>
                                          <a href="../../dati/esercitazioni/altri_media_da_hike/GPS/{$sq}/sq.kml">Percorso GPS</a>
                                        </li>
                                      </ul>
                                    </p>
                                    <p>
                                      <font size="2">Torna alla
                                        <a href="index.html">Lista delle Squadriglie</a></font> 
                                    </p>
                                  </div>

                                </td>

                              </tr>
                              <tr>
                                <td colspan="5"></td>
                                <td align="center">
                                  <a href="../img/sq/sq_{$sqstripped}2.jpg">
                                    <img src="../img/sq/sq_{$sqstripped}2_w.jpg" width="450"/>
                                  </a>
                                </td>
                              </tr>
                            </xsl:if>

                          </tr>

                        </table>
                      </div>
                    </div>
                  </td>
                </tr>
              </table>

            </div>
          </div>

</body>
        </html>

        <!-- fine del layout della singola pagina tag - output format --> </xsl:result-document>

    </xsl:for-each>
  </xsl:template>
</xsl:stylesheet>