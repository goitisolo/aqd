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

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowG";
import module namespace common = "aqd-common" at "aqd_check_common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace filter = "aqd-filter" at "aqd-filter.xquery";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0rc3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";

declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
declare variable $xmlconv:VALID_POLLUTANT_IDS as xs:string* := ("1", "7", "8", "9", "5", "6001", "10","20", "5012", "5014", "5015", "5018", "5029");
declare variable $xmlconv:VALID_POLLUTANT_IDS_11 as xs:string* := ("1", "5", "6001", "10");
declare variable $xmlconv:VALID_POLLUTANT_IDS_27 as xs:string* := ("5", "8", "6001", "10","20", "5012", "5014", "5015", "5018", "5029");
declare variable $xmlconv:VALID_REPMETRIC_IDS_20 as xs:string* := ("3hAbove", "aMean", "wMean", "hrsAbove", "daysAbove", "daysAbove-3yr", "maxd8hrMean","AOT40c", "AOT40c-5yr", "AEI");
declare variable $xmlconv:VALID_REPMETRIC_IDS_23 as xs:string* := ("3hAbove", "aMean", "wMean", "hrsAbove", "daysAbove");

declare variable $xmlconv:VALID_REPMETRIC_IDS_29 as xs:string* := ("3hAbove", "aMean", "wMean", "hrsAbove", "daysAbove","daysAbove-3yr", "maxd8hrMean", "AOT40c", "AOT40c-5yr", "AEI");
declare variable $xmlconv:VALID_REPMETRIC_IDS_24 as xs:string* := ("aMean", "daysAbove");
declare variable $xmlconv:VALID_REPMETRIC_IDS_25 as xs:string* := ("aMean", "AEI");
declare variable $xmlconv:VALID_REPMETRIC_IDS_26 as xs:string* := ("daysAbove");
declare variable $xmlconv:VALID_REPMETRIC_IDS_31 as xs:string* := ("AOT40c", "AOT40c-5yr");
declare variable $xmlconv:VALID_AREACLASSIFICATION_IDS as xs:string* := ("1", "2", "3", "4", "5", "6");
declare variable $xmlconv:VALID_AREACLASSIFICATION_IDS_52 as xs:string* := ("rural","rural-nearcity","rural-regional","rural-remote","urban","suburban");
declare variable $xmlconv:VALID_OBJECTIVETYPE_IDS as xs:string* := ("TV", "LV", "CL","LTO","ECO","LVmaxMOT","INT","ALT");
declare variable $xmlconv:VALID_OBJECTIVETYPE_IDS_19 as xs:string* := ("TV", "LV", "CL", "LVMOT","LVmaxMOT","INT","ALT", "LTO", "ECO");

declare variable $xmlconv:VALID_OBJECTIVETYPE_IDS_28 as xs:string* := ("TV", "LV", "CL","LTO","ECO","LVmaxMOT", "LVMOT", "INT", "ALT");
declare variable $xmlconv:VALID_OBJECTIVETYPE_IDS_32 as xs:string* := ("TV", "LV","LVmaxMOT");
declare variable $xmlconv:VALID_OBJECTIVETYPE_IDS_33 as xs:string* := ("LV");
declare variable $xmlconv:VALID_ADJUSTMENTTYPE_IDS as xs:string* := ("nsCorrection","wssCorrection");
declare variable $xmlconv:VALID_ADJUSTMENTSOURCE_IDS as xs:string* := ("A1","A2","B","B1","B2","C1","C2","D1","D2","E1","E2","F1","F2","G1","G2","H");
declare variable $xmlconv:VALID_ASSESSMENTTYPE_IDS as xs:string* := ("fixed","model","indicative","objective");
declare variable $xmlconv:VALID_PROTECTIONTARGET_IDS as xs:string* := ("H-S1","H-S2");

declare variable $xmlconv:ADJUSTMENTTYPES as xs:string* := ("http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied","http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplicable", "http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected");

(: Rule implementations :)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $cdrUrl := common:getCdrUrl($countryCode)
let $reportingYear := common:getReportingYear($docRoot)

