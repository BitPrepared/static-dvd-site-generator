<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet  [
  <!ENTITY nbsp "&#160;">
  <!ENTITY eacute "&#233;">
  <!ENTITY agrave "&#224;">
  <!ENTITY copy "&#169;">
]>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:saxon="http://saxon.sf.net/" extension-element-prefixes="saxon">

  <xsl:import href="header.xsl"/>
  <xsl:variable name="profondita">../</xsl:variable>
  <xsl:variable name="imgPath">../../foto/</xsl:variable>

  <xsl:output method="html" encoding="utf-8" name="html" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>

  <xsl:template match="/">

  	<xsl:for-each select="elenco/tag">	
  		
  		<xsl:variable name="filename"><xsl:value-of select="nome"/>.html</xsl:variable>
  		<xsl:result-document href="{translate($filename,'  ','__')}" format="html"  >
  		<!-- format the output of product pages from here -->

        <html xmlns="http://www.w3.org/1999/xhtml">
          <head>
                <meta http-equiv="Content-Type" content="text/html; charset=utf-8"/>
                <meta name="description" content=""/>
                <meta name="viewport" content="width=device-width"/>
                <title>Diario Fotografico - &nbsp; ::: <xsl:value-of select="document('../src/impostazioni.xml')/impostazioni/nome"/> ::: <xsl:value-of select="document('../src/impostazioni.xml')/impostazioni/anno"/> </title> 
                <link rel="stylesheet" type="text/css" media="(min-width: 800px)" href="../css/styles.css"/>
                <link rel="stylesheet" type="text/css" media="(max-width: 320px)" href="../css/styles-320.css" />
                <link rel="stylesheet" type="text/css" media="(min-width: 480px) and (max-width: 800px)" href="../css/styles-480.css" />
          </head>
          
          <body>
            
            <!-- Header -->
            <xsl:call-template name="header"/>

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
