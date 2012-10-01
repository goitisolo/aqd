<?xml version="1.0" encoding="UTF-8"?>

<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
 xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
 xmlns:xs="http://www.w3.org/2001/XMLSchema"
 xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
 xmlns:skos="http://www.w3.org/2004/02/skos/core#"
 version="1.0">

<xsl:template match="rdf:RDF">
	<html>
		<head>
			<title><xsl:value-of select="skos:ConceptScheme/rdfs:label"/></title>
                        <style type="text/css">
                        table { border-collapse:collapse }
                        td { border: 1px solid #999 }
                        th { background-color: #87CEFA; text-align: left; padding-right: 2em; border: 1px solid #999 }
                        </style>
		</head>
		<body>
			<h1><xsl:value-of select="skos:ConceptScheme/rdfs:label"/></h1>
			<table style="border: 1px solid #999" cellpading="0" cellspacing="0">
				<xsl:apply-templates select="skos:Concept"/>
			</table>
		</body>
	</html>
</xsl:template>

<xsl:template match="skos:Concept">
	<xsl:if test="position()=1">
		<xsl:call-template name="header"/>
	</xsl:if>
	<tr>
		<xsl:apply-templates />
	</tr>
</xsl:template>

<!-- template for building table cells with values -->
<xsl:template match="*">
	<td>
                <xsl:choose>
                    <xsl:when test="@rdf:resource">
                        <a><xsl:attribute name="href"><xsl:value-of select="@rdf:resource" /></xsl:attribute>
                        <xsl:if test="@rdf:resource = ''">
                                <xsl:value-of select="/rdf:RDF/@xml:base" />
                        </xsl:if>
                        <xsl:value-of select="@rdf:resource" /></a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="." />
                    </xsl:otherwise>
                </xsl:choose>
	</td>
</xsl:template>

<!-- a named template, which creates the table header row and a description -->
<xsl:template name="header">
	<tr>
	<xsl:for-each select="*">
		<th><xsl:value-of select="local-name()" /></th>
	</xsl:for-each>
	</tr>
</xsl:template>

</xsl:stylesheet>
