<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
        xmlns:fn="http://www.w3.org/2005/xpath-functions"
        xmlns:sparql="http://www.w3.org/2005/sparql-results#"
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:aqd="http://www.eionet.europa.eu/aqportal/Drep1"
        xmlns:aqdold="http://www.exampleURI.com/AQD"
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
        xmlns:aqd="http://www.exampleURI.com/AQD"
  -->
<!-- SPARQL Endpoint URL variable -->
<xsl:variable name="sparqlEndpointUrl" select="'http://cr.eionet.europa.eu/sparql'"/>

<xsl:output method='html' encoding='UTF-8' indent='yes'/>

<xsl:template match="/">
  <html>
  <head>
	<style>
                th[scope="row"] {
                    text-align: left;
                    vertical-align:top;
                }
                ul {list-style-type: none; margin: 0; padding: 0}
		span.lbl {float: right; font-weight: bold; text-align: right; padding-right: 3px; width: 100%}
		table.tbl tr td, table.tbl tr th {border: solid 1px #cccccc;}
	</style>
  </head>
  <body>
<!-- Booby traps -->
  <xsl:for-each select="//aqdold:*">
    <xsl:if test="position() = 1">
      <div style="background: #e0e0e0">
      <h1>This file is using an obsolete namespace (http://www.exampleURI.com/AQD) for the aqd prefix</h1>
      <p>The correct one is http://www.eionet.europa.eu/aqportal/Drep1</p>
      </div>
    </xsl:if>
  </xsl:for-each>

  <xsl:apply-templates/>
  </body>
  </html>
</xsl:template>

<xsl:template match="gml:FeatureCollection">
  <h1>Features in this file</h1>

<!-- Reporting authorities -->
  <xsl:for-each select="aqd:AQD_ReportingUnits/am-ru:reportingAuthority">
    <h2><xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>Reporting authority: nr. <xsl:value-of select="position()"/>:
     <xsl:value-of select="@gml:id"/></h2>
    <div><xsl:value-of select="gmd:CI_ResponsibleParty"/></div>
  </xsl:for-each>

<!-- Reporting units -->
  <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingUnits">
    <h2><xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>Reporting unit: nr. <xsl:value-of select="position()"/>:
     <xsl:value-of select="@gml:id"/></h2>
    <table class="tbl">
    <tr><th scope="row">Name</th><td><xsl:value-of select="am-ru:reportingUnitName"/></td></tr>
    <tr><th scope="row">Reporting period</th><td><xsl:call-template name="time_period"><xsl:with-param name="node" select="am-ru:reportingPeriod"/></xsl:call-template></td></tr>
    <tr><th scope="row">Lifespan version</th><td><xsl:value-of select="am-ru:beginLifespanVersion"/></td></tr>
    <tr><th scope="row">Unit</th><td><ul>
    <xsl:for-each select="am-ru:unit">
        <li><xsl:call-template name="datavalue"><xsl:with-param name="node" select="."/></xsl:call-template></li>
    </xsl:for-each>
    </ul></td></tr>
    <tr><th scope="row">Change</th><td><xsl:value-of select="aqd:change"/></td></tr>
    </table>
  </xsl:for-each>


<!-- Zones -->
  <xsl:for-each select="gml:featureMember/aqd:AQD_Zone">
    <h2><xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>Zone: <xsl:value-of select="@gml:id"/></h2>
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
              <tr><td><xsl:value-of select="aqd:pollutantCode"/>
        <xsl:if test="function-available('fn:encode-for-uri')">
        (<xsl:call-template name="componentUrl"><xsl:with-param name="node" select="aqd:pollutantCode"/></xsl:call-template>)
        </xsl:if>
              </td><td><xsl:value-of select="aqd:protectionTarget"/></td></tr>
            </xsl:for-each>
          </table>
        </td></tr>
    </table>
  </xsl:for-each>


<!-- Stations -->
  <xsl:for-each select="gml:featureMember/aqd:AQD_Station">
    <h2><xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>Station: <xsl:value-of select="@gml:id"/></h2>
    <table class="tbl">
    <tr><th scope="row">Name</th><td><xsl:value-of select="ef:name"/></td></tr>
    <tr><th scope="row">Begins</th><td><xsl:value-of select="ef:beginLifespan"/></td></tr>
    <tr><th scope="row">Measurement regime</th><td><xsl:value-of select="ef:measurementRegime"/></td></tr>
    <tr><th scope="row">Media monitored</th><td><xsl:value-of select="ef:mediaMonitored"/></td></tr>
    <tr><th scope="row">Mobile</th><td><xsl:value-of select="ef:mobile"/></td></tr>
    <tr><th scope="row">Belongs to</th><td><ul>
    <xsl:for-each select="ef:belongsTo">
        <li><xsl:call-template name="datavalue"><xsl:with-param name="node" select="."/></xsl:call-template></li>
    </xsl:for-each>
    </ul></td></tr>

    <tr><th scope="row">Operational Activity</th><td><xsl:call-template name="time_period"><xsl:with-param name="node" select="ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime"/></xsl:call-template></td></tr>
    <tr><th scope="row">National station code</th><td><xsl:value-of select="aqd:natlStationCode"/></td></tr>
    <tr><th scope="row">Municipality</th><td><xsl:value-of select="aqd:municipality"/></td></tr>
    <tr><th scope="row">EU station code</th><td><xsl:value-of select="aqd:EUStationCode"/></td></tr>
    <tr><th scope="row">Station info</th><td><xsl:value-of select="aqd:stationInfo"/></td></tr>
    <tr><th scope="row">Area classification</th><td><xsl:value-of select="aqd:areaClassification"/></td></tr>
    </table>
  </xsl:for-each>

<!-- Observations -->
  <xsl:for-each select="gml:featureMember/om:OM_Observation">
    <h2><xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>Observation: <xsl:value-of select="@gml:id"/></h2>
    <table class="tbl">
    <tr><th scope="row">Phenomenon time</th><td><xsl:call-template name="time_period"><xsl:with-param name="node" select="om:phenomenonTime"/></xsl:call-template></td></tr>
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

<xsl:template name="time_period">
    <xsl:param name="node" select="."/>
    <xsl:value-of select="$node/gml:TimePeriod/gml:beginPosition"/> to <xsl:value-of select="$node/gml:TimePeriod/gml:endPosition"/>
</xsl:template>

<xsl:template name="swe_DataArrayType">
    <xsl:param name="node" select="."/>
    <pre>Values (@ replaced by newline):&#10;<xsl:value-of select="translate($node/swe:values,'@','&#10;')"/></pre>
    <table class="tbl">
      <caption><xsl:value-of select="$node/swe:elementType/@name"/></caption>
    <xsl:for-each select="$node/swe:elementType/swe:DataRecord/swe:field">
      <tr><th scope="row"> <xsl:value-of select="@name"/></th>
          <td><xsl:value-of select="*/swe:uom/@code"/></td>
      </tr>
    </xsl:for-each>
    </table>
</xsl:template>

<!-- Template contains the actual SPARQL to query the NUTS labels by code. -->
    <xsl:template name="componentUrl">
        <xsl:param name="code" select="''" />
        <xsl:variable name="sparql"><![CDATA[
PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
PREFIX air: <http://rdfdata.eionet.europa.eu/airbase/schema/>
SELECT ?s WHERE {?s a air:Component .
?s air:componentName> ]]>'<xsl:value-of select="$code" />'<![CDATA[}]]>
        </xsl:variable>
<!-- Create the sparql endpoint URL with correct parameters -->
        <xsl:variable name="sparqlUrl">
            <xsl:call-template name="getSparqlEndPointUrl">
                <xsl:with-param name="sparql">
                    <xsl:value-of select="normalize-space($sparql)" />
                </xsl:with-param>
            </xsl:call-template>
        </xsl:variable>
<!-- Send the query to SPARQL endpoint and parse the query result -->
        <xsl:value-of
            select="fn:document($sparqlUrl)/sparql:sparql/sparql:results/sparql:result/sparql:binding[@name='label']/sparql:literal/text()" />
    </xsl:template>


<!-- Helper template for constructing URL to SPARQL Endpoint. -->
  <xsl:template name="getSparqlEndPointUrl">
    <xsl:param name="sparql" select="''" />
    <xsl:variable name="sparql-encoded" select="fn:encode-for-uri($sparql)"/>
      <xsl:variable name="uriParams"
          select="concat('query=', $sparql-encoded , '&amp;format=application/xml')" />
      <xsl:value-of select="concat($sparqlEndpointUrl, '?', $uriParams)" />
  </xsl:template>

</xsl:stylesheet>
