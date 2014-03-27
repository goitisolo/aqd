<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
 <!ENTITY ref "http://reference.eionet.europa.eu/aq/">
 <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
 <!ENTITY ont "http://rdfdata.eionet.europa.eu/airquality/ontology/">
]>
<xsl:stylesheet version="1.0"
        xmlns:ad="urn:x-inspire:specification:gmlas:Addresses:3.0"
        xmlns:am="http://inspire.ec.europa.eu/schemas/am/3.0rc3"
        xmlns:am-ru="http://inspire.jrc.ec.europa.eu/schemas/am-ru/2.0"
        xmlns:aqd="http://aqd.ec.europa.eu/aqd/0.3.7c"
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
        xmlns:swe="http://www.opengis.net/swe/2.0"
        xmlns:xlink="http://www.w3.org/1999/xlink"

    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:sparql="http://www.w3.org/2005/sparql-results#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:skos="http://www.w3.org/2008/05/skos#"
    xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
    xmlns="&ont;"

        xmlns:str="http://exslt.org/strings"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- $Id$
     For schema http://dd.eionet.europa.eu/schemas/id2011850eu/AirQualityReporting.xsd
  -->
  <xsl:output method="xml" encoding="UTF-8" indent="no"/>

  <xsl:param name="envelopeurl"/>
  <xsl:param name="filename"/>

<!-- Root element -->
  <xsl:template match="/">
    <rdf:RDF>
      <xsl:apply-templates mode="resourceorliteral"/>
    </rdf:RDF>
  </xsl:template>

<!-- Empty wrappers -->
  <xsl:template match="gml:FeatureCollection|gml:featureMember" mode="resourceorliteral">
    <xsl:apply-templates mode="resourceorliteral"/>
  </xsl:template>

<!-- Stop processing of properties -->
  <xsl:template match="am:geometry|sams:shape|om:result|swe:encoding" mode="property"/>

<!-- For literal decimal elements (properties) -->
  <xsl:template match="aqd:altitude|aqd:area|aqd:residentPopulation|
   aqd:inletHeight|aqd:buildingDistance|aqd:kerbDistance|
   aqd:detectionLimit|aqd:numUnits" mode="property">
    <xsl:variable name="value" select="normalize-space(text())"/>
    <xsl:if test="$value != ''">
      <xsl:element name="{local-name()}" namespace="&ont;">
            <xsl:attribute name="rdf:datatype">&xsd;decimal</xsl:attribute>
        <xsl:value-of select="$value"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

<!-- For literal dateTime elements (properties) -->
  <xsl:template match="am:beginLifespanVersion|
    base2:date|base2:dateEnteredIntoForce|
    gml:beginPosition|gml:endPosition|gml:timePosition" mode="property">
    <xsl:variable name="value" select="normalize-space(text())"/>
    <xsl:if test="$value != ''">
      <xsl:element name="{local-name()}" namespace="&ont;">
        <xsl:choose>
          <xsl:when test="string-length($value) = 4">
            <xsl:attribute name="rdf:datatype">&xsd;int</xsl:attribute>
          </xsl:when>
          <xsl:when test="string-length($value) = 10">
            <xsl:attribute name="rdf:datatype">&xsd;date</xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="rdf:datatype">&xsd;dateTime</xsl:attribute>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:value-of select="$value"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

<!-- For literal Boolean elements (properties) -->
  <xsl:template match="ef:mobile|aqd:change|aqd:exceedance|aqd:usedAQD" mode="property">
    <xsl:variable name="value" select="normalize-space(text())"/>
    <xsl:if test="$value != ''">
      <xsl:element name="{local-name()}" namespace="&ont;">
        <xsl:if test="contains('|true|false|1|0|', normalize-space(text()))">
            <xsl:attribute name="rdf:datatype">&xsd;boolean</xsl:attribute>
        </xsl:if>
        <xsl:value-of select="$value"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <xsl:template match="ef:inspireId|aqd:inspireId|am:inspireId|ompr:inspireId" mode="property">
    <!-- Create the declarationFor property -->
    <xsl:element name="declarationFor" namespace="&ont;">
      <xsl:choose>
        <xsl:when test="starts-with(base:Identifier/base:namespace, 'http:')">
          <xsl:attribute name="rdf:resource"><xsl:value-of select="base:Identifier/base:namespace"/>/<xsl:value-of select="base:Identifier/base:localId"/></xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:attribute name="rdf:resource">&ref;<xsl:value-of select="base:Identifier/base:namespace"/>/<xsl:value-of select="base:Identifier/base:localId"/></xsl:attribute>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
    <!-- Also add the original element -->
    <xsl:element name="{local-name()}" namespace="&ont;">
      <xsl:apply-templates mode="resourceorliteral"/>
    </xsl:element>
  </xsl:template>

