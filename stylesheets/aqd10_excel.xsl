<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
        <!ENTITY sep ",">
        <!ENTITY nl "&#xa;">
        <!ENTITY bom "&#xFEFF;">
        ]>
<xsl:stylesheet version="2.0"
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
                xmlns:office="http://openoffice.org/2000/office"
                xmlns:table="http://openoffice.org/2000/table"
                xmlns:number="http://openoffice.org/2000/datastyle"
                xmlns:text="http://openoffice.org/2000/text"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:style="http://openoffice.org/2000/style">
  <xsl:output method="xml"/>

  <xsl:variable name="language">en</xsl:variable>
  <xsl:variable name="labels" select="document('http://converters.eionet.europa.eu/xmlfile/aqd-labels.xml')"/>
  <xsl:variable name="schema" select="document('http://dd.eionet.europa.eu/schemas/aqd10/aqd10.xsd')/xs:schema"/>

  <xsl:template match="gml:FeatureCollection">
    <office:document-content xmlns:office="http://openoffice.org/2000/office"
           xmlns:table="http://openoffice.org/2000/table" office:version="1.0"
           xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:number="http://openoffice.org/2000/datastyle"
           xmlns:text="http://openoffice.org/2000/text" xmlns:fo="http://www.w3.org/1999/XSL/Format"
           xmlns:style="http://openoffice.org/2000/style">
      <office:automatic-styles>
        <style:style style:name="row-height" style:family="table-cell">
          <style:properties  style:row-height="2cm" />
        </style:style>
        <style:style style:name="string-cell" style:family="table-cell">
          <style:properties fo:text-align="left"
                            fo:font-size="10pt" style:column-width="5cm" />
        </style:style>
        <style:style style:name="long-string-cell" style:family="table-cell">
          <style:properties fo:text-align="left"
                            fo:font-size="10pt" style:column-width="15cm" />
        </style:style>
        <style:style style:name="number-cell" style:family="table-cell">
          <style:properties fo:text-align="right"
                            fo:font-size="10pt" style:column-width="5cm" />
        </style:style>
        <style:style style:name="long-number-cell" style:family="table-cell">
          <style:properties fo:text-align="right"
                            fo:font-size="10pt" style:column-width="10cm" />
        </style:style>
        <style:style style:name="total-number-cell" style:family="table-cell">
          <style:properties fo:text-align="right" fo:font-weight="bold"
                            fo:font-size="10pt" style:column-width="5cm" />
        </style:style>
        <style:style style:name="string-heading" style:family="table-cell">
          <style:properties fo:text-align="left"
                            fo:font-size="10pt" style:column-width="5cm" fo:font-weight="bold" style:row-height="2cm" />
        </style:style>
        <style:style style:name="long-string-heading" style:family="table-cell">
          <style:properties fo:text-align="left"
                            fo:font-size="10pt" style:column-width="10cm" fo:font-weight="bold" />
        </style:style>
        <style:style style:name="short-string-heading" style:family="table-cell">
          <style:properties fo:text-align="left"
                            fo:font-size="10pt" style:column-width="2cm" fo:font-weight="bold" style:row-height="2cm" />
        </style:style>
        <style:style style:name="cell1" style:family="table-cell">
          <style:properties fo:text-align="left"
                            fo:font-size="10pt" style:column-width="5cm" />
        </style:style>
        <style:style style:name="cell2" style:family="table-cell">
          <style:properties fo:text-align="center"
                            fo:font-size="12pt" fo:font-style="italic" style:column-width="5cm" />
        </style:style>

        <style:style style:name="Heading2" style:family="table-cell">
          <style:properties fo:text-align="left"
                            fo:font-size="10pt" fo:font-weight="bold" style:column-width="5cm" style:row-height="2cm"/>
        </style:style>
        <style:style style:name="long-Heading2" style:family="table-cell">
          <style:properties fo:text-align="left"
                            fo:font-size="10pt" fo:font-weight="bold" style:column-width="10cm" style:row-height="2cm"/>
        </style:style>
        <style:style style:name="Heading3" style:family="table-cell">
          <style:properties fo:text-align="right"
                            fo:font-size="10pt" fo:font-weight="bold" style:column-width="5cm" />
        </style:style>
        <style:style style:name="Heading4" style:family="table-cell">
          <style:properties fo:text-align="right"
                            fo:font-size="10pt" fo:font-weight="bold" style:column-width="10cm" />
        </style:style>
      </office:automatic-styles>

      <office:body>
        <!-- SAMPLING POINT MODEL PROCESS -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>SAMPLING POINT MODEL PROCESS</xsl:text></xsl:attribute>
          <xsl:call-template name="modelprocess_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="modelprocess_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- SAMPLING POINT GENERAL -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>Sampling Point General</xsl:text></xsl:attribute>
          <xsl:call-template name="samplingpoint_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_SamplingPoint">
              <xsl:call-template name="samplingpoint_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ZONE POLLUTANTS -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ZONE POLLUTANTS</xsl:text></xsl:attribute>
          <xsl:call-template name="pollutant_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="pollutant_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ZONE GENERAL -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ZONE GENERAL</xsl:text></xsl:attribute>
          <xsl:call-template name="general_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="general_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
      </office:body>


    </office:document-content>
  </xsl:template>

  <xsl:template name="modelprocess_headers">
    <table:table-columns>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
    </table:table-columns>
    <table:table-header-rows>
      <table:table-row table:default-cell-value-type="string">
      <table:table-cell table:style-name="Heading2">
        <text:p>
          GMLID
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          LocalId
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          Namespace
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          Version
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          Type
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          Description
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          TemporalResolutionUnit
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          TemporalResolutionNum
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          SpatialResolution
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          DataQualityDescription
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          DataQualityReport
        </text:p>
      </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="modelprocess_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_ModelProcess">
      <table:table-row table:default-cell-value-type="string">
      <!-- 1 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="@gml:id"/>
        </text:p>
      </table:table-cell>
      <!-- 2 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ompr:inspireId/base:Identifier/base:localId"/>
        </text:p>
      </table:table-cell>
      <!-- 3 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ompr:inspireId/base:Identifier/base:namespace"/>
        </text:p>
      </table:table-cell>
      <!-- 4 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ompr:inspireId/base:Identifier/base:versionId"/>
        </text:p>
      </table:table-cell>
      <!-- 5 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ompr:type"/>
        </text:p>
      </table:table-cell>
      <!-- 6 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:description"/>
        </text:p>
      </table:table-cell>
      <!-- 7 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:temporalResolution/aqd:TimeReferences/aqd:unit/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 8 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:temporalResolution/aqd:TimeReferences/aqd:numUnits"/>
        </text:p>
      </table:table-cell>
      <!-- 9 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:spatialResolution"/>
        </text:p>
      </table:table-cell>
      <!-- 10 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:dataQualityDescription"/>
        </text:p>
      </table:table-cell>
      <!-- 11 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:dataQualityReport"/>
        </text:p>
      </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="samplingpoint_headers">
    <table:table-columns>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
    </table:table-columns>
    <table:table-header-rows>
    <table:table-row table:default-cell-value-type="string">
    <table:table-cell table:style-name="Heading2">
      <text:p>
        GMLID
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        LocalId
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        Namespace
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        Version
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        Name
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        AssessmentType
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        Zone
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        Broader
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        BelongsTo
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        OperationalActivityBegin
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        OperationalActivityEnd
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        RelevantEmissions
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        FeatureOfInterest
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        ObservingBegin
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        ObservingEnd
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        ObservedProperty
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        UsedAQD
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        ObjectiveType
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        ReportingMetric
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        ProtectionTarget
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        ReportingDB
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        ReportingDBOther
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        SRSName
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        Pos
      </text:p>
    </table:table-cell>
    <table:table-cell table:style-name="Heading2">
      <text:p>
        InvolvedIn
      </text:p>
    </table:table-cell>
    </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="samplingpoint_rows">
    <xsl:for-each select=".">
      <!-- 1 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="@gml:id"/>
        </text:p>
      </table:table-cell>
      <!-- 2 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:inspireId/base:Identifier/base:localId"/>
        </text:p>
      </table:table-cell>
      <!-- 3 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:inspireId/base:Identifier/base:namespace"/>
        </text:p>
      </table:table-cell>
      <!-- 4 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:inspireId/base:Identifier/base:versionid"/>
        </text:p>
      </table:table-cell>
      <!-- 5 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:name"/>
        </text:p>
      </table:table-cell>
      <!-- 6 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:assessmentType"/>
        </text:p>
      </table:table-cell>
      <!-- 7 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:zone/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 8 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:broader/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 9 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:belongsTo/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 10 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition"/>
        </text:p>
      </table:table-cell>
      <!-- 11 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition"/>
        </text:p>
      </table:table-cell>
      <!-- 12 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 13 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 14 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition"/>
        </text:p>
      </table:table-cell>
      <!-- 15 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition"/>
        </text:p>
      </table:table-cell>
      <!-- 16 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 17 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:usedAQD"/>
        </text:p>
      </table:table-cell>
      <!-- 18 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 19 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 20 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 21 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:reportingDB"/>
        </text:p>
      </table:table-cell>
      <!-- 22 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:reportingDBOther"/>
        </text:p>
      </table:table-cell>
      <!-- 23 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:geometry/gml:Point/@srsName"/>
        </text:p>
      </table:table-cell>
      <!-- 24 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:geometry/gml:Point/gml:pos"/>
        </text:p>
      </table:table-cell>
      <!-- 25 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="ef:involvedIn/@xlink:href"/>
        </text:p>
      </table:table-cell>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="general_headers">
  <table:table-columns>
    <table:table-column
            table:default-cell-value-type="string"
            table:default-cell-style-name="long-string-heading">
    </table:table-column>
    <table:table-column
            table:default-cell-value-type="string"
            table:default-cell-style-name="long-string-heading">
    </table:table-column>
    <table:table-column
            table:default-cell-value-type="string"
            table:default-cell-style-name="long-string-heading">
    </table:table-column>
    <table:table-column
            table:default-cell-value-type="string"
            table:default-cell-style-name="long-string-heading">
    </table:table-column>
    <table:table-column
            table:default-cell-value-type="string"
            table:default-cell-style-name="long-string-heading">
    </table:table-column>
    <table:table-column
            table:default-cell-value-type="string"
            table:default-cell-style-name="long-string-heading">
    </table:table-column>
    <table:table-column
            table:default-cell-value-type="string"
            table:default-cell-style-name="long-string-heading">
    </table:table-column>
  </table:table-columns>
  <table:table-header-rows>
    <table:table-row table:default-cell-value-type="string">
      <table:table-cell table:style-name="Heading2">
        <text:p>
          GMLID
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          LocalId
        </text:p>
      </table:table-cell>
      <table:table-cell table:style-name="Heading2">
        <text:p>
          Namespace
        </text:p>
      </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            GeographicalName
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ZoneCode
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ZoneType
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            BeginTime
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            EndTime
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            EnvironmentalDomain
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AQDZoneType
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ResidentPopulation
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Area
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            TimeExtensionExemption
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ResidentPopulationYear
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            SRSName
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="general_rows">
    <xsl:for-each select="aqd:AQD_Zone">
      <!-- 1 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="@gml:id"/>
        </text:p>
      </table:table-cell>
      <!-- 2 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="am:inspireId/base:Identifier/base:localId"/>
        </text:p>
      </table:table-cell>
      <!-- 3 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="am:inspireId/base:Identifier/base:namespace"/>
        </text:p>
      </table:table-cell>
      <!-- 4 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="am:name/descendant::gn:text"/>
        </text:p>
      </table:table-cell>
      <!-- 5 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:zoneCode"/>
        </text:p>
      </table:table-cell>
      <!-- 6 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="am:zoneType/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 7 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="am:designationPeriod/gml:TimePeriod/gml:beginPosition"/>
        </text:p>
      </table:table-cell>
      <!-- 8 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="am:designationPeriod/gml:TimePeriod/gml:endPosition"/>
        </text:p>
      </table:table-cell>
      <!-- 9 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="am:environmentalDomain/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 10 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:aqdZoneType"/>
        </text:p>
      </table:table-cell>
      <!-- 11 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:residentPopulation"/>
        </text:p>
      </table:table-cell>
      <!-- 12 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:area"/>
        </text:p>
      </table:table-cell>
      <!-- 13 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:timeExtensionExemption/@xlink:href"/>
        </text:p>
      </table:table-cell>
      <!-- 14 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition"/>
        </text:p>
      </table:table-cell>
      <!-- 15 -->
      <table:table-cell table:style-name="cell1">
        <text:p>
          <xsl:value-of select="am:geometry/*/@srsName"/>
        </text:p>
      </table:table-cell>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="pollutant_headers">
    <table:table-columns>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
    </table:table-columns>
    <table:table-header-rows>
      <table:table-row table:default-cell-value-type="string">
        <table:table-cell table:style-name="Heading2">
          <text:p>
            GMLID
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            LocalId
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Namespace
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            GeographicalName
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ZoneCode
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            PollutantCode
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ProtectionTarget
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>
  <xsl:template name="pollutant_rows">
      <xsl:for-each select="aqd:AQD_ZONE/aqd:pollutants/aqd:Pollutant">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../am:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../am:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../am:name/descendant::gn:text"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../aqd:zoneCode"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:pollutantCode/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>