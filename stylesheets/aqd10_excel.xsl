<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
        <!ENTITY sep ";">
        <!ENTITY nl "&#xa;">
        <!ENTITY bom "&#xFEFF;">
        ]>
<xsl:stylesheet version="2.0"
                xmlns:ad="urn:x-inspire:specification:gmlas:Addresses:3.0"
                xmlns:am="http://inspire.ec.europa.eu/schemas/am/3.0"
                xmlns:am-ru="http://inspire.jrc.ec.europa.eu/schemas/am-ru/2.0"
                xmlns:aqd="http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0"
                xmlns:base="http://inspire.ec.europa.eu/schemas/base/3.3"
                xmlns:base2="http://inspire.ec.europa.eu/schemas/base2/1.0"
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
        <!-- ZONE COMPETENT -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Zone) > 0 or
        count(gml:featureMember/aqd:AQD_Zone) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>CompetentAuthorities</xsl:text></xsl:attribute>
            <xsl:call-template name="zoneCompetent_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Zone">
                <xsl:call-template name="zoneCompetent_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Zone">
                <xsl:call-template name="zoneCompetent_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- ZONE GENERAL -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Zone) > 0 or
        count(gml:featureMember/aqd:AQD_Zone) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>AirQualityZones</xsl:text></xsl:attribute>
            <xsl:call-template name="zoneGeneral_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Zone">
                <xsl:call-template name="zoneGeneral_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Zone">
                <xsl:call-template name="zoneGeneral_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- ZONE POLLUTANTS -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Zone/aqd:pollutants) > 0 or
        count(gml:featureMember/aqd:AQD_Zone/aqd:pollutants) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>PollutantsAndProtectionTargets</xsl:text></xsl:attribute>
            <xsl:call-template name="zonePollutants_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Zone/aqd:pollutants">
                <xsl:call-template name="zonePollutants_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Zone/aqd:pollutants">
                <xsl:call-template name="zonePollutants_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT STATION -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Station) > 0 or
        count(gml:featureMember/aqd:AQD_Station) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>AirQualityStations</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointStation_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Station">
                <xsl:call-template name="sampointStation_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Station">
                <xsl:call-template name="sampointStation_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT SAMPLE -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Sample) > 0 or
        count(gml:featureMember/aqd:AQD_Sample) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>Sample</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointSample_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Sample">
                <xsl:call-template name="sampointSample_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Sample">
                <xsl:call-template name="sampointSample_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT PROCESS -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_SamplingPointProcess) > 0 or count(gml:featureMember/aqd:AQD_SamplingPointProcess) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>SamplingProcesses</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointProcess_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_SamplingPointProcess">
                <xsl:call-template name="sampointProcess_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_SamplingPointProcess">
                <xsl:call-template name="sampointProcess_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT NETWORK -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Network) > 0 or
        count(gml:featureMember/aqd:AQD_Network) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>AirQualityNetworks</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointNetwork_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Network">
                <xsl:call-template name="sampointNetwork_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Network">
                <xsl:call-template name="sampointNetwork_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT MODEL -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Model) > 0 or
        count(gml:featureMember/aqd:AQD_Model) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>AirQualityModels</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointModel_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Model">
                <xsl:for-each select="ef:observingCapability">
                  <xsl:call-template name="sampointModel_observing"/>
                </xsl:for-each>
                <xsl:if test="count(aqd:environmentalObjective) > 1">
                  <xsl:for-each select="aqd:environmentalObjective">
                    <xsl:call-template name="sampointModel_environment"/>
                  </xsl:for-each>
                </xsl:if>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Model">
                <xsl:for-each select="ef:observingCapability">
                  <xsl:call-template name="sampointModel_observing"/>
                </xsl:for-each>
                <xsl:if test="count(aqd:environmentalObjective) > 1">
                  <xsl:for-each select="aqd:environmentalObjective">
                    <xsl:call-template name="sampointModel_environment"/>
                  </xsl:for-each>
                </xsl:if>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT EMISSIONS -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_SamplingPoint) > 0 or
        count(gml:featureMember/aqd:AQD_SamplingPoint) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>EmissionConditions</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointEmissions_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_SamplingPoint/ef:observingCapability">
                <xsl:call-template name="sampointEmissions_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_SamplingPoint/ef:observingCapability">
                <xsl:call-template name="sampointEmissions_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT DISPERSION -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Station) > 0 or
        count(gml:featureMember/aqd:AQD_Station) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>DispersionConditions</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointDispersion_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Station">
                <xsl:call-template name="sampointDispersion_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Station">
                <xsl:call-template name="sampointDispersion_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT MODEL PROCESS -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_ModelProcess) > 0 or
        count(gml:featureMember/aqd:AQD_ModelProcess) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>ModelProcesses</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointModelprocess_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_ModelProcess">
                <xsl:call-template name="sampointModelprocess_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ModelProcess">
                <xsl:call-template name="sampointModelprocess_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT MODEL AREA -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_ModelArea) > 0 or
        count(gml:featureMember/aqd:AQD_ModelArea) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>AQModelArea</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointModelArea_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_ModelArea">
                <xsl:call-template name="sampointModelArea_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ModelArea">
                <xsl:call-template name="sampointModelArea_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- SAMPLING POINT GENERAL -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_SamplingPoint) > 0 or
        count(gml:featureMember/aqd:AQD_SamplingPoint) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>SamplingPoints</xsl:text></xsl:attribute>
            <xsl:call-template name="sampointGeneral_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_SamplingPoint">
                <xsl:choose>
                  <xsl:when test="count(aqd:environmentalObjective) > 0">
                    <xsl:call-template name="sampointGeneral_environment"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="sampointGeneral_observing"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_SamplingPoint">
                <xsl:choose>
                  <xsl:when test="count(aqd:environmentalObjective) > 0">
                    <xsl:call-template name="sampointGeneral_environment"/>
                  </xsl:when>
                  <xsl:otherwise>
                    <xsl:call-template name="sampointGeneral_observing"/>
                  </xsl:otherwise>
                </xsl:choose>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- ATTAINMENT PRELIM EXCEED-->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment/aqd:exceedanceDescriptionBase) > 0 or
        count(gml:featureMember/aqd:AQD_Attainment/aqd:exceedanceDescriptionBase) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>BaseExceedanceSituations</xsl:text></xsl:attribute>
            <xsl:call-template name="attainmentPrelimExceed_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment/aqd:exceedanceDescriptionBase">
                <xsl:call-template name="attainmentPrelimExceed_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Attainment/aqd:exceedanceDescriptionBase">
                <xsl:call-template name="attainmentPrelimExceed_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- ATTAINMENT PRELIM DESC ADM
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment) > 0 or
        count(gml:featureMember/aqd:AQD_Attainment) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>ATTAINMENT PRELIM DESC ADM</xsl:text></xsl:attribute>
            <xsl:call-template name="attainmentPrelimdescAdm_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment">
                <xsl:call-template name="attainmentPrelimdescAdm_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Attainment">
                <xsl:call-template name="attainmentPrelimdescAdm_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>-->
        <!-- ATTAINMENT PRELIM DESC-->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment/aqd:exceedanceDescriptionBase) > 0 or
        count(gml:featureMember/aqd:AQD_Attainment/aqd:exceedanceDescriptionBase) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>BaseExceedanceDescription</xsl:text></xsl:attribute>
            <xsl:call-template name="attainmentPrelimdesc_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment/aqd:exceedanceDescriptionBase">
                <xsl:call-template name="attainmentPrelimdesc_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Attainment/aqd:exceedanceDescriptionBase">
                <xsl:call-template name="attainmentPrelimdesc_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- ATTAINMENT GENERAL-->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment) > 0 or
        count(gml:featureMember/aqd:AQD_Attainment) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>GeneralAttainmentInfo</xsl:text></xsl:attribute>
            <xsl:call-template name="attainmentGeneral_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment">
                <xsl:call-template name="attainmentGeneral_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Attainment">
                <xsl:call-template name="attainmentGeneral_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- ATTAINMENT FINAL EXCEED-->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal) > 0 or
        count(gml:featureMember/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>FinalExceedanceSituations</xsl:text></xsl:attribute>
            <xsl:call-template name="attainmentFinalExceed_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal">
                <xsl:call-template name="attainmentFinalExceed_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal">
                <xsl:call-template name="attainmentFinalExceed_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- ATTAINMENT FINAL DESC ADM
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment) > 0 or
        count(gml:featureMember/aqd:AQD_Attainment) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>ATTAINMENT FINAL DESC ADM</xsl:text></xsl:attribute>
            <xsl:call-template name="attainmentFinaldescAdm_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment">
                <xsl:call-template name="attainmentFinaldescAdm_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Attainment">
                <xsl:call-template name="attainmentFinaldescAdm_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>-->
        <!-- ATTAINMENT FINAL DESC -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal) > 0 or
        count(gml:featureMember/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>FinalExceedanceDescription</xsl:text></xsl:attribute>
            <xsl:call-template name="attainmentFinaldesc_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal">
                <xsl:call-template name="attainmentFinaldesc_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal">
                <xsl:call-template name="attainmentFinaldesc_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- ASSESS REGIME METHODS -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods) > 0 or
        count(gml:featureMember/aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>AssessmentRegimeMethods</xsl:text></xsl:attribute>
            <xsl:call-template name="assessRegimeMethods_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods">
                <xsl:call-template name="assesRegimeMethods_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods">
                <xsl:call-template name="assesRegimeMethods_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
        <!-- ASSESS REGIME GENERAL -->
        <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_AssessmentRegime) > 0 or count(gml:featureMember/aqd:AQD_AssessmentRegime) > 0">
          <table:table>
            <xsl:attribute name="table:name"><xsl:text>AssessmentRegimes</xsl:text></xsl:attribute>
            <xsl:call-template name="assessRegimeGeneral_headers"/>
            <table:table-rows>
              <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader/aqd:content/aqd:AQD_AssessmentRegime">
                <xsl:call-template name="assesRegimeGeneral_rows"/>
              </xsl:for-each>
              <xsl:for-each select="gml:featureMember/aqd:AQD_AssessmentRegime">
                <xsl:call-template name="assesRegimeGeneral_rows"/>
              </xsl:for-each>
            </table:table-rows>
          </table:table>
        </xsl:if>
      </office:body>


    </office:document-content>
  </xsl:template>

  <xsl:template name="zoneCompetent_headers">
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
            IndividualName
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Organisation
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Language
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Nativeness
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Address
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Mail
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Telephone
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Website
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Role
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="zoneCompetent_rows">
    <xsl:for-each select=".">
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
            <xsl:value-of select="am:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:name/descendant::gn:text"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zoneCode"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:competentAuthority/base2:RelatedParty/base2:individualName/gmd:LocalisedCharacterString"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:competentAuthority/base2:RelatedParty/base2:organisationName/gmd:LocalisedCharacterString"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:address/ad:AddressRepresentation/ad:adminUnit/gn:GeographicalName/gn:language"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:address/ad:AddressRepresentation/ad:adminUnit/gn:GeographicalName/gn:nativeness"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:address/ad:AddressRepresentation/ad:adminUnit/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:electronicMailAddress"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:telephoneVoice"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:website"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:role"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointStation_headers">
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
            Municipality
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            EUStationCode
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ActivityBegin
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ActivityEnd
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Latitude
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Longitude
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            SRSName
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Altitude
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AltitudeUnit
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AreaClassification
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            BelongsTo
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="sampointStation_rows">
    <xsl:for-each select=".">
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
            <xsl:value-of select="aqd:natlStationCode"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:name"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:municipality"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:EUStationCode"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="normalize-space(tokenize(ef:geometry/gml:Point/gml:pos, ' ')[1])"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="normalize-space(tokenize(ef:geometry/gml:Point/gml:pos, ' ')[2])"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:geometry/gml:Point/@srsName"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:altitude"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:altitude/@uom"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:areaClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:belongsTo/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
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
            Latitude
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Longitude
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
    <xsl:for-each select=".">
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
            <xsl:value-of select="aqd:inspireId/base:Identifier/base:versionId"/>
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
            <xsl:value-of select="aqd:buildingDistance"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:buildingDistance/@uom"/>
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
            <xsl:value-of select="normalize-space(tokenize(sams:shape/gml:Point/gml:pos,' ')[1])" />
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="normalize-space(tokenize(sams:shape/gml:Point/gml:pos,' ')[2])" />
          </text:p>
        </table:table-cell>
        <!-- 13 -->
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
    <xsl:for-each select=".">
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
            <xsl:value-of select="aqd:measurementType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:measurementMethod/aqd:MeasurementMethod/aqd:measurementMethod/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:measurementMethod/aqd:MeasurementMethod/aqd:otherMeasurementMethod"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:samplingMethod/aqd:SamplingMethod/aqd:samplingMethod/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:samplingMethod/aqd:SamplingMethod/aqd:otherSamplingMethod"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dataQuality/aqd:DataQuality/aqd:detectionLimit"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dataQuality/aqd:DataQuality/aqd:detectionLimit/@uom"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dataQuality/aqd:DataQuality/aqd:documentation"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dataQuality/aqd:DataQuality/aqd:qaReport"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:duration/aqd:TimeReferences/aqd:unit/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:duration/aqd:TimeReferences/aqd:numUnits"/>
          </text:p>
        </table:table-cell>
        <!-- 19 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:cadence/aqd:TimeReferences/aqd:unit/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 20 -->
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
            Individual Name
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Organisation Name
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            e-mail Address
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Telephone
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Website
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="sampointNetwork_rows">
    <xsl:for-each select=".">
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
            <xsl:value-of select="aqd:networkType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:operationActivityPeriod/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:operationActivityPeriod/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:aggregationTimeZone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:responsibleParty/base2:RelatedParty/base2:individualName/gmd:LocalisedCharacterString"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:responsibleParty/base2:RelatedParty/base2:organisationName/gmd:LocalisedCharacterString"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:responsibleParty/base2:RelatedParty/base2:contact/base2:Contact/base2:electronicMailAddress"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:responsibleParty/base2:RelatedParty/base2:contact/base2:Contact/base2:telephoneVoice"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:responsibleParty/base2:RelatedParty/base2:contact/base2:Contact/base2:website"/>
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

  <xsl:template name="sampointModel_observing">
    <xsl:for-each select=".">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:inspireId/base:Identifier/base:versionId"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:name"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:mediaMonitored/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:processType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:resultNature/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:procedure/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:featureOfInterest/aqd:AQD_ModelArea/@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:featureOfInterest/aqd:AQD_ModelArea/gml:name"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:organisationLevel/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:observedProperty/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 19 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:assessmentType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 20 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointModel_environment">
    <xsl:for-each select=".">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:inspireId/base:Identifier/base:versionId"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:name"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:mediaMonitored/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:observingCapability/ef:ObservingCapability/ef:processType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:observingCapability/ef:ObservingCapability/ef:resultNature/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/aqd:AQD_ModelArea/@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/aqd:AQD_ModelArea/gml:name"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:organisationLevel/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 19 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:assessmentType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 20 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:zone/@xlink:href"/>
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
    <xsl:for-each select=".">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:inspireId/base:Identifier/base:versionId"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../ef:name"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:observedProperty/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:relevantEmissions/aqd:RelevantEmissions/aqd:mainEmissionSources/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:relevantEmissions/aqd:RelevantEmissions/aqd:trafficEmissions"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:relevantEmissions/aqd:RelevantEmissions/aqd:heatingEmissions"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:relevantEmissions/aqd:RelevantEmissions/aqd:industrialEmissions"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:relevantEmissions/aqd:RelevantEmissions/aqd:distanceSource"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointDispersion_headers">
    <table:table-columns>
      <!-- 1 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 2 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 3 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 4 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 5 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 6 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 7 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 8 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 9 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 10 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 11 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 12 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 13 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 14 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 15 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 16 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 17 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 18 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
    </table:table-columns>
    <table:table-header-rows>
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            GMLID
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            LocalId
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Namespace
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Version
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            NatlStationCode
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Name
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            EUStationCode
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            StationInfo
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AreaClassification
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DispersionLocal
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DistanceJunction
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DistanceJunctionUnit
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            TrafficVolume
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Heavy-dutyFraction
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            TrafficSpeed
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            StreetWidth
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            HeightFacades
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            DispersionRegional
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="sampointDispersion_rows">
    <xsl:for-each select=".">
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
            <xsl:value-of select="aqd:natlStationCode"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:name"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:EUStationCode"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:stationInfo"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:areaClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionLocal/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:distanceJunction"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:distanceJunction/@uom"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:trafficVolume"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:heavy-dutyFraction"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:trafficSpeed"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:streetWidth"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:dispersionSituation/aqd:DispersionSituation/aqd:heightFacades"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
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
            Pollutant
          </text:p>
        </table:table-cell>
        <!-- <table:table-cell table:style-name="Heading2">
          <text:p>
            Adjustments
          </text:p>
        </table:table-cell> -->
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentPrelimExceed_rows">
    <xsl:for-each select=".">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:numericalExceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:numberExceedances"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:pollutant/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:adjustments/@xlink:href"/>
          </text:p>
        </table:table-cell> -->
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
    <xsl:for-each select=".">
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
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Pollutant
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentPrelimdesc_rows">
    <xsl:for-each select=".">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:populationExposed"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:ecosystemAreaExposed"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:sensitivePopulation"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:infrastructureServices"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:referenceYear/gml:TimeInstant/gml:timePosition"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceDuration/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceDuration/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:comment"/>
          </text:p>
        </table:table-cell>
        <!-- 19 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:pollutant/@xlink:href"/>
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
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Pollutant
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentGeneral_rows">
    <xsl:for-each select=".">
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
            <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:assessment/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:pollutant/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="attainmentFinalExceed_headers">
    <table:table-columns>
      <!-- 1 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 2 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 3 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 4 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 5 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 6 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 7 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 8 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 9 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 10 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 11 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 12 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 13 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 14 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
    </table:table-columns>
    <table:table-header-rows>
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            GMLID
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            LocalId
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Namespace
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Zone
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Exceedance
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            NumericalExceedance
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            NumberExceedances
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ObjectiveType
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ReportingMetric
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ProtectionTarget
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            ValueAfterAdjustment
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AdjustmentType
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            AdjustmentDescription
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Pollutant
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentFinalExceed_rows">
    <xsl:for-each select=".">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:numericalExceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:numberExceedances"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentTypeDescription"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:pollutant/@xlink:href"/>
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
    <xsl:for-each select=".">
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
      <!-- 1 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 2 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 3 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 4 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 5 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 6 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 7 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 8 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 9 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 10 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 11 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 12 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 13 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 14 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 15 -->
      <table:table-column
              table:default-cell-value-type="string"
              table:default-cell-style-name="long-string-heading">
      </table:table-column>
      <!-- 16 -->
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
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Pollutant
          </text:p>
        </table:table-cell>
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="attainmentFinaldesc_rows">
    <xsl:for-each select=".">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedance"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed/@xlink:href" separator="&sep;"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:populationExposed"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:ecosystemAreaExposed"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:sensitivePopulation"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:infrastructureServices"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceExposure/aqd:ExceedanceExposure/aqd:referenceYear/gml:TimeInstant/gml:timePosition"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceDuration/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:exceedanceDuration/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:ExceedanceDescription/aqd:comment"/>
          </text:p>
        </table:table-cell>
        <!-- 19 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:pollutant/@xlink:href"/>
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
            SamplingPointAssessment
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
    <xsl:for-each select=".">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../aqd:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../aqd:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../aqd:pollutant/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../../aqd:zone/@xlink:href"/>
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
            <xsl:value-of select="aqd:samplingPointAssessmentMetadata/@xlink:href" separator="&sep;"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
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
    <xsl:for-each select=".">
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
    <xsl:for-each select=".">
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

  <xsl:template name="sampointModelArea_headers">
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
      </table:table-row>
    </table:table-header-rows>
  </xsl:template>

  <xsl:template name="sampointModelArea_rows">
    <xsl:for-each select=".">
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
            <xsl:value-of select="aqd:inspireId/base:Identifier/base:versionId"/>
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
            Latitude
          </text:p>
        </table:table-cell>
        <table:table-cell table:style-name="Heading2">
          <text:p>
            Longitude
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

  <xsl:template name="sampointGeneral_environment">
    <xsl:variable name="Parent" select="."/>
    <xsl:for-each select="ef:observingCapability">
      <xsl:variable name="observingCapability" select="."/>
      <xsl:for-each-group select="$Parent/aqd:environmentalObjective/aqd:EnvironmentalObjective" group-by="concat(aqd:objectiveType/@xlink:href,aqd:reportingMetric/@xlink:href,aqd:protectionTarget/@xlink:href)">
        <table:table-row table:default-cell-value-type="string">
          <!-- 1 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/@gml:id"/>
            </text:p>
          </table:table-cell>
          <!-- 2 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:inspireId/base:Identifier/base:localId"/>
            </text:p>
          </table:table-cell>
          <!-- 3 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:inspireId/base:Identifier/base:namespace"/>
            </text:p>
          </table:table-cell>
          <!-- 4 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:inspireId/base:Identifier/base:versionId"/>
            </text:p>
          </table:table-cell>
          <!-- 5 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:name"/>
            </text:p>
          </table:table-cell>
          <!-- 6 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/aqd:assessmentType/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 7 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/aqd:zone/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 8 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:broader/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 9 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:belongsTo/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 10 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition"/>
            </text:p>
          </table:table-cell>
          <!-- 11 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition"/>
            </text:p>
          </table:table-cell>
          <!-- 12 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 13 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$observingCapability/ef:ObservingCapability/ef:featureOfInterest/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 14 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition"/>
            </text:p>
          </table:table-cell>
          <!-- 15 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition"/>
            </text:p>
          </table:table-cell>
          <!-- 16 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 17 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/aqd:usedAQD"/>
            </text:p>
          </table:table-cell>
          <!-- 18 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="aqd:objectiveType/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 19 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="aqd:reportingMetric/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 20 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="aqd:protectionTarget/@xlink:href"/>
            </text:p>
          </table:table-cell>
          <!-- 21 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/aqd:reportingDB"/>
            </text:p>
          </table:table-cell>
          <!-- 22 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/aqd:reportingDBOther"/>
            </text:p>
          </table:table-cell>
          <!-- 23 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:geometry/gml:Point/@srsName"/>
            </text:p>
          </table:table-cell>
          <!-- 24 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="normalize-space(tokenize($Parent/ef:geometry/gml:Point/gml:pos,' ')[1])" />
            </text:p>
          </table:table-cell>
          <!-- 25 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="normalize-space(tokenize($Parent/ef:geometry/gml:Point/gml:pos,' ')[2])" />
            </text:p>
          </table:table-cell>
          <!-- 26 -->
          <table:table-cell table:style-name="cell1">
            <text:p>
              <xsl:value-of select="$Parent/ef:involvedIn/@xlink:href"/>
            </text:p>
          </table:table-cell>
        </table:table-row>
      </xsl:for-each-group>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="sampointGeneral_observing">
    <xsl:variable name="Parent" select="."/>
    <xsl:for-each select="ef:observingCapability">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:inspireId/base:Identifier/base:versionId"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:name"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/aqd:assessmentType/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/aqd:zone/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 8 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:broader/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 9 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:belongsTo/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 10 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 11 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 12 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 13 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:featureOfInterest/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 14 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 15 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition"/>
          </text:p>
        </table:table-cell>
        <!-- 16 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="ef:ObservingCapability/ef:observedProperty/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 17 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/aqd:usedAQD"/>
          </text:p>
        </table:table-cell>
        <!-- 18 -->
        <table:table-cell table:style-name="cell1">
          <text:p>

          </text:p>
        </table:table-cell>
        <!-- 19 -->
        <table:table-cell table:style-name="cell1">
          <text:p>

          </text:p>
        </table:table-cell>
        <!-- 20 -->
        <table:table-cell table:style-name="cell1">
          <text:p>

          </text:p>
        </table:table-cell>
        <!-- 21 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/aqd:reportingDB"/>
          </text:p>
        </table:table-cell>
        <!-- 22 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/aqd:reportingDBOther"/>
          </text:p>
        </table:table-cell>
        <!-- 23 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:geometry/gml:Point/@srsName"/>
          </text:p>
        </table:table-cell>
        <!-- 24 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="normalize-space(tokenize(../ef:geometry/gml:Point/gml:pos,' ')[1])" />
          </text:p>
        </table:table-cell>
        <!-- 25 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="normalize-space(tokenize(../ef:geometry/gml:Point/gml:pos,' ')[2])" />
          </text:p>
        </table:table-cell>
        <!-- 26 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="$Parent/ef:involvedIn/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="zoneGeneral_headers">
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
            Area [km2]
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

  <xsl:template name="zoneGeneral_rows">
    <xsl:for-each select=".">
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
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

  <xsl:template name="zonePollutants_headers">
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
  <xsl:template name="zonePollutants_rows">
    <xsl:for-each select=".">
      <table:table-row table:default-cell-value-type="string">
        <!-- 1 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../@gml:id"/>
          </text:p>
        </table:table-cell>
        <!-- 2 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../am:inspireId/base:Identifier/base:localId"/>
          </text:p>
        </table:table-cell>
        <!-- 3 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../am:inspireId/base:Identifier/base:namespace"/>
          </text:p>
        </table:table-cell>
        <!-- 4 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../am:name/descendant::gn:text"/>
          </text:p>
        </table:table-cell>
        <!-- 5 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="../aqd:zoneCode"/>
          </text:p>
        </table:table-cell>
        <!-- 6 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:Pollutant/aqd:pollutantCode/@xlink:href"/>
          </text:p>
        </table:table-cell>
        <!-- 7 -->
        <table:table-cell table:style-name="cell1">
          <text:p>
            <xsl:value-of select="aqd:Pollutant/aqd:protectionTarget/@xlink:href"/>
          </text:p>
        </table:table-cell>
      </table:table-row>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>