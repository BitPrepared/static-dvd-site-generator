<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE xsl:stylesheet  [
  <!ENTITY nbsp "&#160;">
  <!ENTITY eacute "&#233;">
  <!ENTITY agrave "&#224;">
  <!ENTITY copy "&#169;">
]>
<xsl:stylesheet 
	version="2.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
    xmlns:saxon="http://saxon.sf.net/"
	extension-element-prefixes="saxon"
	>
<xsl:output method="html" encoding="utf-8" name="html" doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"/>

<xsl:preserve-space elements="*" />
<xsl:template match="/">
<xsl:variable name="lcletters">abcdefghijklmnopqrstuvwxyz</xsl:variable>
<xsl:variable name="ucletters">ABCDEFGHIJKLMNOPQRSTUVWXYZ</xsl:variable>
<xsl:variable name="euroletters">äÄöÖüÜßáÁàÀâÂéÉèÈêÊíÍìÌîÎóÓòÒôÔúÚùÙûÛ</xsl:variable>
<xsl:variable name="normletters">aAoOuUsaAaAaAeEeEeEiIiIiIoOoOoOuUuUuU</xsl:variable>

<xsl:variable name="cr"><xsl:text>&#xa;</xsl:text></xsl:variable> <!-- new line -->	
<xsl:variable name="ncr">&lt;/li &gt;&lt;li&gt;</xsl:variable>

	<xsl:for-each select="fotos/foto">	
		<xsl:variable name="imgPath">../../foto/</xsl:variable>

		
		<xsl:variable name="filename"><xsl:value-of select="nomefile"/>.html</xsl:variable>
		<xsl:result-document href="{translate($filename,'  ','__')}" format="html"  >
		<!-- format the output of product pages from here -->

  <html xmlns="http://www.w3.org/1999/xhtml">
  <head>
  <meta http-equiv="Content-Type" content="text/html; charset=UTF-8"/>
  <title>Diario Fotografico - <xsl:value-of select="nomefile"/>&nbsp; ::: <xsl:value-of select="document('../src/impostazioni.xml')/impostazioni/custom1"/></title>
  <link href="../img/stile.css" rel="stylesheet" type="text/css"/>
  <link href="../img/stile_m.css" rel="stylesheet" type="text/css"/>
<!-- new line -->  
<style type="text/css">


.style1 {font-size: 14px}
.style2 {font-weight: bold}
.style3 {	font-size: 12px;	font-weight: bold;}
  .cloud {
	  display:inline; margin-right:1px;}


</style> </head>
  
  <body>

