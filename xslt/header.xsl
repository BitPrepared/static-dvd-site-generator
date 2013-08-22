<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
<xsl:template name="header">

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

            <xsl:element name="a">
              <xsl:attribute name="xlink:href">
                <xsl:copy-of select="$profondita" />index.html
              </xsl:attribute>
              <xsl:attribute name="target">
                _blank
              </xsl:attribute>
            
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
            </xsl:element>
                
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

                  <xsl:element name="a">

                  <!-- <a href="{path}{nomefile}" target="_blank" alt="{nome}" title="{nome}">-->
                    
                    <!-- <img src="img/menu/{image}" width="45px" height="60px" alt="{nome}"/>  -->

                      <xsl:attribute name="href">
                        <xsl:copy-of select="$profondita" /><xsl:value-of select="path" /><xsl:value-of select="nomefile" />
                      </xsl:attribute>
                      <xsl:attribute name="target">
                        _blank
                      </xsl:attribute>
                      <xsl:attribute name="title">
                        <xsl:value-of select="nome" />
                      </xsl:attribute>
                      <xsl:attribute name="alt">
                        <xsl:value-of select="nome" />
                      </xsl:attribute>

                      <xsl:element name="img">
                            <xsl:attribute name="src">
                              <xsl:copy-of select="$profondita" />img/menu/<xsl:value-of select="image" />
                            </xsl:attribute>
                            <xsl:attribute name="width">
                              45px
                            </xsl:attribute>
                            <xsl:attribute name="height">
                              60px
                            </xsl:attribute>
                            <xsl:attribute name="alt">
                              <xsl:value-of select="nome" />
                            </xsl:attribute>
                      </xsl:element>


                    <!-- <xsl:value-of select="label"/> -->
                  <!-- </a> -->
                </xsl:element>
                </li>
              </xsl:if>
              <xsl:if test="label != 'blog'">
                <li>
                  <!-- <a href="{path}{nomefile}" alt="{nome}" title="{nome}"> -->
                    <!-- <img src="img/menu/{image}" width="45px" height="60px" alt="{nome}" />  -->

                  <xsl:element name="a">    

                    <xsl:attribute name="href">
                        <xsl:copy-of select="$profondita" /><xsl:value-of select="path" /><xsl:value-of select="nomefile" />
                      </xsl:attribute>
                      <xsl:attribute name="target">
                        _blank
                      </xsl:attribute>
                      <xsl:attribute name="title">
                        <xsl:value-of select="nome" />
                      </xsl:attribute>
                      <xsl:attribute name="alt">
                        <xsl:value-of select="nome" />
                      </xsl:attribute>

                      <xsl:element name="img">
                            <xsl:attribute name="src">
                              <xsl:copy-of select="$profondita" />img/menu/<xsl:value-of select="image" />
                            </xsl:attribute>
                            <xsl:attribute name="width">
                              45px
                            </xsl:attribute>
                            <xsl:attribute name="height">
                              60px
                            </xsl:attribute>
                            <xsl:attribute name="alt">
                              <xsl:value-of select="nome" />
                            </xsl:attribute>
                      </xsl:element>


                    <!-- <xsl:value-of select="label"/> -->
                  <!-- </a> -->
                </xsl:element>
                </li>
              </xsl:if>
            </xsl:when>
            <xsl:when test="domain = 'offline'">
              <li>
                <!-- <a href="{path}{nomefile}" alt="{nome}" title="{nome}"> -->
                <xsl:element name="a">    
                  <xsl:attribute name="href">
                        <xsl:copy-of select="$profondita" /><xsl:value-of select="path" /><xsl:value-of select="nomefile" />
                      </xsl:attribute>
                      <xsl:attribute name="target">
                        _blank
                      </xsl:attribute>
                      <xsl:attribute name="title">
                        <xsl:value-of select="nome" />
                      </xsl:attribute>
                      <xsl:attribute name="alt">
                        <xsl:value-of select="nome" />
                      </xsl:attribute>

                  <xsl:element name="img">
                        <xsl:attribute name="src">
                          <xsl:copy-of select="$profondita" />img/menu/<xsl:value-of select="image" />
                        </xsl:attribute>
                        <xsl:attribute name="width">
                          45px
                        </xsl:attribute>
                        <xsl:attribute name="height">
                          60px
                        </xsl:attribute>
                        <xsl:attribute name="alt">
                          <xsl:value-of select="nome" />
                        </xsl:attribute>
                  </xsl:element>

                  <!-- <xsl:value-of select="label"/> -->
                <!--</a>-->
                </xsl:element>
              </li>
            </xsl:when>
          </xsl:choose>
        </xsl:for-each>
      </ol>

    </div>

  </header>
</xsl:template>
</xsl:stylesheet>