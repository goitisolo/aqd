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

declare namespace functx = "http://www.functx.com";

declare variable $dataflowG:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
declare variable $dataflowG:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "679");

(: Rule implementations :)
declare function dataflowG:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
let $ms1Total := prof:current-ms()

let $ms1GeneralParameters:= prof:current-ms()
let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $cdrUrl := common:getCdrUrl($countryCode)
let $reportingYear := common:getReportingYear($docRoot)
let $previousReportingYear := string(number($reportingYear) - 1)

let $bdir := if (contains($source_url, "b_preliminary")) then "b_preliminary/" else "b/"
let $cdir := if (contains($source_url, "c_preliminary")) then "c_preliminary/" else "c/"
let $zonesUrlB := concat($cdrUrl, $bdir)
let $zonesUrlC := concat($cdrUrl, $cdir)
let $latestEnvelopeBperYear := query:getLatestEnvelope($zonesUrlB, $reportingYear)
let $latestEnvelopeCperYear := query:getLatestEnvelope($zonesUrlC, $reportingYear)


let $modelCdrUrl := if ($countryCode = 'gi') then common:getCdrUrl('gb') else $cdrUrl


let $latestEnvelopeByYearB := query:getLatestEnvelope($cdrUrl || "b/", $reportingYear)

let $latestEnvelopeB := query:getLatestEnvelope($cdrUrl || "b/")
let $latestEnvelopeC := query:getLatestEnvelope($cdrUrl || "c/")
let $latestEnvelopeByYearC := query:getLatestEnvelope($cdrUrl || "c/", $reportingYear)
let $latestEnvelopeD := query:getLatestEnvelope($cdrUrl || "d/")
let $latestEnvelopeD1b := query:getLatestEnvelope($cdrUrl || "d1b/", $reportingYear)
let $latestEnvelopeByYearG := query:getLatestEnvelope($cdrUrl || "g/", $reportingYear)
let $latestEnvelopeFromPreviousYearG := query:getLatestEnvelope($cdrUrl || "g/", $previousReportingYear)

let $envelopesC := distinct-values(query:getEnvelopes($cdrUrl || "c/", $reportingYear))
let $latestEnvelopeC := query:getLatestEnvelope($cdrUrl || "c/", $reportingYear)
let $envelopesE1a := distinct-values(query:getEnvelopes($cdrUrl || "e1a/", $reportingYear))
let $envelopesE1b := distinct-values(query:getEnvelopes($cdrUrl || "e1b/", $reportingYear))

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
    (:let $results := sparqlx:run(query:getSamplingPointAssessmentMetadata()):)
    let $results := sparqlx:run(query:getSamplingPointAssessmentMetadata2($countryCode))
    return distinct-values(
            for $i in $results
            return concat($i/sparql:binding[@name='metadataNamespace']/sparql:literal,"/", $i/sparql:binding[@name='metadataId']/sparql:literal)
    )
