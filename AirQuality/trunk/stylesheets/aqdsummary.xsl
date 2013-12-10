<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
        xmlns:ad="urn:x-inspire:specification:gmlas:Addresses:3.0"
        xmlns:am="http://inspire.ec.europa.eu/schemas/am/3.0rc3"
        xmlns:am-ru="http://inspire.jrc.ec.europa.eu/schemas/am-ru/2.0"
        xmlns:aqd1="http://www.eionet.europa.eu/aqportal/Drep1"
        xmlns:aqd="http://aqd.ec.europa.eu/aqd/0.3.7c"
        xmlns:aqdold="http://aqd.ec.europa.eu/aqd/0.3.6b"
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
        table { border-collapse: collapse; margin: 2pt 0pt; border: solid 1px #000000 }
        table.tbl tr td, table.tbl tr th, table.tbl caption {border: solid 1px #cccccc;}
        td, th {padding: 1pt 3pt; }
        table.full {width: 100%}
        caption { background-color: #cddaec; font-size: 130% }
      </style>
    </head>
    <body>
      <xsl:apply-templates/>
    </body>
  </html>
</xsl:template>

<!--
     Root element
  -->
<xsl:template match="gml:FeatureCollection">
  <h1>Summary of features in this file</h1>

  <xsl:if test="count(gml:featureMember/aqd:AQD_Zone) &gt; 0">
    <table class="tbl">
      <xsl:for-each select="gml:featureMember/aqd:AQD_Zone">
        <xsl:if test="position() = 1">
          <xsl:call-template name="AQD_Zone_header"/>
        </xsl:if>
        <xsl:call-template name="AQD_Zone"/>
      </xsl:for-each>
    </table>
  </xsl:if>

  <xsl:if test="count(gml:featureMember/aqd:AQD_AssessmentRegime) &gt; 0">
    <table class="tbl">
      <xsl:for-each select="gml:featureMember/aqd:AQD_AssessmentRegime">
        <xsl:if test="position() = 1">
          <xsl:call-template name="AQD_AssessmentRegime_header"/>
        </xsl:if>
        <xsl:call-template name="AQD_AssessmentRegime"/>
      </xsl:for-each>
    </table>
  </xsl:if>

  <xsl:if test="count(gml:featureMember/aqd:AQD_Station) &gt; 0">
    <table class="tbl">
      <xsl:for-each select="gml:featureMember/aqd:AQD_Station">
        <xsl:if test="position() = 1">
          <xsl:call-template name="AQD_Station_header"/>
        </xsl:if>
        <xsl:call-template name="AQD_Station"/>
      </xsl:for-each>
    </table>
  </xsl:if>

  <xsl:if test="count(gml:featureMember/aqd:AQD_SamplingPoint) &gt; 0">
    <table class="tbl">
      <xsl:for-each select="gml:featureMember/aqd:AQD_SamplingPoint">
        <xsl:if test="position() = 1">
          <xsl:call-template name="AQD_SamplingPoint_header"/>
        </xsl:if>
        <xsl:call-template name="AQD_SamplingPoint"/>
      </xsl:for-each>
    </table>
  </xsl:if>

</xsl:template>



<xsl:template name="AQD_Zone_header">
  <caption>Zones</caption>
  <tr>
    <th>Inspire ID</th>
    <th>Name</th>
    <th>Designation period</th>
    <th>Zone code</th>
    <th>Resident population</th>
    <th>Area</th>
  </tr>
</xsl:template>

<xsl:template name="AQD_Zone">
  <tr>
    <td><xsl:value-of select="am:inspireId/base:Identifier/base:localId"/></td>
    <td><xsl:value-of select="am:name/descendant::gn:text"/></td>
    <td><xsl:value-of select="am:designationPeriod/gml:TimePeriod/gml:beginPosition"/>
     to <xsl:value-of select="am:designationPeriod/gml:TimePeriod/gml:endPosition"/></td>
    <td><xsl:value-of select="aqd:zoneCode"/></td>
    <td><xsl:value-of select="aqd:residentPopulation"/></td>
    <td><xsl:value-of select="aqd:area"/></td>
  </tr>
</xsl:template>



<xsl:template name="AQD_AssessmentRegime_header">
  <caption>Assessment regimes</caption>
  <tr>
    <th>Inspire ID</th>
  </tr>
</xsl:template>

<xsl:template name="AQD_AssessmentRegime">
  <tr>
    <td><xsl:value-of select="aqd:inspireId/base:Identifier/base:localId"/></td>
  </tr>
</xsl:template>



<xsl:template name="AQD_Station_header">
  <caption>Stations</caption>
  <tr>
    <th>Inspire ID</th>
    <th>Name</th>
    <th>Position</th>
    <th>Mobile</th>
    <th>Natl. code</th>
    <th>EU code</th>
  </tr>
</xsl:template>

<xsl:template name="AQD_Station">
  <tr>
    <td><xsl:value-of select="ef:inspireId/base:Identifier/base:localId"/></td>
    <td><xsl:value-of select="ef:name"/></td>
    <td><xsl:value-of select="ef:geometry/gml:Point/gml:pos"/></td>
    <td><xsl:value-of select="ef:mobile"/></td>
    <td><xsl:value-of select="aqd:natlStationCode"/></td>
    <td><xsl:value-of select="aqd:EUStationCode"/></td>
  </tr>
</xsl:template>




<xsl:template name="AQD_SamplingPoint_header">
  <caption>Sampling points</caption>
  <tr>
    <th>Inspire ID</th>
    <th>Name</th>
    <th>Position</th>
    <th>Mobile</th>
    <th>Belongs to</th>
    <th>Used AQD</th>
  </tr>
</xsl:template>

<xsl:template name="AQD_SamplingPoint">
  <tr>
    <td><xsl:value-of select="ef:inspireId/base:Identifier/base:localId"/></td>
    <td><xsl:value-of select="ef:name"/></td>
    <td><xsl:value-of select="ef:geometry/gml:Point/gml:pos"/></td>
    <td><xsl:value-of select="ef:mobile"/></td>
    <td><xsl:value-of select="ef:belongsTo/@xlink:href"/></td>
    <td><xsl:value-of select="aqd:usedAQD"/></td>
  </tr>
</xsl:template>


<!-- Wildcard property -->
<xsl:template match="*" mode="property">
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
</xsl:template>


</xsl:stylesheet>
<!-- vim: set expandtab sw=2 : -->
