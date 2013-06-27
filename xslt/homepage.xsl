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
      
    <div id="logo" class="logo">

        <svg
           xmlns:dc="http://purl.org/dc/elements/1.1/"
           xmlns:cc="http://creativecommons.org/ns#"
           xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
           xmlns:svg="http://www.w3.org/2000/svg"
           xmlns="http://www.w3.org/2000/svg" 
           xmlns:xlink="http://www.w3.org/1999/xlink" 
           xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
           xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
           width="380"
           height="100"
           id="svg2"
           version="1.1"
           inkscape:version="0.48.2 r9819"
           sodipodi:docname="New document 1">

           <a xlink:href="index.html" target="_blank">
            <g
             inkscape:label="Layer 1"
             inkscape:groupmode="layer"
             id="layer1">
              <text
                 xml:space="preserve"
                 style="font-size:40px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;line-height:125%;letter-spacing:0px;word-spacing:0px;fill:#000000;fill-opacity:1;stroke:none;font-family:Caribbean;-inkscape-font-specification:Caribbean"
                 x="20"
                 y="54.362183"
                 id="text2985"
                 sodipodi:linespacing="125%">
                <tspan sodipodi:role="line" id="tspan2987" x="20" y="54.362183">Bit Prepared</tspan>
              </text>
            </g>
          </a>

          <g
           inkscape:label="Layer 2"
           inkscape:groupmode="layer"
           id="layer2">
            <text
               xml:space="preserve"
               style="font-size:20px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;line-height:125%;letter-spacing:0px;word-spacing:0px;fill:#000000;fill-opacity:1;stroke:none;font-family:Caribbean;-inkscape-font-specification:Caribbean"
               x="40"
               y="90.362183"
               id="text2985"
               sodipodi:linespacing="125%">
              <tspan sodipodi:role="line" id="tspan2987" x="40" y="90.362183">Isola di Mel&eacute;e</tspan>
            </text>
          </g>

        </svg>


    </div>


    <div id="menu" class="menu">

      <ol>
        <xsl:for-each select="document('../src/impostazioni.xml')/impostazioni/posizioni/posizione">
          <xsl:choose>
            <xsl:when test="domain = 'both'">
              <xsl:if test="label = 'blog'">
                <li>
                  <a href="{path}{nomefile}" target="_blank" alt="{nome}" title="{nome}">
                    <img src="img/menu/{image}" width="45px" height="60px" alt="{nome}"/>  
                    <!-- <xsl:value-of select="label"/> -->
                  </a>
                </li>
              </xsl:if>
              <xsl:if test="label != 'blog'">
                <li>
                  <a href="{path}{nomefile}" alt="{nome}" title="{nome}">
                    <img src="img/menu/{image}" width="45px" height="60px" alt="{nome}" />  
                    <!-- <xsl:value-of select="label"/> -->
                  </a>
                </li>
              </xsl:if>
            </xsl:when>
            <xsl:when test="domain = 'offline'">
              <li>
                <a href="{path}{nomefile}" alt="{nome}" title="{nome}">
                  <img src="img/menu/{image}" width="45px" height="60px" alt="{nome}"/>  
                  <!-- <xsl:value-of select="label"/> -->
                </a>
              </li>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </ol>

    </div>

  </header>

  <div style="clear:both;"></div>

  <div role="container">

    <div role="main" class="main-content">
      
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
        <a href="{homepage/foto2}" target="_blank">
        <span data-picture="" data-alt="A giant stone face at The Bayon temple in Angkor Thom, Cambodia">
        <span data-src="img/gruppo/gruppo_low.jpg"></span>
        <span data-src="img/gruppo/gruppo_400.jpg" data-media="(min-width: 400px)"></span>
        <span data-src="img/gruppo/gruppo_low.jpg" data-media="(min-width: 800px)"></span>
        <span data-src="img/gruppo/gruppo_low.jpg" data-media="(min-width: 1000px)"></span>
        <span data-src="img/gruppo/gruppo_400_retina.jpg" data-media="(min-width: 400px) and (min-device-pixel-ratio: 2.0)"></span> <!-- retina -->

          <!-- Fallback content for non-JS browsers. Same img src as the initial, unqualified source element. -->
          <noscript><img src="img/gruppo/gruppo_low.jpg" alt="A giant stone face at The Bayon temple in Angkor Thom, Cambodia"></img></noscript>
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