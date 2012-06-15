<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:aqd="http://www.exampleURI.com/AQD"
        xmlns:base="urn:x-inspire:specification:gmlas:BaseTypes:3.2"
        xmlns:gmd="http://www.isotc211.org/2005/gmd"
        xmlns:gco="http://www.isotc211.org/2005/gco"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        xmlns:gml="http://www.opengis.net/gml/3.2"
        xmlns:gss="http://www.isotc211.org/2005/gss"
        xmlns:gts="http://www.isotc211.org/2005/gts"
        xmlns:gsr="http://www.isotc211.org/2005/gsr"
        xmlns:ef="http://inspire.jrc.ec.europa.eu/schemas/ef/2.0"
        xmlns:base2="http://inspire.jrc.ec.europa.eu/schemas/base2/0.1"
        xmlns:om="http://www.opengis.net/om/2.0"
        xmlns:swe="http://www.opengis.net/swe/2.0"
        xmlns:sams="http://www.opengis.net/samplingSpatial/2.0"
        xmlns:sam="http://www.opengis.net/sampling/2.0"
        xmlns:am="http://inspire.jrc.ec.europa.eu/schemas/am/2.0"
        xmlns:gn="urn:x-inspire:specification:gmlas:GeographicalNames:3.0"
        xmlns:am-ru="http://inspire.jrc.ec.europa.eu/schemas/am-ru/2.0"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- $Id$
     For schema http://dd.eionet.europa.eu/schemas/id2011850eu/AQD.xsd
             or http://dd.eionet.europa.eu/schemas/id2011850eu/AQD.xsd http://schemas.opengis.net/gml/3.2.1/gml.xsd
  -->
<xsl:output method='html' encoding='UTF-8' indent='yes'/>

<xsl:template match="/">
  <html>
  <head>
	<style>
		ul {list-style-type: none; margin: 0; padding: 0}
                .datatable th[scope="row"] {
                    text-align: right;
                    vertical-align:top;
                }
		span.lbl {float: right; font-weight: bold; text-align: right; padding-right: 3px; width: 100%}
		table.tbl tr td, table.tbl tr th {border: solid 1px #cccccc;}
	</style>
  </head>
  <body>
  
  <xsl:apply-templates/>
  </body>
  </html>
</xsl:template>

<xsl:template match="gml:FeatureCollection">
  <h2>Features</h2>

<!-- Reporting authorities -->
  <xsl:for-each select="aqd:AQD_ReportingUnits/am-ru:reportingAuthority">
    <h3>Reporting authority: nr. <xsl:value-of select="position()"/></h3>
    <div><xsl:value-of select="gmd:CI_ResponsibleParty"/></div>
  </xsl:for-each>

  <xsl:for-each select="gml:featureMember/aqd:AQD_Zone">
    <h3><xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>Zone: <xsl:value-of select="@gml:id"/></h3>
    <table class="tbl">
    <tr><th scope="row">Zone type</th><td><xsl:value-of select="am:zoneType"/></td></tr>
    <tr><th scope="row">Zone code</th><td><xsl:value-of select="aqd:zoneCode"/></td></tr>
    <tr><th scope="row">LAU</th><td><xsl:value-of select="aqd:LAU"/></td></tr>
    <tr><th scope="row">Resident population</th><td><xsl:value-of select="aqd:residentPopulation"/> (<xsl:value-of select="aqd:residentPopulationYear"/>)</td></tr>
    <tr><th scope="row">Legal basis</th><td><xsl:value-of select="am:legalBasis/base2:LegislationReference/base2:legalName"/></td></tr>
    <tr><th scope="row">Pollutants</th><td>
          <table>
            <tr><th>Code</th><th>Protection target</th></tr>
            <xsl:for-each select="aqd:pollutants">
              <tr><td><xsl:value-of select="aqd:pollutantCode"/></td><td><xsl:value-of select="aqd:protectionTarget"/></td></tr>
            </xsl:for-each>
          </table>
        </td></tr>
    </table>
  </xsl:for-each>



<!-- Observations -->
  <xsl:for-each select="gml:featureMember/om:OM_Observation">
    <h3><xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>Observation: <xsl:value-of select="@gml:id"/></h3>
    <table class="tbl">
    <tr><th scope="row">Phenomenon time</th><td><xsl:value-of select="om:phenomenonTime/gml:TimePeriod/gml:beginPosition"/> to <xsl:value-of select="om:phenomenonTime/gml:TimePeriod/gml:endPosition"/></td></tr>
    <tr><th scope="row">Result time</th><td><xsl:value-of select="om:resultTime/gml:TimeInstant/gml:timePosition"/></td></tr>
    <tr><th scope="row">Procedure</th><td><xsl:call-template name="datavalue"><xsl:with-param name="node" select="om:procedure"/></xsl:call-template></td></tr>
    <tr><th scope="row">Observed property</th><td><xsl:call-template name="datavalue"><xsl:with-param name="node" select="om:observedProperty"/></xsl:call-template></td></tr>
    <tr><th scope="row">Feature of interest</th><td><xsl:call-template name="datavalue"><xsl:with-param name="node" select="om:featureOfInterest"/></xsl:call-template></td></tr>
    <tr><th scope="row">Result</th><td>
    <xsl:call-template name="swe_DataArrayType"><xsl:with-param name="node" select="om:result"/></xsl:call-template>
    </td></tr>
    </table>
  </xsl:for-each>
</xsl:template>


<xsl:template name="datavalue">
    <xsl:param name="node" select="."/>
    <xsl:choose>
      <xsl:when test="$node/@xlink:href != ''">
        <a><xsl:attribute name="href"><xsl:value-of select="$node/@xlink:href"/></xsl:attribute><xsl:value-of select="$node/@xlink:href"/></a>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$node"/>
      </xsl:otherwise>
    </xsl:choose>
</xsl:template>

<xsl:template name="swe_DataArrayType">
    <xsl:param name="node" select="."/>
    <div>Values (@@ replaced by spaces): <xsl:value-of select="translate($node/swe:values,'@','&#10;')"/></div>
    <table class="tbl">
      <caption><xsl:value-of select="$node/swe:elementType/@name"/></caption>
    <xsl:for-each select="$node/swe:elementType/swe:DataRecord/swe:field">
      <tr><th scope="row"> <xsl:value-of select="@name"/></th>
          <td><xsl:value-of select="*/swe:uom/@code"/></td>
      </tr>
    </xsl:for-each>
    </table>
</xsl:template>

</xsl:stylesheet>
