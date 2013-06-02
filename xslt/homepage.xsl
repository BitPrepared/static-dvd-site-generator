<?xml version="1.0" encoding="utf-8"?>
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
<!ENTITY eacute "&#0233;">
<!ENTITY euro   "&#8364;">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output method="html" encoding="utf-8" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
  <xsl:template match="/">

    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
          <meta name="description" content=""/>
          <meta name="viewport" content="width=device-width"/>
          <title><xsl:value-of select="homepage/nomeEvento"/> ::: <xsl:value-of select="homepage/anno"/></title> 
          <link href="css/styles.css" rel="stylesheet" type="text/css"/>
    </head>
<body>

  <header role="title">
      <div>
        <a href="index.html" style="color:#00000; font-weight:bold;">Isola di Mel&eacute;e</a>
      </div>
  </header>

  <div role="container">

    <div role="main" class="main-content">
      
      <a href="index.html">    
        <img src="img/logo_melee.gif" width="760" height="79" border="0" />    
      </a>

      <h1 class="headline"> Costigiola <xsl:value-of select="homepage/anno"/> </h1>
      <p>
        <xsl:value-of select="homepage/testosaluto" disable-output-escaping="yes"/>    
      </p>
      
      <p>
        <center>
          <xsl:value-of select="homepage/firma" disable-output-escaping="no"/>    
          <br />    
          <xsl:value-of select="homepage/capicampo" disable-output-escaping="no"/>    
        </center>
      </p>
      

      <blockquote>
        <xsl:value-of select="homepage/msgneo" disable-output-escaping="no"/>    
      </blockquote>

      <p align="center">
        <a href="{homepage/foto2}" target="_blank"> <img src="{homepage/foto1}" alt="Foto di Gruppo" border="0" width="650"/> </a>
        <em>(clicca sulla foto per ingradirla)</em>
      </p>
      
      <p>
        <font size="1"><xsl:value-of select="homepage/footer" disable-output-escaping="no"/></font> 
      </p>
      

    </div>

    <div role="sidebar" class="menu">
      <ol>
        <xsl:for-each select="document('../src/impostazioni.xml')/impostazioni/posizioni/posizione">
          <xsl:choose>
            <xsl:when test="domain = 'both'">
              <xsl:if test="label = 'blog'">
                <li>
                  <a href="{path}{nomefile}" target="_blank" alt="{nome}">
                    <img src="img/menu/{image}" width="45px" height="60px" alt="{nome}"/>  
                    <xsl:value-of select="label"/>
                  </a>
                </li>
              </xsl:if>
              <xsl:if test="label != 'blog'">
                <li>
                  <a href="{path}{nomefile}" alt="{nome}">
                    <img src="img/menu/{image}" width="45px" height="60px" alt="{nome}" />  
                    <xsl:value-of select="label"/>
                  </a>
                </li>
              </xsl:if>
            </xsl:when>
            <xsl:when test="domain = 'offline'">
              <li>
                <a href="{path}{nomefile}" alt="{nome}">
                  <img src="img/menu/{image}" width="45px" height="60px" alt="{nome}"/>  
                  <xsl:value-of select="label"/>
                </a>
              </li>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </ol>
    </div>

  </div>
  
  <footer role="contentinfo">
    <p class="copyright">&copy; Bit Prepared, 2013. All rights reserved.</p>
  </footer>

</body>
    </html>
  </xsl:template>
</xsl:stylesheet>