<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
        xmlns:ad="urn:x-inspire:specification:gmlas:Addresses:3.0"
        xmlns:am="http://inspire.jrc.ec.europa.eu/schemas/am/2.0"
        xmlns:am-ru="http://inspire.jrc.ec.europa.eu/schemas/am-ru/2.0"
        xmlns:aqd1="http://www.eionet.europa.eu/aqportal/Drep1"
        xmlns:aqd="http://aqd.ec.europa.eu/aqd/0.3.6b"
        xmlns:aqdold="http://www.exampleURI.com/AQD"
        xmlns:base2="http://inspire.ec.europa.eu/schemas/base2/1.0rc3"
        xmlns:base="http://inspire.ec.europa.eu/schemas/base/3.3rc3/"
        xmlns:ef="http://inspire.ec.europa.eu/schemas/ef/3.0rc3"
        xmlns:fn="http://www.w3.org/2005/xpath-functions"
        xmlns:gco="http://www.isotc211.org/2005/gco"
        xmlns:gmd="http://www.isotc211.org/2005/gmd"
        xmlns:gml="http://www.opengis.net/gml/3.2"
        xmlns:gn="urn:x-inspire:specification:gmlas:GeographicalNames:3.0"
        xmlns:gsr="http://www.isotc211.org/2005/gsr"
        xmlns:gss="http://www.isotc211.org/2005/gss"
        xmlns:gts="http://www.isotc211.org/2005/gts"
        xmlns:om="http://www.opengis.net/om/2.0"
        xmlns:ompr="http://inspire.ec.europa.eu/schemas/ompr/2.0rc3"
        xmlns:sam="http://www.opengis.net/sampling/2.0"
        xmlns:sams="http://www.opengis.net/samplingSpatial/2.0"
        xmlns:sparql="http://www.w3.org/2005/sparql-results#"
        xmlns:swe="http://www.opengis.net/swe/2.0"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- $Id$
     For schema http://dd.eionet.europa.eu/schemas/id2011850eu/AQD.xsd
             or http://dd.eionet.europa.eu/schemas/id2011850eu/AQD.xsd http://schemas.opengis.net/gml/3.2.1/gml.xsd
        xmlns:aqd="http://www.exampleURI.com/AQD"
  -->
<!-- SPARQL Endpoint URL variable -->
<xsl:variable name="sparqlEndpointUrl" select="'http://cr.eionet.europa.eu/sparql'"/>
<xsl:variable name="labelsFile" select="'http://converters.eionet.europa.eu/xmlfile/aqd-labels.xml'"/>

<xsl:output method='html' encoding='UTF-8' indent='yes'/>