let $namespaces := distinct-values($docRoot//base:namespace)
let $allAttainments := query:getAllAttainmentIds2($namespaces)

let $samplingPoints := 
    for $envelopeE1a in $envelopesE1a 
    let $results := sparqlx:run(query:getAssessmentMethodsE($envelopeE1a))
    return distinct-values(
            for $i in $results
            return $i
    )

let $modelAssessments := 
    for $envelopeE1b in $envelopesE1b 
    let $results := sparqlx:run(query:getAssessmentMethodsE($envelopeE1b))
    return distinct-values(
            for $i in $results
            return $i
    )

let $ms2GeneralParameters:= prof:current-ms()
(: File prefix/namespace check :)
let $ms1NS := prof:current-ms()
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

let $ms2NS := prof:current-ms()

(: VOCAB check:)
let $ms1VOCAB := prof:current-ms()

let $VOCABinvalid := checks:vocab($docRoot)

let $ms2VOCAB := prof:current-ms()


(:VOCABALL check @goititer:)

let $ms1CVOCABALL := prof:current-ms()

let $VOCABALLinvalid := checks:vocaball($docRoot)

let $ms2CVOCABALL := prof:current-ms()

(: G0 :)

let $ms1G0 := prof:current-ms()

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


let $ms2G0 := prof:current-ms()

(: G01 :)

let $ms1G01 := prof:current-ms()

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


let $ms2G01 := prof:current-ms()

(: G02 :)

let $ms1G02 := prof:current-ms()

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
                <td title="Sparql">{sparqlx:getLink(query:getAllAttainmentIds2Query($namespaces))}</td>
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


let $ms2G02 := prof:current-ms()

(: G03 - :)

let $ms1G03 := prof:current-ms()

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


let $ms2G03 := prof:current-ms()

(: G04 - :)

let $ms1G04 := prof:current-ms()

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


let $ms2G04 := prof:current-ms()

(: G05 Compile & feedback a list of the exceedances situations based on the content of ./aqd:zone, ./aqd:pollutant, ./aqd:objectiveType, ./aqd:reportingMetric,
   ./aqd:protectionTarget, aqd:exceedanceDescription_Final/aqd:ExceedanceDescription/aqd:exceedance :)

let $ms1G05 := prof:current-ms()

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


let $ms2G05 := prof:current-ms()

(: G06 :)

let $ms1G06 := prof:current-ms()

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


let $ms2G06 := prof:current-ms()

(: G07 duplicate @gml:ids and aqd:inspireIds and ef:inspireIds :)
(: Feedback report shall include the gml:id attribute, ef:inspireId, aqd:inspireId, ef:name and/or ompr:name elements as available. :)

let $ms1G07 := prof:current-ms()

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

let $ms2G07 := prof:current-ms()

(: G08 ./aqd:inspireId/base:Identifier/base:localId shall be an unique code for the attainment records starting with ISO2-country code :)

let $ms1G08 := prof:current-ms()

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


let $ms2G08 := prof:current-ms()

(: G09 ./ef:inspireId/base:Identifier/base:namespace shall resolve to a unique namespace identifier for the data source (within an annual e-Reporting cycle). :)

let $ms1G09 := prof:current-ms()

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


let $ms2G09 := prof:current-ms()

(: G09.1 :)

let $ms1G09.1 := prof:current-ms()

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


let $ms2G09.1 := prof:current-ms()

(: G10 pollutant codes :)

let $ms1G10 := prof:current-ms()

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


let $ms2G10 := prof:current-ms()

(: G11 :)

let $ms1G11 := prof:current-ms()

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


let $ms2G11 := prof:current-ms()

(: G12 :)

let $ms1G12 := prof:current-ms()

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

let $ms2G12 := prof:current-ms()

(: G13 - :)

let $ms1G13 := prof:current-ms()

let $G13Results :=
    try {
        sparqlx:run(query:getG13(upper-case($countryCode), $reportingYear))
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
                <td title="Sparql">{sparqlx:getLink(query:getG13(upper-case($countryCode), $reportingYear))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ms2G13 := prof:current-ms()

(: G13b :)

let $ms1G13b := prof:current-ms()

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
                <td title="Sparql">{sparqlx:getLink(query:getG13(upper-case($countryCode), $reportingYear))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ms2G13b := prof:current-ms()

(: G13c :)

let $ms1G13c := prof:current-ms()

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
                <td title="Sparql">{sparqlx:getLink(query:getG13(upper-case($countryCode), $reportingYear))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ms2G13c := prof:current-ms()

(: G14 - COUNT number zone-pollutant-target comibantion to match those in dataset B and dataset C for the same reporting Year & compare it with Attainment. :)

let $ms1G14 := prof:current-ms()

let $G14table :=
    try {
        let $G14resultBC :=
            for $i in sparqlx:run(query:getG14($latestEnvelopeBperYear, $latestEnvelopeCperYear, $reportingYear))
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
                <td title="Sparql">{sparqlx:getLink(query:getG14($latestEnvelopeBperYear, $latestEnvelopeCperYear, $reportingYear))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ms2G14 := prof:current-ms()

(: G14b :)

let $ms1G14b := prof:current-ms()

let $G14binvalid :=
    try {
        let $exception := ($vocabulary:OBJECTIVETYPE_VOCABULARY || "ALT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "INT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "MO")
        let $query :=
            "PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
           PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
           PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
           PREFIX rod: <http://rod.eionet.europa.eu/schema.rdf#>

           SELECT ?localId ?inspireLabel
           WHERE {
                GRAPH ?file{
                  ?regime a aqd:AQD_AssessmentRegime ;
                  aqd:inspireId ?inspireId ;
                  aqd:assessmentThreshold ?assessmentThreshold .
                  ?inspireId rdfs:label ?inspireLabel .
                  ?inspireId aqd:localId ?localId .
                  ?assessmentThreshold aqd:environmentalObjective ?objective .
                  ?objective aqd:objectiveType ?objectiveType .
                  FILTER (!(str(?objectiveType) in ('" || string-join($exception, "','") || "')))
              }
                <" || $latestEnvelopeByYearC || "> rod:hasFile ?file
   }"
        let $all := distinct-values(data(sparqlx:run($query)/sparql:binding[@name = 'inspireLabel']/sparql:literal))
        let $allLocal := data($docRoot//aqd:AQD_Attainment[not(aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href = $exception)]/aqd:assessment/@xlink:href)
        for $x in $all
        where (not($x = $allLocal))
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{$x}</td>
                <td title="Sparql">{sparqlx:getLink($query)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2G14b := prof:current-ms()


(: G15 :)

let $ms1G15 := prof:current-ms()

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
                <td title="Sparql">{sparqlx:getLink(query:getZone($latestEnvelopeByYearB))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2G15 := prof:current-ms()


(: G17 :)

let $ms1G17 := prof:current-ms()

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
                <td title="Sparql1">{sparqlx:getLink(query:getZone($cdrUrl))}</td>
                <td title="Sparql2">{sparqlx:getLink(query:getPollutantlD($cdrUrl))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2G17 := prof:current-ms()

(: G18 :)
let $ms1G18 := prof:current-ms()

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
                <td title="Sparql">{sparqlx:getLink(query:getTimeExtensionExemption($cdrUrl))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2G18 := prof:current-ms()

(: G19 .//aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of :)

let $ms1G19 := prof:current-ms()
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

let $ms2G19 := prof:current-ms()

(: G20 - ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute shall resolve to one of
... :)
let $ms1G20 := prof:current-ms()

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

let $ms2G20 := prof:current-ms()

(: G21 - aqd:protectionTarget match with vocabulary codes :)

let $ms1G21 := prof:current-ms()

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

let $ms2G21 := prof:current-ms()

(: G22 :)

let $ms1G22 := prof:current-ms()

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

let $ms2G22 := prof:current-ms()

(: G38 :)

let $ms1G38 := prof:current-ms()

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

let $ms2G38 := prof:current-ms()

(: G39 :)

let $ms1G39 := prof:current-ms()

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

let $ms2G39 := prof:current-ms()

(: G40 - :)

let $ms1G40 := prof:current-ms()

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

let $ms2G40 := prof:current-ms()

(: G41 - :)

let $ms1G41 := prof:current-ms()

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

let $ms2G41 := prof:current-ms()

(: G42 - :)

let $ms1G42 := prof:current-ms()

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

let $ms2G42 := prof:current-ms()

(: G44 - aqd:AQD_Attainment/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedance shall EQUAL “true” or “false” :)

let $ms1G44 := prof:current-ms()

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

let $ms2G44 := prof:current-ms()

(: G45 - If ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedance is TRUE EITHER ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)

let $ms1G45 := prof:current-ms()

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

let $ms2G45 := prof:current-ms()

(: G46 :)

let $ms1G46 := prof:current-ms()

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

let $ms2G46 := prof:current-ms()

(: G47 :)

let $ms1G47 := prof:current-ms()

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

let $ms2G47 := prof:current-ms()

(: G52 :)

let $ms1G52 := prof:current-ms()

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

let $ms2G52 := prof:current-ms()

(: G53 :)

let $ms1G53 := prof:current-ms()

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

let $ms2G53 := prof:current-ms()

(: G54 - :)

let $ms1G54 := prof:current-ms()

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

let $ms2G54 := prof:current-ms()

(: G55 :)

let $ms1G55 := prof:current-ms()

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

let $ms2G55 := prof:current-ms()

(: G56 :)

let $ms1G56 := prof:current-ms()

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

let $ms2G56 := prof:current-ms()

(: G57 - :)

let $ms1G57 := prof:current-ms()

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

let $ms2G57 := prof:current-ms()

(: G58 - aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance shall EQUAL “true” or “false” :)

let $ms1G58 := prof:current-ms()

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

let $ms2G58 := prof:current-ms()

(: G59 - If ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance is TRUE EITHER ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)

let $ms1G59 := prof:current-ms()

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

let $ms2G59 := prof:current-ms()

(: G60 - If ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance is FALSE EITHER ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)

let $ms1G60 := prof:current-ms()

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

let $ms2G60 := prof:current-ms()

(: G61 :)

let $ms1G61 := prof:current-ms()

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

let $ms2G61 := prof:current-ms()

(: G62 - :)

let $ms1G62 := prof:current-ms()

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

let $ms2G62 := prof:current-ms()

(: G63 :)

let $ms1G63 := prof:current-ms()

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

let $ms2G63 := prof:current-ms()

(: G64 :)

let $ms1G64 := prof:current-ms()

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

let $ms2G64 := prof:current-ms()

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

(: G66 
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
    }:)

(: G66 :)

let $ms1G66 := prof:current-ms()

let $G66invalid :=
    try {


        let $valuesInC := sparqlx:run(query:getG66($latestEnvelopeC, $reportingYear))
        let $valuesInCConcat :=
            for $x in $valuesInC             
                return $x/sparql:binding[@name="localId"]/sparql:literal || "###" || $x/sparql:binding[@name="assessment"]/sparql:uri || "##"
        
        for $i in $valuesInCConcat
             let $localIdC := tokenize($i, "###")[1]
             let $assessmentC := tokenize($i, "###")[2]
             let $assessmentCsubs := substring-before(substring($assessmentC, string-length("http://reference.eionet.europa.eu/aq/")+1), "##")
                    

            let $valuesInG :=
                for $r in $validAssessment/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:modelAssessmentMetadata[not(@xlink:href = $assessmentCsubs)]        
                    let $assesmentG := substring-after(data($r/../../../../../../../aqd:assessment/fn:normalize-space(@xlink:href)),"/")

                    where ($assesmentG = $localIdC)
                return data($r/../../../../../../../@gml:id)|| "###"||substring-after(data($r/../../../../../../../aqd:assessment/fn:normalize-space(@xlink:href)),"/")|| "###"||data($r/fn:normalize-space(@xlink:href))

        for $x in $valuesInG
            let $localId := tokenize($x, "###")[1]
            let $assessment := tokenize($x, "###")[2]
            let $station := tokenize($x, "###")[3]

        (:where $station != $assessmentCsubs:)
        return
            <tr>
                <td title="gml:id">{$localId}</td>
                <td title="aqd:assessment">{functx:substring-after-if-contains($assessment, "://reference.eionet.europa.eu/aq/")}</td>
                <td title="aqd:modelAssessmentMetadata">{$station}</td>
                <td title="C gml:id">{$localIdC}</td>
                <td title="C aqd:modelAssessmentMetadata">{functx:substring-after-if-contains($assessmentCsubs, "://reference.eionet.europa.eu/aq/")}</td>
                <td title="Sparql">{sparqlx:getLink(query:getG66($latestEnvelopeC, $reportingYear))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ms2G66 := prof:current-ms()


(: G67 - :)

let $ms1G67 := prof:current-ms()

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

let $ms2G67 := prof:current-ms()

(: G70 :)

let $ms1G70 := prof:current-ms()

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

let $ms2G70 := prof:current-ms()

(: G71 :)

let $ms1G71 := prof:current-ms()

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

let $ms2G71 := prof:current-ms()

(: G72 :)

let $ms1G72 := prof:current-ms()

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

let $ms2G72 := prof:current-ms()

(: G73 :)

let $ms1G73 := prof:current-ms()

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

let $ms2G73 := prof:current-ms()

(: G74 :)

let $ms1G74 := prof:current-ms()

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

let $ms2G74 := prof:current-ms()

(: G75 :)

let $ms1G75 := prof:current-ms()

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

let $ms2G75 := prof:current-ms()

(: G76 :)

let $ms1G76 := prof:current-ms()

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

let $ms2G76 := prof:current-ms()

(: G78 - ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance shall EQUAL “true” or “false” :)

let $ms1G78 := prof:current-ms()

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

let $ms2G78 := prof:current-ms()

(: G79 - If ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance is TRUE EITHER ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)

let $ms1G79 := prof:current-ms()

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

let $ms2G79 := prof:current-ms()

(: G80 - If ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance is FALSE EITHER ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)

let $ms1G80 := prof:current-ms()

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

let $ms2G80 := prof:current-ms()

(: G81 :)

let $ms1G81 := prof:current-ms()

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

let $ms2G81 := prof:current-ms()

(: G82 - :)

let $ms1G82 := prof:current-ms()

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

let $ms2G82 := prof:current-ms()

(:~ G85 - WHERE ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance shall EQUAL “true”
 :  ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed OR
 :  ./aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed MUST be populated (At least 1 xlink must be found)
 :)

let $ms1G85 := prof:current-ms()

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

let $ms2G85 := prof:current-ms()

(: G86 :)

let $ms1G86 := prof:current-ms()

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

let $ms2G86 := prof:current-ms()

(: G89 :)

let $ms1G89 := prof:current-ms()

let $G89invalid :=
    try {
        let $assessmentMethodsSampling := sparqlx:run(query:getAssessmentMethodsCSamplingPoint($latestEnvelopeC))
        let $assessmentMethodsModels := sparqlx:run(query:getAssessmentMethodsCModels($latestEnvelopeC))
        for $x in $docRoot//aqd:AQD_Attainment/aqd:assessment/@xlink:href
        let $assessment := functx:substring-after-last($x, '/')        
            let $sampling :=
                for $assessmentMethod in $assessmentMethodsSampling[sparql:binding[@name='localId']/sparql:literal = $assessment]/sparql:binding[@name='samplingPointAssessmentMetadata']/sparql:literal
                    let $localId := $assessmentMethod/../../sparql:binding[@name='localId']/sparql:literal
                    return
                    if (not(empty($assessmentMethod))) then  
                        if ($samplingPoints = $assessmentMethod) then ()
                        else   
                            <tr>
                                 <td title="Not found">{"Sampling Point Assessment for: " || functx:substring-after-last(string($assessmentMethod), '/')}</td>
                                 <td title="localId">{$localId}</td>
                                 <td title="Sparql">{sparqlx:getLink(query:getAssessmentMethodsCSamplingPoint($latestEnvelopeC))}</td>
                            </tr>   
            let $models := 
                for $assessmentMethod in $assessmentMethodsModels[sparql:binding[@name='localId']/sparql:literal = $assessment]/sparql:binding[@name='modelAssessmentMetadata']/sparql:literal
                    let $localId := $assessmentMethod/../../sparql:binding[@name='localId']/sparql:literal
                    return
                    if (not(empty($assessmentMethod))) then  
                        if ($modelAssessments = $assessmentMethod) then ()
                        else   
                            <tr>
                                 <td title="Not found">{"Model Point Assessment for: " || functx:substring-after-last(string($assessmentMethod), '/')}</td>
                                 <td title="localId">{$localId}</td>
                                 <td title="Sparql">{sparqlx:getLink(query:getAssessmentMethodsCModels($latestEnvelopeC))}</td>
                            </tr>                                                        

        let $countModels := count($models)
        let $countSampling := count($sampling)
        return 
            if($countSampling != 0) then
                $sampling
            else if ($countModels != 0) then
                $models 
            else
            ()
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2G89 := prof:current-ms()


(: G91 :)

let $ms1G91 := prof:current-ms()

let $G91invalid :=
    try {
        let $exceedanceResults := sparqlx:run(query:getAqdExceedanceWithZoneQueryGraph($latestEnvelopeFromPreviousYearG))
        
        (: 1. Error will return if combination of elements aqd:pollutant + aqd:objectiveType + aqd:reportingMetric + aqd:protectionTarget + aqd:zone match and aqd:exceedance do not match: :)
        let $notMatch := (
          for $x in $docRoot//gml:featureMember/aqd:AQD_Attainment
            let $attainmentId := $x/aqd:inspireId/base:Identifier/base:localId
            let $exceedance := $x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance
            
            let $pollutant := functx:substring-after-last(data($x/aqd:pollutant/@xlink:href), "/")
            let $objectiveType := functx:substring-after-last(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href), "/")
            let $reportingMetric := functx:substring-after-last(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href), "/")
            let $protectionTarget := functx:substring-after-last(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href), "/")
            let $zone := functx:substring-after-last(data($x/aqd:zone/@xlink:href), "/")
            
            for $result in $exceedanceResults(:[ sparql:binding[@name='pollutant']/sparql:uri = $pollutant and sparql:binding[@name='objectiveType']/sparql:uri = $objectiveType and sparql:binding[@name='reportingMetric']/sparql:uri = $reportingMetric and sparql:binding[@name='protectionTarget']/sparql:uri = $protectionTarget and sparql:binding[@name='zone']/sparql:uri = $zone ]:)
              let $localIdResult := $result/sparql:binding[@name='localId']/sparql:literal
              let $exceedanceResult := (
                  if($result/sparql:binding[@name='exceedance']/sparql:literal = 1) then "true"
                  else if($result/sparql:binding[@name='exceedance']/sparql:literal = 0) then "false"
              )
              let $pollutantResult := functx:substring-after-last($result/sparql:binding[@name='pollutant']/sparql:uri, "/")
              let $objectiveTypeResult := functx:substring-after-last($result/sparql:binding[@name='objectiveType']/sparql:uri, "/")
              let $reportingMetricResult := functx:substring-after-last($result/sparql:binding[@name='reportingMetric']/sparql:uri, "/")
              let $protectionTargetResult := functx:substring-after-last($result/sparql:binding[@name='protectionTarget']/sparql:uri, "/")
              let $zoneResult := functx:substring-after-last($result/sparql:binding[@name='zone']/sparql:uri, "/")
              
              let $errorMessage := 
                if( ( $pollutant = $pollutantResult and $objectiveType = $objectiveTypeResult and $reportingMetric = $reportingMetricResult and $protectionTarget = $protectionTargetResult and $zone = $zoneResult ) and 
                    ( ($exceedance="true" and $exceedanceResult="false") or ($exceedance="false" and $exceedanceResult="true") ) ) 
                    then "combination of elements do not match"
              
              return 
                if( ( $pollutant = $pollutantResult and $objectiveType = $objectiveTypeResult and $reportingMetric = $reportingMetricResult and $protectionTarget = $protectionTargetResult and $zone = $zoneResult ) and 
                    ( ($exceedance="true" and $exceedanceResult="false") or ($exceedance="false" and $exceedanceResult="true") ) )
                then 
                <tr>
                  <td title="base:localId from update">{$attainmentId}</td>
                  <td title="aqd:exceedance from update">{$exceedance}</td>
                  <td title="aqd:pollutant from update">{$pollutant}</td>
                  <td title="aqd:objectiveType from update">{$objectiveType}</td>
                  <td title="aqd:reportingMetric from update">{$reportingMetric}</td>
                  <td title="aqd:protectionTarget from update">{$protectionTarget}</td>
                  <td title="aqd:zone from update">{$zone}</td>
                  
                  <td title="base:localId from latest envelope from previous year">{$localIdResult}</td>
                  <td title="aqd:exceedance from latest envelope from previous year">{$exceedanceResult}</td>
                  <td title="aqd:pollutant from previous year">{$pollutantResult}</td>
                  <td title="aqd:objectiveType from previous year">{$objectiveTypeResult}</td>
                  <td title="aqd:reportingMetric from previous year">{$reportingMetricResult}</td>
                  <td title="aqd:protectionTarget from previous year">{$protectionTargetResult}</td>
                  <td title="aqd:zone from previous year">{$zoneResult}</td>
                  
                  <td title="error message">{$errorMessage}</td>
                  <td title="Sparql">{sparqlx:getLink(query:getAqdExceedanceWithZoneQueryGraph($latestEnvelopeFromPreviousYearG))}</td>
                </tr>
          )
          
          (: 2. Error will return if the combination of elements aqd:pollutant + aqd:objectiveType + aqd:reportingMetric + aqd:protectionTarget + aqd:zone (from SPARQL) is missing in the XML: :)
          let $missing := (
            let $combinationXML := (
              for $x in $docRoot//gml:featureMember/aqd:AQD_Attainment
                let $attainmentId := $x/aqd:inspireId/base:Identifier/base:localId
                let $exceedance := $x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance
                
                let $pollutant := functx:substring-after-last(data($x/aqd:pollutant/@xlink:href), "/")
                let $objectiveType := functx:substring-after-last(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href), "/")
                let $reportingMetric := functx:substring-after-last(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href), "/")
                let $protectionTarget := functx:substring-after-last(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href), "/")
                let $zone := functx:substring-after-last(data($x/aqd:zone/@xlink:href), "/")
                
                return $pollutant || " , " || $objectiveType || " , " || $reportingMetric  || " , " || $protectionTarget  || " , " || $zone
            ) 
            
            for $result in $exceedanceResults
              let $localIdResult := $result/sparql:binding[@name='localId']/sparql:literal
              let $exceedanceResult := (
                  if($result/sparql:binding[@name='exceedance']/sparql:literal = 1) then "true"
                  else if($result/sparql:binding[@name='exceedance']/sparql:literal = 0) then "false"
              )
              let $pollutantResult := functx:substring-after-last($result/sparql:binding[@name='pollutant']/sparql:uri, "/")
              let $objectiveTypeResult := functx:substring-after-last($result/sparql:binding[@name='objectiveType']/sparql:uri, "/")
              let $reportingMetricResult := functx:substring-after-last($result/sparql:binding[@name='reportingMetric']/sparql:uri, "/")
              let $protectionTargetResult := functx:substring-after-last($result/sparql:binding[@name='protectionTarget']/sparql:uri, "/")
              let $zoneResult := functx:substring-after-last($result/sparql:binding[@name='zone']/sparql:uri, "/")
              
              let $combinationResults := $pollutantResult || " , " || $objectiveTypeResult || " , " || $reportingMetricResult  || " , " || $protectionTargetResult  || " , " || $zoneResult
              
              let $isPreviousYearCombinationInXML := count(index-of($combinationXML, $combinationResults))
              
              let $errorMessage := 
                if( $isPreviousYearCombinationInXML = 0 ) then "combination of elements from the latest envelope from previous year is missing in the update"
              
              return 
                if( $isPreviousYearCombinationInXML = 0 ) 
                then 
                <tr>
                  <td title="base:localId from update">{data("Missing combination")}</td>
                  <td title="aqd:exceedance from update">{data("Missing combination")}</td>
                  <td title="aqd:pollutant from update">{data("Missing combination")}</td>
                  <td title="aqd:objectiveType from update">{data("Missing combination")}</td>
                  <td title="aqd:reportingMetric from update">{data("Missing combination")}</td>
                  <td title="aqd:protectionTarget from update">{data("Missing combination")}</td>
                  <td title="aqd:zone from update">{data("Missing combination")}</td>
                  
                  <td title="base:localId from latest envelope from previous year">{$localIdResult}</td>
                  <td title="aqd:exceedance from latest envelope from previous year">{$exceedanceResult}</td>
                  <td title="aqd:pollutant from previous year">{$pollutantResult}</td>
                  <td title="aqd:objectiveType from previous year">{$objectiveTypeResult}</td>
                  <td title="aqd:reportingMetric from previous year">{$reportingMetricResult}</td>
                  <td title="aqd:protectionTarget from previous year">{$protectionTargetResult}</td>
                  <td title="aqd:zone from previous year">{$zoneResult}</td>
                  
                  <td title="error message">{$errorMessage}</td>
                  <td title="Sparql">{sparqlx:getLink(query:getAqdExceedanceWithZoneQueryGraph($latestEnvelopeFromPreviousYearG))}</td>
                </tr>
          )
        
        (: 3. List of errors: :)    
        let $countNotMatch := count($notMatch)
        let $countMissing := count($missing)
        return
            (if($countNotMatch != 0) then $notMatch ,
            if($countMissing != 0) then $missing )
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2G91 := prof:current-ms()


(: G92 :)

let $ms1G92 := prof:current-ms()

let $G92invalid :=
    try {
        let $exceedanceResults := sparqlx:run(query:getAqdExceedanceQueryGraph($latestEnvelopeByYearG))
                
        let $localIdsXML := $docRoot//gml:featureMember/aqd:AQD_Attainment/aqd:inspireId/base:Identifier/base:localId
        
        (: 1. Error will return if base:localIds match and aqd:exceedance do not match: :)
        let $notMatch := (
          for $x in $docRoot//gml:featureMember/aqd:AQD_Attainment
            let $attainmentId := $x/aqd:inspireId/base:Identifier/base:localId
            let $exceedance := $x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance
            
            for $result in $exceedanceResults[sparql:binding[@name='localId']/sparql:literal = $attainmentId]
              let $localIdResult := $result/sparql:binding[@name='localId']/sparql:literal
              let $exceedanceResult := (
                  if($result/sparql:binding[@name='exceedance']/sparql:literal = 1) then "true"
                  else if($result/sparql:binding[@name='exceedance']/sparql:literal = 0) then "false"
              )
              
              let $errorMessage := if( $attainmentId = $localIdResult and ( ($exceedance="true" and $exceedanceResult="false") or ($exceedance="false" and $exceedanceResult="true") ) ) then "aqd:exceedance do not match"
              
              return if( $attainmentId = $localIdResult and ( ($exceedance="true" and $exceedanceResult="false") or ($exceedance="false" and $exceedanceResult="true") ) ) then 
                <tr>
                  <td title="base:localId from update">{$attainmentId}</td>
                  <td title="aqd:exceedance from update">{$exceedance}</td>
                  <td title="reporting year">{$reportingYear}</td>
                  <td title="latest envelope by year">{$latestEnvelopeByYearG}</td>
                  <td title="base:localId from latest envelope">{$localIdResult}</td>
                  <td title="aqd:exceedance from latest envelope">{$exceedanceResult}</td>
                  <td title="error message">{$errorMessage}</td>
                  <td title="Sparql">{sparqlx:getLink(query:getAqdExceedanceQueryGraph($latestEnvelopeByYearG))}</td>
                </tr>
          )
          
          (: 2. Error will return if base:localIds (from SPARQL) are missing in the XML: :)
          let $missing := (
            for $result in $exceedanceResults
              let $localIdResult := $result/sparql:binding[@name='localId']/sparql:literal
              
              let $isLatestLocalIdInXML := count(index-of($localIdsXML, $localIdResult))
              
              let $exceedanceResult := (
                if( $isLatestLocalIdInXML = 0 ) then
                  if($result/sparql:binding[@name='exceedance']/sparql:literal = 1) then "true"
                  else if($result/sparql:binding[@name='exceedance']/sparql:literal = 0) then "false"
              )
              
              let $errorMessage := if( $isLatestLocalIdInXML = 0 ) then "base:localId from the latest envelope is missing in the update"
              
              return if( $isLatestLocalIdInXML = 0 ) then
                <tr>
                  <td title="base:localId from update">{data("Missing value")}</td>
                  <td title="aqd:exceedance from update">{data("Missing value")}</td>
                  <td title="reporting year">{$reportingYear}</td>
                  <td title="latest envelope by year">{$latestEnvelopeByYearG}</td>
                  <td title="base:localId from latest envelope">{$localIdResult}</td>
                  <td title="aqd:exceedance from latest envelope">{$exceedanceResult}</td>
                  <td title="error message">{$errorMessage}</td>
                  <td title="Sparql">{sparqlx:getLink(query:getAqdExceedanceQueryGraph($latestEnvelopeByYearG))}</td>
                </tr>                
          )
        
        (: 3. List of errors: :)    
        let $countNotMatch := count($notMatch)
        let $countMissing := count($missing)
        return
            (if($countNotMatch != 0) then $notMatch ,
            if($countMissing != 0) then $missing )
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ms2G92 := prof:current-ms()


let $ms2Total := prof:current-ms()
return
    <table class="maintable hover">
    <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
         <!--{html:buildNoCount2Sparql("VOCABALL", $labels:VOCABALL, $labels:VOCABALL_SHORT, $VOCABALLinvalid, "All values are valid", "Invalid urls found", $errors:VOCABALL)}-->
        {html:build3("G0", $labels:G0, $labels:G0_SHORT, $G0table, string($G0table/td), errors:getMaxError($G0table))}
        {html:build1("G01", $labels:G01, $labels:G01_SHORT, $tblAllAttainments, "", string($countAttainments), "", "", $errors:G01)}
        {html:buildSimpleSparql("G02", $labels:G02, $labels:G02_SHORT, $G02table, "", "", $G02errorLevel)}
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
        {html:build2Sparql("G13", $labels:G13, $labels:G13_SHORT, $G13invalid, "All values are valid", " invalid value", $errors:G13)}
        {html:build2Sparql("G13b", $labels:G13b, $labels:G13b_SHORT, $G13binvalid, "All values are valid", " invalid value", $errors:G13b)}
        {html:build2Sparql("G13c", $labels:G13c, $labels:G13c_SHORT, $G13cinvalid, "All values are valid", " invalid value", $errors:G13c)}
        {html:build2Sparql("G14", $labels:G14, $labels:G14_SHORT, $G14table, "All values are valid", "record", errors:getMaxError($G14table))}
        {html:build2Sparql("G14b", $labels:G14b, $labels:G14b_SHORT, $G14binvalid, "All assessment regimes are reported", " missing assessment regime", $errors:G14b)}
        {html:build2Sparql("G15", $labels:G15, $labels:G15_SHORT, $G15invalid, "All values are valid", " invalid value", $errors:G15)}
        {html:build2Sparql("G17", $labels:G17, $labels:G17_SHORT, $G17invalid, "All values are valid", " invalid value", $errors:G17)}
        {html:build2Sparql("G18", $labels:G18, $labels:G18_SHORT, $G18invalid, "All values are valid", " invalid value", $errors:G18)}
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
        {html:build2Sparql("G66", $labels:G66, $labels:G66_SHORT, $G66invalid, "All values are valid", " invalid value", $errors:G66)}
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
        <!-- {html:buildNoCount2Sparql("G89", $labels:G89, $labels:G89_SHORT, $G89invalid, "All values are valid", "Invalid value found", $errors:G89)} -->
        {html:build2Sparql("G89", $labels:G89, $labels:G89_SHORT, $G89invalid, "All values are valid", " invalid value", $errors:G89)}
        {html:build2Sparql("G91", $labels:G91, $labels:G91_SHORT, $G91invalid, "All values are valid", " invalid value", $errors:G91)}
        {html:build2Sparql("G92", $labels:G92, $labels:G92_SHORT, $G92invalid, "All values are valid", " invalid value", $errors:G92)}
        {$G82invalid}
    </table>
     <table>
    <br/>
    <caption> {$labels:TIMINGTABLEHEADER} </caption>
        <tr>
            <th>Query</th>
            <th>Process time in miliseconds</th>
            <th>Process time in seconds</th>
        </tr>

       {common:runtime("Common variables",  $ms1GeneralParameters, $ms2GeneralParameters)}
       {common:runtime("NS", $ms1NS, $ms2NS)}
       {common:runtime("VOCAB", $ms1VOCAB, $ms2VOCAB)}
       <!--{common:runtime("VOCABALL", $ms1CVOCABALL, $ms2CVOCABALL)}-->
       {common:runtime("G0",  $ms1G0, $ms2G0)}
       {common:runtime("G01", $ms1G01, $ms2G01)}
       {common:runtime("G02", $ms1G02, $ms2G02)}
       {common:runtime("G03", $ms1G03, $ms2G03)}
       {common:runtime("G04",  $ms1G04, $ms2G04)}
       {common:runtime("G05", $ms1G05, $ms2G05)}
       {common:runtime("G06",  $ms1G06, $ms2G06)}
       {common:runtime("G07",  $ms1G07, $ms2G07)}
       {common:runtime("G08",  $ms1G08, $ms2G08)}
       {common:runtime("G09",  $ms1G09, $ms2G09)}
       {common:runtime("G09.1",  $ms1G09.1, $ms2G09.1)}
       {common:runtime("G10",  $ms1G10, $ms2G10)}
       {common:runtime("G11",  $ms1G11, $ms2G11)}
       {common:runtime("G12",  $ms1G12, $ms2G12)}
       {common:runtime("G13",  $ms1G13, $ms2G13)}
       {common:runtime("G13b",  $ms1G13b, $ms2G13b)}
       {common:runtime("G13c",  $ms1G13c, $ms2G13c)}
       {common:runtime("G14",  $ms1G14, $ms2G14)}
       {common:runtime("G14b",  $ms1G14b, $ms2G14b)}
       {common:runtime("G15",  $ms1G15, $ms2G15)}
       {common:runtime("G17",  $ms1G17, $ms2G17)}
       {common:runtime("G18",  $ms1G18, $ms2G18)}
       {common:runtime("G19",  $ms1G19, $ms2G19)}
       {common:runtime("G20", $ms1G20, $ms2G20)}
       {common:runtime("G21",  $ms1G21, $ms2G21)}
       {common:runtime("G22",  $ms1G22, $ms2G22)}
       {common:runtime("G38",  $ms1G38, $ms2G38)}
       {common:runtime("G39",  $ms1G39, $ms2G39)}
       {common:runtime("G40",  $ms1G40, $ms2G40)}
       {common:runtime("G41",  $ms1G41, $ms2G41)}
       {common:runtime("G42",  $ms1G42, $ms2G42)}
       {common:runtime("G44",  $ms1G44, $ms2G44)}
       {common:runtime("G45",  $ms1G45, $ms2G45)}
       {common:runtime("G46",  $ms1G46, $ms2G46)}
       {common:runtime("G47",  $ms1G47, $ms2G47)}
       {common:runtime("G52",  $ms1G52, $ms2G52)}
       {common:runtime("G53",  $ms1G53, $ms2G53)}
       {common:runtime("G54",  $ms1G54, $ms2G54)}
       {common:runtime("G55",  $ms1G55, $ms2G55)}
       {common:runtime("G56",  $ms1G56, $ms2G56)}
       {common:runtime("G58",  $ms1G58, $ms2G58)}
       {common:runtime("G59",  $ms1G59, $ms2G59)}
       {common:runtime("G60",  $ms1G60, $ms2G60)}
       {common:runtime("G61",  $ms1G61, $ms2G61)}
       {common:runtime("G62",  $ms1G62, $ms2G62)}
       {common:runtime("G63",  $ms1G63, $ms2G63)}
       {common:runtime("G64",  $ms1G64, $ms2G64)}
       {common:runtime("G66",  $ms1G66, $ms2G66)}
       {common:runtime("G67",  $ms1G67, $ms2G67)}
       {common:runtime("G70",  $ms1G70, $ms2G70)}
       {common:runtime("G71",  $ms1G71, $ms2G71)}
       {common:runtime("G72",  $ms1G72, $ms2G72)}
       {common:runtime("G73",  $ms1G73, $ms2G73)}
       {common:runtime("G74",  $ms1G74, $ms2G74)}
       {common:runtime("G75",  $ms1G75, $ms2G75)}
       {common:runtime("G76",  $ms1G76, $ms2G76)}
       {common:runtime("G78",  $ms1G78, $ms2G78)}
       {common:runtime("G79",  $ms1G79, $ms2G79)}
       {common:runtime("G80",  $ms1G80, $ms2G80)}
       {common:runtime("G81",  $ms1G81, $ms2G81)}
       {common:runtime("G82",  $ms1G82, $ms2G82)}
       {common:runtime("G85",  $ms1G85, $ms2G85)}
       {common:runtime("G86",  $ms1G86, $ms2G86)}
       {common:runtime("G89",  $ms1G89, $ms2G89)}
       {common:runtime("G91",  $ms1G91, $ms2G91)}
       {common:runtime("G92",  $ms1G92, $ms2G92)}
       {common:runtime("Total time",  $ms1Total, $ms2Total)}
    </table>
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
