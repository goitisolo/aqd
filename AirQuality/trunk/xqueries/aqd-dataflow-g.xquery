xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :
 : XQuery script implements dataflow G tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Enriko Käsper
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document
 : @author George Sofianos
 :)

module namespace dataflowG = "http://converters.eionet.europa.eu/dataflowG";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace filter = "aqd-filter" at "aqd-filter.xquery";
import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";
import module namespace checks = "aqd-checks" at "aqd-checks.xq";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace ad = "urn:x-inspire:specification:gmlas:Addresses:3.0";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace om = "http://www.opengis.net/om/2.0";
declare namespace swe = "http://www.opengis.net/swe/2.0";
declare namespace ompr="http://inspire.ec.europa.eu/schemas/ompr/2.0";
declare namespace sams="http://www.opengis.net/samplingSpatial/2.0";
declare namespace sam = "http://www.opengis.net/sampling/2.0";
declare namespace gmd = "http://www.isotc211.org/2005/gmd";
declare namespace gco = "http://www.isotc211.org/2005/gco";

declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace adms = "http://www.w3.org/ns/adms#";
declare namespace prop = "http://dd.eionet.europa.eu/property/";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

declare variable $dataflowG:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
declare variable $dataflowG:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "679");

(: Rule implementations :)
declare function dataflowG:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $cdrUrl := common:getCdrUrl($countryCode)
let $modelCdrUrl := if ($countryCode = 'gi') then common:getCdrUrl('gb') else $cdrUrl
let $reportingYear := common:getReportingYear($docRoot)

let $latestEnvelopeByYearB := query:getLatestEnvelope($cdrUrl || "b/", $reportingYear)
let $latestEnvelopeB := query:getLatestEnvelope($cdrUrl || "b/")
let $latestEnvelopeC := query:getLatestEnvelope($cdrUrl || "c/")
let $latestEnvelopeByYearC := query:getLatestEnvelope($cdrUrl || "c/", $reportingYear)
let $latestEnvelopeD := query:getLatestEnvelope($cdrUrl || "d/")
let $latestEnvelopeD1b := query:getLatestEnvelope($cdrUrl || "d1b/", $reportingYear)
let $latestEnvelopeByYearG := query:getLatestEnvelope($cdrUrl || "g/", $reportingYear)

let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition

let $latestModels :=
    try {
        let $all := distinct-values(data(sparqlx:run(query:getModel($latestEnvelopeD1b))//sparql:binding[@name = 'inspireLabel']/sparql:literal))
        return if (empty($all)) then distinct-values(data(sparqlx:run(query:getModel($latestEnvelopeD))//sparql:binding[@name = 'inspireLabel']/sparql:literal)) else $all
    } catch * {
        ()
    }

(: GLOBAL variables needed for all checks :)
let $assessmentRegimeIds := distinct-values(data(sparqlx:run(query:getAssessmentRegime($cdrUrl || "c/"))//sparql:binding[@name='inspireLabel']/sparql:literal))
let $assessmentMetadataNamespace := distinct-values(data(sparqlx:run(query:getAssessmentMethods())//sparql:binding[@name='assessmentMetadataNamespace']/sparql:literal))
let $assessmentMetadataId := distinct-values(data(sparqlx:run(query:getAssessmentMethods())//sparql:binding[@name='assessmentMetadataId']/sparql:literal))
let $assessmentMetadata := distinct-values(data(sparqlx:run(query:getAssessmentMethods())//concat(sparql:binding[@name='assessmentMetadataNamespace']/sparql:literal,"/",sparql:binding[@name='assessmentMetadataId']/sparql:literal)))
let $validAssessment :=
    for $x in $docRoot//aqd:AQD_Attainment/aqd:assessment[@xlink:href = $assessmentRegimeIds]
    return $x

let $latestSamplingPoints := data(sparqlx:run(query:getSamplingPoint($latestEnvelopeD))/sparql:binding[@name="inspireLabel"]/sparql:literal)

let $samplingPointAssessmentMetadata :=
    let $results := sparqlx:run(query:getSamplingPointAssessmentMetadata())
    return distinct-values(
            for $i in $results
            return concat($i/sparql:binding[@name='metadataNamespace']/sparql:literal,"/", $i/sparql:binding[@name='metadataId']/sparql:literal)
    )
let $namespaces := distinct-values($docRoot//base:namespace)
let $allAttainments := query:getAllAttainmentIds2($namespaces)

(: File prefix/namespace check :)
let $NSinvalid :=
    try {
        let $XQmap := inspect:static-context((), 'namespaces')
        let $fileMap := map:merge((
            for $x in in-scope-prefixes($docRoot/*)
            return map:entry($x, string(namespace-uri-for-prefix($x, $docRoot/*)))))

        return map:for-each($fileMap, function($a, $b) {
            let $x := map:get($XQmap, $a)
            return
                if ($x != "" and not($x = $b)) then
                    <tr>
                        <td title="Prefix">{$a}</td>
                        <td title="File namespace">{$b}</td>
                        <td title="XQuery namespace">{$x}</td>
                    </tr>
                else
                    ()
        })
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: VOCAB check:)
let $VOCABinvalid := checks:vocab($docRoot)

(: G0 :)
let $G0table :=
    try {
        if ($reportingYear = "") then
            <tr class="{$errors:ERROR}">
                <td title="Status">Reporting Year is missing.</td>
            </tr>
        else if($headerBeginPosition > $headerEndPosition) then
            <tr class="{$errors:BLOCKER}">
                <td title="Status">Start position must be less than end position</td>
            </tr>
        else if (query:deliveryExists($dataflowG:OBLIGATIONS, $countryCode, "g/", $reportingYear)) then
            <tr class="{$errors:WARNING}">
                <td title="Status">Updating delivery for {$reportingYear}</td>
            </tr>
        else
            <tr class="{$errors:INFO}">
                <td title="Status">New delivery for {$reportingYear}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $isNewDelivery := errors:getMaxError($G0table) = $errors:INFO
let $knownAttainments :=
    if ($isNewDelivery) then
        distinct-values(data(sparqlx:run(query:getAttainment($cdrUrl || "g/"))//sparql:binding[@name='inspireLabel']/sparql:literal))
    else
        distinct-values(data(sparqlx:run(query:getAttainment($latestEnvelopeByYearG))//sparql:binding[@name='inspireLabel']/sparql:literal))

(: G01 :)
let $countAttainments := count($docRoot//aqd:AQD_Attainment)
let $tblAllAttainments :=
    try {
        for $rec in $docRoot//aqd:AQD_Attainment
        return
            <tr>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="base:localId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($rec/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="aqd:zone">{common:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G02 :)
let $G02table :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment
        let $inspireId := concat(data($x/aqd:inspireId/base:Identifier/base:namespace), "/", data($x/aqd:inspireId/base:Identifier/base:localId))
        where (not($inspireId = $knownAttainments))
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="aqd:inspireId">{$inspireId}</td>
                <td title="aqd:pollutant">{common:checkLink(distinct-values(data($x/aqd:pollutant/@xlink:href)))}</td>
                <td title="aqd:objectiveType">{common:checkLink(distinct-values(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)))}</td>
                <td title="aqd:reportingMetric">{common:checkLink(distinct-values(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href)))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(distinct-values(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href)))}</td>
                <td title="aqd:zone">{common:checkLink(distinct-values(data($x/aqd:zone/@xlink:href)))}</td>
                <td title="aqd:assessment">{common:checkLink(distinct-values(data($x/aqd:assessment/@xlink:href)))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $G02errorLevel :=
    if ($isNewDelivery and count(
        for $x in $docRoot//aqd:AQD_Attainment
            let $id := $x/aqd:inspireId/base:Identifier/base:namespace || "/" || $x/aqd:inspireId/base:Identifier/base:localId
        where ($allAttainments = $id)
        return 1) > 0) then
            $errors:G02
        else
            $errors:INFO

(: G03 - :)
let $G03table :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment
        let $inspireId := data($x/aqd:inspireId/base:Identifier/base:namespace) ||  "/" || data($x/aqd:inspireId/base:Identifier/base:localId)
        where ($inspireId = $knownAttainments)
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="aqd:inspireId">{$inspireId}</td>
                <td title="aqd:pollutant">{common:checkLink(distinct-values(data($x/aqd:pollutant/@xlink:href)))}</td>
                <td title="aqd:objectiveType">{common:checkLink(distinct-values(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)))}</td>
                <td title="aqd:reportingMetric">{common:checkLink(distinct-values(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href)))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(distinct-values(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href)))}</td>
                <td title="aqd:zone">{common:checkLink(distinct-values(data($x/aqd:zone/@xlink:href)))}</td>
                <td title="aqd:assessment">{common:checkLink(distinct-values(data($x/aqd:assessment/@xlink:href)))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $G03errorLevel :=
    if (not($isNewDelivery) and count($G03table) = 0)  then
        $errors:G03
    else
        $errors:INFO

(: G04 - :)
let $G04table :=
    try {
        let $gmlIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(@gml:id))
        let $inspireIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(aqd:inspireId))
        for $x in $docRoot//aqd:AQD_Attainment
            let $id := $x/@gml:id
            let $inspireId := $x/aqd:inspireId
            let $aqdinspireId := concat($x/aqd:inspireId/base:Identifier/base:localId, "/", $x/aqd:inspireId/base:Identifier/base:namespace)
        where count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
                    and count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1
        return
            <tr>
                <td title="gml:id">{distinct-values($x/@gml:id)}</td>
                <td title="aqd:inspireId">{distinct-values($aqdinspireId)}</td>
                <td title="aqd:pollutant">{common:checkLink(distinct-values(data($x/aqd:pollutant/@xlink:href)))}</td>
                <td title="aqd:objectiveType">{common:checkLink(distinct-values(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)))}</td>
                <td title="aqd:reportingMetric">{common:checkLink(distinct-values(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href)))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(distinct-values(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href)))}</td>
                <td title="aqd:zone">{common:checkLink(distinct-values(data($x/aqd:zone/@xlink:href)))}</td>
                <td title="aqd:assessment">{common:checkLink(distinct-values(data($x/aqd:assessment/@xlink:href)))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G05 Compile & feedback a list of the exceedances situations based on the content of ./aqd:zone, ./aqd:pollutant, ./aqd:objectiveType, ./aqd:reportingMetric,
   ./aqd:protectionTarget, aqd:exceedanceDescription_Final/aqd:ExceedanceDescription/aqd:exceedance :)
let $G05table :=
    try {
        for $rec in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance = "true"]
        return
            <tr>
                <td title="aqd:zone">{common:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:objectiveType">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href))}</td>
                <td title="aqd:reportingMetric">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
                <td title="aqd:exceedance">{data($rec/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance)}</td>
                <td title="aqd:numberExceedances">{data($rec/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances)}</td>
                <td title="aqd:numericalExceedance">{data($rec/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numericalExceedance)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G06 :)
let $G06table :=
    try {
        let $errorClass := if (number($reportingYear) >= 2015) then $errors:G06 else $errors:INFO
        for $rec in $docRoot//aqd:AQD_Attainment[aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT"]
        return
            <tr class="{$errorClass}">
                <td title="aqd:zone">{common:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
                <td title="aqd:inspireId">{common:checkLink(data(concat($rec/aqd:inspireId/base:Identifier/base:localId, "/", $rec/aqd:inspireId/base:Identifier/base:namespace)))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:objectiveType">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href))}</td>
                <td title="aqd:reportingMetric">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G07 duplicate @gml:ids and aqd:inspireIds and ef:inspireIds :)
(: Feedback report shall include the gml:id attribute, ef:inspireId, aqd:inspireId, ef:name and/or ompr:name elements as available. :)
let $G07invalid :=
    try {
        let $gmlIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(@gml:id))
        let $inspireIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(aqd:inspireId))
        let $efInspireIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(ef:inspireId))
        let $invalidDuplicateGmlIds :=
            for $attainment in $docRoot//aqd:AQD_Attainment
            let $id := $attainment/@gml:id
            let $inspireId := $attainment/aqd:inspireId
            let $efInspireId := $attainment/ef:inspireId
            where count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
                    or count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) > 1
                    or (count(index-of($efInspireIds, lower-case(normalize-space($efInspireId)))) > 1 and not(empty($efInspireId)))
            return
                $attainment
        for $rec in $invalidDuplicateGmlIds
        return
            <tr>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="base:localId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($rec/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="base:versionId">{data($rec/aqd:inspireId/base:Identifier/base:versionId)}</td>
                <td title="base:localId">{data($rec/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($rec/ef:inspireId/base:Identifier/base:namespace)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G08 ./aqd:inspireId/base:Identifier/base:localId shall be an unique code for the attainment records starting with ISO2-country code :)
let $G08invalid :=
    try {
        let $localIds :=  $docRoot//aqd:AQD_Attainment/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
        for $rec in $docRoot//aqd:AQD_Attainment/aqd:inspireId/base:Identifier
        let $id := $rec/lower-case(normalize-space(base:localId))
        where (count(index-of($localIds, lower-case(normalize-space($id)))) > 1 and not(empty($id)))
        return
            <tr>
                <td title="gml:id">{data($rec/../../@gml:id)}</td>
                <td title="base:localId">{data($rec/base:localId)}</td>
                <td title="base:namespace">{data($rec/base:namespace)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G09 ./ef:inspireId/base:Identifier/base:namespace shall resolve to a unique namespace identifier for the data source (within an annual e-Reporting cycle). :)
let $G09table :=
    try {
        for $id in distinct-values($docRoot//aqd:AQD_Attainment/aqd:inspireId/base:Identifier/base:namespace)
            let $localId := $docRoot//aqd:AQD_Attainment/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G09.1 :)
let $G09.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//base:namespace)
        where (not($x = $prefLabel) and not($x = $altLabel))
        return
            <tr>
                <td title="base:namespace">{$x}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G10 pollutant codes :)
let $G10invalid :=
    try {
        let $valid := ($vocabulary:POLLUTANT_VOCABULARY || "1", $vocabulary:POLLUTANT_VOCABULARY || "7", $vocabulary:POLLUTANT_VOCABULARY || "8", $vocabulary:POLLUTANT_VOCABULARY || "9", $vocabulary:POLLUTANT_VOCABULARY || "5",
        $vocabulary:POLLUTANT_VOCABULARY || "6001", $vocabulary:POLLUTANT_VOCABULARY || "10", $vocabulary:POLLUTANT_VOCABULARY || "20", $vocabulary:POLLUTANT_VOCABULARY ||  "5012",
        $vocabulary:POLLUTANT_VOCABULARY || "5014", $vocabulary:POLLUTANT_VOCABULARY || "5015", $vocabulary:POLLUTANT_VOCABULARY || "5018", $vocabulary:POLLUTANT_VOCABULARY || "5029")
        for $x in $docRoot//aqd:AQD_Attainment/aqd:pollutant
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{data($x/../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:pollutant">{data($x/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($x/../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)}</td>
                <td title="aqd:reportingMetric">{data($x/../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href)}</td>
                <td title="aqd:protectionTarget">{data($x/../aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G11 :)
let $G11invalid :=
    try {
        let $valid := ($vocabulary:POLLUTANT_VOCABULARY || "1", $vocabulary:POLLUTANT_VOCABULARY || "5", $vocabulary:POLLUTANT_VOCABULARY || "6001", $vocabulary:POLLUTANT_VOCABULARY || "10")
        for $x in $docRoot//aqd:AQD_Attainment/aqd:pollutant
        where not($x/@xlink:href = $valid) and exists($x/../aqd:exceedanceDescriptionBase)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:pollutant">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G12 :)
let $G12invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment/aqd:pollutant
        let $pollutantXlinkG12 := fn:substring-after(data($x/fn:normalize-space(@xlink:href)), "pollutant/")
        where empty(index-of(('1', '5', '6001', '10'), $pollutantXlinkG12)) and (exists($x/../aqd:exceedanceDescriptionAdjustment))
        return
            <tr>
                <td title="aqd:AQD_Attainment">{data($x/../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:pollutant">{data($x/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G13 - :)
let $G13Results :=
    try {
        sparqlx:run(query:getG13($cdrUrl, $reportingYear))
    } catch * {
        ()
    }
let $G13inspireLabels := distinct-values(data($G13Results//sparql:binding[@name='inspireLabel']/sparql:literal))
let $G13invalid :=
    try {
        let $remoteConcats :=
            for $x in $G13Results
            return $x/sparql:binding[@name='inspireLabel']/sparql:literal || $x/sparql:binding[@name='pollutant']/sparql:uri || $x/sparql:binding[@name='objectiveType']/sparql:uri

        for $x in $docRoot//aqd:AQD_Attainment[aqd:assessment/@xlink:href]
        let $xlink := $x/aqd:assessment/@xlink:href
        let $concat := $x/aqd:assessment/@xlink:href/string() || $x/aqd:pollutant/@xlink:href || $x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href
        where (not($xlink = $G13inspireLabels) or (not($concat = $remoteConcats)))
        return
            <tr>
                <td title="aqd:AQD_Attainment">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:assessment">{data($x/aqd:assessment/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }
(: G13b :)
let $G13binvalid :=
    try {
        let $remoteConcats :=
            for $x in $G13Results
            return $x/sparql:binding[@name='inspireLabel']/sparql:literal || $x/sparql:binding[@name='pollutant']/sparql:uri || $x/sparql:binding[@name='protectionTarget']/sparql:uri

        for $x in $docRoot//aqd:AQD_Attainment[aqd:assessment/@xlink:href]
        let $xlink := $x/aqd:assessment/@xlink:href
        let $concat := $x/aqd:assessment/@xlink:href/string() || $x/aqd:pollutant/@xlink:href || $x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href
        where (not($xlink = $G13inspireLabels) or (not($concat = $remoteConcats)))
        return
            <tr>
                <td title="aqd:AQD_Attainment">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:assessment">{data($x/aqd:assessment/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }
(: G13c :)
let $G13cinvalid :=
    try {
        let $remoteConcats :=
            for $x in $G13Results
            return $x/sparql:binding[@name='inspireLabel']/sparql:literal || $x/sparql:binding[@name='pollutant']/sparql:uri || $x/sparql:binding[@name='objectiveType']/sparql:uri ||
            $x/sparql:binding[@name='reportingMetric']/sparql:uri || $x/sparql:binding[@name='protectionTarget']/sparql:uri

        for $x in $docRoot//aqd:AQD_Attainment[aqd:assessment/@xlink:href]
        let $xlink := $x/aqd:assessment/@xlink:href
        let $concat := $x/aqd:assessment/@xlink:href/string() || $x/aqd:pollutant/@xlink:href || $x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href ||
        $x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href || $x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href
        where (not($xlink = $G13inspireLabels) or (not($concat = $remoteConcats)))
        return
            <tr>
                <td title="aqd:AQD_Attainment">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:assessment">{data($x/aqd:assessment/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: G14 - COUNT number zone-pollutant-target comibantion to match those in dataset B and dataset C for the same reporting Year & compare it with Attainment. :)
let $G14table :=
    try {
        let $G14resultBC :=
            for $i in sparqlx:run(query:getG14($latestEnvelopeB, $latestEnvelopeC, $reportingYear))
            return
                <result>
                    <pollutantName>{string($i/sparql:binding[@name = "Pollutant"]/sparql:literal)}</pollutantName>
                    <protectionTarget>{string($i/sparql:binding[@name = "ProtectionTarget"]/sparql:literal)}</protectionTarget>
                    <countB>{
                        let $x := string($i/sparql:binding[@name = "countOnB"]/sparql:literal)
                        return if ($x castable as xs:integer) then xs:integer($x) else 0
                    }</countB>
                    <countC>{
                        let $x := string($i/sparql:binding[@name = "countOnC"]/sparql:literal)
                        return if ($x castable as xs:integer) then xs:integer($x) else 0
                    }</countC>
                </result>
        let $G14tmp :=
            for $x in $docRoot//aqd:AQD_Attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/
                    aqd:protectionTarget[not(../string(aqd:objectiveType/@xlink:href) = ("http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO",
                    "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO", "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT",
                    "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/INT"))]
            let $pollutant := string($x/../../../aqd:pollutant/@xlink:href)
            let $zone := string($x/../../../aqd:zone/@xlink:href)
            let $protectionTarget := string($x/@xlink:href)
            let $key := string-join(($zone, $pollutant, $protectionTarget), "#")
            group by $pollutant, $protectionTarget
            return
                <result>
                    <pollutantName>{dd:getNameFromPollutantCode($pollutant)}</pollutantName>
                    <pollutantCode>{tokenize($pollutant, "/")[last()]}</pollutantCode>
                    <protectionTarget>{$protectionTarget}</protectionTarget>
                    <count>{count(distinct-values($key))}</count>
                </result>
        let $G14ResultG := filter:filterByName($G14tmp, "pollutantCode", (
            "1", "7", "8", "9", "5", "6001", "10", "20", "5012", "5018", "5014", "5015", "5029"
        ))

        for $x in $G14resultBC
            let $vsName := string($x/pollutantName)
            let $vsCode := string($x/pollutantCode)
            let $protectionTarget := string($x/protectionTarget)
            let $countB := number($x/countB)
            let $countC := number($x/countC)
            let $countG := number($G14ResultG[pollutantName = $vsName and protectionTarget = $protectionTarget]/count)
            let $errorClass :=
                if ((string($countB), string($countC), string($countG)) = "NaN") then $errors:G14
                else if ($countG > $countC) then $errors:G14
                else if ($countG > $countB) then $errors:G14
                else if ($countC > $countG) then $errors:WARNING
                else if ($countB > $countG) then $errors:WARNING
                else $errors:INFO
        order by $vsName
        return
            <tr class="{$errorClass}">
                <td title="Pollutant Name">{$vsName || " (" || $G14ResultG[pollutantName = $vsName and protectionTarget = $protectionTarget]/pollutantCode || ")"}</td>
                <td title="Protection Target">{$protectionTarget}</td>
                <td title="Count B">{string($countB)}</td>
                <td title="Count C">{string($countC)}</td>
                <td title="Count G">{string($countG)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G14b :)
let $G14binvalid :=
    try {
        let $exception := ($vocabulary:OBJECTIVETYPE_VOCABULARY || "ALT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "INT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "MO")
        let $query :=
            "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
   PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
   PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

   SELECT ?localId ?inspireLabel
   WHERE {
          ?regime a aqd:AQD_AssessmentRegime ;
          aqd:inspireId ?inspireId ;
          aqd:assessmentThreshold ?assessmentThreshold .
          ?inspireId rdfs:label ?inspireLabel .
          ?inspireId aqd:localId ?localId .
          ?assessmentThreshold aqd:environmentalObjective ?objective .
          ?objective aqd:objectiveType ?objectiveType .
          FILTER (CONTAINS(str(?regime), '" || $latestEnvelopeByYearC || "'))
          FILTER (!(str(?objectiveType) in ('" || string-join($exception, "','") || "')))
   }"
        let $all := distinct-values(data(sparqlx:run($query)/sparql:binding[@name = 'inspireLabel']/sparql:literal))
        let $allLocal := data($docRoot//aqd:AQD_Attainment[not(aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href = $exception)]/aqd:assessment/@xlink:href)
        for $x in $all
        where (not($x = $allLocal))
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{$x}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G15 :)
let $G15invalid :=
    try {
        let $exceptions := ($vocabulary:OBJECTIVETYPE_VOCABULARY || "ALT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "INT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "ECO", $vocabulary:OBJECTIVETYPE_VOCABULARY || "ERT")
        let $valid := distinct-values(data(sparqlx:run(query:getZone($latestEnvelopeByYearB))//sparql:binding[@name='inspireLabel']/sparql:literal))
        for $x in $docRoot//aqd:AQD_Attainment
        let $pollutant := data($x/aqd:pollutant/@xlink:href)
        let $reportingMetric := data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href)
        let $objectiveType := data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)
        let $zone := $x/aqd:zone
        where not($objectiveType = $exceptions) and not($zone/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:zone">{data($zone/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G17 :)
let $G17invalid :=
    try {
        let $zones := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:run(query:getZone($cdrUrl))//sparql:binding[@name='inspireLabel']/sparql:literal)) else ()
        let $pollutants := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:run(query:getPollutantlD($cdrUrl))//sparql:binding[@name='key']/sparql:literal)) else ()

        for $x in $docRoot//aqd:AQD_Attainment[aqd:zone/@xlink:href]
        let $zone := data($x/aqd:zone/@xlink:href)
        let $pollutant := concat($x/aqd:zone/@xlink:href, '#', $x/aqd:pollutant/@xlink:href)
        where exists($zones) and exists($pollutants) and ($zone = $zones) and not($pollutant = $pollutants)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:AQD_Zone">{$zone}</td>
                <td title="Pollutant">{data($x/aqd:pollutant/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: G18 :)
let $G18invalid :=
    try {
        let $localId :=  if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:run(query:getTimeExtensionExemption($cdrUrl))//sparql:binding[@name='localId']/sparql:literal)) else ""
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription]
        let $objectiveType := data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)
        let $reportingMetric := data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href)
        let $protectionTarget := data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href)
        let $zone := data($x/aqd:zone/@xlink:href)
        where exists($localId) and ($zone = $localId) and ($objectiveType != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{$objectiveType}</td>
                <td title="aqd:reportingMetric">{$reportingMetric}</td>
                <td title="aqd:protectionTarget">{$protectionTarget}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G19 .//aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of :)
let $G19invalid :=
    try {
        let $valid := ($vocabulary:OBJECTIVETYPE_VOCABULARY || "TV", $vocabulary:OBJECTIVETYPE_VOCABULARY || "LV",$vocabulary:OBJECTIVETYPE_VOCABULARY || "CL",
        $vocabulary:OBJECTIVETYPE_VOCABULARY || "LVMOT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "LVmaxMOT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "INT",
        $vocabulary:OBJECTIVETYPE_VOCABULARY || "ALT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "LTO", $vocabulary:OBJECTIVETYPE_VOCABULARY || "ECO",
        $vocabulary:OBJECTIVETYPE_VOCABULARY || "LV-S2")
        for $x in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        where not($x/aqd:objectiveType/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G20 - ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute shall resolve to one of
... :)
let $G20invalid :=
    try {
        let $valid := ($vocabulary:REPMETRIC_VOCABULARY || "3hAbove", $vocabulary:REPMETRIC_VOCABULARY || "aMean", $vocabulary:REPMETRIC_VOCABULARY || "wMean",
        $vocabulary:REPMETRIC_VOCABULARY || "hrsAbove", $vocabulary:REPMETRIC_VOCABULARY || "daysAbove", $vocabulary:REPMETRIC_VOCABULARY || "daysAbove-3yr",
        $vocabulary:REPMETRIC_VOCABULARY || "maxd8hrMean", $vocabulary:REPMETRIC_VOCABULARY || "AOT40c", $vocabulary:REPMETRIC_VOCABULARY || "AOT40c-5yr", $vocabulary:REPMETRIC_VOCABULARY || "AEI")
        for $x in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        where not($x/aqd:reportingMetric/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G21 - aqd:protectionTarget match with vocabulary codes :)
let $G21invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:PROTECTIONTARGET_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        where not($x/aqd:protectionTarget/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType/@xlink:href)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric/@xlink:href)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G22 :)
let $G22invalid :=
    try {
        let $environmentalObjectiveCombinations := doc("http://dd.eionet.europa.eu/vocabulary/aq/environmentalobjective/rdf")
        for $x in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        let $objectiveType := data($x/aqd:objectiveType/@xlink:href)
        let $reportingMetric := data($x/aqd:reportingMetric/@xlink:href)
        let $protectionTarget := data($x/aqd:protectionTarget/@xlink:href)
        where (not($environmentalObjectiveCombinations//skos:Concept[prop:hasProtectionTarget/@rdf:resource = $protectionTarget
                and prop:hasObjectiveType/@rdf:resource = $objectiveType and prop:hasReportingMetric/@rdf:resource = $reportingMetric]))
        return
            <tr>
                <td title="aqd:AQD_Attainment">{data($x/../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:pollutant">{data($x/../../aqd:pollutant/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType/@xlink:href)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric/@xlink:href)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G38 :)
let $G38invalid :=
    try {
        let $valid := ($vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural", $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural-nearcity", $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural-regional",
        $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural-remote",$vocabulary:AREA_CLASSIFICATION_VOCABULARY || "urban", $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "suburban")
        for $x in $docRoot//aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G39 :)
let $G39invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
        where (not($x/@xlink:href = $latestModels))
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($x/../../../../../@gml:id)}</td>
                <td title="aqd:AQD_Model">{data($x/fn:normalize-space(@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G40 - :)
let $G40invalid  :=
    try {
        for $r in $validAssessment/../aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed[@xlink:href = $assessmentMetadata]
        where exists($assessmentMetadata)
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                <td title="aqd:assessment">{data($r/../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                <td title="aqd:modelUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G41 - :)
let $G41invalid :=
    try {
        for $r in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed[not(@xlink:href = $latestSamplingPoints)]
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:SamplingPoint">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G42 - :)
let $G42invalid  :=
    try {
        for $r in $validAssessment/../aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationlUsed[not(@xlink:href = $samplingPointAssessmentMetadata)]
        where exists($samplingPointAssessmentMetadata)
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                <td title="aqd:assessment">{data($r/../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G44 - aqd:AQD_Attainment/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedance shall EQUAL “true” or “false” :)
let $G44invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedance[not(string() = ("true", "false"))]
        return
            <tr>
                <td title="base:localId">{$x/../../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:exceedanc">{$x/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: G45 - If ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedance is TRUE EITHER ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)
let $G45invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedance = "true"]
            let $numerical := string($x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numericalExceedance)
            let $numbers := string($x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numberExceedances)
            let $percentile := string($x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:percentileExceedance)
        where not(common:containsAnyNumber(($numerical, $numbers, $percentile)))
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G46 :)
let $G46invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedance = "false"]
            let $numerical := string($x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numericalExceedance)
            let $numbers := string($x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numberExceedances)
            let $percentile := string($x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:percentileExceedance)
        where not(common:containsAnyNumber(($numerical, $numbers, $percentile)))
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G47 :)
let $G47invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"]
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G52 :)
let $G52invalid :=
    try {
        let $valid := ($vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural", $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural-nearcity", $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural-regional",
        $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural-remote",$vocabulary:AREA_CLASSIFICATION_VOCABULARY || "urban", $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "suburban")
        for $x in $docRoot//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G53 :)
let $G53invalid :=
    try {
        for $r in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed[not(@xlink:href = $latestModels)]
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:Model">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G54 - :)
let $G54invalid :=
    try {
        for $r in $validAssessment/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed[not(@xlink:href = $assessmentMetadata)]
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                <td title="aqd:assessment">{data($r/../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G55 :)
let $G55invalid :=
    try {
        for $r in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed[not(@xlink:href = $latestSamplingPoints)]
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:SamplingPoint">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G56 :)
let $G56invalid :=
    try {
        for $r in $validAssessment/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationlUsed[not(@xlink:href = $samplingPointAssessmentMetadata)]
        where exists($samplingPointAssessmentMetadata)
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                <td title="aqd:assessment">{data($r/../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: G57 - :)
let $G57invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment
        let $reportingXlink := fn:substring-after(data($x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)), "reportingmetric/")
        where empty(index-of(data($x/aqd:pollutant/fn:normalize-space(@xlink:href)), "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001")) = false() and
                (empty(index-of(('aMean'), $reportingXlink)))
        return
            <tr>
                <td title="reporting link">{$reportingXlink}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G58 - aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance shall EQUAL “true” or “false” :)
let $G58invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance[not(string() = ("true", "false"))]
        return
            <tr>
                <td title="base:localId">{$x/../../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:exceedanc">{$x/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G59 - If ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance is TRUE EITHER ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)
let $G59invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment[/aqd:ExceedanceDescription/aqd:exceedance = "true"]
            let $numerical := string($x/aqd:ExceedanceDescription/aqd:numericalExceedance)
            let $numbers := string($x/aqd:ExceedanceDescription/aqd:numberExceedances)
            let $percentile := string($x/aqd:ExceedanceDescription/aqd:percentileExceedance)
        where not(common:containsAnyNumber(($numerical, $numbers, $percentile)))
        return
            <tr>
                <td title="base:localId">{$x/../aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G60 - If ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance is FALSE EITHER ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)
let $G60invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment[aqd:ExceedanceDescription/aqd:exceedance = "false"]
            let $numerical := string($x/aqd:ExceedanceDescription/aqd:numericalExceedance)
            let $numbers := string($x/aqd:ExceedanceDescription/aqd:numberExceedances)
            let $percentile := string($x/aqd:ExceedanceDescription/aqd:percentileExceedance)
        where not(common:containsAnyNumber(($numerical, $numbers, $percentile)))
        return
            <tr>
                <td title="base:localId">{$x/../aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G61 :)
let $G61invalid :=
    try {
        let $valid := ($vocabulary:ADJUSTMENTTYPE_VOCABULARY || "nsCorrection", $vocabulary:ADJUSTMENTTYPE_VOCABULARY || "wssCorrection")
        for $x in $docRoot//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G62 - :)
let $G62invalid :=
    try {
        let $valid := ($vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "A1", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "A2", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "B", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "B1",
        $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "B2", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "C1", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "C2", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "D1",
        $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "D2", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "E1", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "E2", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "F1",
        $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "F2", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "G1", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "G2", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY || "H")
        for $x in $docRoot//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentSource
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G63 :)
let $G63invalid :=
    try {
        let $valid := ($vocabulary:ASSESSMENTTYPE_VOCABULARY || "fixed", $vocabulary:ASSESSMENTTYPE_VOCABULARY || "model", $vocabulary:ASSESSMENTTYPE_VOCABULARY || "indicative", $vocabulary:ASSESSMENTTYPE_VOCABULARY || "objective")
        for $x in $docRoot//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentType
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G64 :)
let $G64invalid :=
    try {
        let $types := ($vocabulary:ADJUSTMENTTYPE_VOCABULARY || "nsCorrection", $vocabulary:ADJUSTMENTTYPE_VOCABULARY || "wssCorrection")
        for $x in $docRoot//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType[@xlink:href = $types]
        let $model := data($x/../aqd:assessmentMethod/aqd:AssessmentMethods/aqd:modelAssessmentMetadata/@xlink:href)
        let $samplingPoint := data($x/../aqd:assessmentMethod/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href)
        where empty($model) and empty($samplingPoint)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../../../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:modelAssessmentMetadata">{$model}</td>
                <td title="aqd:samplingPointAssessmentMetadata">{$samplingPoint}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G65
let $G65invalid :=
    try {
        let $types := ($vocabulary:ADJUSTMENTTYPE_VOCABULARY || "nsCorrection", $vocabulary:ADJUSTMENTTYPE_VOCABULARY || "wssCorrection")
        for $x in $docRoot//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType[@xlink:href = $types]
        let $model := data($x/../aqd:assessmentMethod/aqd:AssessmentMethods/aqd:modelAssessmentMetadata/@xlink:href)
        let $samplingPoint := data($x/../aqd:assessmentMethod/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/@xlink:href)
        where (exists($model) and not($model = $latestModels)) or (exists($samplingPoint) and not($samplingPoint = $latestSamplingPoints))
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../../../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:modelAssessmentMetadata">{$model}</td>
                <td title="aqd:samplingPointAssessmentMetadata">{$samplingPoint}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }:)

(: G66 :)
let $G66invalid :=
    try {
        for $r in $validAssessment/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:modelAssessmentMetadata[not(@xlink:href = $assessmentMetadata)]
        where exists($assessmentMetadata)
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:assessment">{data($r/../../../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G67 - :)
let $G67invalid :=
    try {
        for $x in $validAssessment/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata[not(@xlink:href = $samplingPointAssessmentMetadata)]
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../../../../../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:assessment">{data($x/../../../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                <td title="aqd:samplingPointAssessmentMetadata">{data($x/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G70 :)
let $G70invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea[count(@uom) > 0 and fn:normalize-space(@uom) != "http://dd.eionet.europa.eu/vocabulary/uom/area/km2" and fn:normalize-space(@uom) != "http://dd.eionet.europa.eu/vocabularyconcept/uom/area/km2"]]
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G71 :)
let $G71invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength[count(@uom) > 0 and fn:normalize-space(@uom) != "http://dd.eionet.europa.eu/vocabulary/uom/length/km" and fn:normalize-space(@uom) != "http://dd.eionet.europa.eu/vocabularyconcept/uom/length/km"]]
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G72 :)
let $G72invalid :=
    try {
        let $valid := ($vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural", $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural-nearcity", $vocabulary:AREA_CLASSIFICATION_VOCABULARY ||"rural-regional",
        $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rural-remote", $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "urban", $vocabulary:AREA_CLASSIFICATION_VOCABULARY || "suburban")
        for $x in $docRoot//aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Attainment">{$x/../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:objectiveType">{data($x/aqd:objectiveType)}</td>
                <td title="aqd:reportingMetric">{data($x/aqd:reportingMetric)}</td>
                <td title="aqd:protectionTarget">{data($x/aqd:protectionTarget)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G73 :)
let $G73invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
        where not($x/@xlink:href = $latestModels)
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($x/../../../../../@gml:id)}</td>
                <td title="aqd:AQD_Model">{data($x/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G74 :)
let $modelUsed_74  :=
    try {
        for $r in $validAssessment/../aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed[not(@xlink:href = $assessmentMetadata)]
        where exists($assessmentMetadata)
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:assessment">{data($r/../../../../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: G75 :)
let $G75invalid  :=
    try {
        for $r in $docRoot//aqd:AQD_Attainment//aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed
        where not($r/@xlink:href = $latestSamplingPoints)
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:stationUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G76 :)
let $G76invalid  :=
    try {
        for $r in $validAssessment/../aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationlUsed[not(@xlink:href = $samplingPointAssessmentMetadata)]
        where exists($assessmentMetadata)
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                <td title="aqd:assessment">{data($r/../../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G78 - ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance shall EQUAL “true” or “false” :)
let $G78invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance[not(string() = ("true", "false"))]
        return
            <tr>
                <td title="base:localId">{$x/../../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:exceedanc">{$x/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: G79 - If ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance is TRUE EITHER ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)
let $G79invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance = "true"]
        let $numerical := string($x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numericalExceedance)
        let $numbers := string($x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances)
        let $percentile := string($x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:percentileExceedance)
        where not(common:containsAnyNumber(($numerical, $numbers, $percentile)))
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: G80 - If ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance is FALSE EITHER ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)
let $G80invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance = "false"]
        let $numerical := string($x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numericalExceedance)
        let $numbers := string($x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances)
        let $percentile := string($x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:percentileExceedance)
        where not(common:containsAnyNumber(($numerical, $numbers, $percentile)))
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G81 :)
let $G81invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionAdjustmen/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType/fn:normalize-space(@xlink:href)!="http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected"]
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G82 - :)
let $G82invalid :=
    try {
        let $valid := ("http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied","http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable", "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected")
        for $r in $docRoot//aqd:AQD_Attainment//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType[@xlink:href = $valid]
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                <td title="gml:id">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(:~ G85 - WHERE ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance shall EQUAL “true”
 :  ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed OR
 :  ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed MUST be populated (At least 1 xlink must be found)
 :)
let $G85invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance = "true"]
            let $stationUsed := data($x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed/@xlink:href)
            let $modelUsed := data($x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed/@xlink:href)
        where (count($stationUsed) = 0 and count($modelUsed) = 0)
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: G86 :)
let $G86invalid :=
    try {
        for $x in $docRoot//aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea[aqd:stationUsed/@xlink:href or aqd:modelUsed/@xlink:href]
        let $stationErrors :=
            for $i in data($x/aqd:stationUsed/@xlink:href)
            where (not($i = $latestSamplingPoints))
            return 1
        let $modelErrors :=
            for $i in data($x/aqd:modelUsed/@xlink:href)
            where (not($i = $latestModels))
            return 1
        where (count($stationErrors) >0 or count($modelErrors) >0)
        return
            <tr>
                <td title="base:localId">{string($x/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:stationUsed">{data($x/aqd:stationUsed/@xlink:href)}</td>
                <td title="aqd:modelUsed">{data($x/aqd:modelUsed/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

return
    <table class="maintable hover">
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
        {html:build3("G0", $labels:G0, $labels:G0_SHORT, $G0table, string($G0table/td), errors:getMaxError($G0table))}
        {html:build1("G01", $labels:G01, $labels:G01_SHORT, $tblAllAttainments, "", string($countAttainments), "", "", $errors:G01)}
        {html:buildSimple("G02", $labels:G02, $labels:G02_SHORT, $G02table, "", "", $G02errorLevel)}
        {html:buildSimple("G03", $labels:G03, $labels:G03_SHORT, $G03table, "", "", $G03errorLevel)}
        {html:build1("G04", $labels:G04, $labels:G04_SHORT, $G04table, "", string(count($G04table)), " ", "", $errors:G04)}
        {html:build1("G05", $labels:G05, $labels:G05_SHORT, $G05table, "", string(count($G05table)), " exceedance", "", $errors:G05)}
        {html:build2("G06", $labels:G06, $labels:G06_SHORT, $G06table, "All values are valid", "record", errors:getMaxError($G06table))}
        {html:build2("G07", $labels:G07, $labels:G07_SHORT, $G07invalid, "No duplicates found", " duplicate", $errors:G07)}
        {html:build2("G08", $labels:G08, $labels:G08_SHORT, $G08invalid, "No duplicate values found", " duplicate value", $errors:G08)}
        {html:buildUnique("G09", $labels:G09, $labels:G09_SHORT, $G09table, "namespace", $errors:G09)}
        {html:build2("G09.1", $labels:G09.1, $labels:G09.1_SHORT, $G09.1invalid, "All values are valid", " invalid namespaces", $errors:G09.1)}
        {html:build2("G10", $labels:G10, $labels:G10_SHORT, $G10invalid, "All values are valid", "", $errors:G10)}
        {html:build2("G11", $labels:G11, $labels:G11_SHORT, $G11invalid, "All values are valid", " invalid value", $errors:G11)}
        {html:build2("G12", $labels:G12, $labels:G12_SHORT, $G12invalid, "All values are valid", " invalid value", $errors:G12)}
        {html:build2("G13", $labels:G13, $labels:G13_SHORT, $G13invalid, "All values are valid", " invalid value", $errors:G13)}
        {html:build2("G13b", $labels:G13b, $labels:G13b_SHORT, $G13binvalid, "All values are valid", " invalid value", $errors:G13b)}
        {html:build2("G13c", $labels:G13c, $labels:G13c_SHORT, $G13cinvalid, "All values are valid", " invalid value", $errors:G13c)}
        {html:build2("G14", $labels:G14, $labels:G14_SHORT, $G14table, "All values are valid", "record", errors:getMaxError($G14table))}
        {html:build2("G14b", $labels:G14b, $labels:G14b_SHORT, $G14binvalid, "All assessment regimes are reported", " missing assessment regime", $errors:G14b)}
        {html:build2("G15", $labels:G15, $labels:G15_SHORT, $G15invalid, "All values are valid", " invalid value", $errors:G15)}
        {html:build2("G17", $labels:G17, $labels:G17_SHORT, $G17invalid, "All values are valid", " invalid value", $errors:G17)}
        {html:build2("G18", $labels:G18, $labels:G18_SHORT, $G18invalid, "All values are valid", " invalid value", $errors:G18)}
        {html:build2("G19", $labels:G19, $labels:G19_SHORT, $G19invalid, "All values are valid", "", $errors:G19)}
        {html:build2("G20", $labels:G20, $labels:G20_SHORT, $G20invalid, "All values are valid", "", $errors:G20)}
        {html:build2("G21", $labels:G21, $labels:G21_SHORT, $G21invalid, "No invalid protection target types found", " invalid value", $errors:G21)}
        {html:build2("G22", $labels:G22, $labels:G22_SHORT, $G22invalid, "No invalid objective types for Health found", " invalid value", $errors:G22)}
        {html:buildInfoTR("Specific checks on aqd:exceedanceDescriptionBase")}
        {html:build2("G38", $labels:G38, $labels:G38_SHORT, $G38invalid, "All values are valid", "", $errors:G38)}
        {html:build2("G39", $labels:G39, $labels:G39_SHORT, $G39invalid, "All values are valid", " invalid value", $errors:G39)}
        {html:build2("G40", $labels:G40, $labels:G40_SHORT, $G40invalid, "All values are valid", " invalid value", $errors:G40)}
        {html:build2("G41", $labels:G41, $labels:G41_SHORT, $G41invalid, "All values are valid", " invalid value", $errors:G41)}
        {html:build2("G42", $labels:G42, $labels:G42_SHORT, $G42invalid, "All values are valid", " invalid value", $errors:G42)}
        {html:build2("G44", $labels:G44, $labels:G44_SHORT, $G44invalid, "All values are valid", " invalid value", $errors:G44)}
        {html:build2("G45", $labels:G45, $labels:G45_SHORT, $G45invalid, "All values are valid", " invalid value", $errors:G45)}
        {html:build2("G46", $labels:G46, $labels:G46_SHORT, $G46invalid, "All values are valid", " invalid value", $errors:G46)}
        {html:build2("G47", $labels:G47, $labels:G47_SHORT, $G47invalid, "All values are valid", " invalid value", $errors:G47)}
        {html:buildInfoTR("Specific checks on aqd:exceedanceDescriptionAdjustment")}
        {html:build2("G52", $labels:G52, $labels:G52_SHORT, $G52invalid, "All values are valid", "", $errors:G52)}
        {html:build2("G53", $labels:G53, $labels:G53_SHORT, $G53invalid, "All values are valid", " invalid value", $errors:G53)}
        {html:build2("G54", $labels:G54, $labels:G54_SHORT, $G54invalid, "All values are valid", " invalid value", $errors:G54)}
        {html:build2("G55", $labels:G55, $labels:G55_SHORT, $G55invalid, "All values are valid", " invalid value", $errors:G55)}
        {html:build2("G56", $labels:G56, $labels:G56_SHORT, $G56invalid, "All values are valid", " invalid value", $errors:G56)}
        {html:build2("G58", $labels:G58, $labels:G58_SHORT, $G58invalid, "All values are valid", " invalid value", $errors:G58)}
        {html:build2("G59", $labels:G59, $labels:G59_SHORT, $G59invalid, "All values are valid", " invalid value", $errors:G59)}
        {html:build2("G60", $labels:G60, $labels:G60_SHORT, $G60invalid, "All values are valid", " invalid value", $errors:G60)}
        {html:build2("G61", $labels:G61, $labels:G61_SHORT, $G61invalid, "All values are valid", "", $errors:G61)}
        {html:build2("G62", $labels:G62, $labels:G62_SHORT, $G62invalid, "All values are valid", "", $errors:G62)}
        {html:build2("G63", $labels:G63, $labels:G63_SHORT, $G63invalid, "All values are valid", "", $errors:G63)}
        {html:build2("G64", $labels:G64, $labels:G64_SHORT, $G64invalid, "All values are valid", " invalid value", $errors:G64)}
        {html:build2("G66", $labels:G66, $labels:G66_SHORT, $G66invalid, "All values are valid", " invalid value", $errors:G66)}
        {html:build2("G67", $labels:G67, $labels:G67_SHORT, $G67invalid, "All values are valid", " invalid value", $errors:G67)}
        {html:buildInfoTR("Specific checks on aqd:exceedanceDescriptionFinal")}
        {html:build2("G70", $labels:G70, $labels:G70_SHORT, $G70invalid, "All values are valid", " invalid value", $errors:G70)}
        {html:build2("G71", $labels:G71, $labels:G71_SHORT, $G71invalid, "All values are valid", " invalid value", $errors:G71)}
        {html:build2("G72", $labels:G72, $labels:G72_SHORT, $G72invalid, "All values are valid", "", $errors:G72)}
        {html:build2("G73", $labels:G73, $labels:G73_SHORT, $G73invalid, "All values are valid", " invalid value", $errors:G73)}
        {html:build2("G74", $labels:G74, $labels:G74_SHORT, $modelUsed_74, "All values are valid", " invalid value", $errors:G74)}
        {html:build2("G75", $labels:G75, $labels:G75_SHORT, $G75invalid, "All values are valid", " invalid value", $errors:G75)}
        {html:build2("G76", $labels:G76, $labels:G76_SHORT, $G76invalid, "All values are valid", " invalid value", $errors:G76)}
        {html:build2("G78", $labels:G78, $labels:G78_SHORT, $G78invalid, "All values are valid", " invalid value", $errors:G78)}
        {html:build2("G79", $labels:G79, $labels:G79_SHORT, $G79invalid, "All values are valid", " invalid value", $errors:G79)}
        {html:build2("G80", $labels:G80, $labels:G80_SHORT, $G80invalid, "All values are valid", " invalid value", $errors:G80)}
        {html:build2("G81", $labels:G81, $labels:G81_SHORT, $G81invalid, "All values are valid", " invalid value", $errors:G81)}
        {html:build2("G85", $labels:G85, $labels:G85_SHORT, $G85invalid, "All values are valid", " invalid value", $errors:G85)}
        {html:build2("G86", $labels:G86, $labels:G86_SHORT, $G86invalid, "All values are valid", " invalid value", $errors:G86)}
        {$G82invalid}
    </table>
};


declare function dataflowG:buildVocItemsList($ruleId as xs:string, $vocabularyUrl as xs:string, $ids as xs:string*)
as element(div) {
    let $list :=
        for $id in $ids
        let $refUrl := concat($vocabularyUrl, $id)
        return
            <li><a href="{ $refUrl }">{ $refUrl } </a></li>


    return
     <div>
         <a id='vocLink-{$ruleId}' href='javascript:toggleItem("vocValuesDiv","vocLink", "{$ruleId}", "item")'>Show items</a>
         <div id="vocValuesDiv-{$ruleId}" style="display:none"><ul>{ $list }</ul></div>
     </div>


};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function dataflowG:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countZones := count(doc($source_url)//aqd:AQD_Attainment)
let $result := if ($countZones > 0) then dataflowG:checkReport($source_url, $countryCode) else ()
let $meta := map:merge((
    map:entry("count", $countZones),
    map:entry("header", "Check air quality attainment of environmental objectives"),
    map:entry("dataflow", "Dataflow G"),
    map:entry("zeroCount", <p>No aqd:AQD_Attainment elements found from this XML.</p>),
    map:entry("report", <p>This check evaluated the delivery by executing the tier-1 tests on air quality assessment regimes data in Dataflow G as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
))
return
    html:buildResultDiv($meta, $result)
};