(: GLOBAL variables needed for all checks :)
let $assessmentRegimeIds := distinct-values(data(sparqlx:executeSparqlQuery(query:getAssessmentRegimeIdsC($cdrUrl))//sparql:binding[@name='inspireLabel']/sparql:literal))
let $assessmentMetadataNamespace := distinct-values(data(sparqlx:executeSparqlQuery(query:getAssessmentMethods())//sparql:binding[@name='assessmentMetadataNamespace']/sparql:literal))
let $assessmentMetadataId := distinct-values(data(sparqlx:executeSparqlQuery(query:getAssessmentMethods())//sparql:binding[@name='assessmentMetadataId']/sparql:literal))
let $assessmentMetadata := distinct-values(data(sparqlx:executeSparqlQuery(query:getAssessmentMethods())//concat(sparql:binding[@name='assessmentMetadataNamespace']/sparql:literal,"/",sparql:binding[@name='assessmentMetadataId']/sparql:literal)))
let $validAssessment :=
    for $x in $docRoot//aqd:AQD_Attainment/aqd:assessment[@xlink:href = $assessmentRegimeIds]
    return $x
let $samplingPointlD :=
    let $results := if (fn:string-length($countryCode) = 2) then sparqlx:executeSparqlQuery(query:getSamplingPoint($cdrUrl)) else ()
    let $values :=
        for $i in $results
        return concat($i/sparql:binding[@name='namespace']/sparql:literal, '/', $i/sparql:binding[@name = 'localId']/sparql:literal)
    return distinct-values($values)
let $isSamplingPointAvailable := count($samplingPointlD) > 0
let $samplingPointAssessmentMetadata :=
    let $results := sparqlx:executeSparqlQuery(query:getSamplingPointAssessmentMetadata())
    return distinct-values(
            for $i in $results
            return concat($i/sparql:binding[@name='metadataNamespace']/sparql:literal,"/", $i/sparql:binding[@name='metadataId']/sparql:literal)
    )

(: G1 :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G2 :)
let $G2table :=
    try {
        let $attainments := distinct-values(data(sparqlx:executeSparqlQuery(query:getInspireLabels($cdrUrl))//sparql:binding[@name='inspireLabel']/sparql:literal))
        for $x in $docRoot//aqd:AQD_Attainment
        let $inspireId := concat(data($x/aqd:inspireId/base:Identifier/base:namespace), "/", data($x/aqd:inspireId/base:Identifier/base:localId))
        where (not($inspireId = $attainments))
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="base:localId">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($x/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="aqd:zone">{common:checkLink(data($x/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($x/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: G3 :)
let $G3table :=
    try {
        let $attainments := distinct-values(data(sparqlx:executeSparqlQuery(query:getInspireLabels($cdrUrl))//sparql:binding[@name = 'inspireLabel']/sparql:literal))
        let $keys := distinct-values(data(sparqlx:executeSparqlQuery(query:getExistingAttainmentSqarql($cdrUrl))//sparql:binding[@name = 'key']/sparql:literal))
        for $attainment in $docRoot//aqd:AQD_Attainment
        let $inspireKey := concat(data($attainment//aqd:inspireId/base:Identifier/base:namespace), "/", data($attainment//aqd:inspireId/base:Identifier/base:localId))
        let $key := concat($inspireKey, "#",
                data($attainment/aqd:pollutant/@xlink:href), "#", data($attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href), "#",
                data($attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href), "#",
                data($attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))
        let $existingRec := not(empty(index-of($attainments, $inspireKey)))
        where ($inspireKey = $attainments and not($key = $keys))
        return
            <tr>
                <td title="gml:id">{data($attainment/@gml:id)}</td>
                <td title="base:localId">{data($attainment/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($attainment/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="aqd:zone">{common:checkLink(data($attainment/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($attainment/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G4 :)
let $G4table :=
    try {
        let $gmlIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(@gml:id))
        let $inspireIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(aqd:inspireId))
        let $uniqueAttainment :=
            for $attainment in $docRoot//aqd:AQD_Attainment
            let $id := $attainment/@gml:id
            let $inspireId := $attainment/aqd:inspireId
            where count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
                    and count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1
            return
                $attainment
        for $rec in $uniqueAttainment
        let $aqdinspireId := concat($rec/aqd:inspireId/base:Identifier/base:localId, "/", $rec/aqd:inspireId/base:Identifier/base:namespace)
        return
            <tr>
                <td title="gml:id">{distinct-values($rec/@gml:id)}</td>
                <td title="aqd:inspireId">{distinct-values($aqdinspireId)}</td>
                <td title="aqd:pollutant">{common:checkLink(distinct-values(data($rec/aqd:pollutant/@xlink:href)))}</td>
                <td title="aqd:objectiveType">{common:checkLink(distinct-values(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)))}</td>
                <td title="aqd:reportingMetric">{common:checkLink(distinct-values(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href)))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(distinct-values(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href)))}</td>
                <td title="aqd:zone">{common:checkLink(distinct-values(data($rec/aqd:zone/@xlink:href)))}</td>
                <td title="aqd:assessment">{common:checkLink(distinct-values(data($rec/aqd:assessment/@xlink:href)))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G5 Compile & feedback a list of the exceedances situations based on the content of ./aqd:zone, ./aqd:pollutant, ./aqd:objectiveType, ./aqd:reportingMetric,
   ./aqd:protectionTarget, aqd:exceedanceDescription_Final/aqd:ExceedanceDescription/aqd:exceedance :)
let $G5table :=
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G6 :)
let $G6table :=
    try {
        for $rec in $docRoot//aqd:AQD_Attainment[aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT"]
        return
            <tr>
                <td title="aqd:zone">{common:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
                <td title="aqd:inspireId">{common:checkLink(data(concat($rec/aqd:inspireId/base:Identifier/base:localId, "/", $rec/aqd:inspireId/base:Identifier/base:namespace)))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:objectiveType">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href))}</td>
                <td title="aqd:reportingMetric">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G7 duplicate @gml:ids and aqd:inspireIds and ef:inspireIds :)
(: Feedback report shall include the gml:id attribute, ef:inspireId, aqd:inspireId, ef:name and/or ompr:name elements as available. :)
let $G7invalid :=
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G8 ./aqd:inspireId/base:Identifier/base:localId shall be an unique code for the attainment records starting with ISO2-country code :)
let $G8invalid :=
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G9 ./ef:inspireId/base:Identifier/base:namespace shall resolve to a unique namespace identifier for the data source (within an annual e-Reporting cycle). :)
let $G9table :=
    try {
        for $id in distinct-values($docRoot//aqd:AQD_Attainment/aqd:inspireId/base:Identifier/base:namespace)
            let $localId := $docRoot//aqd:AQD_Attainment/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G9.1 :)
let $invalidNamespaces :=
    try {
        common:checkNamespaces($source_url)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G10 pollutant codes :)
let $G10invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:AQD_Attainment", "aqd:pollutant", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G11 :)
let $G11invalid :=
    try {
        for $exceedanceDescriptionBase in $docRoot//aqd:AQD_Attainment/aqd:pollutant
        let $pollutantXlinkG11 := fn:substring-after(data($exceedanceDescriptionBase/fn:normalize-space(@xlink:href)), "pollutant/")
        where empty(index-of(('1', '5', '6001', '10'), $pollutantXlinkG11)) and exists($exceedanceDescriptionBase/../aqd:exceedanceDescriptionBase)
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($exceedanceDescriptionBase/../@gml:id)}</td>
                <td title="aqd:pollutant">{data($exceedanceDescriptionBase/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G12 :)
let $G12invalid :=
    try {
        for $exceedanceDescriptionAdjustment in $docRoot//aqd:AQD_Attainment/aqd:pollutant
        let $pollutantXlinkG12 := fn:substring-after(data($exceedanceDescriptionAdjustment/fn:normalize-space(@xlink:href)), "pollutant/")
        where empty(index-of(('1', '5', '6001', '10'), $pollutantXlinkG12)) and (exists($exceedanceDescriptionAdjustment/../aqd:exceedanceDescriptionAdjustment))
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($exceedanceDescriptionAdjustment/../@gml:id)}</td>
                <td title="aqd:pollutant">{data($exceedanceDescriptionAdjustment/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G13 :)
let $G13invalid :=
    try {

        let $inspireLabels := distinct-values(data(sparqlx:executeSparqlQuery(query:getG13($cdrUrl, $reportingYear))//sparql:binding[@name='inspireLabel']/sparql:literal))
        for $x in $docRoot//aqd:AQD_Attainment/aqd:assessment[not(@xlink:href = $inspireLabels)]
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($x/../@gml:id)}</td>
                <td title="aqd:assessment">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: G14 - COUNT number zone-pollutant-target comibantion to match those in dataset B and dataset C for the same reporting Year & compare it with Attainment. :)
let $G14resultBC :=
    for $i in sparqlx:executeSparqlQuery(query:getG14($countryCode))
    where ($i/sparql:binding[@name = "ReportingYear"]/string(sparql:literal) = $reportingYear)
    return
        <result>
            <pollutantName>{string($i/sparql:binding[@name = "Pollutant"]/sparql:literal)}</pollutantName>
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
            aqd:protectionTarget[not(../string(aqd:objectiveType/@xlink:href) = ("http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO", "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO"))]
    let $pollutant := $x/../../../aqd:pollutant/@xlink:href
    let $zone := $x/../../../aqd:zone/@xlink:href
    let $protectiontarget := $x/@xlink:href
    let $key := string-join(($zone, $pollutant, $protectiontarget), "#")
    group by $pollutant
    return
        <result>
            <pollutantName>{dd:getNameFromPollutantCode($pollutant)}</pollutantName>
            <pollutantCode>{tokenize($pollutant, "/")[last()]}</pollutantCode>
            <count>{count(distinct-values($key))}</count>
        </result>
let $G14ResultG := filter:filterByName($G14tmp, "pollutantCode", (
    "1","7","8","9","5", "6001", "10", "20", "5012", "5018", "5014", "5015", "5029"
))

(: G14.1 :)
let $G14.1invalid :=
    try {
        let $all := sparqlx:executeSparqlQuery(query:getAssessmentRegimeIds($cdrUrl))//sparql:binding[@name="inspireLabel"]/sparql:literal/string()
        let $allLocal := data($docRoot//aqd:AQD_Attainment/aqd:assessment/@xlink:href)
        for $x in $all
        where (not($x = $allLocal))
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{$x}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G15 :)
let $G15invalid :=
    try {
        let $resultXml := if (fn:string-length($countryCode) = 2) then query:getZoneLocallD($cdrUrl) else ""
        let $isZoneLocallDCodesAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
        let $zoneLocallD := if($isZoneLocallDCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
        let $isZoneLocallDCodesAvailable := count($resultXml) > 0
        for $x in $docRoot//aqd:AQD_Attainment/aqd:zone
        where $isZoneLocallDCodesAvailable and not($x/@nilReason = "inapplicable") and (empty(index-of($zoneLocallD, $x/fn:normalize-space(@xlink:href))))
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($x/../@gml:id)}</td>
                <td title="aqd:zone">{data($x/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G17 :)
let $G17invalid :=
    try {
        let $zones := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getZoneLocallD($cdrUrl))//sparql:binding[@name='inspireLabel']/sparql:literal)) else ()
        let $pollutants := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getPollutantlD($cdrUrl))//sparql:binding[@name='key']/sparql:literal)) else ()

        for $x in $docRoot//aqd:AQD_Attainment[aqd:zone/@xlink:href]
        let $zone := data($x/aqd:zone/@xlink:href)
        let $pollutant := concat($x/aqd:zone/@xlink:href, '#', $x/aqd:pollutant/@xlink:href)
        where exists($zones) and exists($pollutants) and ($zone = $zones) and not($pollutant = $pollutants)
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: G18 :)
let $G18invalid :=
    try {
        let $localId :=  if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getTimeExtensionExemption($cdrUrl))//sparql:binding[@name='localId']/sparql:literal)) else ""
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href]
        let $objectiveType := data($x/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)
        let $zone := data($x/aqd:zone/@xlink:href)
        where exists($localId) and ($zone = $localId) and ($objectiveType != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")
        return
            <tr>
                <td title="base:localId">{$x/../../../../../aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G19 .//aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of :)
let $G19invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:EnvironmentalObjective", "aqd:objectiveType", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_19)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G20 - ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute shall resolve to one of
... :)
let $G20invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:EnvironmentalObjective", "aqd:reportingMetric",
                $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_20)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: G21 WHERE ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute
EQUALS http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute
EQUALS http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V :)
let $G21invalid :=
    try {
        for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        where
            $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V'
                    and $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL'
        return
            <tr>
                <td title="gml:id">{data($obj/../../@gml:id)}</td>
                <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: 22 :)
let $G22invalid :=
    try {
        for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        let $isInvalid :=
            ($obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H'
                    and $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1'
                    and $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2')
                    and ($obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV')
        where $isInvalid
        return
            <tr>
                <td title="gml:id">{data($obj/../../@gml:id)}</td>
                <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: 23 :)
let $G23invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment
        let $reportingXlink := fn:substring-after(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)), "reportingmetric/")
        where empty(index-of(data($x/aqd:pollutant/fn:normalize-space(@xlink:href)), "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1")) = false() and (empty(index-of(('daysAbove', 'hrsAbove', 'wMean', 'aMean', '3hAbove'), $reportingXlink)))
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: 24 :)
let $G24invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment
        let $reportingXlink := fn:substring-after(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)), "reportingmetric/")
        where empty(index-of(data($x/aqd:pollutant/fn:normalize-space(@xlink:href)), "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5")) = false() and (empty(index-of(('daysAbove', 'aMean'), $reportingXlink)))
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: G25 /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea uom attribute shall be “km2”
let $invalidSurfaceAreas :=
    for $obj in $docRoot//aqd:AQD_Attainment
    let $uom := $obj//aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea/@uom
    where not(empty($uom)) and lower-case(data($uom)) != 'km2'
    return $obj

let $tblInvalidSurfaceAreas :=
   for $rec in $invalidSurfaceAreas
   return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($rec/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea/@uom)}</td>
        </tr> :)

(: G25 :)
let $G25invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment
        let $reportingXlink := fn:substring-after(data($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)), "reportingmetric/")
        where empty(index-of(data($x/aqd:pollutant/fn:normalize-space(@xlink:href)), "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001")) = false() and
                (empty(index-of(('aMean'), $reportingXlink)) and empty(index-of(('AEI'), $reportingXlink)))
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G26 :)
let $G26invalid :=
    try {
        for $aqdReportingMetricG26 in $docRoot//aqd:AQD_Attainment
        let $reportingXlink := fn:substring-after(data($aqdReportingMetricG26/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)), "reportingmetric/")
        where empty(index-of(data($aqdReportingMetricG26/aqd:pollutant/fn:normalize-space(@xlink:href)), "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10")) = false() and (empty(index-of(('daysAbove'), $reportingXlink)))
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($aqdReportingMetricG26/@gml:id)}</td>
                <td title="aqd:pollutant">{data($aqdReportingMetricG26/aqd:pollutant/fn:normalize-space(@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G27 :)
let $G27invalid :=
    try {
        for $aqdReportingMetricG27 in $docRoot//aqd:AQD_Attainment
        let $reportingXlink := fn:substring-after(data($aqdReportingMetricG27/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/fn:normalize-space(@xlink:href)), "protectiontarget/")
        where (empty(index-of("V", $reportingXlink)) = false()) and ($aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"
                or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"
                or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"
                or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8"
                or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20"
                or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012"
                or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014"
                or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015"
                or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018"
                or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029")
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($aqdReportingMetricG27/@gml:id)}</td>
                <td title="aqd:pollutant">{data($aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G28  :)
let $G28invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:EnvironmentalObjective", "aqd:objectiveType", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_28)
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G29 :)
let $G29invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:EnvironmentalObjective", "aqd:reportingMetric", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_29)
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: 30 :)
let $G30invalid :=
    try {
        for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        where
            $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V'
                    and $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL'
        return
            <tr>
                <td title="gml:id">{data($obj/../../@gml:id)}</td>
                <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: G31 :)
let $G31invalid :=
    try {
        for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        let $isInvalid :=
            $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V'
                    and ($obj/aqd:reportingMetric/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c'
                    or $obj/aqd:reportingMetric/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5y')
        where $isInvalid
        return
            <tr>
                <td title="gml:id">{data($obj/../../@gml:id)}</td>
                <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
                <td title="aqd:reportingMetric">{data($obj/aqd:reportingMetric/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G32 :)
let $G32invalid :=
    try {
        for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        let $isInvalid :=
            $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H'
                    and $obj/../../aqd:pollutant/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001'
                    and $obj/../../aqd:pollutant/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7'
                    and ($obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV'
                    or $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV'
                    or $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT')
        where $isInvalid
        return
            <tr>
                <td title="gml:id">{data($obj/../../@gml:id)}</td>
                <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: G33 :)
let $G33invalid :=
    try {
        for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
        let $isInvalid :=
            $obj/aqd:objectiveType/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV'
                    and $obj/../../aqd:pollutant/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001'
                    and $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1'
                    and $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2'
                    and $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H'
        where $isInvalid
        return
            <tr>
                <td title="gml:id">{data($obj/../../@gml:id)}</td>
                <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G38 :)
let $G38invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionBase", "aqd:ExceedanceArea", "aqd:areaClassification",  $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G39 :)
let $G39invalid :=
    try {
        let $modelCdrUrl := if ($countryCode = 'gi') then common:getCdrUrl('gb') else $cdrUrl
        let $modelLocallD := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getModel($modelCdrUrl))//concat(sparql:binding[@name='namespace']/sparql:literal,"/",sparql:binding[@name='localId']/sparql:literal))) else ()

        for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
        where exists($modelLocallD) and (empty(index-of($modelLocallD, $x/fn:normalize-space(@xlink:href))))
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($x/../../../../../@gml:id)}</td>
                <td title="aqd:AQD_Model">{data($x/fn:normalize-space(@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr status="failed">
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G41 - :)
let $G41invalid :=
    try {
        for $r in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed[not(@xlink:href = $samplingPointlD)]
        where $isSamplingPointAvailable
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:SamplingPoint">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr status="failed">
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
        <tr status="failed">
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
        <tr status="failed">
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
        where ($numerical = "") and not($numbers castable as xs:integer)
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        where ($numerical = "") and not($numbers castable as xs:integer)
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G52 :)
let $G52invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:ExceedanceArea", "aqd:areaClassification",  $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G53 :)
let $G53invalid :=
    try {
        let $model := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getModel($cdrUrl))//concat(sparql:binding[@name='namespace']/sparql:literal,"/",sparql:binding[@name='localId']/sparql:literal))) else ()
        let $isModelAvailable := count($model) > 0

        for $r in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed[not(@xlink:href = $model)]
        where $isModelAvailable
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:Model">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G55 :)
let $G55invalid :=
    try {
        for $r in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed[not(@xlink:href = $samplingPointlD)]
        where $isSamplingPointAvailable
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:SamplingPoint">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        <tr status="failed">
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
        <tr status="failed">
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G59 - If ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance is TRUE EITHER ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)
let $G59invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance = "true"]
            let $numerical := string($x/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numericalExceedance)
            let $numbers := string($x/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numberExceedances)
        where ($numerical = "") and not($numbers castable as xs:integer)
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G60 - If ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance is FALSE EITHER ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numericalExceedance
OR ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numberExceedances must be provided AS an integer number :)
let $G60invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedance = "false"]
            let $numerical := string($x/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numericalExceedance)
            let $numbers := string($x/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:numberExceedances)
        where ($numerical = "") and not($numbers castable as xs:integer)
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G61 :)
let $G61invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentType", $vocabulary:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G62 - :)
let $G62invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentSource", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTSOURCE_IDS)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G63 :)
let $G63invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:AssessmentMethods", "aqd:assessmentType", $vocabulary:ASSESSMENTTYPE_VOCABULARY, $xmlconv:VALID_ASSESSMENTTYPE_IDS)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G64 :)
let $G64invalid :=
    try {
        let $model := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getModel($cdrUrl))//concat(sparql:binding[@name='namespace']/sparql:literal,"/",sparql:binding[@name='localId']/sparql:literal))) else ()
        let $isModelAvailable := count($model) > 0

        for $r in xmlconv:getValidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentType", $vocabulary:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)
        let $root := $r/../../../../. (: aqd:AQD_Attainment :)
        let $meta := $root/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:modelAssessmentMetadata
        where ((empty(index-of($model, $meta/fn:normalize-space(@xlink:href))))) and $isModelAvailable and string-length($meta/fn:normalize-space(@xlink:href))
        return
            <tr>
                <td title="gml:id">{data($root/@gml:id)}</td>
                <td title="aqd:modelAssessmentMetadata">{data($meta/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: G65 :)
let $G65invalid :=
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G66 :)
let $G66invalid :=
    try {
        for $r in xmlconv:getValidDDConceptLimited($source_url, "aqd:exceedanceDescriG66ptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentType", $vocabulary:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)
        let $root := $r/../../../../. (: aqd:AQD_Attainment :)
        let $meta := $root//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata
        where (empty(index-of($samplingPointlD, $meta/fn:normalize-space(@xlink:href)))) and $isSamplingPointAvailable and string-length($meta/fn:normalize-space(@xlink:href))
        return
            <tr>
                <td title="gml:id">{data($root/@gml:id)}</td>
                <td title="aqd:modelAssessmentMetadata">{data($meta/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G67 - :)
let $G67invalid :=
    try {
        for $r in $validAssessment/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata[not(@xlink:href = $samplingPointAssessmentMetadata)]
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:assessment">{data($r/../../../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                <td title="aqd:samplingPointAssessmentMetadata">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        <tr status="failed">
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G72 :)
let $G72invalid :=
    try {
        xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionFinal", "aqd:ExceedanceArea",  "aqd:areaClassification",  $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G73 :)
let $G73invalid :=
    try {
        let $modelCdrUrl := if ($countryCode = 'gi') then common:getCdrUrl('gb') else $cdrUrl
        let $modelLocallD := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getModel($modelCdrUrl))//concat(sparql:binding[@name='namespace']/sparql:literal,"/",sparql:binding[@name='localId']/sparql:literal))) else ()

        for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
        where exists($modelLocallD) and (empty(index-of($modelLocallD, $x/fn:normalize-space(@xlink:href))))
        return
            <tr>
                <td title="Feature type">{"aqd:AQD_Attainment"}</td>
                <td title="gml:id">{data($x/../../../../../@gml:id)}</td>
                <td title="aqd:AQD_Model">{data($x/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: G75 :)
let $G75invalid  :=
    try {
        for $r in $docRoot//aqd:AQD_Attainment//aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed
        where exists($samplingPointlD) and (empty(index-of($samplingPointlD, $r/fn:normalize-space(@xlink:href))))
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                <td title="aqd:stationUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        <tr status="failed">
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
        <tr status="failed">
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
        where ($numerical = "") and not($numbers castable as xs:integer)
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        where ($numerical = "") and not($numbers castable as xs:integer)
        return
            <tr>
                <td title="base:localId">{$x/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: G82 - :)
let $G82invalid :=
    try {
        for $r in $docRoot//aqd:AQD_Attainment//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType[@xlink:href = $xmlconv:ADJUSTMENTTYPES]
        return
            <tr>
                <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                <td title="gml:id">{data($r/fn:normalize-space(@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: G86 :)
let $G86invalid :=
    try {
        let $stations := sparqlx:executeSparqlQuery(query:getG86Stations($cdrUrl))/sparql:binding[@name="inspireLabel"]/sparql:literal/string()
        let $models := sparqlx:executeSparqlQuery(query:getG86Models($cdrUrl))/sparql:binding[@name="inspireLabel"]/sparql:literal/string()
        for $x in $docRoot//aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea[aqd:stationUsed/@xlink:href or aqd:modelUsed/@xlink:href]
        let $stationErrors :=
            for $i in data($x/aqd:stationUsed/@xlink:href)
            where (not($i = $stations))
            return 1
        let $modelErrors :=
            for $i in data($x/aqd:modelUsed/@xlink:href)
            where (not($i = $models))
            return 1
        where (count($stationErrors) >0 or count($modelErrors) >0)
        return
            <tr>
                <td title="base:localId">{string($x/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:stationUsed">{data($x/aqd:stationUsed/@xlink:href)}</td>
                <td title="aqd:modelUsed">{data($x/aqd:modelUsed/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

return
    <table class="maintable hover">
        {html:buildResultRows("G1", $labels:G1, $labels:G1_SHORT, $tblAllAttainments, "", string($countAttainments), "", "",$errors:ERROR)}
        {html:buildResultRows("G2", $labels:G2, $labels:G2_SHORT, $G2table, "", string(count($G2table)), "", "",$errors:ERROR)}
        {html:buildResultRows("G3", $labels:G3, $labels:G3_SHORT, $G3table, "", string(count($G3table)), "", "",$errors:ERROR)}
        {html:buildResultRows("G4", $labels:G4, $labels:G4_SHORT, $G4table, "", string(count($G4table)), " ", "",$errors:ERROR)}
        {html:buildResultRows("G5", $labels:G5, $labels:G5_SHORT, $G5table, "", string(count($G5table)), " exceedance", "", $errors:ERROR)}
        {html:buildResultRows("G6", $labels:G6, $labels:G6_SHORT, $G6table, "", string(count($G6table)), " attainment", "",$errors:ERROR)}
        {html:buildResultRows("G7", $labels:G7, $labels:G7_SHORT, $G7invalid, "", "No duplicates found", " duplicate", "", $errors:ERROR)}
        {html:buildResultRows("G8", $labels:G8, $labels:G8_SHORT, $G8invalid, "base:localId", "No duplicate values found", " duplicate value", "",$errors:ERROR)}
        {html:buildResultRows("G9", $labels:G9, $labels:G9_SHORT, $G9table, "", string(count($G9table)), "", "", $errors:INFO)}
        {html:buildResultRows("G9.1", $labels:G9.1, $labels:G9.1_SHORT, $invalidNamespaces, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G10", <span>The content of /aqd:AQD_Attainment/aqd:pollutant xlink:xref shall resolve to a pollutant in
            <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G10", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS)}
            </span>, $labels:PLACEHOLDER, $G10invalid, "aqd:pollutant", "", "", "", $errors:ERROR)}
        {html:buildResultRows("G11", <span>WHERE ./aqd:pollutant xlink:href attribute EQUALs  <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G11", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_11)} ./aqd:exceedanceDescriptionBase may occur</span>, $labels:PLACEHOLDER,
            $G11invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G12", <span>WHERE ./aqd:pollutant xlink:href attribute EQUALs  <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G12", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_11)} ./aqd:exceedanceDescriptionAdjustment may occur</span>, $labels:PLACEHOLDER,
                $G12invalid, "base:namespace", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:buildResultRows("G13", $labels:G13, $labels:G13_SHORT, $G13invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultG14("G14", $labels:G14, $labels:G14_SHORT, $G14resultBC, $G14ResultG)}
        {html:build2("G14.1", $labels:G14.1, $labels:G14.1_SHORT, $G14.1invalid, "", "All assessment regimes are reported", " missing assessment regime", "", $errors:WARNING)}
        {html:buildResultRows("G15", $labels:G15, $labels:G15_SHORT, $G15invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G17", $labels:G17, $labels:G17_SHORT, $G17invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G18", $labels:G18, $labels:G18_SHORT, $G18invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G19", <span>./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of
            <a href="{ $vocabulary:OBJECTIVETYPE_VOCABULARY }">{ $vocabulary:OBJECTIVETYPE_VOCABULARY }</a>
            Allowed items: {xmlconv:buildVocItemsList("G19", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_19)}</span>, $labels:PLACEHOLDER, $G19invalid, "aqd:objectivetype", "", "", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G20", <span>The content of ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G20", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_20)}</span>, $labels:PLACEHOLDER, $G20invalid, "aqd:reportingMetric", "", "", "",$errors:ERROR)}
        {html:buildResultRows("G21", $labels:G21, $labels:G21_SHORT, $G21invalid, "", "No invalid objective types for Vegetation found", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G22", $labels:G22, $labels:G22_SHORT, $G22invalid, "", "No invalid objective types for Health found", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G23", <span>WHERE ./aqd:pollutant xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1 ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G23", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_23)}</span>, $labels:PLACEHOLDER,
                $G23invalid, "aqd:reportingMetric", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G24", <span>WHERE ./aqd:pollutant xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5 ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one ofS
            {xmlconv:buildVocItemsList("G24", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_24)}</span>, $labels:PLACEHOLDER,
                $G24invalid, "aqd:reportingMetric", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G25", <span>WHERE ./aqd:pollutant xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G25", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_25)}</span>, $labels:PLACEHOLDER,
                $G25invalid, "aqd:reportingMetric", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G26", <span>WHERE ./aqd:pollutant xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10 ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G26", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_26)}</span>, $labels:PLACEHOLDER,
                $G26invalid, "aqd:reportingMetric", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G27", <span>./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute shall NOT EQUAL http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V and
            <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G27", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_27)}</span>, $labels:PLACEHOLDER,
                $G27invalid, "aqd:reportingMetric", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G28", <span>./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of
            <a href="{ $vocabulary:OBJECTIVETYPE_VOCABULARY }">{ $vocabulary:OBJECTIVETYPE_VOCABULARY }</a>
            Allowed items: {xmlconv:buildVocItemsList("G28", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_28)}</span>, $labels:PLACEHOLDER, $G28invalid, "aqd:objectivetype", "", "", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G29", <span>The content of ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G29", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_29)}</span>, $labels:PLACEHOLDER, $G29invalid, "aqd:reportingMetric", "", "", "",$errors:ERROR)}
        {html:buildResultRows("G30", $labels:G30, $labels:G30_SHORT, $G30invalid, "", "No invalid objective types for Vegetation found", " invalid", "",$errors:ERROR)}
        {html:buildResultRows("G31", <span>The content of ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute shall EQUAL
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V and /aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute on shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
        {xmlconv:buildVocItemsList("G31", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_31)}</span>, $labels:PLACEHOLDER,
                $G31invalid, "aqd:reportingMetric", "", "", "",$errors:ERROR)}
        {html:buildResultRows("G32", <span>The content of ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute shall EQUAL
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H AND /aqd:polluntant is NOT EQUAL to
            http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 where ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType  xlink:href attribute on shall resolve to a valid concept in
            <a href="{ $vocabulary:OBJECTIVETYPE_VOCABULARY }">{ $vocabulary:OBJECTIVETYPE_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G32", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_32)}</span>, $labels:PLACEHOLDER,
                $G32invalid, "aqd:reportingMetric",  "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G33", <span>./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/xlink:href  attribute   EQUALS
                http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
                and the content of ./aqd:pollutant is EQUAL to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001
            ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute EQUALS
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H

            </span>, $labels:PLACEHOLDER,
                $G33invalid, "aqd:reportingMetric", "All values are valid", " invalid value", "",$errors:ERROR)}

        {html:buildResultRowsWithTotalCount_G("G38", <span>The content of /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:areaClassification xlink:xref shall resolve to a areaClassification in
            <a href="{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}">{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G38", $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)}
        </span>, $labels:PLACEHOLDER, $G38invalid, "aqd:areaClassification", "", "", "",$errors:ERROR)}
        {html:buildResultRows("G39", $labels:G39, $labels:G39_SHORT, $G39invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G40", $labels:G40, $labels:G40_SHORT, $G40invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G41", $labels:G41, $labels:G41_SHORT, $G41invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G42", $labels:G42, $labels:G42_SHORT, $G42invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:build2("G44", $labels:G44, $labels:G44_SHORT, $G44invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G45", $labels:G45, $labels:G45_SHORT, $G45invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G46", $labels:G46, $labels:G46_SHORT, $G46invalid, "", "All values are valid", " invalid value", "", $errors:WARNING)}
        {html:buildResultRows("G47", $labels:G47, $labels:G47_SHORT, $G47invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G52", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:areaClassification xlink:xref shall resolve to a areaClassification in
            <a href="{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}">{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G52", $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)}
        </span>, $labels:PLACEHOLDER, $G52invalid, "aqd:areaClassification", "", "", "", $errors:ERROR)}
        {html:buildResultRows("G53", $labels:G53, $labels:G53_SHORT, $G53invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G54", $labels:G54, $labels:G54_SHORT, $G54invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G55", $labels:G55, $labels:G55_SHORT, $G55invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G56", $labels:G56, $labels:G56_SHORT, $G56invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:build2("G58", $labels:G58, $labels:G58_SHORT, $G58invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G59", $labels:G59, $labels:G59_SHORT, $G59invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G60", $labels:G60, $labels:G60_SHORT, $G60invalid, "", "All values are valid", " invalid value", "", $errors:WARNING)}
        {html:buildResultRowsWithTotalCount_G("G61", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType xlink:xref shall resolve to a adjustmentType in
            <a href="{ $vocabulary:ADJUSTMENTTYPE_VOCABULARY}">{ $vocabulary:ADJUSTMENTTYPE_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G61", $vocabulary:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)}
        </span>, $labels:PLACEHOLDER, $G61invalid, "aqd:areaClassification", "", "", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G62", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmenSource xlink:xref shall resolve to a adjustmenSource in
            <a href="{ $vocabulary:ADJUSTMENTSOURCE_VOCABULARY}">{ $vocabulary:ADJUSTMENTSOURCE_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G62", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTSOURCE_IDS)}
        </span>, $labels:PLACEHOLDER, $G62invalid, "aqd:areaClassification", "", "", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G63", <span>The content of ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentType shall resolve to
            <a href="{  $vocabulary:ASSESSMENTTYPE_VOCABULARY}">{  $vocabulary:ASSESSMENTTYPE_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G63",  $vocabulary:ASSESSMENTTYPE_VOCABULARY, $xmlconv:VALID_ASSESSMENTTYPE_IDS)}
        </span>, $labels:PLACEHOLDER, $G63invalid, "aqd:areaClassification", "", "", "",$errors:ERROR)}
        {html:buildResultRows("G64", $labels:G64, $labels:G64_SHORT, $G64invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G65", $labels:G65, $labels:G65_SHORT, $G65invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G66", $labels:G66, $labels:G66_SHORT, $G66invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G67", $labels:G67, $labels:G67_SHORT, $G67invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G70", $labels:G70, $labels:G70_SHORT, $G70invalid, "base:namespace", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:buildResultRows("G71", $labels:G71, $labels:G71_SHORT, $G71invalid, "base:namespace", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G72", <span>The content of /aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification  xlink:xref shall resolve to a areaClassification in
            <a href="{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}">{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G72", $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)}
        </span>, $labels:PLACEHOLDER, $G72invalid, "aqd:areaClassification", "", "", "",$errors:ERROR)}
        {html:buildResultRows("G73", $labels:G73, $labels:G73_SHORT, $G73invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G74", $labels:G74, $labels:G74_SHORT, $modelUsed_74, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G75", $labels:G75, $labels:G75_SHORT, $G75invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("G76", $labels:G76, $labels:G76_SHORT, $G76invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:build2("G78", $labels:G78, $labels:G78_SHORT, $G78invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G79", $labels:G79, $labels:G79_SHORT, $G79invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G80", $labels:G80, $labels:G80_SHORT, $G80invalid, "", "All values are valid", " invalid value", "", $errors:WARNING)}
        {html:buildResultRows("G81", $labels:G81, $labels:G81_SHORT, $G81invalid, "base:namespace", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:build2("G85", $labels:G85, $labels:G85_SHORT, $G85invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G86", $labels:G86, $labels:G86_SHORT, $G86invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {$G82invalid}
    </table>
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*)
as element(tr)*{
    xmlconv:checkVocabularyConceptValues($source_url, $parentObject, $featureType, $element, $vocabularyUrl, $limitedIds, "")
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $parentObject, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string) as element(tr)* {
    xmlconv:checkVocabularyConceptValues($source_url, $parentObject, $featureType, $element, $vocabularyUrl, (), "")
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*, $vocabularyType as xs:string)
as element(tr)*{

    let $sparql :=
        if ($vocabularyType = "collection") then
            xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
        else
            xmlconv:getConceptUrlSparql($vocabularyUrl)
    let $crConcepts := sparqlx:executeSimpleSparqlQuery($sparql)

    let $allRecords :=
    if ($parentObject != "") then
        doc($source_url)//gml:featureMember/descendant::*[name()=$parentObject]/descendant::*[name()=$featureType]
    else
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

    for $rec in $allRecords
    for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href
    let $conceptUrl := normalize-space($conceptUrl)

    where string-length($conceptUrl) > 0

    return
        <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) and xmlconv:isValidLimitedValue($conceptUrl, $vocabularyUrl, $limitedIds) }">
            <td title="Feature type">{ $featureType }</td>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="base:localId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
            <td title="aqd:name">{data($rec/aqd:name)}</td>
            <td title="{ $element }" style="color:red">{$conceptUrl}</td>
        </tr>

};
declare function xmlconv:getCheckedVocabularyConceptValues($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*)
{
     xmlconv:getCheckedVocabularyConceptValues($source_url, $parentObject, $featureType, $element, $vocabularyUrl, $limitedIds, "")
};



declare function xmlconv:getCheckedVocabularyConceptValues($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*, $vocabularyType as xs:string)
{

    let $sparql :=
        if ($vocabularyType = "collection") then
            xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
        else
            xmlconv:getConceptUrlSparql($vocabularyUrl)
    let $crConcepts := sparqlx:executeSimpleSparqlQuery($sparql)

    let $allRecords :=
        if ($parentObject != "") then
            doc($source_url)//gml:featureMember/descendant::*[name()=$parentObject]/descendant::*[name()=$featureType]
        else
            doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

    for $rec in $allRecords
    for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href
    let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0
    return
        $rec


};

declare function xmlconv:getValidDDConceptLimited($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $allowedIds as xs:string*) {
    xmlconv:getCheckedVocabularyConceptValues($source_url, $parentObject, $featureType, $element, $vocabularyUrl, $allowedIds)
};

declare function xmlconv:isValidLimitedValue($conceptUrl as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*) as xs:boolean {
    let $limitedUrls :=
        for $id in $limitedIds
        return concat($vocabularyUrl, $id)

    return
        empty($limitedIds) or not(empty(index-of($limitedUrls, $conceptUrl)))
};

declare function xmlconv:getConceptUrlSparql($scheme as xs:string) as xs:string {
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label
    WHERE {
      ?concepturl skos:inScheme <", $scheme, ">;
                  skos:prefLabel ?label
    }")
};

declare function xmlconv:getCollectionConceptUrlSparql($collection as xs:string) as xs:string {
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl
    WHERE {
        GRAPH <", $collection, "> {
            <", $collection, "> skos:member ?concepturl .
            ?concepturl a skos:Concept
        }
    }")
};

declare function xmlconv:isMatchingVocabCode($crConcepts as element(sparql:results), $concept as xs:string) as xs:boolean {
    count($crConcepts//sparql:result/sparql:binding[@name="concepturl" and sparql:uri=$concept]) > 0
};


declare function xmlconv:isinvalidDDConceptLimited($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $allowedIds as xs:string*)
as element(tr)* {
    xmlconv:checkVocabularyConceptValues($source_url, $parentObject, $featureType, $element, $vocabularyUrl, $allowedIds)
};

declare function xmlconv:buildVocItemsList($ruleId as xs:string, $vocabularyUrl as xs:string, $ids as xs:string*)
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
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countZones := count(doc($source_url)//aqd:AQD_Attainment)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url, $countryCode) else ()

return
    <div>
        <h2>Check air quality attainment of environmental objectives  - Dataflow G</h2>
        {
        if ( $countZones = 0) then
            <p>No aqd:AQD_Attainment elements found from this XML.</p>
        else
        <div>
            {
                if ($result//div/@class = 'error') then
                    <p class="error" style="color:red"><strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[@class='error'], ',')}</strong></p>
                else
                    <p>This XML file passed all crucial checks.</p>
            }
            {
                if ($result//div/@class = 'warning') then
                    <p class="warning" style="color:orange"><strong>This XML file generated warnings during the following check(s): {string-join($result//div[@class = 'warning'], ',')}</strong></p>
                else
                    ()
            }
            <p>This check evaluated the delivery by executing the tier-1 tests on air quality assessment regimes data in Dataflow G as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
            <div><a id='legendLink' href="javascript: showLegend()" style="padding-left:10px;">How to read the test results?</a></div>
            <fieldset style="font-size: 90%; display:none" id="legend">
                <legend>How to read the test results</legend>
                All test results are labeled with coloured bullets. The number in the bullet reffers to the rule code. The background colour of the bullets means:
                <ul style="list-style-type: none;">
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Blue', 'info')}</div> - the data confirms to the rule, but additional feedback could be provided in QA result.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Red', 'error')}</div> - the crucial check did NOT pass and errenous records found from the delivery.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Orange', 'warning')}</div> - the non-crucial check did NOT pass.</li>
                    <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Grey', 'skipped')}</div> - the check was skipped due to no relevant values found to check.</li>
                </ul>
                <p>Click on the "Show records" link to see more details about the test result.</p>
            </fieldset>
            <h3>Test results</h3>
            {$result}
        </div>
        }
    </div>

};