<table width="100%" height="100%" border="0" cellpadding="0" cellspacing="0" class="main">
  <tr>    <td align="right" valign="top" width="250px">
  
  <div id="menu">

      <!-- qui ci va il menu -->
      <li><a href="../index.html" style="color:#000000; font-weight:bold;">Isola di Melèe</a></li>


      <!-- prepara il menu per le differenti versioni, lancampo mette solo fol, blog, angoli di sq e dati e programmi; offline prepara per il cd e online prepara per la versione sul sito per archiviazioni annate -->

      <xsl:choose>
      <xsl:when test="document('../src/impostazioni.xml')/impostazioni/versione = 'lancampo'">
      <xsl:for-each select="document('../src/impostazioni.xml')/impostazioni/posizioni/posizione">
      <xsl:choose>
        <xsl:when test="custom2 = 'both'">
          <li><a href="../{path}{nomefile}"> <img src="../img/{image}" width="45px" height="60px" /> <xsl:value-of select="label"/></a></li>
          </xsl:when>
          </xsl:choose>
       </xsl:for-each>
       </xsl:when>
       <xsl:when test="document('../src/impostazioni.xml')/impostazioni/versione = 'offline'">
      <xsl:for-each select="document('../src/impostazioni.xml')/impostazioni/posizioni/posizione">
      <xsl:choose>
        <xsl:when test="custom2 = 'both'">
        <!-- fatto al volo per esportare il blog in una nuova finestra la notte del esporta campo. sistema il menu in tutte le versioni di espoerttazione --> 
        <xsl:if test="label = 'blog'">
            <li><a href="../{path}{nomefile}" target="_blank"> <img src="../img/{image}" width="50px" height="60px" /> <xsl:value-of select="label"/></a></li>
      </xsl:if>
      <xsl:if test="label != 'blog'">
         
          <li><a href="../{path}{nomefile}"> <img src="../img/{image}" width="45px" height="60px" /> <xsl:value-of select="label"/></a></li>
        
        </xsl:if>
        
        <!-- qui -->
          </xsl:when>
            <xsl:when test="custom2 = 'offline'">
          <li><a href="../{path}{nomefile}"> <img src="../img/{image}" width="45px" height="60px" /> <xsl:value-of select="label"/></a></li>
          </xsl:when>
          </xsl:choose>
       </xsl:for-each>
       </xsl:when>
       <xsl:when test="document('../src/impostazioni.xml')/impostazioni/versione = 'online'">
       <xsl:for-each select="document('../src/impostazioni.xml')/impostazioni/posizioni/posizione">
      <xsl:choose>
        <xsl:when test="custom2 = 'both'">
          <li><a href="../{path}{nomefile}"> <img src="../img/{image}" width="45px" height="60px" /> <xsl:value-of select="label"/></a></li>
          </xsl:when>
            <xsl:when test="custom2 = 'offline'">
          <li><a href="../{path}{nomefile}"> <img src="../img/{image}" width="45px" height="60px" /> <xsl:value-of select="label"/></a></li>
          </xsl:when>
          </xsl:choose>
       </xsl:for-each>
       </xsl:when>
      </xsl:choose>
    <!-- fine menu -->



 
 
 


        <span style="color:#000000;">

         <br/><br/>

         <li><strong>Cloud Attivit&agrave; :</strong></li>

         <xsl:for-each  select="document('../src/attivita.xml')/elenco/attivita">
              <li><a href="{tags/tag}.html"><xsl:value-of select="nome"/></a></li>
         </xsl:for-each>
         <br/><br/>
          <li><strong>Cloud Tags:</strong></li>

         <xsl:for-each  select="document('../src/tag.xml')/elenco/tag">
              <li class="cloud"><a href="{nome}.html"><xsl:value-of select="nome"/></a></li>
         </xsl:for-each>
         
        </span>
  
  
  </div>


  </td>

    <td align="center" valign="top" scope="col">
   <div iD="bone">
<div iD="head"><a href="index.html"><img src="../img/title1.gif" width="760" height="79" border="0" /></a></div>
    <div iD="content">
	
			<h2 class="productPage"><xsl:value-of select="nomefile" /></h2>
			<div id="moduleWrapper">
  
		
	
					<div class="module">
					<hr color="#42AC88"/>
	
						<div class="imgBox">
							<a href="{$imgPath}{nomefile}"><img src="med/{nomefile}" alt="{image}" /></a>
						</div>
						<table class="products" cellspacing="1px">
							
							<tbody>
							<xsl:if test="rank  != ''"><tr><td>Rank:  <img src="../img/star{rank}.gif" /></td></tr></xsl:if>
                            <br />
							<xsl:for-each select="commenti/commento">
								<tr><td height="25px">
								<xsl:choose>
    <xsl:when test="autore != ''">
    <strong><xsl:value-of select="autore" />:</strong> &nbsp;<xsl:value-of select="text" /><br />
      </xsl:when>
      <xsl:otherwise>
      
      </xsl:otherwise>
 </xsl:choose>

									<p>&nbsp;</p></td>
								</tr>
							</xsl:for-each>
							</tbody>
						</table>
					</div>
					
<div iD="footer"> <img src="../img/mappa_mi.png" width="760" height="300" /> </div>
</div></div> </div> </td>
  </tr>
</table>
</body></html>
			
		<!-- end of product page output format -->
		</xsl:result-document>


	</xsl:for-each>
</xsl:template>
</xsl:stylesheet>
