<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
 <!ENTITY ref "http://reference.eionet.europa.eu/aq/">
 <!ENTITY xsd "http://www.w3.org/2001/XMLSchema#">
 <!ENTITY ont "http://reference.eionet.europa.eu/aq/ontology/">
]>
<!-- $Id$
  -->
<xsl:stylesheet version="1.0"
        xmlns:ms="urn:schemas-microsoft-com:sql:SqlRowSet1"
        xmlns:ad="urn:x-inspire:specification:gmlas:Addresses:3.0"
        xmlns:am="http://inspire.ec.europa.eu/schemas/am/3.0"
        xmlns:am-ru="http://inspire.jrc.ec.europa.eu/schemas/am-ru/2.0"
        xmlns:aqd="http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0"
        xmlns:base2="http://inspire.ec.europa.eu/schemas/base2/1.0"
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

    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
    xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
    xmlns:sparql="http://www.w3.org/2005/sparql-results#"
    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:skos="http://www.w3.org/2008/05/skos#"
    xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
    xmlns="&ont;"

        xmlns:str="http://exslt.org/strings"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

  <xsl:output method="xml" encoding="UTF-8" indent="no"/>


<!-- Root element -->
  <xsl:template match="/">
    <rdf:RDF>
      <!-- <xsl:attribute name="xml:base">&ref;</xsl:attribute> -->
      <xsl:apply-templates select="IPR_AnnualStatisticsExport/ms:Value"/>
    </rdf:RDF>
  </xsl:template>

  <xsl:template match="ms:Value">
    <ValidatedExceedence>
      <xsl:attribute name="rdf:about">#<xsl:value-of select="@observation_id"/></xsl:attribute>

      <inspireNamespace><xsl:value-of select="@network_namespace"/></inspireNamespace>
      <station>
        <xsl:call-template name="res-uri">
          <xsl:with-param name="baseuri" select="@network_namespace"/>
          <xsl:with-param name="localid" select="@station_localid"/>
        </xsl:call-template>
      </station>
      <samplingPoint>
        <xsl:call-template name="res-uri">
          <xsl:with-param name="baseuri" select="@network_namespace"/>
          <xsl:with-param name="localid" select="@samplingpoint_localid"/>
        </xsl:call-template>
      </samplingPoint>
      <sample>
        <xsl:call-template name="res-uri">
          <xsl:with-param name="baseuri" select="@network_namespace"/>
          <xsl:with-param name="localid" select="@sample_localid"/>
        </xsl:call-template>
      </sample>
      <procedure>
        <xsl:call-template name="res-uri">
          <xsl:with-param name="baseuri" select="@network_namespace"/>
          <xsl:with-param name="localid" select="@procedure_localid"/>
        </xsl:call-template>
      </procedure>
      <!--
      <xsl:if test="@station_lat != 'missing'"><geo:lat><xsl:value-of select="@station_lat"/></geo:lat></xsl:if>
      <xsl:if test="@station_long != 'missing'"><geo:long><xsl:value-of select="@station_long"/></geo:long></xsl:if>
      -->
      <beginPosition rdf:datatype="&xsd;dateTime"><xsl:value-of select="@datetime_begin"/></beginPosition>
      <endPosition rdf:datatype="&xsd;dateTime"><xsl:value-of select="@datetime_end"/></endPosition>
      <inserted rdf:datatype="&xsd;dateTime"><xsl:value-of select="@datetime_inserted"/></inserted>
      <xsl:if test="@datetime_updated != ''">
        <updated rdf:datatype="&xsd;dateTime"><xsl:value-of select="@datetime_updated"/></updated>
      </xsl:if>
      <airqualityValue rdf:datatype="&xsd;decimal"><xsl:value-of select="@value_numeric"/></airqualityValue>
      <datacapturePct rdf:datatype="&xsd;decimal"><xsl:value-of select="@datacapture"/></datacapturePct>
      <observationVerification><xsl:attribute name="rdf:resource"><xsl:value-of select="@verification"/></xsl:attribute></observationVerification>
      <observationValidity><xsl:attribute name="rdf:resource"><xsl:value-of select="@validity"/></xsl:attribute></observationValidity>
      <aggregationType><xsl:attribute name="rdf:resource"><xsl:value-of select="@aggregationType"/></xsl:attribute></aggregationType>
      <xsl:if test="@unit != ''">
        <unit><xsl:value-of select="@unit"/></unit>
      </xsl:if>
      <pollutant><xsl:attribute name="rdf:resource"><xsl:value-of select="@property_id"/></xsl:attribute></pollutant>
      </ValidatedExceedence>
    <!--
network_namespace="ES.BDCA.AQD"
network_localid="NET_ES216A"
observation_id="Observation_01036005_1_384c642f8c-ad7a-4d92-9fb4-411f08e2f1d7"
station_localid="STA_ES1350A"
samplingpoint_localid="SP_01036005_1_38"
sample_localid="SAM_01036005_1_38"
procedure_localid="SPP_01036005_1_38.1"
station_lat="missing" station_lon="missing"
samplingpoint_lat="missing" samplingpoint_lon="missing"
datetime_begin="2013-01-01T00:00:00"
datetime_end="2014-01-01T00:00:00"
datetime_inserted="2014-06-04T08:20:02.2530000"
value_numeric="9.00000000"
datacapture="0.01141553"
verification="http://dd.eionet.europa.eu/vocabulary/aq/observationverification/3" verification_notation="3"
validity="http://dd.eionet.europa.eu/vocabulary/aq/observationvalidity/-1"        validity_notation="-1"
aggregationType="http://dd.eionet.europa.eu/vocabulary/aq/aggregationprocess/P1Y" aggregationtype_notation="P1Y"
property_id="http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1"                property_notation="SO2"
-->
  </xsl:template>


<!-- NAMED TEMPLATES -->

<xsl:template name="res-uri">
  <xsl:param name="baseuri"/>
  <xsl:param name="localid"/>
  <xsl:attribute name="rdf:resource">
    <xsl:call-template name="ref-uri">
      <xsl:with-param name="baseuri" select="$baseuri"/>
      <xsl:with-param name="localid" select="$localid"/>
    </xsl:call-template>
  </xsl:attribute>
</xsl:template>

<xsl:template name="ref-uri">
  <xsl:param name="baseuri"/>
  <xsl:param name="localid"/>
  <xsl:choose>
    <xsl:when test="starts-with($baseuri, 'http:')">
        <xsl:call-template name="fix-uri">
          <xsl:with-param name="text" select="concat($baseuri,'/',$localid)"/>
        </xsl:call-template>
    </xsl:when>
    <xsl:otherwise>
        <xsl:call-template name="fix-uri">
          <xsl:with-param name="text" select="concat('&ref;',$baseuri,'/',$localid)"/>
        </xsl:call-template>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

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
