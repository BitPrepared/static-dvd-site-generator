<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet  [
  <!ENTITY nbsp "&#160;">
  <!ENTITY eacute "&#233;">
  <!ENTITY agrave "&#224;">
  <!ENTITY copy "&#169;">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/" extension-element-prefixes="saxon">

  <xsl:output method="html" encoding="utf-8" name="html" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>

  <xsl:template match="/">

  	<xsl:for-each select="elenco/tag">	
  		<xsl:variable name="imgPath">../../foto/</xsl:variable>
  		
  		<xsl:variable name="filename"><xsl:value-of select="nome"/>.html</xsl:variable>
  		<xsl:result-document href="{translate($filename,'  ','__')}" format="html"  >
  		<!-- format the output of product pages from here -->

        <html xmlns="http://www.w3.org/1999/xhtml">
          <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                <meta name="description" content=""/>
                <meta name="viewport" content="width=device-width"/>
                <title>Diario Fotografico - &nbsp; ::: <xsl:value-of select="homepage/nomeEvento"/> ::: <xsl:value-of select="homepage/anno"/></title> 
                <link href="../css/styles.css" rel="stylesheet" type="text/css"/>
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
                     width="340"
                     height="100"
                     id="svg2"
                     version="1.1"
                     sodipodi:docname="Homepage Titolo">

                    <g id="layer1">
                      <a xlink:href="../index.html" target="_blank">
                        <text
                           xml:space="preserve"
                           style="font-size:40px;font-style:normal;font-weight:normal;line-height:125%;letter-spacing:0px;word-spacing:0px;fill:#000000;fill-opacity:1;stroke:none;font-family:Sans"
                           x="5"
                           y="54"
                           id="text2985"
                           sodipodi:linespacing="125%">
                        <tspan
                             sodipodi:role="line" id="tspan2987" x="5" y="54"
                             style="font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-family:Caribbean;-inkscape-font-specification:Caribbean">Bit Prepared</tspan>
                        </text>
                      </a>     
                      <text
                         xml:space="preserve"
                         style="font-size:40px;font-style:normal;font-weight:normal;line-height:125%;letter-spacing:0px;word-spacing:0px;fill:#000000;fill-opacity:1;stroke:none;font-family:Sans"
                         x="5"
                         y="90"
                         id="text2989"
                         sodipodi:linespacing="125%">
                      <tspan
                           sodipodi:role="line" id="tspan2991" x="5" y="90"
                           style="font-size:20px;font-style:normal;font-variant:normal;font-weight:normal;font-stretch:normal;font-family:Caribbean;-inkscape-font-specification:Caribbean">Costigiola 22 - 26 agosto 2013</tspan></text>
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
                            <a href="../{path}{nomefile}" target="_blank" alt="{nome}" title="{nome}">
                              <img src="../img/menu/{image}" width="45px" height="60px" alt="{nome}"/>  
                              <!-- <xsl:value-of select="label"/> -->
                            </a>
                          </li>
                        </xsl:if>
                        <xsl:if test="label != 'blog'">
                          <li>
                            <a href="../{path}{nomefile}" alt="{nome}" title="{nome}">
                              <img src="../img/menu/{image}" width="45px" height="60px" alt="{nome}" />  
                              <!-- <xsl:value-of select="label"/> -->
                            </a>
                          </li>
                        </xsl:if>
                      </xsl:when>
                      <xsl:when test="domain = 'offline'">
                        <li>
                          <a href="../{path}{nomefile}" alt="{nome}" title="{nome}">
                            <img src="../img/menu/{image}" width="45px" height="60px" alt="{nome}"/>  
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

              <h1 class="headline"> Isola di Mel&eacute;e <xsl:value-of select="homepage/anno"/> </h1>

              <div role="main" class="two-column-main-content">

                <!-- FOTO -->
                <div class="fotobook">                

                  <h2>
                    <xsl:value-of select="nome"/>
                  </h2>

                  <xsl:for-each select="gruppo/foto">

                    <div class="foto-in-elenco">

                      <a href="{idfile}.html" class="image">
                        <img alt="{idfile}" src="thu/{idfile}" />
                      </a>

                      <p class="description" style="font-size:10px;">
                        <xsl:value-of select="idfile"/>
                        <br />
                        <xsl:if test="rank  != ''">
                          <img src="../img/rank/star{rank}.gif" />
                        </xsl:if>
                      </p>
                    </div>

                  </xsl:for-each>

                  <!--div class="clear"/-->

                </div>
              </div>

              <div role="sidebar" class="two-column-left-content">


                <h3>Cloud Tags:</h3>
                <ul>

                    <xsl:for-each  select="document('../src/tag.xml')/elenco/tag">
                      <li>
                        <a href="{nome}.html">
                          <xsl:value-of select="nome"/>
                        </a>
                      </li>
                    </xsl:for-each>

                  </ul>
                  
                  <h3>Cloud Attivit&agrave; :</h3>
                  <ul>

                    <xsl:for-each  select="document('../src/attivita.xml')/elenco/attivita">
                      <li>
                        <a href="{tags/tag}.html">
                          <xsl:value-of select="nome"/>
                        </a>
                      </li>
                    </xsl:for-each>
                    
                  </ul>
                
              </div>

            </div>
            
            <footer role="contentinfo">
              <p class="copyright">&copy; Bit Prepared, 2013. All rights reserved.</p>
            </footer>

            <script src="js/matchmedia.js"/>
            <script src="js/picturefill.js"/>
              
          </body>
        </html>
  			
  		<!-- end of product page output format -->
  		</xsl:result-document>

  	</xsl:for-each>

  </xsl:template>

</xsl:stylesheet>