<xsl:template match="/">
  <html>
  <head>
	<style>
                .errormsg { background: #ffe0e0; font-size: 120%; padding: 0.2em; border: 1px solid darkred; margin: 0.5em; }
                .inlineerror { background: #ffe0e0; font-weight: bold; padding: 0 0.2em; border: 1px solid darkred; margin: 0.1em 0.1em 0.1em 0.6em; }
                th[scope="row"] {
                    text-align: right;
                    vertical-align:top;
                    background-color: #b6ddf7;
                }
                ul {list-style-type: none; margin: 0; padding: 0}
		span.lbl {float: right; font-weight: bold; text-align: right; padding-right: 3px; width: 100%}
		table.tbl tr td, table.tbl tr th {border: solid 1px #cccccc;}
                table.full {width: 100%}
	</style>
  </head>
  <body>
<!-- Booby traps -->
  <xsl:for-each select="//aqdold:*">
    <xsl:if test="position() = 1">
      <div class="errormsg">
      <p>This file is using an obsolete namespace (http://www.exampleURI.com/AQD) for the aqd prefix</p>
      <p>The correct one is http://dd.eionet.europa.eu/schemas/id2011850eu</p>
      </div>
    </xsl:if>
  </xsl:for-each>

  <xsl:for-each select="//aqd1:*">
    <xsl:if test="position() = 1">
      <div class="errormsg">
      <p>This file is using an obsolete namespace (http://www.eionet.europa.eu/aqportal/Drep1) for the aqd prefix</p>
      <p>The correct one is http://dd.eionet.europa.eu/schemas/id2011850eu</p>
      </div>
    </xsl:if>
  </xsl:for-each>


  <xsl:apply-templates/>
  </body>
  </html>
</xsl:template>

<xsl:template match="gml:FeatureCollection">
  <h1>Features in this file</h1>
<!-- Booby traps -->
  <xsl:if test="not(contains(@xsi:schemaLocation,'http://dd.eionet.europa.eu/schemas/'))">
      <div class="errormsg">
      <p>Error: AQD schema found in xsi:schemaLocation without full URL or wrong URL!<br/>
      Found: <xsl:value-of select="@xsi:schemaLocation"/><br/>
      Correct syntax: "http://www.eionet.europa.eu/aqportal/Drep1 http://dd.eionet.europa.eu/schemas/id2011850eu/AQD.xsd" or later version.
      </p>
      </div>
  </xsl:if>
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="gml:featureMember">
  <xsl:apply-templates mode="feature"/>
</xsl:template>

<!-- Features -->
<xsl:template match="*" mode="feature">
    <h2><xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>
      <xsl:call-template name="getLabel"><xsl:with-param name="node" select="."/></xsl:call-template>: <xsl:value-of select="@gml:id"/>
    </h2>
    <table class="tbl full">
    <xsl:apply-templates mode="property"/>
    </table>
</xsl:template>

<!-- Assessment regimes -->
<xsl:template match="aqd:AQD_AssessmentRegime">
    <h2><xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>Assessment regime: <xsl:value-of select="@gml:id"/></h2>
    <table class="tbl">
    <tr><th scope="row">Zone</th>
        <td><xsl:call-template name="datavalue"><xsl:with-param name="node" select="aqd:zone"/></xsl:call-template></td></tr>
    <tr><th scope="row">Pollutant</th>
        <td><xsl:call-template name="datavalue"><xsl:with-param name="node" select="aqd:pollutant"/></xsl:call-template></td></tr>
    <xsl:apply-templates select="aqd:assessmentThreshold"/>
    <xsl:apply-templates select="aqd:assessmentMethods"/>

    </table>
</xsl:template>


<xsl:template match="aqd:assessmentThreshold">
    <tr><th scope="column" colspan="2">Assessment threshold</th>
    </tr>
    <tr><th scope="row">Objective Type</th>
        <td><xsl:call-template name="datavalue"><xsl:with-param name="node" select="aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:objectiveType"/></xsl:call-template></td>
    </tr>
    <tr><th scope="row">Reporting Metric</th>
        <td><xsl:call-template name="datavalue"><xsl:with-param name="node" select="aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:reportingMetric"/></xsl:call-template></td>
    </tr>
    <tr><th scope="row">Protection Target</th>
        <td><xsl:call-template name="datavalue"><xsl:with-param name="node" select="aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:protectionTarget"/></xsl:call-template></td>
    </tr>
    <tr><th scope="row">Exceedance Attainment</th>
        <td><xsl:value-of select="aqd:AssessmentThreshold/aqd:exceedanceAttainment"/></td>
    </tr>
    <tr><th scope="row">Classification date</th>
        <td><xsl:value-of select="aqd:AssessmentThreshold/aqd:classificationDate"/></td>
    </tr>
    <tr><th scope="row">Classification report</th>
        <td><xsl:value-of select="aqd:AssessmentThreshold/aqd:classificationReport"/></td>
    </tr>
</xsl:template>

<xsl:template match="aqd:assessmentMethods">
    <tr><th scope="column" colspan="2">Assessment methods</th></tr>
    <tr>
    <th scope="row">
        <xsl:call-template name="datavalue"><xsl:with-param name="node" select="aqd:AssessmentMethods/aqd:assessmentType"/></xsl:call-template><br/>
        <xsl:value-of select="aqd:AssessmentMethods/aqd:assessmentTypeDescription"/>
    </th>
    <td>
<xsl:for-each select="aqd:AssessmentMethods/aqd:modelAssessmentMetadata">
<xsl:call-template name="datavalue"><xsl:with-param name="node" select="."/></xsl:call-template><br/>
</xsl:for-each>
</td>
</tr>
</xsl:template>

<!-- PROPERTIES -->
<xsl:template match="swe:encoding" mode="property"/>

<xsl:template match="swe:field" mode="property">
  <tr>
    <th scope="row"><xsl:value-of select="local-name()"/>: <xsl:value-of select="@name"/></th>
    <td>
        <xsl:apply-templates mode="resourceorliteral"/>
    </td>
  </tr>
</xsl:template>

<xsl:template match="swe:values" mode="property">
  <tr>
    <th scope="row"><xsl:value-of select="local-name()"/></th>
    <td>
    <pre>Values (@ replaced by newline):&#10;<xsl:value-of select="translate(text(),'@','&#10;')"/></pre>
    </td>
  </tr>
</xsl:template>

<xsl:template match="*" mode="property">
  <tr>
    <th scope="row">
      <xsl:call-template name="getLabel"><xsl:with-param name="node" select="."/></xsl:call-template>
    </th>
    <td>
      <xsl:choose>
        <xsl:when test="@xlink:href != ''">
          <a><xsl:attribute name="href"><xsl:value-of select="@xlink:href"/></xsl:attribute><xsl:value-of select="@xlink:href"/></a>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="text()"/>
          <xsl:apply-templates mode="resourceorliteral"/>
        </xsl:otherwise>
      </xsl:choose>
    </td>
  </tr>
</xsl:template>

<xsl:template match="swe:Time|swe:Category|swe:Quantity" mode="resourceorliteral">
  Vocabulary: <xsl:value-of select="@definition"/>
</xsl:template>

<xsl:template match="text()" mode="resourceorliteral">
  <xsl:value-of select="text()"/>
</xsl:template>

<xsl:template match="*" mode="resourceorliteral">
  <table>
    <xsl:if test="@gml:id != ''">
      <caption>
        <xsl:attribute name="id"><xsl:value-of select="@gml:id"/></xsl:attribute>
        <xsl:value-of select="local-name()"/>: <xsl:value-of select="@gml:id"/>
      </caption>
    </xsl:if>
    <xsl:apply-templates mode="property"/>
  </table>
</xsl:template>

<!-- NAMED TEMPLATES -->

<!-- Any generic data value -->
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

  <xsl:template name="getLabel">
    <xsl:param name="node"/>
    <xsl:variable name="label" select="document($labelsFile)/labels/labelset[lang='en']/label[@id=name($node)]"/>
    <xsl:choose>
      <xsl:when test="$label = ''">
         <xsl:value-of select="$label"/>
      </xsl:when>
      <xsl:otherwise>
         <xsl:value-of select="local-name($node)"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
<!-- vim: set expandtab sw=2 : -->
