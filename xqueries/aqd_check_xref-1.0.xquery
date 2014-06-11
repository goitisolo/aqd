xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Main module)
 :
 : Version:     $Id: aqd_check_xref.xquery 16061 2014-05-19 14:11:51Z kasperen $
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
declare namespace om = "http://inspire.ec.europa.eu/schemas/ompr/2.0rc3";
(:~ declare Content Registry SPARQL endpoint:)
declare variable $xmlconv:CR_SPARQL_URL := "http://cr.eionet.europa.eu/sparql";

declare variable $xmlconv:DATAFLOW_D_OBLIGATION := "http://rod.eionet.europa.eu/obligations/672";

(:~ Source file URL parameter name :)
declare variable $xmlconv:SOURCE_URL_PARAM := "source_url=";

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
declare variable $source_url as xs:string external;

c: http://cdrtest.eionet.europa.eu/gb/eu/aqd/c/envu3n8zq/C_GB_AssessmentRegime_prelim.xml
e:http://cdrtest.eionet.europa.eu/gb/eu/aqd/e1a/envut0aoa/E2a_GB2013123113version5.xml
GB: http://cdr.eionet.europa.eu/gb/eu/aqd/c/envuqxsrq/C_GB_AssessmentRegime_prelim.xml
NL: http://cdr.eionet.europa.eu/nl/eu/aqd/d/envurreqq/REP_D-NL_RIVM_20131220_D-001.xml
:)


(: removes the file part from the end of URL and appends 'xml' for getting the envelope xml description :)
declare function xmlconv:getEnvelopeXML($url as xs:string){

        let $col := fn:tokenize($url,'/')
        let $col := fn:remove($col, fn:count($col))
        let $ret := fn:string-join($col,'/')
        let $ret := fn:concat($ret,'/xml')
        return
            if(fn:doc-available($ret)) then
                doc($ret)
            else
             ""
(:              "http://cdrtest.eionet.europa.eu/ee/eu/art17/envriytkg/xml" :)
}
;(:~
 : Get the cleaned URL without authorisation info
 : @param $url URL of the source XML file
 : @return String
 :)
declare function xmlconv:getCleanUrl($url)
as xs:string
{
    if ( contains($url, $xmlconv:SOURCE_URL_PARAM)) then
        fn:substring-after($url, $xmlconv:SOURCE_URL_PARAM)
    else
        $url
};

(: XMLCONV QA sends the file URL to XQuery engine as source_file paramter value in URL which is able to retreive restricted content from CDR.
   This method replaces the source file url value in source_url parameter with another URL. source_file url must be the last parameter :)
declare function xmlconv:replaceSourceUrl($url as xs:string, $url2 as xs:string) as xs:string{

    if (contains($url,$xmlconv:SOURCE_URL_PARAM)) then
        fn:concat(fn:substring-before($url, $xmlconv:SOURCE_URL_PARAM), $xmlconv:SOURCE_URL_PARAM, $url2)
    else
        $url2
}
;


