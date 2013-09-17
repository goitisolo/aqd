<?xml version="1.0" encoding="UTF-8"?>
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
        xmlns:sam="http://www.opengis.net/sampling/2.0"
        xmlns:sams="http://www.opengis.net/samplingSpatial/2.0"
        xmlns:swe="http://www.opengis.net/swe/2.0"
        xmlns:xlink="http://www.w3.org/1999/xlink"
        xmlns:xs="http://www.w3.org/2001/XMLSchema"

    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:sparql="http://www.w3.org/2005/sparql-results#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:skos="http://www.w3.org/2008/05/skos#"
    xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
    xmlns="http://rdfdata.eionet.europa.eu/airquality/ontology/"

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
  <xsl:template match="aqd:area|aqd:residentPopulation|
   aqd:inletHeight|aqd:buildingDistance|aqd:kerbDistance|
   aqd:detectionLimit|aqd:numUnits" mode="property">
    <xsl:variable name="value" select="normalize-space(text())"/>
    <xsl:if test="$value != ''">
      <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
            <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#decimal</xsl:attribute>
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
      <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
        <xsl:choose>
          <xsl:when test="string-length($value) = 4">
            <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#int</xsl:attribute>
          </xsl:when>
          <xsl:when test="string-length($value) = 10">
            <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#date</xsl:attribute>
          </xsl:when>
          <xsl:otherwise>
            <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#dateTime</xsl:attribute>
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
      <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
        <xsl:if test="contains('|true|false|1|0|', normalize-space(text()))">
            <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#boolean</xsl:attribute>
        </xsl:if>
        <xsl:value-of select="$value"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

<!-- For literal elements (properties) -->
  <xsl:template match="*" mode="property">
    <xsl:variable name="value" select="normalize-space(text())"/>
    <xsl:if test="$value != '' or count(*) &gt; 0 or @xlink:href != ''">
      <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
      <xsl:choose>
        <xsl:when test="@xlink:href != ''">
          <xsl:attribute name="rdf:resource">
            <xsl:if test="not(contains(@xlink:href,'://'))"><xsl:value-of select="$envelopeurl"/>/</xsl:if>
            <xsl:call-template name="fix-uri">
              <xsl:with-param name="text" select="@xlink:href"/>
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
          <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#decimal</xsl:attribute>
          <xsl:value-of select="substring-before(gml:pos/text(),' ')"/>
        </geo:lat>
        <geo:long>
          <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#decimal</xsl:attribute>
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

  <!-- Standard resources -->
  <xsl:template match="*" mode="resourceorliteral">
    <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
      <xsl:if test="@gml:id != ''">
        <xsl:attribute name="rdf:ID">
          <xsl:value-of select="@gml:id"/>
        </xsl:attribute>
      </xsl:if>
      <xsl:apply-templates mode="property"/>
    </xsl:element>
  </xsl:template>

<!-- NAMED TEMPLATES -->

<xsl:template name="fix-uri">
  <xsl:param name="text" select="."/>
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
</xsl:template>

<!--
  <xsl:template name="swe_DataArrayType">
    <xsl:param name="node" select="."/>
    <xsl:call-template name="split-results">
        <xsl:with-param name="text" select="om:result/swe:values"/>
        <xsl:with-param name="pollutant" select="$node/swe:elementType/swe:DataRecord/swe:field[last()]/@name"/>
    </xsl:call-template>
  </xsl:template>
-->

  <!-- split on the @@ -->
<!--
  <xsl:template name="split-results">
    <xsl:param name="text"/>
    <xsl:param name="pollutant"/>
    <xsl:choose>
      <xsl:when test="contains($text, '@@')">
        <xsl:call-template name="resultasresource">
          <xsl:with-param name="text" select="substring-before($text, '@@')"/>
          <xsl:with-param name="pollutant" select="$pollutant"/>
        </xsl:call-template>
        <xsl:call-template name="split-results">
          <xsl:with-param name="text" select="substring-after($text, '@@')"/>
          <xsl:with-param name="pollutant" select="$pollutant"/>
        </xsl:call-template>
      </xsl:when>
      <xsl:otherwise>
        <xsl:call-template name="resultasresource">
          <xsl:with-param name="text" select="$text"/>
          <xsl:with-param name="pollutant" select="$pollutant"/>
        </xsl:call-template>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="resultasresource">
    <xsl:param name="text"/>
    <xsl:param name="pollutant"/>
    <xsl:if test="$text != ''">
      <result>
        <rdf:Description>
          <xsl:attribute name="rdf:ID">
            <xsl:value-of select="concat(generate-id(),'_',translate($text,':,-','___'))"/>
          </xsl:attribute>
          <xsl:call-template name="splitonefield">
            <xsl:with-param name="text" select="$text"/>
            <xsl:with-param name="columns" select="'time,validity,verification,measurement'"/>
          </xsl:call-template>
        </rdf:Description>
      </result>
    </xsl:if>
  </xsl:template>

  <xsl:template name="splitonefield">
    <xsl:param name="text"/>
    <xsl:param name="columns"/>
      <xsl:choose>
        <xsl:when test="contains($columns, ',')">
          <xsl:call-template name="resultproperty">
            <xsl:with-param name="text" select="substring-before($text, ',')"/>
            <xsl:with-param name="column" select="substring-before($columns, ',')"/>
          </xsl:call-template>
          <xsl:call-template name="splitonefield">
            <xsl:with-param name="text" select="substring-after($text, ',')"/>
            <xsl:with-param name="columns" select="substring-after($columns, ',')"/>
          </xsl:call-template>
        </xsl:when>
        <xsl:otherwise>
          <xsl:call-template name="resultproperty">
            <xsl:with-param name="text" select="$text"/>
            <xsl:with-param name="column" select="$columns"/>
          </xsl:call-template>
        </xsl:otherwise>
      </xsl:choose>
  </xsl:template>

  <xsl:template name="resultproperty">
    <xsl:param name="text"/>
    <xsl:param name="column"/>
    <xsl:element name="{$column}">
      <xsl:if test="string(number($text)) != 'NaN'">
        <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#decimal</xsl:attribute>
      </xsl:if>
    <xsl:value-of select="$text"/>
    </xsl:element>
  </xsl:template>
-->

</xsl:stylesheet>
<!-- vim: set expandtab sw=2 : -->