<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
 <!ENTITY sep ",">
 <!ENTITY nl "&#xa;">
 <!ENTITY bom "&#xFEFF;">
]>
<!-- $Id$
  AQD_SamplingPointProcess for fixed measurements business data 3 - Measurement processes / configurations
  For schema http://dd.eionet.europa.eu/schemas/id2011850eu/AQD.xsd
-->
<xsl:stylesheet version="1.0"
        xmlns:str="http://exslt.org/strings"

        xmlns:ad="urn:x-inspire:specification:gmlas:Addresses:3.0"
        xmlns:am="http://inspire.ec.europa.eu/schemas/am/3.0"
        xmlns:am-ru="http://inspire.jrc.ec.europa.eu/schemas/am-ru/2.0"
        xmlns:aqd="http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0"
        xmlns:base="http://inspire.ec.europa.eu/schemas/base/3.3"
        xmlns:ef="http://inspire.ec.europa.eu/schemas/ef/3.0"
        xmlns:fn="http://www.w3.org/2005/xpath-functions"
        xmlns:gco="http://www.isotc211.org/2005/gco"
        xmlns:gmd="http://www.isotc211.org/2005/gmd"
        xmlns:gml="http://www.opengis.net/gml/3.2"
        xmlns:gn="urn:x-inspire:specification:gmlas:GeographicalNames:3.0"
        xmlns:gsr="http://www.isotc211.org/2005/gsr"
        xmlns:gss="http://www.isotc211.org/2005/gss"
        xmlns:gts="http://www.isotc211.org/2005/gts"
        xmlns:om="http://www.opengis.net/om/2.0"
        xmlns:ompr="http://inspire.ec.europa.eu/schemas/ompr/2.0"
        xmlns:sam="http://www.opengis.net/sampling/2.0"
        xmlns:sams="http://www.opengis.net/samplingSpatial/2.0"
        xmlns:swe="http://www.opengis.net/swe/2.0"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method='text' encoding='UTF-8' indent='no'/>

<xsl:template match="/">
  <xsl:text>&bom;</xsl:text>
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="gml:FeatureCollection">
  <xsl:call-template name="header"/>
  <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader) &gt; 0">
    <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
      <xsl:apply-templates select="aqd:content"/>
    </xsl:for-each>
  </xsl:if>
  <xsl:call-template name="table">
    <xsl:with-param name="nodetype" select="gml:featureMember/aqd:AQD_SamplingPointProcess"/>
  </xsl:call-template>
</xsl:template>

<xsl:template match="aqd:content">
  <xsl:call-template name="table">
    <xsl:with-param name="nodetype" select="aqd:AQD_SamplingPointProcess"/>
  </xsl:call-template>
</xsl:template>

<!-- Named templates -->

<xsl:template name="header">
    <xsl:text>GMLID</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>LocalId</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Namespace</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Version</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Type</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>measurementType</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>measurementMethod</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>otherMeasurementMethod</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>samplingMethod</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>otherSamplingMethod</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>equivalenceDemonstrated</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>demonstrationReport</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>detectionLimit</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>detectionLimitUnit</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>documentation</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>qaReport</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>DurationUnit</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>DurationNumUnits</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>CadenceUnit</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>CadenceNumUnits</xsl:text><xsl:text>&nl;</xsl:text>
</xsl:template>

<xsl:template name="table">
    <xsl:param name="nodetype"/>
    <xsl:if test="count($nodetype) &gt; 0">
        <xsl:for-each select="$nodetype">
          <xsl:call-template name="row"/>
        </xsl:for-each>
    </xsl:if>
</xsl:template>

<xsl:template name="row">
    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="@gml:id"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="ef:inspireId/base:Identifier/base:localId"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="ef:inspireId/base:Identifier/base:namespace"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="ef:inspireId/base:Identifier/base:versionid"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="ompr:type"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:measurementType/@xlink:href"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:measurementMethod/aqd:MeasurementMethod/aqd:measurementMethod/@xlink:href"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:measurementMethod/aqd:MeasurementMethod/aqd:otherMeasurementMethod"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:samplingMethod/aqd:SamplingMethod/aqd:samplingMethod/@xlink:href"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:samplingMethod/aqd:SamplingMethod/aqd:otherSamplingMethod"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:dataQuality/aqd:DataQuality/aqd:detectionLimit"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:dataQuality/aqd:DataQuality/aqd:detectionLimit/@UoM"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:dataQuality/aqd:DataQuality/aqd:documentation"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:dataQuality/aqd:DataQuality/aqd:qaReport"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:duration/aqd:TimeReferences/aqd:unit/@xlink:href"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:duration/aqd:TimeReferences/aqd:numUnits"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:cadence/aqd:TimeReferences/aqd:unit/@xlink:href"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:cadence/aqd:TimeReferences/aqd:numUnits"/>
    </xsl:call-template>
    <xsl:text>&nl;</xsl:text>

</xsl:template>

<xsl:template name="wrapext">
    <xsl:param name="value"/>
    <xsl:choose>
      <xsl:when test="contains($value,'&sep;') or contains($value,'&#xa;') or contains($value,'&quot;')">
        <xsl:choose>
          <xsl:when test="function-available('str:replace')">
            <xsl:text>"</xsl:text><xsl:value-of select="str:replace($value,'&quot;','&quot;&quot;')"/><xsl:text>"</xsl:text>
          </xsl:when>
          <xsl:when test="function-available('replace')">
            <xsl:text>"</xsl:text><xsl:value-of select="replace($value,'&quot;','&quot;&quot;')"/><xsl:text>"</xsl:text>
          </xsl:when>
          <xsl:otherwise>
            <xsl:text>"</xsl:text><xsl:value-of select="$value"/><xsl:text>"</xsl:text>
          </xsl:otherwise>
        </xsl:choose>
      </xsl:when>
      <xsl:otherwise>
        <xsl:value-of select="$value"/>
      </xsl:otherwise>
    </xsl:choose>
</xsl:template>

</xsl:stylesheet>
<!-- vim: set expandtab sw=2 : -->
