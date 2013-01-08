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
                        table { border-collapse:collapse; border: 1px solid #999; width: 98%; margin-top: 1em }
                        th { background-color: #87CEFA; text-align: left; padding-right: 2em; border: 1px solid #999; width:14em }
                        td { border: 1px solid #999}
                        </style>
		</head>
		<body>
			<h1><xsl:value-of select="skos:ConceptScheme/rdfs:label"/></h1>

                        <xsl:apply-templates mode="resource"/>
		</body>
	</html>
</xsl:template>

<xsl:template match="*" mode="resource">
        <table>
                <tr><th colspan="2">Resource URI:
                <xsl:choose>
                    <xsl:when test="@rdf:ID">
                                <xsl:value-of select="/rdf:RDF/@xml:base" />#<xsl:value-of select="@rdf:ID"/>
                    </xsl:when>
                    <xsl:when test="@rdf:about">
                        <xsl:if test="not(starts-with(@rdf:about,'http:') or starts-with(@rdf:about,'/'))">
                            <xsl:value-of select="/rdf:RDF/@xml:base"/>
                        </xsl:if>
                            <xsl:value-of select="@rdf:about"/>
                    </xsl:when>
                    <xsl:otherwise>
                        {Anonymous}
                    </xsl:otherwise>
                </xsl:choose>
                </th></tr>
        <xsl:if test="name() != 'rdf:Description'">
        <tr><th>rdf:type</th><td><xsl:value-of select="name()" /></td></tr>
        </xsl:if>
        <xsl:apply-templates mode="property"/>
        </table>
</xsl:template>

<xsl:template match="*" mode="property">
    <tr>
        <th><xsl:value-of select="name()" /></th>
	<td>
                <xsl:choose>
                    <xsl:when test="@rdf:resource">
                        <a>
                        <xsl:choose>
                            <xsl:when test="starts-with(@rdf:resource,'http:')">
                                <xsl:attribute name="href"><xsl:value-of select="@rdf:resource" /></xsl:attribute>
                            </xsl:when>
                            <xsl:when test="@rdf:resource = ''">
                                <xsl:attribute name="href"><xsl:value-of select="/rdf:RDF/@xml:base" /></xsl:attribute>
                            </xsl:when>
                            <xsl:otherwise>
                                <xsl:attribute name="href"><xsl:value-of select="/rdf:RDF/@xml:base" /><xsl:value-of select="@rdf:resource" /></xsl:attribute>
                            </xsl:otherwise>
                            <xsl:value-of select="@rdf:resource" />
                        </xsl:choose>
                        </a>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:value-of select="." />
                    </xsl:otherwise>
                </xsl:choose>
	</td>
    </tr>
</xsl:template>

</xsl:stylesheet>