(:
 : =====================================================================d=
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

declare function xmlconv:checkVocabularyReferences(){

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
        $result
};
declare function xmlconv:getCrosslinkRuleMapping(){

    <mapping>
        <rule id="dataflowD">
            <element>aqd:pollutantCode</element>
            <element>aqd:pollutant</element>
            <element>ef:observedProperty</element>
            <element>om:observedProperty</element>
        </rule>
    </mapping>
};
declare function xmlconv:getReferencedEnvelope($obligation as xs:string, $locality as xs:string){

    let $sparql := concat(
        "PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

SELECT distinct ?envelope ?released
WHERE {
  ?envelope a rod:Delivery .
  ?envelope rod:locality <", $locality, "> .
  ?envelope rod:released ?released .
  ?envelope rod:obligation <", $obligation , "> .
} ORDER BY desc(?released)")

    let $envelopes := xmlconv:executeSparqlQuery($sparql)

    let $envelopeUrl :=
        if (count($envelopes//sparql:result) > 0 ) then
            $envelopes//sparql:result[1]/sparql:binding[@name="envelope"]/sparql:uri
        else
            ""
    return
        $envelopeUrl
};

(: types: aq:Model, aq:SamplingPoint, aq:SamplingPointProcess, aq:Station, aq:Network:)
declare function xmlconv:getEnvelopeFeatureTypes($envelope as xs:string, $types as xs:string*){

    let $prefixedTypes :=
        for $type in $types
        return
            concat("aq:", $type)

    let $sparql := concat(
        "PREFIX dcterms: <http://purl.org/dc/terms/>
PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>
PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

SELECT distinct concat(?inspireNamespace, '/', ?inspireId) as ?id
WHERE {
  ?envelope a rod:Delivery .
  ?envelope rod:hasFile ?file .
  ?file cr:mediaType 'text/xml' .
  ?featureType dcterms:source ?file .
  ?featureType aq:inspireNamespace ?inspireNamespace .
  ?featureType aq:inspireId ?inspireId .
  ?featureType rdf:type ?type .
  FILTER (?envelope = <", $envelope, "> AND
    ?type IN (", string-join($prefixedTypes, ','), "))
}")

    let $featureTypes := xmlconv:executeSparqlQuery($sparql)
    return
        $featureTypes//sparql:result/sparql:binding[@name="id"]/sparql:literal
};
declare function xmlconv:checkCrosslinkReferences(){


    let $envelopeXml := xmlconv:getEnvelopeXML($source_url)

    let $coverage := $envelopeXml/envelope/coverage
    let $dataflowDEnvelopeUrl := xmlconv:getReferencedEnvelope($xmlconv:DATAFLOW_D_OBLIGATION, $coverage)
    let $dataflowDEnvelopeLink :=
        if (string-length($dataflowDEnvelopeUrl)>0) then
            <a href="{ $dataflowDEnvelopeUrl }">Dataflow D delivery.</a>
        else
            <span style="color:blue">Dataflow D delivery (not found)!</span>

    (: c24 :)
    let $modelAssessmentMetadataLinks := doc($source_url)//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMetadata/@xlink:href
    let $modelAssessmentMetadataResult := xmlconv:checkDataflowDReferences(
        $dataflowDEnvelopeUrl,
        <span>C24 - the assessment methods shall resolve to a traversable link to an assessment method /aqd:AQD_Model reported under {
            if (count($modelAssessmentMetadataLinks)>0 ) then $dataflowDEnvelopeLink else "Dataflow D."}</span>,
        $modelAssessmentMetadataLinks,
        ("Model"),
        "/aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMetadata")

    (: c25 :)
    let $samplingPointAssessmentMetadatLinks := doc($source_url)//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href
    let $samplingPointAssessmentMetadatResult := xmlconv:checkDataflowDReferences(
        $dataflowDEnvelopeUrl,
        <span>C25 - the assessment methods shall resolve to a traversable link to an assessment method /aqd:AQD_SamplingPoint reported under {
            if (count($modelAssessmentMetadataLinks)>0 ) then $dataflowDEnvelopeLink else "Dataflow D."}</span>,
        $samplingPointAssessmentMetadatLinks,
        ("SamplingPoint"),
        "/aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata")

    (: e5 :)
    let $omProcedureLinks := doc($source_url)//aqd:OM_Observation/om:procedure/@xlink:href
    let $omProcedureResult := xmlconv:checkDataflowDReferences(
        $dataflowDEnvelopeUrl,
        <span>E5/F5 - the observation procedures shall resolve to a traversable link to /aqd:AQD_ModelProcess OR /aqd:AQD_SamplingPointProcess reported under {
            if (count($omProcedureLinks)>0 ) then $dataflowDEnvelopeLink else "Dataflow D."}</span>,
        $omProcedureLinks,
        ("ModelProcess", "SamplingPointProcess"),
        "/aqd:OM_Observation/om:procedure")

    (: e6 :)
    let $omNameLinks := doc($source_url)//aqd:OM_Observation/om:parameter/om:NamedValue/om:name/@xlink:href
    let $omNameResult := xmlconv:checkDataflowDReferences(
        $dataflowDEnvelopeUrl,
        <span>E6/F6 - the observation name shall resolve to a traversable link to /aqd:AQD_Model OR /aqd:AQD_SamplingPoint reported under {
            if (count($omNameLinks)>0 ) then $dataflowDEnvelopeLink else "Dataflow D."}</span>,
        $omNameLinks,
        ("Model", "SamplingPoint"),
        "/aqd:OM_Observation/om:parameter/om:NamedValue/om:name")

    (: e8 :)
    let $omFeatureOfInterestLinks := doc($source_url)//aqd:OM_Observation/om:featureOfInterest/@xlink:href
    let $omFeatureOfInterestResult := xmlconv:checkDataflowDReferences(
        $dataflowDEnvelopeUrl,
        <span>E8/F8 - the observation featureOfInterest shall resolve to a traversable link to /aqd:AQD_Model OR /aqd:AQD_Sample reported under {
            if (count($omFeatureOfInterestLinks)>0 ) then $dataflowDEnvelopeLink else "Dataflow D."}</span>,
        $omFeatureOfInterestLinks,
        ("Model", "Sample"),
        "/aqd:OM_Observation/om:featureOfInterest")

    return
        ( $modelAssessmentMetadataResult,
        $samplingPointAssessmentMetadatResult,
        $omProcedureResult,
        $omNameResult,
        $omFeatureOfInterestResult)
};
declare function xmlconv:checkDataflowDReferences($dataflowDEnvelopeUrl as xs:string, $ruleHeading as element(span), $checkedReferences as node()*, $referencedObjectTypes as xs:string*, $ruleElement as xs:string){

    let $dataflowDModels :=
        if (count($checkedReferences)>0 ) then
            xmlconv:getEnvelopeFeatureTypes($dataflowDEnvelopeUrl, $referencedObjectTypes)
        else
            ()

    let $invalidCheckedReferences :=
        if (count($checkedReferences)>0 ) then
            distinct-values(
                for $link in $checkedReferences
                where empty(index-of($dataflowDModels, $link))
                return
                    $link
            )
        else
            ()
    let $result := xmlconv:buildCodeCheckCount($ruleHeading, count($checkedReferences), $invalidCheckedReferences,($ruleElement))
    return
        $result
};
declare function xmlconv:buildCodeCheckCount($ruleHeading, $allRefsCount as xs:integer, $invalidRefs as xs:string*, $refsElements as xs:string*){

    let $errorCount := count($invalidRefs)
    return
            <tr codesCount="{ $allRefsCount }" errorCount="{ $errorCount }">
                <td style="vertical-align:top">{ $ruleHeading }</td>{
                    if  ($allRefsCount = 0) then
                        <td style="vertical-align:top">No references found.</td>
                    else if ($errorCount > 0) then
                        <td style="color:red;vertical-align:top">{ $errorCount } invalid reference{ substring("s ", number(not($errorCount > 1)) * 2)}found out of { $allRefsCount } checked</td>
                    else
                        <td style="color:green;vertical-align:top">Found { $allRefsCount } reference{ substring("s,", number(not($allRefsCount > 1)) * 2)} all valid</td>
                    }
                <td style="vertical-align:top">{ string-join($refsElements, ", ")}</td>
                <td style="vertical-align:top">{ $invalidRefs }</td>
            </tr>

};
(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string)
as element(div){

    let $allRefElements :=
        for $elem in doc($source_url)//*[contains(@xlink:href, ':')]
        return
            $elem
    let $vocabularyRefsResult := xmlconv:checkVocabularyReferences()
    let $crosslinkRefsResult := xmlconv:checkCrosslinkReferences()


    let $allRefsCount := count($allRefElements)
    let $errorCount := sum($vocabularyRefsResult/@errorCount) + sum($crosslinkRefsResult/@errorCount)

    return
    <div class="feedbacktext">
        <div>
            <h2>Check references</h2>
            {
            if ($allRefsCount = 0) then
                <div>No references found from this report.</div>
            else if ($errorCount > 0) then
                <div style="color:red">{ $errorCount } invalid reference{ substring("s ", number(not(sum($errorCount) > 1)) * 2)}found out of { $allRefsCount } checked from this report.</div>
            else
                <div style="color:green">Found { $allRefsCount } reference{ substring("s ", number(not($allRefsCount > 1)) * 2)}from this report, all valid.</div>
            }
        </div>{
        if ( count($vocabularyRefsResult )> 0 or count($crosslinkRefsResult )> 0) then
            <table class="datatable">
                <thead>
                    <tr><th>Reference rule</th><th>Result</th><th>Checked elements</th><th>Invalid references</th></tr>
                </thead>
                <tbody>
                    {$vocabularyRefsResult}
                    {$crosslinkRefsResult}
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
