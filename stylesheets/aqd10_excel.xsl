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
        <!-- SAMPLING POINT SAMPLE -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>SAMPLING POINT SAMPLE</xsl:text></xsl:attribute>
          <xsl:call-template name="sampointSample_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="sampointSample_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- SAMPLING POINT PROCESS -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>SAMPLING POINT PROCESS</xsl:text></xsl:attribute>
          <xsl:call-template name="sampointProcess_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="sampointProcess_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- SAMPLING POINT NETWORK -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>SAMPLING POINT NETWORK</xsl:text></xsl:attribute>
          <xsl:call-template name="sampointNetwork_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="sampointNetwork_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- SAMPLING POINT MODEL -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>SAMPLING POINT MODEL</xsl:text></xsl:attribute>
          <xsl:call-template name="sampointModel_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="sampointModel_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- SAMPLING POINT EMISSIONS -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>SAMPLING POINT EMISSIONS</xsl:text></xsl:attribute>
          <xsl:call-template name="sampointEmissions_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="sampointEmissions_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- SAMPLING POINT DISPERSION -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>SAMPLING POINT DISPERSION</xsl:text></xsl:attribute>
          <xsl:call-template name="sampointDispersion_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="sampointDispersion_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- SAMPLING POINT MODEL PROCESS -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>SAMPLING POINT MODEL PROCESS</xsl:text></xsl:attribute>
          <xsl:call-template name="sampointModelprocess_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="sampointModelprocess_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- SAMPLING POINT GENERAL -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>Sampling Point General</xsl:text></xsl:attribute>
          <xsl:call-template name="sampointGeneral_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_SamplingPoint">
              <xsl:call-template name="sampointGeneral_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ATTAINMENT PRELIM EXCEED-->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ATTAINMENT PRELIM EXCEED</xsl:text></xsl:attribute>
          <xsl:call-template name="attainmentPrelimExceed_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="attainmentPrelimExceed_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ATTAINMENT PRELIM DESC ADM-->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ATTAINMENT PRELIM DESC ADM</xsl:text></xsl:attribute>
          <xsl:call-template name="attainmentPrelimdescAdm_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="attainmentPrelimdescAdm_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ATTAINMENT PRELIM DESC-->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ATTAINMENT PRELIM DESC</xsl:text></xsl:attribute>
          <xsl:call-template name="attainmentPrelimdesc_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="attainmentPrelimdesc_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ATTAINMENT GENERAL-->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ATTAINMENT GENERAL</xsl:text></xsl:attribute>
          <xsl:call-template name="attainmentGeneral_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="attainmentGeneral_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ATTAINMENT FINAL EXCEED-->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ATTAINMENT FINAL EXCEED</xsl:text></xsl:attribute>
          <xsl:call-template name="attainmentFinalExceed_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="attainmentFinalExceed_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ATTAINMENT FINAL DESC ADM-->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ATTAINMENT FINAL DESC ADM</xsl:text></xsl:attribute>
          <xsl:call-template name="attainmentFinaldescAdm_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="attainmentFinaldescAdm_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ATTAINMENT FINAL DESC -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ATTAINMENT FINAL DESC</xsl:text></xsl:attribute>
          <xsl:call-template name="attainmentFinaldesc_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
              <xsl:call-template name="attainmentFinaldesc_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ASSESS REGIME METHODS -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ASSESS REGIME METHODS</xsl:text></xsl:attribute>
          <xsl:call-template name="assessRegimeMethods_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_AssessmentRegime">
              <xsl:call-template name="assesRegimeMethods_rows"/>
            </xsl:for-each>
          </table:table-rows>
        </table:table>
        <!-- ASSESS REGIME GENERAL -->
        <table:table>
          <xsl:attribute name="table:name"><xsl:text>ASSESS REGIME GENERAL</xsl:text></xsl:attribute>
          <xsl:call-template name="assessRegimeGeneral_headers"/>
          <table:table-rows>
            <xsl:for-each select="gml:featureMember/aqd:AQD_AssessmentRegime">
              <xsl:call-template name="assesRegimeGeneral_rows"/>
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


  <xsl:template name="sampointSample_headers">
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
            InletHeight
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            InletHeightUnit
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            BuilldingDistance
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            BuilldingDistanceUnit
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            KerbDistance
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            KerbDistanceUnit
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Pos
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

  <xsl:template name="sampointSample_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_SamplingPointProcess">
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
            <xsl:value-of select="ef:inspireId/base:Identifier/base:versionId"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:inletHeight"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:inletHeight/@uom"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:builldingDistance"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:builldingDistance/@uom"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:kerbDistance"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:kerbDistance/@uom"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="sams:shape/gml:Point/gml:pos"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="sams:shape/gml:Point/@srsName"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointProcess_headers">
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
            measurementType
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            measurementMethod
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            otherMeasurementMethod
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            samplingMethod
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            otherSamplingMethod
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            equivalenceDemonstrated
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            demonstrationReport
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            detectionLimit
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            detectionLimitUnit
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            documentation
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            qaReport
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DurationUnit
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DurationNumUnits
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            CadenceUnit
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            CadenceNumUnits
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="sampointProcess_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_SamplingPointProcess">
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
            <xsl:value-of select="ef:inspireId/base:Identifier/base:versionId"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ompr:type"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:measurementType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:measurementMethod/aqd:MeasurementMethod/aqd:measurementMethod/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:measurementMethod/aqd:MeasurementMethod/aqd:otherMeasurementMethod"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:samplingMethod/aqd:SamplingMethod/aqd:samplingMethod/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:samplingMethod/aqd:SamplingMethod/aqd:otherSamplingMethod"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dataQuality/aqd:DataQuality/aqd:detectionLimit"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dataQuality/aqd:DataQuality/aqd:detectionLimit/@UoM"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dataQuality/aqd:DataQuality/aqd:documentation"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dataQuality/aqd:DataQuality/aqd:qaReport"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:duration/aqd:TimeReferences/aqd:unit/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:duration/aqd:TimeReferences/aqd:numUnits"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:cadence/aqd:TimeReferences/aqd:unit/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:cadence/aqd:TimeReferences/aqd:numUnits"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointNetwork_headers">
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
            NetworkType
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            OperationBegin
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            OperationEnd
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Timezone
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ResponsibleParty
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="sampointNetwork_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Network">
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
            <xsl:value-of select="ef:inspireId/base:Identifier/base:versionId"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:name"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:networkType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:operationActivityPeriod/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:operationActivityPeriod/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:aggregationTimeZone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:responsibleParty"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointModel_headers">
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
            MediaMonitored
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ObservingTimeBegin
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ObservingTimeEnd
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ProcessType
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ResultNature
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Procedure
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            FeatureOfInterestId
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            FeatureOfInterestName
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            OrganisationLevel
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ObservedProperty
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
            AssessmentType
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Zone
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="sampointModel_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Model">
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
            <xsl:value-of select="ef:inspireId/base:Identifier/base:versionId"/>
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
            <xsl:value-of select="ef:mediaMonitored/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:processType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:resultNature/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/aqd:AQD_ModelArea/@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/aqd:AQD_ModelArea/gml:name"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:organisationLevel/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 19 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessmentType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 20 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointEmissions_headers">
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
            ObservedProperty
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            StationClassification
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            MainEmmissionSources
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            TrafficEmissions
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            HeatingEmissions
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            IndustrialEmissions
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DistanceSource
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="sampointEmissions_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Station">
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
            <xsl:value-of select="ef:inspireId/base:Identifier/base:versionId"/>
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
            <xsl:value-of select="ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:relevantEmissions/aqd:RelevantEmissions/aqd:mainEmissionSources/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:relevantEmissions/aqd:RelevantEmissions/aqd:trafficEmissions"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:relevantEmissions/aqd:RelevantEmissions/aqd:heatingEmissions"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:relevantEmissions/aqd:RelevantEmissions/aqd:industrialEmissions"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:relevantEmissions/aqd:RelevantEmissions/aqd:distanceSource"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointDispersion_headers">
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
            NatlStationCode
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Name
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            EUStationCode
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            StationInfo
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AreaClassification
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DispersionLocal
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DistanceJunction
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DistanceJunctionUnit
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            TrafficVolume
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Heavy-dutyFraction
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            TrafficSpeed
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            StreetWidth
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            HeightFacades
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DispersionRegional
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="sampointDispersion_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Station">
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
            <xsl:value-of select="ef:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:inspireId/base:Identifier/base:versionId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:natlStationCode"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:name"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:EUStationCode"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:stationInfo"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:areaClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionLocal/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:distanceJunction"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:distanceJunction/@uom"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:trafficVolume"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:heavy-dutyFraction"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:trafficSpeed"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:streetWidth"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:heightFacades"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionRegional/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="attainmentPrelimExceed_headers">
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
            Zone
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Exceedance
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            NumericalExceedance
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            NumberExceedances
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
            Adjustments
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentPrelimExceed_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Attainment">
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
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:numericalExceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:numberExceedances"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:adjustments/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="attainmentPrelimdescAdm_headers">
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
            Exceedance
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AdministrativeUnit
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentPrelimdescAdm_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Attainment">
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
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:administrativeUnit/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="attainmentPrelimdesc_headers">
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
            Zone
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Exceedance
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AreaClassification
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            SurfaceArea
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            RoadLength
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            StationUsed
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ModelUsed
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            PopulationExposed
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            EcosystemAreaExposed
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            SensitivePopulation
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            InfrastructureServices
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ReferenceYear
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ExceedanceDurationBegin
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ExceedanceDurationEnd
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Comment
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentPrelimdesc_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Attainment">
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
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:populationExposed"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:ecosystemAreaExposed"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:sensitivePopulation"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:infrastructureServices"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:referenceYear/gml:TimeInstant/gml:timePosition"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceDuration/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:exceedanceDuration/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionPreliminary/aqd:ExceedanceDescription/aqd:comment"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="attainmentGeneral_headers">
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
            Pollutant
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
            Zone
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Assessment
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentGeneral_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Attainment">
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
            <xsl:value-of select="aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:pollutant/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessment/@xlink:href""/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="attainmentFinalExceed_headers">
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
            Zone
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Exceedance
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            NumericalExceedance
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            NumberExceedances
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
            Adjustments
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentFinalExceed_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Attainment">
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
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numericalExceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:adjustments/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="attainmentFinaldescAdm_headers">
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
            Exceedance
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AdministrativeUnit
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentFinaldescAdm_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Attainment">
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
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:administrativeUnit/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="attainmentFinaldesc_headers">
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
              Zone
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              Exceedance
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              AreaClassification
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              SurfaceArea
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              RoadLength
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              StationUsed
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              ModelUsed
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              PopulationExposed
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              EcosystemAreaExposed
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              SensitivePopulation
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              InfrastructureServices
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              ReferenceYear
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              ExceedanceDurationBegin
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              ExceedanceDurationEnd
            </text:p>
          </table:table-cell>
          <table:table-cell table:style-name="Heading2">
            <text:p>
              Comment
            </text:p>
          </table:table-cell>
        </table:table-row>
      </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentFinaldesc_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_Attainment">
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
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:populationExposed"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:ecosystemAreaExposed"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:sensitivePopulation"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:infrastructureServices"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:referenceYear/gml:TimeInstant/gml:timePosition"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceDuration/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceDuration/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:comment"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="assessRegimeMethods_headers">
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
            Pollutant
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Zone
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AssessmentType
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Description
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ModelAssessmentMetadata
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="assesRegimeMethods_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_AssessmentRegime">
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
            <xsl:value-of select="aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:pollutant/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessmentType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessmentTypeDescription"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:modelAssessmentMetadata/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="assessRegimeGeneral_headers">
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
            Pollutant
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Zone
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
            ExceedanceAttainment
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ClassificationDate
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ClassificationReport
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="assesRegimeGeneral_rows">
    <xsl:for-each select="aqd:content/aqd:AQD_AssessmentRegime">
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
            <xsl:value-of select="aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:pollutant/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:exceedanceAttainment/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:classificationDate/gml:TimeInstant/gml:timePosition"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:classificationReport"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointModelprocess_headers">
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

  <xsl:template name="sampointModelprocess_rows">
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

  <xsl:template name="sampointGeneral_headers">
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

  <xsl:template name="sampointGeneral_rows">
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