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
declare namespace aqd = "http://aqd.ec.europa.eu/aqd/0.3.7c";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlconv:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";

(:declare option xqilla:psvi "false"; :)
(:===================================================================:)
(: Variable given as an external parameter by the QA service                                                 :)
(:===================================================================:)

declare variable $source_url as xs:string external;
(:
    Change it for testing locally:
declare variable $source_url as xs:string external;
declare variable $source_url as xs:untypedAtomic external;
declare variable $source_url := "../test/DE_D_Station.xml";
declare variable $source_url as xs:string external;
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
                        <div>"{ $polCode }"</div>
        else
            ()
};


declare function xmlconv:isMatchingVocabCode($crConcepts as element(sparql:results), $polCode as xs:string)
as xs:boolean
{
    count($crConcepts//sparql:result/sparql:binding[@name="concepturl" and sparql:uri=$polCode])>0
};

declare function xmlconv:getVocabularyMapping(){

    <mapping>
        <vocabulary label="Pollutant codes" url="http://dd.eionet.europa.eu/vocabulary/aq/pollutant/">
            <element>aqd:pollutantCode</element>
            <element>aqd:pollutant</element>
            <element>ef:observedProperty</element>
            <element>om:observedProperty</element>
        </vocabulary>
        <vocabulary label="Area classification codes" url="http://dd.eionet.europa.eu/vocabulary/aq/areaclassification/">
            <element>aqd:areaClassification</element>
        </vocabulary>
        <vocabulary label="Assessment types" url="http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/">
            <element>aqd:assessmentType</element>
        </vocabulary>
        <vocabulary label="Environmental domains" url="http://dd.eionet.europa.eu/vocabulary/common/environmentaldomain/">
            <element>am:environmentalDomain</element>
        </vocabulary>
        <vocabulary label="Zone types" url="http://dd.eionet.europa.eu/vocabulary/aq/zonetype/">
            <element>aqd:aqdZoneType</element>
        </vocabulary>
        <vocabulary label="Protection targets" url="http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/">
            <element>aqd:protectionTarget</element>
        </vocabulary>
        <vocabulary label="Time extension types" url="http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/">
            <element>aqd:timeExtensionExemption</element>
        </vocabulary>
        <vocabulary label="Emission sources" url="http://dd.eionet.europa.eu/vocabulary/aq/emissionsource/">
            <element>aqd:mainEmissionSources</element>
        </vocabulary>
        <vocabulary label="Station classifications" url="http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/">
            <element>aqd:stationClassification</element>
        </vocabulary>
        <vocabulary label="Measurement Equipment codes" url="http://dd.eionet.europa.eu/vocabulary/aq/measurementequipment/">
            <element>aqd:MeasurementEquipment/aqd:equipment</element>
        </vocabulary>
        <vocabulary label="Sampling Equipment codes" url="http://dd.eionet.europa.eu/vocabulary/aq/samplingequipment/">
            <element>aqd:SamplingEquipment/aqd:equipment</element>
        </vocabulary>
        <vocabulary label="Equivalence demonstrated codes" url="http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/">
            <element>aqd:equivalenceDemonstrated</element>
        </vocabulary>
        <vocabulary label="Measurement types" url="http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/">
            <element>aqd:measurementType</element>
        </vocabulary>
        <vocabulary label="Time units" url="http://dd.eionet.europa.eu/vocabulary/uom/time/">
            <element>aqd:unit</element>
        </vocabulary>
        <vocabulary label="Process parameters" url="http://dd.eionet.europa.eu/vocabulary/aq/processparameter/">
            <element checkConceptOnly="true">ompr:name</element>
            <element checkConceptOnly="true">om:name</element>
        </vocabulary>
        <vocabulary label="Observation units" url="http://dd.eionet.europa.eu/vocabulary/uom/concentration/">
            <element checkConceptOnly="true">swe:uom</element>
        </vocabulary>
        <vocabulary label="Objective type" url="http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/">
            <element>aqd:objectiveType</element>
        </vocabulary>
        <vocabulary label="Reporting metric" url="http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/">
            <element>aqd:reportingMetric</element>
        </vocabulary>
        <vocabulary label="Assessment Threshold Exceedance" url="http://dd.eionet.europa.eu/vocabulary/aq/assessmentthresholdexceedance/">
            <element>aqd:exceedanceAttainment</element>
        </vocabulary>
        <vocabulary label="Legislation level" url="http://inspire.ec.europa.eu/codeList/LegislationLevelValue/" ruleType="startsWith">
            <element>base2:level</element>
        </vocabulary>
        <vocabulary label="AQ reference" url="http://reference.eionet.europa.eu/page/" ruleType="mustNotStartWith">
            <element>*</element>
        </vocabulary>
    </mapping>
};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string)
as element(div){
let $vocabularies := xmlconv:getVocabularyMapping()//vocabulary

let $reportedVocabularyElements :=
    for $elem in doc($source_url)//*[contains(@xlink:href, ':')]
    (:string-length(@checkConceptOnly)=0 and:)
    where count($vocabularies//element[contains(.,'/') and substring-before(., '/') = $elem/../name() and substring-after(., '/') = $elem/name()]) > 0
        or count($vocabularies//element[not(@checkConceptOnly) and not(contains(.,'/')) and . = $elem/name()]) > 0
        or count($vocabularies//element[@checkConceptOnly = 'true' and . = $elem/name() and starts-with($elem/@xlink:href, ../@url)]) > 0
    return
        $elem

let $allRefElements :=
    for $elem in doc($source_url)//*[contains(@xlink:href, ':')]
    return
        $elem

let $allRefsCount := count($allRefElements)

let $result := for $vocabulary in $vocabularies
        let $vocabularyUrl := data($vocabulary/@url)
        let $codes := $reportedVocabularyElements[
            count(index-of($vocabulary//element[not(@checkConceptOnly)], name(.))) > 0
            or count(index-of($vocabulary//element[not(@checkConceptOnly)], concat(name(..), '/', name(.)))) > 0
            or (count(index-of($vocabulary//element[@checkConceptOnly='true'], name(.))) > 0 and starts-with(@xlink:href, $vocabulary/@url))]/@xlink:href
        let $invalidCodes :=
            if ($vocabulary/@ruleType = "startsWith") then
                distinct-values($codes[not(starts-with(., $vocabularyUrl))])
            else if ($vocabulary/@ruleType = "mustNotStartWith") then
                (:distinct-values($codes[starts-with(., $vocabularyUrl)]):)
                distinct-values($allRefElements[starts-with(@xlink:href, $vocabularyUrl)]/concat(name(),'=',@xlink:href))
            else
                xmlconv:validateCode(distinct-values($codes), $vocabularyUrl)
        let $ruleHeading :=
            if ($vocabulary/@ruleType = "startsWith") then
                <span>The reference must start with { $vocabularyUrl }</span>
            else if ($vocabulary/@ruleType = "mustNotStartWith") then
                <span>The reference must NOT start with { $vocabularyUrl }</span>
            else
                <span>The reference must point to concept in <a href="{ $vocabularyUrl }">{ data($vocabulary/@label) } vocabulary</a></span>

        let $errorCount := count($invalidCodes)
        let $codesCount :=
         if ($vocabulary/@ruleType = "mustNotStartWith") then
            $allRefsCount
         else
            count($codes)
    return
        <tr codesCount="{ $allRefsCount }" errorCount="{ $errorCount }">
            <td style="vertical-align:top">{ $ruleHeading }</td>{
                if  ($codesCount = 0) then
                    <td style="vertical-align:top">No references found.</td>
                else if ($errorCount > 0) then
                    <td style="color:red;vertical-align:top">{ $errorCount } invalid reference{ substring("s ", number(not($errorCount > 1)) * 2)}found out of { $codesCount } checked</td>
                else
                    <td style="color:green;vertical-align:top">Found { $codesCount } reference{ substring("s,", number(not($codesCount > 1)) * 2)} all valid</td>
                }
            <td style="vertical-align:top">{ string-join($vocabulary//element, ", ")}</td>
            <td style="vertical-align:top">{ $invalidCodes }</td>
        </tr>
return
<div class="feedbacktext">
        <div>
            <h2>Check references</h2>
            {
            if ($allRefsCount = 0) then
                <div>No references found from this report.</div>
            else if (sum($result/@errorCount) > 0) then
                <div style="color:red">{ sum($result/@errorCount) } invalid reference{ substring("s ", number(not(sum($result/@errorCount) > 1)) * 2)}found out of { $allRefsCount } checked from this report.</div>
            else
                <div style="color:green">Found { $allRefsCount } reference{ substring("s ", number(not($allRefsCount > 1)) * 2)}from this report, all valid.</div>
            }
        </div>{
        if ( count($result )> 0) then
            <table class="datatable">
                <thead>
                    <tr><th>Reference rule</th><th>Result</th><th>Checked elements</th><th>Invalid references</th></tr>
                </thead>
                <tbody>
                    {$result}
                </tbody>
            </table>
        else
            ()
     }
    <div>
    {()
    (:
    Discover vocablary concepts used in XML
    let  $items := distinct-values(doc($source_url)//*[starts-with(@xlink:href, 'http://rdfdata') or starts-with(@xlink:href, 'http://dd.eionet')]/concat(@xlink:href,' - ',  name(.)))
    return
        for $n in $items
        order by $n
        return
            <p>{$n}</p>
     :)
    }
    </div>
</div>

};
xmlconv:proceed( $source_url )
