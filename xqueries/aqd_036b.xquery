xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Main module)
 :
 : Version:     $Id$
 : Created:     3 July 2012
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script validates reported data against the codelists stored in CR (Content Registry).
 : The script uses CR SPARQL endpoint.
 :
 : @author Enriko Käsper
 :)

declare namespace xmlconv="http://converters.eionet.europa.eu";
declare namespace aqd = "http://aqd.ec.europa.eu/aqd/0.3.6b";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlconv:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";

(:declare option xqilla:psvi "false"; :)
(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)
declare variable $source_url as xs:untypedAtomic external;
(:

    Change it for testing locally:
declare variable $source_url as xs:string external;
declare variable $source_url := "http://cdr.eionet.europa.eu/gb/eu/aqd/e2a/colutn32a/envuvlxkq/B_GB_Zones.xml";
:)

(:
 : ======================================================================
 :              SPARQL HELPER methods
 : ======================================================================
 :)
(:~ Function executes given SPARQL query and returns result elements in SPARQL result format.
 : URL parameters will be correctly encoded.
 : @param $sparql SPARQL query.
 : @return sparql:results element containing zero or more sparql:result subelements in SPARQL result format.
 :)
declare function xmlconv:executeSparqlQuery($sparql as xs:string)
as element(sparql:results)
{
    let $uri := xmlconv:getSparqlEndpointUrl($sparql, "xml")

    return
        fn:doc($uri)//sparql:results
};


(:~
 : Get the SPARQL endpoint URL.
 : @param $sparql SPARQL query.
 : @param $format xml or html.
 : @param $inference use inference when executing sparql query.
 : @return link to sparql endpoint
 :)
declare function xmlconv:getSparqlEndpointUrl($sparql as xs:string, $format as xs:string)
as xs:string
{
    let $sparql := fn:encode-for-uri(fn:normalize-space($sparql))
    let $resultFormat :=
        if ($format = "xml") then
            "application/xml"
        else if ($format = "html") then
            "text/html"
        else
            $format
    let $defaultGraph := ""
    let $uriParams := concat("query=", $sparql, "&amp;format=", $resultFormat, $defaultGraph)
    let $uri := concat($xmlconv:CR_SPARQL_URL, "?", $uriParams)
    return $uri
};


(:
 : ======================================================================
 :     QA rules
 : ======================================================================
 :)
declare function xmlconv:getConceptUrlSparql($scheme as xs:string)
as xs:string
{
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label
    WHERE {
      ?concepturl skos:inScheme <", $scheme, ">;
                  skos:prefLabel ?label
    }")
};

declare function xmlconv:validateCode($elems, $scheme as xs:string)
as element(div)*
{
    let $sparql := xmlconv:getConceptUrlSparql($scheme)
    let $crConcepts := xmlconv:executeSparqlQuery($sparql)

    for $polCodeElem in $elems
    let $polCode := normalize-space($polCodeElem)
    let $isMatchingCode := xmlconv:isMatchingVocabCode($crConcepts, $polCode)
    return
        if (not( $isMatchingCode )) then
                        <div>"{ $polCode }" is not a valid code.</div>
        else
            ()
};


declare function xmlconv:isMatchingVocabCode($crConcepts as element(sparql:results), $polCode as xs:string)
as xs:boolean
{
    count($crConcepts//sparql:result/sparql:binding[@name="concepturl" and sparql:uri=$polCode])>0
};


(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string) {

<div class="feedbacktext">
    <h2>Pollutant codes</h2>
    {
    if (count(xmlconv:validateCode(
            doc($source_url)//aqd:areaClassification/@xlink:href,
            "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/")) > 0) then
        <div style="color:red">{ count(xmlconv:validateCode(
                doc($source_url)//aqd:areaClassification/@xlink:href,
                "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/")) } invalid codes found!</div>
    else
        <div style="color:green">All codes are valid.</div>
    }
    { xmlconv:validateCode(
            doc($source_url)//aqd:areaClassification/@xlink:href,
            "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/") }
    <p>
    <a href="http://dd.eionet.europa.eu/vocabulary/aq/pollutant/">Pollutant codes vocabulary</a>
    </p>


    <h2>Area classification codes</h2>
    {
    if (count(xmlconv:validateCode(
            doc($source_url)//aqd:areaClassification/@xlink:href,
            "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/")) > 0) then
        <div style="color:red">{ count(xmlconv:validateCode(
                doc($source_url)//aqd:areaClassification/@xlink:href,
                "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/")) } invalid codes found!</div>
    else
        <div style="color:green">All codes are valid.</div>
    }
    { xmlconv:validateCode(
            doc($source_url)//aqd:areaClassification/@xlink:href,
            "http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/") }
    <p>
    <a href="http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/">Area classification codes vocabulary</a>
    </p>


    <h2>Assessment types</h2>
    {
    if (count(xmlconv:validateCode(
            doc($source_url)//aqd:assessmentType/@xlink:href,
            "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/")) > 0) then
        <div style="color:red">{ count(xmlconv:validateCode(
                doc($source_url)//aqd:assessmentType/@xlink:href,
                "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/")) } invalid codes found!</div>
    else
        <div style="color:green">All codes are valid.</div>
    }
    { xmlconv:validateCode(
            doc($source_url)//aqd:assessmentType/@xlink:href,
            "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/") }
    <p>
    <a href="http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/">Assessment types vocabulary</a>
    </p>


</div>
};
xmlconv:proceed( $source_url )
