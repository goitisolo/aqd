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

    xmlns:owl="http://www.w3.org/2002/07/owl#"
    xmlns:skos="http://www.w3.org/2008/05/skos#"
    xmlns="http://rdfdata.eionet.europa.eu/airquality/ontology/"
    xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"

        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<!-- $Id$
     For schema http://dd.eionet.europa.eu/schemas/id2011850eu/AQD.xsd
             or http://dd.eionet.europa.eu/schemas/id2011850eu/AQD.xsd http://schemas.opengis.net/gml/3.2.1/gml.xsd
        xmlns:aqd="http://www.exampleURI.com/AQD"
  -->
  <xsl:output method="xml" encoding="UTF-8" indent="yes"/>

  <xsl:template match="/">
    <rdf:RDF>
      <xsl:apply-templates/>
    </rdf:RDF>
  </xsl:template>

<!-- Empty wrappers -->
  <xsl:template match="gml:featureMember">
    <xsl:apply-templates mode="resource"/>
  </xsl:template>

<!-- Empty wrappers -->
  <xsl:template match="am-ru:reportingAuthority|gmd:CI_ResponsibleParty|gmd:contactInfo|gmd:CI_Contact|gmd:CI_Address" mode="property">
    <xsl:apply-templates mode="property"/>
  </xsl:template>

<!-- Stop processing of resources -->
  <xsl:template match="om:OM_Observation" mode="resource"/>

<!-- Stop processing of properties -->
  <xsl:template match="ef:geometry|am:geometry|sams:shape|om:result" mode="property"/>

<!-- for literal elements -->
  <xsl:template match="*" mode="property">
    <xsl:if test="normalize-space(.) != ''">
      <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
        <xsl:value-of select="normalize-space(.)"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

<!-- for literal dateTime elements -->
  <xsl:template match="ef:beginLifespan" mode="property">
    <xsl:if test="normalize-space(text()) != ''">
      <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
        <xsl:attribute name="rdf:datatype">http://www.w3.org/2001/XMLSchema#dateTime</xsl:attribute>
        <xsl:value-of select="normalize-space(.)"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

  <!-- for elements with sub-elements -->
  <xsl:template match="ef:observingCapability|gmd:address|am:competentAuthority|base2:LegislationReference" mode="property">
    <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
      <xsl:apply-templates mode="resource"/>
    </xsl:element>
  </xsl:template>

  <!-- standard resources -->
  <xsl:template match="*" mode="resource">
    <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
      <xsl:attribute name="rdf:ID">
        <xsl:value-of select="generate-id()"/>
      </xsl:attribute>
      <xsl:apply-templates mode="property"/>
    </xsl:element>
  </xsl:template>

<!-- for literal elements -->
  <xsl:template match="am:name" mode="property">
    <xsl:if test="text() != ''">
      <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
        <xsl:value-of select="descendant::gn:text"/>
      </xsl:element>
    </xsl:if>
  </xsl:template>

<!-- Treat as anonymous resource -->
  <xsl:template match="aqd:pollutants" mode="property">
    <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
      <Pollutant>
      <xsl:attribute name="rdf:ID">
        <xsl:value-of select="generate-id()"/>
      </xsl:attribute>
      <xsl:apply-templates mode="property"/>
      </Pollutant>
    </xsl:element>
  </xsl:template>

<!-- Treat as anonymous resource -->
  <xsl:template match="aqd:relevantEmissions" mode="property">
    <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
      <xsl:element name="RelevantEmissions" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
        <xsl:attribute name="rdf:ID">
          <xsl:value-of select="generate-id()"/>
        </xsl:attribute>
        <xsl:apply-templates mode="property"/>
      </xsl:element>
    </xsl:element>
  </xsl:template>

  <!-- Periods -->
  <xsl:template match="om:phenomenonTime|am-ru:reportingPeriod|ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime" mode="property">
    <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/"><xsl:value-of select="gml:TimePeriod/gml:beginPosition"/>/<xsl:value-of select="gml:TimePeriod/gml:endPosition"/></xsl:element>
  </xsl:template>



  <!-- named resources -->
  <xsl:template match="aqd:AQD_Zone|aqd:AQD_ReportingUnits|aqd:AQD_SamplingPoint|aqd:AQD_featureOfInterest|
       aqd:AQD_Station|aqd:AQD_Process|ef:ObservingCapability" mode="resource">
    <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
      <xsl:attribute name="rdf:ID"><xsl:value-of select="@gml:id"/></xsl:attribute>
    <xsl:apply-templates mode="property"/>
    </xsl:element>
  </xsl:template>


<!-- properties with xlinks -->
  <xsl:template match="am-ru:unit|
     ef:belongsTo|ef:observedProperty|ef:procedure|ef:featureOfInterest|ef:broader|
     om:procedure|om:observedProperty|om:featureOfInterest|om:name|
     sam:sampledFeature" mode="property">
    <xsl:element name="{local-name()}" namespace="http://rdfdata.eionet.europa.eu/airquality/ontology/">
      <xsl:choose>
        <xsl:when test="@xlink:href != ''">
          <xsl:attribute name="rdf:resource">
            <xsl:value-of select="@xlink:href"/>
          </xsl:attribute>
        </xsl:when>
        <xsl:otherwise>
          <xsl:value-of select="."/>
        </xsl:otherwise>
      </xsl:choose>
    </xsl:element>
  </xsl:template>

  <xsl:template name="swe_DataArrayType">
    <xsl:param name="node" select="."/>
    <pre>Values (@ replaced by newline):
<xsl:value-of select="translate($node/swe:values,'@','&#10;')"/></pre>
    <table class="tbl">
      <caption>
        <xsl:value-of select="$node/swe:elementType/@name"/>
      </caption>
      <xsl:for-each select="$node/swe:elementType/swe:DataRecord/swe:field">
        <tr>
          <th scope="row">
            <xsl:value-of select="@name"/>
          </th>
          <td>
            <xsl:value-of select="*/swe:uom/@code"/>
          </td>
        </tr>
      </xsl:for-each>
    </table>
  </xsl:template>
</xsl:stylesheet>
