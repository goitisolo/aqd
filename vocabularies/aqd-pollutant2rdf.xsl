<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
      xmlns:xs="http://www.w3.org/2001/XMLSchema" 
      xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
      xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
      xmlns="http://www.w3.org/2004/02/skos/core#">
    <xsl:output method="xml" indent="yes"/>

    <xsl:template match="/">
        <rdf:RDF>
          <ConceptScheme rdf:about="">
            <rdfs:label>The vocabulary of pollutants from AQD.xsd</rdfs:label>
          </ConceptScheme>
            <xsl:apply-templates/>
        </rdf:RDF>
    </xsl:template>

    <xsl:template match="xs:simpleType[@name='Pollutants']/xs:restriction">
        <xsl:for-each select="*">
            <xsl:element name="Concept">
                <xsl:attribute name="rdf:about"><xsl:value-of select="position()" /></xsl:attribute>
                <notation rdf:datatype="http://www.w3.org/2001/XMLSchema#integer"><xsl:value-of select="position()" /></notation>
                <prefLabel><xsl:value-of select="@value" /></prefLabel>
                <inScheme rdf:resource=""/>
            </xsl:element>
        </xsl:for-each>
    </xsl:template>

</xsl:stylesheet>
