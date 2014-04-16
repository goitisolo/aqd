<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE xsl:stylesheet [
 <!ENTITY sep ",">
 <!ENTITY nl "&#xa;">
 <!ENTITY bom "&#xFEFF;">
]>
<!-- $Id$
     For schema http://dd.eionet.europa.eu/schemas/id2011850eu/AQD.xsd
  -->
<xsl:stylesheet version="1.0"
        xmlns:str="http://exslt.org/strings"

        xmlns:ad="urn:x-inspire:specification:gmlas:Addresses:3.0"
        xmlns:am="http://inspire.ec.europa.eu/schemas/am/3.0rc3"
        xmlns:am-ru="http://inspire.jrc.ec.europa.eu/schemas/am-ru/2.0"
        xmlns:aqd1="http://www.eionet.europa.eu/aqportal/Drep1"
        xmlns:aqd="http://aqd.ec.europa.eu/aqd/0.3.7c"
        xmlns:base="http://inspire.ec.europa.eu/schemas/base/3.3rc3/"
        xmlns:base2="http://inspire.ec.europa.eu/schemas/base2/1.0rc3"
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
        xmlns:xs="http://www.w3.org/2001/XMLSchema"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:output method='text' encoding='UTF-8' indent='no'/>

<xsl:template match="/">
  <xsl:text>&bom;</xsl:text>
  <xsl:apply-templates/>
</xsl:template>

<!--
     Root element
  -->
<xsl:template match="gml:FeatureCollection">

  <xsl:call-template name="header"/>
  <xsl:if test="count(gml:featureMember/aqd:AQD_ReportingHeader) &gt; 0">
    <xsl:for-each select="gml:featureMember/aqd:AQD_ReportingHeader">
      <xsl:apply-templates select="aqd:content"/>
    </xsl:for-each>
  </xsl:if>

  <xsl:call-template name="table">
    <xsl:with-param name="nodetype" select="gml:featureMember/aqd:AQD_Zone"/>
  </xsl:call-template>

</xsl:template>

<xsl:template match="aqd:content">
  <xsl:call-template name="table">
    <xsl:with-param name="nodetype" select="aqd:AQD_Zone"/>
  </xsl:call-template>
</xsl:template>


<xsl:template name="table">
    <xsl:param name="nodetype"/>
    <xsl:if test="count($nodetype) &gt; 0">
        <xsl:for-each select="$nodetype">
          <xsl:call-template name="row"/>
        </xsl:for-each>
    </xsl:if>
</xsl:template>

<xsl:template name="header">
    <xsl:text>GMLID</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>LocalId</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Namespace</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>GeographicalName</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>ZoneCode</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>IndividualName</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Organisation</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Language</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Nativeness</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Address</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Mail</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Telephone</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Website</xsl:text><xsl:text>&sep;</xsl:text>
    <xsl:text>Role</xsl:text><xsl:text>&nl;</xsl:text>
</xsl:template>

<xsl:template name="row">
    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="@gml:id"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:inspireId/base:Identifier/base:localId"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:inspireId/base:Identifier/base:namespace"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:name/descendant::gn:text"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="aqd:zoneCode"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:individualName/gmd:LocalisedCharacterString"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:organisationName/gmd:LocalisedCharacterString"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:address/ad:AddressRepresentation/ad:adminUnit/gn:GeographicalName/gn:language"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:address/ad:AddressRepresentation/ad:adminUnit/gn:GeographicalName/gn:nativeness"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:address/ad:AddressRepresentation/ad:adminUnit/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

<!--
    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:address/ad:AddressRepresentation/ad:locatorDesignator"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:address/ad:AddressRepresentation/ad:postCode"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>
-->
    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:electronicMailAddress"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:telephoneVoice"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:website"/>
    </xsl:call-template>
    <xsl:text>&sep;</xsl:text>

    <xsl:call-template name="wrapext">
      <xsl:with-param name="value" select="am:competentAuthority/base2:RelatedParty/base2:contact/base2:Contact/base2:role"/>
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