<!-- For literal elements (properties) -->
  <xsl:template match="*" mode="property">
    <xsl:variable name="value" select="normalize-space(text())"/>
    <xsl:if test="$value != '' or count(*) &gt; 0 or @xlink:href != ''">
      <xsl:element name="{local-name()}" namespace="&ont;">
      <xsl:choose>
        <xsl:when test="@xlink:href != ''">
          <xsl:attribute name="rdf:resource">
            <xsl:if test="not(contains(@xlink:href,'://'))">&ref;</xsl:if>
            <xsl:call-template name="fix-uri">
              <xsl:with-param name="text" select="normalize-space(@xlink:href)"/>
            </xsl:call-template>
          </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$value"/><xsl:apply-templates mode="resourceorliteral"/>
        </xsl:otherwise>
      </xsl:choose>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <!-- Ignore polygons -->
  <xsl:template match="gml:Polygon" mode="resourceorliteral"/>

  <xsl:template match="gml:Point" mode="resourceorliteral">
    <xsl:if test="gml:pos/@srsDimension='2' and (@srsName='urn:ogc:def:crs:EPSG::6326' or @srsName='urn:ogc:def:crs:EPSG::4326')">
      <geo:Point>
        <xsl:attribute name="rdf:ID">
          <xsl:value-of select="@gml:id"/>
        </xsl:attribute>
        <rdf:type rdf:resource="http://www.w3.org/2003/01/geo/wgs84_pos#SpatialThing"/>
        <geo:lat>
          <xsl:attribute name="rdf:datatype">&xsd;decimal</xsl:attribute>
          <xsl:value-of select="substring-before(gml:pos/text(),' ')"/>
        </geo:lat>
        <geo:long>
          <xsl:attribute name="rdf:datatype">&xsd;decimal</xsl:attribute>
          <xsl:value-of select="substring-after(gml:pos/text(),' ')"/>
        </geo:long>
      </geo:Point>
    </xsl:if>
  </xsl:template>


  <!-- The property contains text -->
  <xsl:template match="text()" mode="resourceorliteral">
    <xsl:value-of select="text()"/>
  </xsl:template>

  <!-- Unneeded wrappers -->
  <xsl:template match="gco:CharacterString|gmd:LocalisedCharacterString" mode="resourceorliteral">
    <xsl:value-of select="text()"/>
  </xsl:template>

  <xsl:template match="gmd:PT_FreeText" mode="resourceorliteral">
    <xsl:value-of select="descendant::gmd:LocalisedCharacterString/text()"/>
  </xsl:template>

  <xsl:template match="gn:GeographicalName" mode="resourceorliteral">
    <xsl:value-of select="descendant::gn:text/text()"/>
  </xsl:template>

  <!-- Standard resources -->
  <xsl:template match="*" mode="resourceorliteral">
    <xsl:element name="{local-name()}" namespace="&ont;">
      <xsl:if test="@gml:id != ''">
        <xsl:attribute name="rdf:ID">
          <xsl:value-of select="@gml:id"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates mode="property"/>
    </xsl:element>
  </xsl:template>

<!-- NAMED TEMPLATES -->

<!-- Replace spaces with %20 -->
<xsl:template name="fix-uri">
  <xsl:param name="text" select="."/>

  <xsl:choose>
    <xsl:when test="function-available('replace')">
      <xsl:value-of select="replace($text,' ','%20')"/>
    </xsl:when>
    <xsl:when test="function-available('str:replace')">
      <xsl:value-of select="str:replace($text,' ','%20')"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:choose>
        <xsl:when test="contains($text, ' ')">
          <xsl:value-of select="substring-before($text, ' ')"/>%20<xsl:call-template name="fix-uri">
            <xsl:with-param name="text" select="substring-after($text, ' ')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="$text"/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>
<!-- vim: set expandtab sw=2 : -->
