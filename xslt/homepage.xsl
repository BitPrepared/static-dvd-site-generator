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

  <xsl:import href="header.xsl"/>
  <xsl:variable name="profondita"></xsl:variable>

  <xsl:output method="html" encoding="utf-8" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>
  <xsl:template match="/">

    <html xmlns="http://www.w3.org/1999/xhtml">
    <head>
          <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
          <meta name="description" content=""/>
          <meta name="viewport" content="width=device-width"/>
          <title><xsl:value-of select="homepage/nomeEvento"/> ::: <xsl:value-of select="homepage/anno"/></title> 
          <link rel="stylesheet" type="text/css" media="(min-width: 800px)" href="css/styles.css"/>
          <link rel="stylesheet" type="text/css" media="(max-width: 320px)" href="css/styles-320.css" />
          <link rel="stylesheet" type="text/css" media="(min-width: 480px) and (max-width: 800px)" href="css/styles-480.css" />
    </head>
    <body>

      <!-- Header -->
      <xsl:call-template name="header"/>

      <div style="clear:both;"></div>

      <div role="container">

        <div role="main" class="main-content">
          
          <h1 class="headline"> Isola di Mel&eacute;e <xsl:value-of select="homepage/anno"/> </h1>
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
            <a href="{homepage/foto2}" target="_blank">
            <span data-picture="" data-alt="A giant stone face at The Bayon temple in Angkor Thom, Cambodia">
            <span data-src="img/gruppo/gruppo_200.jpg"></span>
            <span data-src="img/gruppo/gruppo_400.jpg" data-media="(min-width: 400px)"></span>
            <span data-src="img/gruppo/gruppo_800.jpg" data-media="(min-width: 800px)"></span>
            <span data-src="img/gruppo/gruppo_1000.jpg" data-media="(min-width: 1000px)"></span>
            <span data-src="img/gruppo/gruppo_200_retina.jpg" data-media="(min-width: 200px) and (min-device-pixel-ratio: 2.0)"></span> <!-- retina -->

              <!-- Fallback content for non-JS browsers. Same img src as the initial, unqualified source element. -->
              <noscript><img src="img/gruppo/gruppo_200.jpg" alt="A giant stone face at The Bayon temple in Angkor Thom, Cambodia"></img></noscript>
            </span>
            </a>
            <em>(clicca sulla foto per ingradirla)</em>
          </p>
          
          <p>
            <font size="1"><xsl:value-of select="homepage/footer" disable-output-escaping="no"/></font> 
          </p>
          

        </div>

        <div role="sidebar">
          
        </div>

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