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
declare namespace aqd = "http://www.eionet.europa.eu/aqportal/Drep1";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlconv:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";

(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)
declare variable $source_url as xs:string external;

(:
	Change it for testing locally:
declare variable $source_url as xs:string external;
declare variable $source_url := "http://cdr.eionet.europa.eu/gb/eu/aqd/b/envt_q2ua/2012_05_zone_all.xml";
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
    let $uri := xmlconv:getSparqlEndpointUrl($sparql, "xml", fn:false())

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
declare function xmlconv:getSparqlEndpointUrl($sparql as xs:string, $format as xs:string, $inference as xs:boolean)
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
    let $useInferencing := if ($inference) then "&amp;useInferencing=false" else ""
    let $defaultGraph := ""
    let $uriParams := concat("query=", $sparql, $useInferencing, "&amp;format=", $resultFormat, $defaultGraph)
    let $uri := concat($xmlconv:CR_SPARQL_URL, "?", $uriParams)
    return $uri
};
(:
 : ======================================================================
 :     QA rules
 : ======================================================================
 :)
declare function xmlconv:getComponentUrlSparql()
as xs:string
{
	"PREFIX : <http://rdfdata.eionet.europa.eu/airbase/schema/>
		SELECT * WHERE {
		  ?componenturl a :Component;
          :componentName ?label
	}"
};
declare function xmlconv:validatePollutantCode($url as xs:string)
as element(div)*
{
	let $sparql := xmlconv:getComponentUrlSparql()
	let $crComponents := xmlconv:executeSparqlQuery($sparql)

	for $polCodeElem in doc($url)//aqd:pollutantCode
	let $polCode := normalize-space($polCodeElem)
	let $isMatchingCode := xmlconv:isMatchingPollutantCode($crComponents, $polCode)
	let $matchingCodeByLabel := if (not($isMatchingCode)) then xmlconv:getMatchingPollutantCodeByLabel($crComponents, $polCode) else ()
	return
		if (not( $isMatchingCode )) then
			if (count($matchingCodeByLabel)>0) then
				<div>"{ $polCode }" is not a valid code - please use <a href="{ $matchingCodeByLabel }">{ $matchingCodeByLabel }</a></div>
			else
				<div>"{ $polCode }" is not a valid code.</div>
		else
			()
};

declare function xmlconv:isMatchingPollutantCode($crComponents as element(sparql:results), $polCode as xs:string)
as xs:boolean
{
	count($crComponents//sparql:result/sparql:binding[@name="componenturl" and sparql:uri=$polCode])>0
};
declare function xmlconv:getMatchingPollutantCodeByLabel($crComponents as element(sparql:results), $polCode as xs:string)
as xs:string*
{
	$crComponents//sparql:result[lower-case(sparql:binding[@name="label"]/sparql:literal) = lower-case($polCode)]/sparql:binding[@name="componenturl"]/sparql:uri
};
(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string) {

<div class="feedbacktext">
	{
	if (count(xmlconv:validatePollutantCode($source_url)) >0) then
		<div style="color:red">{ count(xmlconv:validatePollutantCode($source_url)) } invalid codes found!</div>
	else
		<div style="color:green">All codes are valid.</div>
	}
	{ xmlconv:validatePollutantCode($source_url) }
	<br/>
    <a href="{ xmlconv:getSparqlEndpointUrl(xmlconv:getComponentUrlSparql(), "html", fn:false()) }">Pollutant codes in Content Registry</a>
</div>
};
xmlconv:proceed( $source_url )