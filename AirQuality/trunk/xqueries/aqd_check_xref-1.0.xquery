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
 : BLOCKER logic added and other changes by Hermann Peifer, EEA, August 2015
 : @author George Sofianos
 :)

declare namespace xmlconv = "http://converters.eionet.europa.eu";
declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace ompr = "http://inspire.ec.europa.eu/schemas/ompr/2.0";
declare namespace om = "http://www.opengis.net/om/2.0";

import module namespace common = "aqd-common" at "aqd_check_common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";


declare variable $xmlconv:DATAFLOW_D_OBLIGATION := "http://rod.eionet.europa.eu/obligations/672";
declare variable $source_url as xs:string external;

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

declare function xmlconv:validateCode($elems, $scheme as xs:string) as element(div)* {
    let $sparql := xmlconv:getConceptUrlSparql($scheme)
    let $crConcepts := sparqlx:executeSparqlQuery($sparql)

    for $polCodeElem in $elems
    let $polCode := normalize-space($polCodeElem)
    let $isMatchingCode := xmlconv:isMatchingVocabCode($crConcepts, $polCode)
    return
        if (not( $isMatchingCode )) then
                        <div>"{ $polCode }"</div>
        else
            ()
};


declare function xmlconv:isMatchingVocabCode($crConcepts as element(sparql:results), $polCode as xs:string) as xs:boolean {
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
            <element checkConceptOnly="true">am:environmentalDomain</element>
        </vocabulary>
        <vocabulary label="Environmental domains" url="http://inspire.ec.europa.eu/codeList/MediaValue/" ruleType="startsWith">
            <element checkConceptOnly="true">am:environmentalDomain</element>
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
        <vocabulary label="Zone type code" url="http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone" ruleType="exactMatch">
            <element checkConceptOnly="true">am:zoneType</element>
        </vocabulary>
    </mapping>
};

declare function xmlconv:checkVocabularyReferences() {

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
            else if ($vocabulary/@ruleType = "exactMatch") then
                    distinct-values($codes[. != $vocabularyUrl])
            else
                xmlconv:validateCode(distinct-values($codes), $vocabularyUrl)
        let $ruleHeading :=
            if ($vocabulary/@ruleType = "startsWith") then
                <span>The reference must start with { $vocabularyUrl }</span>
            else if ($vocabulary/@ruleType = "mustNotStartWith") then
                <span>The reference must NOT start with { $vocabularyUrl }</span>
            else if ($vocabulary/@ruleType = "exactMatch") then
                    <span>The reference shall resolve to <a href="{ $vocabularyUrl }">{ $vocabularyUrl }</a></span>
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

declare function xmlconv:getCrosslinkRuleMapping() {
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
        "PREFIX dcterms: <http://purl.org/dc/terms/>
        PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

        SELECT distinct ?envelope ?released
        WHERE {
         GRAPH <http://rdfdata.eionet.europa.eu/airquality/samplingpoints.ttl> {
           ?record dcterms:source ?file
         }
         ?envelope rod:hasFile ?file .
         ?envelope a rod:Delivery .
         ?envelope rod:locality <", $locality, "> .
         ?envelope rod:released ?released .
        }
        ORDER BY desc(?released)")

    let $envelopes := sparqlx:executeSparqlQuery($sparql)

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

    let $featureTypes := sparqlx:executeSparqlQuery($sparql)
    return
        $featureTypes//sparql:result/sparql:binding[@name="id"]/sparql:literal
};
declare function xmlconv:checkCrosslinkReferences() {
    let $envelopeXml := common:getEnvelopeXML($source_url)
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
        ("Model", "SamplingPoint"),
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
    let $omProcedureLinks := doc($source_url)//om:OM_Observation/om:procedure/@xlink:href
    let $omProcedureResult := xmlconv:checkDataflowDReferences(
        $dataflowDEnvelopeUrl,
        <span>E5/F5 - the observation procedures shall resolve to a traversable link to /aqd:AQD_ModelProcess OR /aqd:AQD_SamplingPointProcess reported under {
            if (count($omProcedureLinks)>0 ) then $dataflowDEnvelopeLink else "Dataflow D."}</span>,
        $omProcedureLinks,
        ("ModelProcess", "SamplingPointProcess"),
        "/om:OM_Observation/om:procedure")

    (: e6 :)
    let $omNameLinks := (doc($source_url)//om:OM_Observation/om:parameter/om:NamedValue[om:name/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint']/om:value[normalize-space(.) != ""],
        doc($source_url)//om:OM_Observation/om:parameter/om:NamedValue[om:name/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/processparameter/SamplingPoint']/om:value/@xlink:href[normalize-space(.) != ""])
    let $omNameResult := xmlconv:checkDataflowDReferences(
        $dataflowDEnvelopeUrl,
        <span>E6/F6 - the observation name shall resolve to a traversable link to /aqd:AQD_Model OR /aqd:AQD_SamplingPoint reported under {
            if (count($omNameLinks)>0 ) then $dataflowDEnvelopeLink else "Dataflow D."}</span>,
        $omNameLinks,
        ("Model", "SamplingPoint"),
        "/om:OM_Observation/om:parameter/om:NamedValue/om:value or /om:OM_Observation/om:parameter/om:NamedValue/om:value/@xlink:href when ../om:name equals .../SamplingPoint")

    (: e8 :)
    let $omFeatureOfInterestLinks := doc($source_url)//om:OM_Observation/om:featureOfInterest/@xlink:href
    let $omFeatureOfInterestResult := xmlconv:checkDataflowDReferences(
        $dataflowDEnvelopeUrl,
        <span>E8/F8 - the observation featureOfInterest shall resolve to a traversable link to /aqd:AQD_ModelArea OR /aqd:AQD_Sample reported under {
            if (count($omFeatureOfInterestLinks)>0 ) then $dataflowDEnvelopeLink else "Dataflow D."}</span>,
        $omFeatureOfInterestLinks,
        ("ModelArea", "Sample"),
        "/om:OM_Observation/om:featureOfInterest")

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
declare function xmlconv:proceed($source_url as xs:string) as element(div) {
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
                <span id="feedbackStatus" class="INFO">No references found from this report.</span>
            else if ($errorCount > 0) then
				<span id="feedbackStatus" class="BLOCKER" style="color:red">{ $errorCount } invalid reference{ substring("s ", number(not(sum($errorCount) > 1)) * 2)}found out of { $allRefsCount } checked from this report.</span>
            else
                <span id="feedbackStatus" class="INFO" style="color:green">Found { $allRefsCount } reference{ substring("s ", number(not($allRefsCount > 1)) * 2)}from this report, all valid.</span>
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
