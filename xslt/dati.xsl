<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE xsl:stylesheet  [
<!ENTITY nbsp   "&#160;">
<!ENTITY copy   "&#169;">
<!ENTITY Egrave "&#200;">
<!ENTITY Agrave "&#192;">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:import href="header.xsl"/>
  <xsl:variable name="profondita"></xsl:variable>

  <xsl:output method="html" encoding="utf-8" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
  <xsl:template match="/">

    <xsl:variable name="pathDocu">../dati/esercitazioni/</xsl:variable>
    <xsl:variable name="pathProg">../programmi/</xsl:variable>

    <html xmlns="http://www.w3.org/1999/xhtml">

<head>
      <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
      <meta name="description" content=""/>
      <meta name="viewport" content="width=device-width"/>
      <title><xsl:value-of select="dati/title"/>
        :::
        <xsl:value-of select="document('../src/impostazioni.xml')/impostazioni/nome"/>
        :::
        <xsl:value-of select="document('../src/impostazioni.xml')/impostazioni/anno"/></title> 
      <link href="css/styles.css" rel="stylesheet" type="text/css"/>
</head>

<body>

      <!-- Header -->
      <xsl:call-template name="header"/>

      <div style="clear:both;"></div>

      <div role="container">

        <div role="main" class="main-content">

          <table>
            <tr>
              <td align="center" valign="top" scope="col">
                <div id="bone">
                  <div id="content">
                    <table width="100%" height="100%" border="0" cellpadding="0" cellspacing="0">
                      <tr>
                        <td align="left" valign="top" height="10"></td>
                      </tr>
                      <tr>
                        <td align="left" valign="top">
                          <p class="titolo"> <b>Esercitazioni e Programmi</b>
                          </p>
                          <table width="100%" border="0" cellpadding="5" cellspacing="0" class="filinosx">
                            <xsl:choose>
                              <xsl:when test="dati/editoria/active = 'N'">
                                <tr align="center" class="cellafoto">
                                  <td colspan="4" valign="bottom" class="filino" height="160">
                                    <span class="style2"> <strong><font size="2" style="color:#000000">NON &Egrave; PRESENTE ANCORA NESSUNA ATTIVIT&Agrave;, TORNA QUANDO AVRAI FATTO QUALCOSA.</font> </strong> 
                                    </span>
                                  </td>
                                </tr>
                              </xsl:when>
                              <xsl:otherwise>
                                <tr align="center" class="cellafoto">
                                  <td width="13%" valign="top" class="filino">
                                    <span class="style2"> <strong><font size="2">ATTIVIT&Agrave;</font></strong> 
                                    </span>
                                  </td>
                                  <td width="" valign="top" class="filino">
                                    <span class="style2">
                                      <strong>
                                        <font size="2">DATI</font>
                                      </strong>
                                    </span>
                                  </td>
                                  <td width="" valign="top" class="filino">
                                    <span class="style2">
                                      <strong>
                                        <font size="2">PROGRAMMI</font>
                                      </strong>
                                    </span>
                                  </td>
                                  <td width="13%" valign="top" class="filino">
                                    <span class="style2">
                                      <strong>
                                        <font size="2">INFORMAZIONI</font>
                                      </strong>
                                    </span>
                                  </td>
                                </tr>
                                <tr>
                                  <td valign="top" class="filino">
                                    <span class="style3">
                                      <font size="2" style="font-weight:bold; color: #000000;"><xsl:value-of select="dati/editoria/mainlabel"/></font> 
                                    </span>
                                  </td>
                                  <td valign="top" nowrap="nowrap" class="filino style4">

                                    <ul>
                                      <xsl:for-each select="dati/editoria/others/bansiere">
                                        <li>
                                          <font size="2">
                                            <xsl:value-of select="label" disable-output-escaping="yes"/>
                                            -
                                            <xsl:value-of select="pc"/>
                                            &nbsp;
                                            <a href="../dati/esercitazioni/esercitazioni_editoria/{odt}">odt</a>
                                            |
                                            <a href="../dati/esercitazioni/esercitazioni_editoria/{pdf}">Pdf</a>
                                          </font>
                                        </li>
                                      </xsl:for-each>

                                    </ul>

                                  </td>
                                  <td valign="top" class="filino style4">
                                    <ul>
                                      <xsl:for-each select="dati/editoria/programs/program">
                                        <li>
                                          <font size="2">
                                            <a href="{path}">
                                              <xsl:value-of select="label" disable-output-escaping="yes"/>
                                            </a>
                                          </font>
                                        </li>
                                      </xsl:for-each>
                                    </ul>
                                  </td>
                                  <td valign="top" class="filino">
                                    <p class="style4">
                                      <font size="2">
                                        <xsl:value-of select="dati/editoria/instNote" disable-output-escaping="yes"/>
                                      </font>
                                    </p>
                                  </td>
                                </tr>
                              </xsl:otherwise>
                            </xsl:choose>
                            <xsl:if test="dati/cartina/active = 'Y'">
                              <tr bgcolor="#42AC88">
                                <td height="1" colspan="4" valign="top" class="filino1"></td>
                              </tr>
                              <tr>
                                <td valign="top" class="filino">
                                  <span class="style3">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="dati/cartina/mainlabel"/>
                                    </font>
                                  </span>
                                </td>
                                <td valign="top" class="filino style4">
                                  <xsl:for-each-group select="dati/cartina/sqall/item" group-by="sq">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="sq"/>
                                    </font>
                                    <ul>
                                      <xsl:for-each select="current-group()">
                                        <li>
                                          <font size="2">
                                            <xsl:value-of select="pc"/>
                                            &nbsp;
                                            <a href="{dwg}">Dwg</a>
                                            |
                                            <a href="{pdf}">Pdf</a>
                                          </font>
                                        </li>
                                      </xsl:for-each>
                                    </ul>
                                  </xsl:for-each-group>
                                </td>
                                <td valign="top" class="filino style4">
                                  <ul>
                                    <xsl:for-each select="dati/cartina/programs/program">
                                      <li>
                                        <font size="2">
                                          <a href="{path}">
                                            <xsl:value-of select="label" disable-output-escaping="yes"/>
                                          </a>
                                        </font>
                                      </li>
                                    </xsl:for-each>
                                  </ul>
                                </td>
                                <td valign="top" class="filino">
                                  <p class="style4">
                                    <font size="2">
                                      <xsl:value-of select="dati/cartina/instNote" disable-output-escaping="yes"/>
                                    </font>
                                  </p>
                                </td>
                              </tr>
                            </xsl:if>
                            <xsl:if test="dati/via/active = 'Y'">
                              <tr bgcolor="#42AC88">
                                <td height="1" colspan="4" valign="top" class="filino1"></td>
                              </tr>
                              <tr>
                                <td valign="top" class="filino">
                                  <span class="style3">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="dati/via/mainlabel"/>
                                    </font>
                                  </span>
                                </td>
                                <td valign="top" class="filino">&nbsp;</td>
                                <td valign="top" class="filino style4">
                                  <ul>
                                    <xsl:for-each select="dati/via/programs/program">
                                      <li>
                                        <font size="2">
                                          <a href="{path}">
                                            <xsl:value-of select="label" disable-output-escaping="yes"/>
                                          </a>
                                        </font>
                                      </li>
                                    </xsl:for-each>
                                  </ul>
                                </td>
                                <td valign="top" class="filino">
                                  <p class="style4">
                                    <font size="2">
                                      <xsl:value-of select="dati/via/instNote" disable-output-escaping="yes"/>
                                    </font>
                                  </p>
                                </td>
                              </tr>
                            </xsl:if>
                            <xsl:if test="dati/morse/active = 'Y'">
                              <tr bgcolor="#42AC88">
                                <td height="1" colspan="4" valign="top" class="filino1"></td>
                              </tr>
                              <tr>
                                <td valign="top" class="filino">
                                  <span class="style3">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="dati/morse/mainlabel"/>
                                    </font>
                                  </span>
                                </td>
                                <td valign="top" class="filino">&nbsp;</td>
                                <td valign="top" class="filino style4">
                                  <ul>
                                    <xsl:for-each select="dati/morse/programs/program">
                                      <li>
                                        <font size="2">
                                          <a href="{path}">
                                            <xsl:value-of select="label" disable-output-escaping="yes"/>
                                          </a>
                                        </font>
                                      </li>
                                    </xsl:for-each>
                                  </ul>
                                </td>
                                <td valign="top" class="filino">
                                  <p class="style4">
                                    <font size="2">
                                      <xsl:value-of select="dati/morse/instNote" disable-output-escaping="yes"/>
                                    </font>
                                  </p>
                                </td>
                              </tr>
                            </xsl:if>
                            <xsl:if test="dati/stelle/active = 'Y'">
                              <tr bgcolor="#42AC88">
                                <td height="1" colspan="4" valign="top" class="filino1"></td>
                              </tr>
                              <tr>
                                <td valign="top" class="filino">
                                  <span class="style3">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="dati/stelle/mainlabel"/>
                                    </font>
                                  </span>
                                </td>
                                <td valign="top" class="filino">&nbsp;</td>
                                <td valign="top" class="filino style4">
                                  <ul>
                                    <xsl:for-each select="dati/stelle/programs/program">
                                      <li>
                                        <font size="2">
                                          <a href="{path}">
                                            <xsl:value-of select="label" disable-output-escaping="yes"/>
                                          </a>
                                        </font>
                                      </li>
                                    </xsl:for-each>
                                  </ul>
                                </td>
                                <td valign="top" class="filino">
                                  <p class="style4">
                                    <font size="2">
                                      <xsl:value-of select="dati/stelle/instNote" disable-output-escaping="yes"/>
                                    </font>
                                  </p>
                                </td>
                              </tr>
                            </xsl:if>
                            <xsl:if test="dati/internet/active = 'Y'">
                              <tr bgcolor="#42AC88">
                                <td height="1" colspan="4" valign="top" class="filino1"></td>
                              </tr>
                              <tr>
                                <td valign="top" class="filino">
                                  <span class="style3">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="dati/internet/mainlabel"/>
                                    </font>
                                  </span>
                                </td>
                                <td valign="top" class="filino">&nbsp;</td>
                                <td class="filino">
                                  <ul>
                                    <xsl:for-each select="dati/internet/programs/program">
                                      <li>
                                        <font size="2">
                                          <xsl:value-of select="label" disable-output-escaping="yes"/>
                                          &nbsp;
                                          <xsl:value-of select="odp"  disable-output-escaping="yes"/>
                                          <xsl:value-of select="pdf"  disable-output-escaping="yes"/>
                                          <xsl:value-of select="subnote"/>
                                        </font>
                                      </li>
                                    </xsl:for-each>

                                  </ul>
                                </td>
                                <td valign="top" class="filino">
                                  <p class="style4">
                                    <font size="2">
                                      <xsl:value-of select="dati/internet/instNote" disable-output-escaping="yes"/>
                                    </font>
                                  </p>
                                </td>
                              </tr>
                            </xsl:if>
                            <xsl:if test="dati/prbm/active = 'Y'">
                              <tr bgcolor="#42AC88">
                                <td height="1" colspan="4" valign="top" class="filino1"></td>
                              </tr>
                              <tr>
                                <td valign="top" class="filino">
                                  <span class="style3">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="dati/prbm/mainlabel"/>
                                    </font>
                                  </span>
                                </td>
                                <td valign="top" class="filino">
                                  <ul class="style4">

                                    <xsl:for-each select="dati/prbm/sqall/item">
                                      <li>
                                        <font size="2">
                                          sq
                                          <xsl:value-of select="sq"/>
                                          &nbsp;
                                          <a href="../dati/esercitazioni/prbm/{sq}/index.html">Finale</a>
                                          |
                                          <a href="../dati/esercitazioni/prbm/{sq}.prb">PRB</a>
                                        </font>
                                      </li>
                                    </xsl:for-each>

                                  </ul>
                                  <p>
                                    <font size="2">PERCORSI RILEVATI CON GPS-LOGGER</font>
                                  </p>
                                  <ul class="style4">

                                    <xsl:for-each select="dati/prbm/gps/item">

                                      <li>
                                        <font size="2">
                                          <xsl:value-of select="sq"/>
                                          &nbsp;
                                          <a href="../dati/esercitazioni/altri_media_da_hike/GPS/{sq}/">Percorso</a>
                                        </font>
                                      </li>

                                    </xsl:for-each>
                                  </ul>
                                </td>
                                <td valign="top" class="filino">
                                  <ul class="style4">
                                    <xsl:for-each select="dati/prbm/programs/program">
                                      <li>
                                        <font size="2">
                                          <a href="{path}">
                                            <xsl:value-of select="label" disable-output-escaping="yes"/>
                                          </a>
                                        </font>
                                      </li>
                                    </xsl:for-each>

                                  </ul>
                                </td>
                                <td valign="top" class="filino">

                                  <p class="style4">
                                    <font size="2">
                                      <xsl:value-of select="dati/prbm/instNote" disable-output-escaping="yes"/>
                                    </font>
                                  </p>
                                </td>
                              </tr>
                            </xsl:if>
                            <xsl:if test="dati/flora/active = 'Y'">
                              <tr bgcolor="#42AC88">
                                <td height="1" colspan="4" valign="top" class="filino1"></td>
                              </tr>
                              <tr>
                                <td valign="top" class="filino">
                                  <span class="style3">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="dati/flora/mainlabel"/>
                                    </font>
                                  </span>
                                </td>
                                <td class="filino">&nbsp;</td>
                                <td class="filino">
                                  <ul class="style4">
                                    <xsl:for-each select="dati/flora/programs/program">
                                      <li>
                                        <font size="2">
                                          <a href="{path}">
                                            <xsl:value-of select="label" disable-output-escaping="yes"/>
                                          </a>
                                        </font>
                                      </li>
                                    </xsl:for-each>

                                  </ul>
                                </td>
                                <td valign="top" class="filino">
                                  <p class="style4">
                                    <font size="2">
                                      <xsl:value-of select="dati/flora/instNote" disable-output-escaping="yes"/>
                                    </font>
                                  </p>
                                </td>
                              </tr>
                            </xsl:if>
                            <xsl:if test="dati/maya/active = 'Y'">
                              <tr bgcolor="#42AC88">
                                <td height="1" colspan="4" valign="top" class="filino1"></td>
                              </tr>
                              <tr>
                                <td valign="top" class="filino">
                                  <span class="style3">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="dati/maya/mainlabel"/>
                                    </font>
                                  </span>
                                </td>
                                <td class="filino">&nbsp;</td>
                                <td valign="top" class="filino style4">
                                  <ul>
                                    <xsl:for-each select="dati/maya/programs/program">
                                      <li>
                                        <font size="2">
                                          <a href="{path}">
                                            <xsl:value-of select="label" disable-output-escaping="yes"/>
                                          </a>
                                        </font>
                                      </li>
                                    </xsl:for-each>
                                  </ul>
                                </td>
                                <td valign="top" class="filino">
                                  <p class="style4">
                                    <font size="2">
                                      <xsl:value-of select="dati/maya/instNote" disable-output-escaping="yes"/>
                                    </font>
                                  </p>
                                </td>
                              </tr>
                            </xsl:if>
                            <xsl:if test="dati/karaoke/active = 'Y'">
                              <tr bgcolor="#42AC88">
                                <td height="1" colspan="4" valign="top" class="filino1"></td>
                              </tr>
                              <tr>
                                <td valign="top" class="filino">
                                  <span class="style3">
                                    <font size="2" style="font-weight:bold; color: #000000;">
                                      <xsl:value-of select="dati/karaoke/mainlabel"/>
                                    </font>
                                  </span>
                                </td>
                                <td class="filino">&nbsp;</td>
                                <td valign="top" class="filino style4">
                                  <ul>
                                    <xsl:for-each select="dati/karaoke/programs/program">
                                      <li>
                                        <font size="2">
                                          <a href="{path}">
                                            <xsl:value-of select="label" disable-output-escaping="yes"/>
                                          </a>
                                        </font>
                                      </li>
                                    </xsl:for-each>
                                  </ul>
                                </td>
                                <td valign="top" class="filino">
                                  <p class="style4">
                                    <font size="2">
                                      <xsl:value-of select="dati/karaoke/instNote" disable-output-escaping="yes"/>
                                    </font>
                                  </p>
                                </td>
                              </tr>
                            </xsl:if>
                          </table>
                        </td>
                      </tr>
                    </table>
                  </div>
                </div>
              </td>
            </tr>
          </table>

        </div>

        <div role="sidebar"></div>

      </div>

      <footer role="contentinfo">
        <p class="copyright">&copy; Bit Prepared, 2013. All rights reserved.</p>
      </footer>

      <script src="js/matchmedia.js"/>
      <script src="js/picturefill.js"/>

    </body>
    </html>
  </xsl:template>
</xsl:stylesheet>