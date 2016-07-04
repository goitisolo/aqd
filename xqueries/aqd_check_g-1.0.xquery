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
(:===================================================================:)
(: Variable given as an external parameter by the QA service         :)
(:===================================================================:)
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

(: G1 :)
let $countAttainments := count($docRoot//aqd:AQD_Attainment)
let $tblAllAttainments :=
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

(: G2 :)
let $attainmentsInDelivery := $docRoot//aqd:AQD_Attainment
let $inspireSparql := query:getInspireLabels($cdrUrl)
let $isCRAvailable := string-length($inspireSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($inspireSparql, "xml"))

let $attainmentsInCR := if ($isCRAvailable) then
    distinct-values(data(sparqlx:executeSparqlQuery($inspireSparql)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ()

let $newAttainments :=
for $attainment in $attainmentsInDelivery
let $inspireId := concat(data($attainment/aqd:inspireId/base:Identifier/base:namespace), "/", data($attainment/aqd:inspireId/base:Identifier/base:localId))
return
    if (empty(index-of($attainmentsInCR, $inspireId))) then
        <tr>
            <td title="gml:id">{data($attainment/@gml:id)}</td>
            <td title="base:localId">{data($attainment/aqd:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($attainment/aqd:inspireId/base:Identifier/base:namespace)}</td>
            <td title="aqd:zone">{common:checkLink(data($attainment/aqd:zone/@xlink:href))}</td>
            <td title="aqd:pollutant">{common:checkLink(data($attainment/aqd:pollutant/@xlink:href))}</td>
            <td title="aqd:protectionTarget">{common:checkLink(data($attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
        </tr>
    else ()


(: G3 :)
let $existingAttainmentSparql := query:getExistingAttainmentSqarql($cdrUrl)
let $isCRAvailable := string-length($existingAttainmentSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($existingAttainmentSparql, "xml"))

let $attainmentsKeysInCR := if($isCRAvailable) then
    distinct-values(data(sparqlx:executeSparqlQuery($existingAttainmentSparql)//sparql:binding[@name='key']/sparql:literal))  else ()


let $changedAttainments :=
for $attainment in $attainmentsInDelivery
    let $inspireKey := concat(data($attainment//aqd:inspireId/base:Identifier/base:namespace), "/", data($attainment//aqd:inspireId/base:Identifier/base:localId))
    let $key := concat($inspireKey, "#",
        data($attainment/aqd:pollutant/@xlink:href), "#", data($attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href), "#",
        data($attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href), "#",
        data($attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))

        let $existingRec := not(empty(index-of($attainmentsInCR, $inspireKey)))
    return
    if ($existingRec = true() and empty(index-of($attainmentsKeysInCR, $key))) then
        <tr>
            <td title="gml:id">{data($attainment/@gml:id)}</td>
            <td title="base:localId">{data($attainment/aqd:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($attainment/aqd:inspireId/base:Identifier/base:namespace)}</td>
            <td title="aqd:zone">{common:checkLink(data($attainment/aqd:zone/@xlink:href))}</td>
            <td title="aqd:pollutant">{common:checkLink(data($attainment/aqd:pollutant/@xlink:href))}</td>
            <td title="aqd:protectionTarget">{common:checkLink(data($attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
        </tr>

    else
        ()

(: G4 :)
let $gmlIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(@gml:id))
let $inspireIds := $docRoot//aqd:AQD_Attainment/lower-case(normalize-space(aqd:inspireId))
let $pollutant := $docRoot//aqd:AQD_Attainment/aqd:pollutant/lower-case(normalize-space(@xlink:href))
let $objectiveType := $docRoot//aqd:AQD_Attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/lower-case(normalize-space(@xlink:href))
let $reportingMetric := $docRoot//aqd:AQD_Attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/lower-case(normalize-space(@xlink:href))
let $protectionTarget := $docRoot//aqd:AQD_Attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/lower-case(normalize-space(@xlink:href))
let $zone := $docRoot//aqd:AQD_Attaiment/aqd:zone/lower-case(normalize-space(@xlink:href))
let $assessment := $docRoot//aqd:AQD_Attaiment/aqd:assessment/lower-case(normalize-space(@xlink:href))

let $uniqueAttainment :=
    for $attainment in $docRoot//aqd:AQD_Attainment
    let $id := $attainment/@gml:id
    let $inspireId := $attainment/aqd:inspireId
    (:)let $pollutantId := $attainment/aqd:pollutant/@xlink:href
    let $objectiveTypeId := $attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href
    let $reportingMetricId := $attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href
    let $protectionTargetId := $attainment/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href
    let $zoneId := $attainment/aqd:zone/@xlink:href
    let $assessmentId := $attainment/aqd:assessment/@xlink:href:)

    where count(index-of($gmlIds, lower-case(normalize-space($id)))) = 1
            and count(index-of($inspireIds, lower-case(normalize-space($inspireId)))) = 1
            (:) and count(index-of($pollutant, lower-case(normalize-space($pollutantId)))) = 1
            and count(index-of($pollutant, lower-case(normalize-space($pollutantId)))) = 1
            and count(index-of($objectiveType, lower-case(normalize-space($objectiveTypeId)))) = 1
            and count(index-of($reportingMetric, lower-case(normalize-space($reportingMetricId)))) = 1
            and count(index-of($protectionTarget, lower-case(normalize-space($protectionTargetId)))) = 1
            and count(index-of($zone, lower-case(normalize-space($zoneId)))) = 1
            and count(index-of($assessment, lower-case(normalize-space($assessmentId)))) = 1:)
    return
        $attainment

let $tblAllAttainmentsG4 :=
    for $rec in $uniqueAttainment
    let $aqdinspireId := concat($rec/aqd:inspireId/base:Identifier/base:localId,"/",$rec/aqd:inspireId/base:Identifier/base:namespace)
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

(: G5 Compile & feedback a list of the exceedances situations based on the content of
 ./aqd:zone, ./aqd:pollutant, ./aqd:objectiveType, ./aqd:reportingMetric, ./aqd:protectionTarget, aqd:exceedanceDescription_Final/aqd:ExceedanceDescription/aqd:exceedance :)
(:
let $countExceedances := count($docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance = "true"])
:)
let $allExceedances :=
    for $attainment in $docRoot//aqd:AQD_Attainment    
    where (data($attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedance) = "true")        
    return
        $attainment

let $tblAllExceedances :=
    for $rec in $allExceedances
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

(: G6 :)
(:
let $resultXml := if (fn:string-length($countryCode) = 2) then xmlconv:getAqdZone($cdrUrl) else ""
let $isAqdZoneCodesAvailable := string-length($resultXml) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($resultXml, "xml"))
let $localId := if($isAqdZoneCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='localId']/sparql:literal))  else ""
let $timeExtensionExemption := if($isAqdZoneCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='timeExtensionExemption']/sparql:uri)) else ""
let $isAqdZoneCodesAvailable := count($resultXml) > 0

let $aqdObjectiveType :=
   for $x in $docRoot//aqd:AQD_Attainment
    let $href := if (xmlconv:isMissingOrEmpty($x/aqd:zone/@xlink:href)) then "" else data($x/aqd:zone/@xlink:href)
    where $isAqdZoneCodesAvailable and $href != "" and not(empty($localId)) and empty(index-of($localId, $href)) = false()
    return if ($x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")  then  $x else ()
:)

let $tblG6 :=
    for $rec in $docRoot//aqd:AQD_Attainment
    where normalize-space(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href)) = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT"
    return
        <tr>
            <td title="aqd:zone">{common:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
            <td title="aqd:inspireId">{common:checkLink(data(concat($rec/aqd:inspireId/base:Identifier/base:localId,"/",$rec/aqd:inspireId/base:Identifier/base:namespace)))}</td>
            <td title="aqd:pollutant">{common:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
            <td title="aqd:objectiveType">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href))}</td>
            <td title="aqd:reportingMetric">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href))}</td>
            <td title="aqd:protectionTarget">{common:checkLink(data($rec/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
        </tr>

(: G7 duplicate @gml:ids and aqd:inspireIds and ef:inspireIds :)
(: Feedback report shall include the gml:id attribute, ef:inspireId, aqd:inspireId, ef:name and/or ompr:name elements as available. :)
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

let $tblDuplicateGmlIds :=
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

(: G8 ./aqd:inspireId/base:Identifier/base:localId shall be an unique code for the attainment records starting with ISO2-country code :)

let $localIds :=  $docRoot//aqd:AQD_Attainment/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))

let $invalidDuplicateLocalIds :=
    for $rec in $docRoot//aqd:AQD_Attainment/aqd:inspireId/base:Identifier
    let $id := $rec/lower-case(normalize-space(base:localId))
    where (count(index-of($localIds, lower-case(normalize-space($id)))) > 1 and not(empty($id)))
    return
        <tr>
            <td title="gml:id">{data($rec/../../@gml:id)}</td>
            <td title="base:localId">{data($rec/base:localId)}</td>
            <td title="base:namespace">{data($rec/base:namespace)}</td>
        </tr>


(: G9 ./ef:inspireId/base:Identifier/base:namespace shall resolve to a unique namespace identifier for the data source (within an annual e-Reporting cycle). :)
let $tblG9 :=
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
let $invalidPollutantCodes := xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:AQD_Attainment", "aqd:pollutant",  $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS)

(: G11 :)
let $invalidExceedanceDescriptionBase :=
        for $exceedanceDescriptionBase in $docRoot//aqd:AQD_Attainment/aqd:pollutant
        let $pollutantXlinkG11:= fn:substring-after(data($exceedanceDescriptionBase/fn:normalize-space(@xlink:href)),"pollutant/")
        where empty(index-of(('1','5','6001','10'),$pollutantXlinkG11))
        return if (not(exists($exceedanceDescriptionBase/../aqd:exceedanceDescriptionBase)))
        then () else
            <tr>
                <td title="Feature type">{ "aqd:AQD_Attainment" }</td>
                <td title="gml:id">{data($exceedanceDescriptionBase/../@gml:id)}</td>
                <td title="aqd:pollutant">{data($exceedanceDescriptionBase/fn:normalize-space(@xlink:href))}</td>
            </tr>

(: G12 :)
let $invalidExceedanceDescriptionAdjustment:=
    for $exceedanceDescriptionAdjustment in $docRoot//aqd:AQD_Attainment/aqd:pollutant
    let $pollutantXlinkG12:= fn:substring-after(data($exceedanceDescriptionAdjustment/fn:normalize-space(@xlink:href)),"pollutant/")
    where empty(index-of(('1','5','6001','10'),$pollutantXlinkG12))
    return if (not(exists($exceedanceDescriptionAdjustment/../aqd:exceedanceDescriptionAdjustment)))
    then () else
     <tr>
        <td title="Feature type">{ "aqd:AQD_Attainment" }</td>
        <td title="gml:id">{data($exceedanceDescriptionAdjustment/../@gml:id)}</td>
        <td title="aqd:pollutant">{data($exceedanceDescriptionAdjustment/fn:normalize-space(@xlink:href))}</td>
     </tr>

(: G13 :)
let $G13invalid :=
    try {
        let $query := query:getG13($cdrUrl, $reportingYear)
        let $inspireLabels :=
            if (doc-available(sparqlx:getSparqlEndpointUrl($query, "xml"))) then
                distinct-values(data(sparqlx:executeSparqlQuery(query:getG13($cdrUrl, $reportingYear))//sparql:binding[@name='inspireLabel']/sparql:literal))
            else
                ()
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

(: G15 :)
let $resultXml := if (fn:string-length($countryCode) = 2) then query:getZoneLocallD($cdrUrl) else ""
let $isZoneLocallDCodesAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
let $zoneLocallD := if($isZoneLocallDCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""
let $isZoneLocallDCodesAvailable := count($resultXml) > 0

let $invalidAssessmentZone :=
  for $x in $docRoot//aqd:AQD_Attainment/aqd:zone
    where $isZoneLocallDCodesAvailable and not($x/@nilReason="inapplicable")
    return  if (empty(index-of($zoneLocallD, $x/fn:normalize-space(@xlink:href)))) then <tr>
        <td title="Feature type">{ "aqd:AQD_Attainment" }</td>
        <td title="gml:id">{data($x/../@gml:id)}</td>
        <td title="aqd:zone">{data($x/fn:normalize-space(@xlink:href))}</td>
    </tr>
    else ()

(: G16 TODO Doesn't have am:designationPeriod element :)
(: /aqd:AQD_Zone/am:designationPeriod/gml:TimePeriod/gml:endPosition  :)

(: G17 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then query:getZoneLocallD($cdrUrl) else ""
let $isZoneLocallDCodesAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
let $zoneLocallD := if($isZoneLocallDCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ()
let $isZoneLocallDCodesAvailable := count($zoneLocallD) > 0

let $resultSparql := if (fn:string-length($countryCode) = 2) then query:getPollutantlD($cdrUrl) else ""
let $isPollutantCodesAvailable := string-length($resultSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultSparql, "xml"))
let $pollutansCode:= if($isPollutantCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultSparql)//sparql:binding[@name='key']/sparql:literal)) else ()
let $isPollutantCodesAvailable := count($pollutansCode) > 0

let $invalidPollutant :=
    for $x in $docRoot//aqd:AQD_Attainment
    let $zoneId := if (not(empty($x/aqd:zone/@xlink:href))) then data($x/aqd:zone/@xlink:href) else ""
    where $isPollutantCodesAvailable and $isZoneLocallDCodesAvailable and
    (not(empty(index-of($zoneLocallD, $zoneId))))
    return
        if (empty(index-of($pollutansCode, concat($x/aqd:zone/fn:normalize-space(@xlink:href),'#', $x/aqd:pollutant/fn:normalize-space(@xlink:href))))) then $x/@gml:id else ()


(: G18 :)

let $resultXml := if (fn:string-length($countryCode) = 2) then query:getTimeExtensionExemption($cdrUrl) else ""
let $isLocalCodesAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
let $localId := if($isLocalCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml)//sparql:binding[@name='localId']/sparql:literal)) else ""
let $isLocalCodesAvailable := count($resultXml) > 0

let $invalidObjectiveType :=
for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType
where $isLocalCodesAvailable and empty(index-of($localId, $x/../../../../../aqd:zone/@xlink:href))=false()
return  if ($x/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")  then $x/../../../../../@gml:id else ()

(: G19
.//aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of:)
let $invalidObjectiveTypes_19 := xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:EnvironmentalObjective", "aqd:objectiveType", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_19)

(: G20 - ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute shall resolve to one of
... :)

let $invalidReportingMetric := xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:EnvironmentalObjective", "aqd:reportingMetric",
    $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_20)


(: G21
WHERE
./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute
EQUALS http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL
./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute
EQUALS http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V

:)
let $invalidobjectiveTypesForVEG :=
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

(: 22 :)
let $invalidobjectiveTypesForVEGG22 :=
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


(: 23 :)
let $invalidAqdReportingMetric :=
    for $aqdReportingMetric in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetric/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdReportingMetric/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1"))=false()
    return  if (empty(index-of(('daysAbove','hrsAbove','wMean','aMean', '3hAbove'),$reportingXlink))) then $aqdReportingMetric/@gml:id else ()

(: 24 :)
let $invalidAqdReportingMetricG24 :=
    for $aqdReportingMetricG24 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG24/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdReportingMetricG24/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"))=false()
    return  if (empty(index-of(('daysAbove','aMean'),$reportingXlink))) then $aqdReportingMetricG24/@gml:id else ()

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

let $invalidAqdReportingMetricG25 :=
    for $aqdReportingMetricG25 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG25/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdReportingMetricG25/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"))=false()
    return  if (empty(index-of(('aMean'),$reportingXlink)) and empty(index-of(('AEI'),$reportingXlink))) then $aqdReportingMetricG25/@gml:id else ()

(: G26 /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength uom attribute shall be “km”
let $invalidRoadLengths :=
    for $obj in $docRoot//aqd:AQD_Attainment
    let $uom := $obj//aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength/@uom
    where not(empty($uom)) and lower-case(data($uom)) != 'km'
    return $obj

let $tblinvalidRoadLengths :=
   for $rec in $invalidRoadLengths
   return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($rec/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength/@uom)}</td>
        </tr>:)

(: G26 :)

let $invalidAqdReportingMetricG26 :=
    for $aqdReportingMetricG26 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG26/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdReportingMetricG26/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"))=false()
    return  if (empty(index-of(('daysAbove'),$reportingXlink))) then
        <tr>
        <td title="Feature type">{ "aqd:AQD_Attainment" }</td>
        <td title="gml:id">{data($aqdReportingMetricG26/@gml:id)}</td>
        <td title="aqd:pollutant">{data($aqdReportingMetricG26/aqd:pollutant/fn:normalize-space(@xlink:href))}</td>
    </tr> else ()

(: G27/aqd:AQD_Attainment
   /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification xlink:href attribute shall resolve to
...
let $invalidClassification :=
    xmlconv:checkVocabularyConceptValues("aqd:exceedanceDescriptionBase", "aqd:ExceedanceArea", "aqd:areaClassification", $xmlconv:AREACLASSIFICATION_VOCABULARY) :)

(: G27 :)
let $invalidAqdReportingMetricG27 :=
      for $aqdReportingMetricG27 in $docRoot//aqd:AQD_Attainment
      let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG27/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/fn:normalize-space(@xlink:href)),"protectiontarget/")
        where   $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href)= "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018"
            or $aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029"
    return  if (empty(index-of("V",$reportingXlink))=false()) then
        <tr>
        <td title="Feature type">{ "aqd:AQD_Attainment" }</td>
        <td title="gml:id">{data($aqdReportingMetricG27/@gml:id)}</td>
        <td title="aqd:pollutant">{data($aqdReportingMetricG27/aqd:pollutant/fn:normalize-space(@xlink:href))}</td>
    </tr>
    else ()

(: G28  :)

let $invalidObjectiveTypes_28 := xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:EnvironmentalObjective", "aqd:objectiveType", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_28)

(: G29 :)


let $invalidReportingMetric_29 := xmlconv:isinvalidDDConceptLimited($source_url, "", "aqd:EnvironmentalObjective", "aqd:reportingMetric",
    $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_29)

 (: 30 :)

let $invalidobjectiveTypesForCriticalL :=
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

(: G31 :)

let $invalidobjectiveTypesForAOT31 :=
    for $obj in $docRoot//aqd:environmentalObjective/aqd:EnvironmentalObjective
    let $isInvalid :=
        $obj/aqd:protectionTarget/@xlink:href != 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V'
         and ($obj/aqd:reportingMetric/@xlink:href = 'http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c'
          or $obj/aqd:reportingMetric/@xlink:href ='http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5y')
    where $isInvalid
    return
        <tr>
            <td title="gml:id">{data($obj/../../@gml:id)}</td>
            <td title="aqd:protectionTarget">{data($obj/aqd:protectionTarget/@xlink:href)}</td>
            <td title="aqd:objectiveType">{data($obj/aqd:objectiveType/@xlink:href)}</td>
            <td title="aqd:reportingMetric">{data($obj/aqd:reportingMetric/@xlink:href)}</td>
        </tr>

(: G32 :)

let $invalidobjectiveTypesForHealth :=
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


(: G33 :)

let $invalidobjectiveTypesForLV :=
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


(: G38 :)
let $invalidAreaClassificationCodes := xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionBase", "aqd:ExceedanceArea", "aqd:areaClassification",  $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)
        (:)let $invalidAqdReportingMetricG37 :=
    for $aqdReportingMetricG37 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdReportingMetricG37/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective//aqd:protectionTarget/fn:normalize-space(@xlink:href)),"protectiontarget/")
    where empty(index-of(data($aqdReportingMetricG37/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"))=false()
       or empty(index-of(data($aqdReportingMetricG37/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"))=false()
       or empty(index-of(data($aqdReportingMetricG37/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"))=false()
    return  if (empty(index-of(('V'),$reportingXlink))) then $reportingXlink else ():)

(: G39 :)

(: used below as well :)
let $modelCdrUrl := if ($countryCode = 'gi') then common:getCdrUrl('gb') else $cdrUrl

let $resultXml := if (fn:string-length($countryCode) = 2) then query:getModel($modelCdrUrl) else ""
let $isModelCodesAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
(:let $modelLocallD := if($isModelCodesAvailable) then distinct-values(data(xmlconv:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else "":)
let $modelLocallD := if($isModelCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml)//concat(sparql:binding[@name='namespace']/sparql:literal,"/",sparql:binding[@name='localId']/sparql:literal))) else ""


let $invalidAssessmentModel :=
  for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
    where $isModelCodesAvailable
    return  if (empty(index-of($modelLocallD, $x/fn:normalize-space(@xlink:href)))) then <tr>
        <td title="Feature type">{ "aqd:AQD_Attainment" }</td>
        <td title="gml:id">{data($x/../../../../../@gml:id)}</td>
        <td title="aqd:AQD_Model">{data($x/fn:normalize-space(@xlink:href))}</td>
    </tr>
    else ()


(: G40   :)

let $resultXml := if (fn:string-length($countryCode) = 2) then query:getLocallD($cdrUrl) else ""
let $isLocallDCodesAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
let $inspireLabel := if($isLocallDCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml)//sparql:binding[@name='inspireLabel']/sparql:literal)) else ""


let $resultXml2 :=  query:getAssessmentMethods()
let $isAssessmentMethodsAvailable := string-length($resultXml2) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml2, "xml"))
let $assessmentMetadataNamespace := if($isAssessmentMethodsAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml2)//sparql:binding[@name='assessmentMetadataNamespace']/sparql:literal)) else ""
let $assessmentMetadataId := if($isAssessmentMethodsAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml2)//sparql:binding[@name='assessmentMetadataId']/sparql:literal)) else ""
let $assessmentMetadata := if($isAssessmentMethodsAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml2)//concat(sparql:binding[@name='assessmentMetadataNamespace']/sparql:literal,"/",sparql:binding[@name='assessmentMetadataId']/sparql:literal))) else ""
(: for G42, G67 :)
let $resultXml3 :=  query:getSamplingPointAssessmentMetadata()
let $isAssessmentMethodsAvailable := string-length($resultXml3) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml3, "xml"))
let $samplingPointAssessmentMetadata := if($isAssessmentMethodsAvailable) then 
    let $results := sparqlx:executeSparqlQuery($resultXml3)
    let $values :=
        for $i in $results
            return concat($i/sparql:binding[@name='metadataNamespace']/sparql:literal,"/", $i/sparql:binding[@name='metadataId']/sparql:literal)
    let $values := distinct-values($values)
    return if (not(empty($values))) then $values else ()
    else ()

let $isAssessmentMethodsAvailable := count($resultXml2) > 0


  let $validAssessment_40 :=
     for $x in $docRoot//aqd:AQD_Attainment/aqd:assessment
    where $isLocallDCodesAvailable
    return  if (not(empty(index-of($inspireLabel, $x/fn:normalize-space(@xlink:href))))) then $x else ()

  let $invalidModelUsed  :=
    for $r in $validAssessment_40/../aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
        where $isAssessmentMethodsAvailable
        return  if ((empty(index-of($assessmentMetadata, $r/fn:normalize-space(@xlink:href))))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                    <td title="aqd:assessment">{data($r/../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                    <td title="aqd:modelUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
                else ()



(: G41 :)
(: - CAUTION - Some of the following variables are being used in other rules :)

let $modelCdrUrl_1 := $cdrUrl
let $resultXml := if (fn:string-length($countryCode) = 2) then query:getSamplingPoint($modelCdrUrl_1) else ""
let $isSamplingPointAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
let $samplingPointlD := if($isSamplingPointAvailable) then
    let $results := sparqlx:executeSparqlQuery($resultXml)
    let $values :=
        for $i in $results
            return concat($i/sparql:binding[@name='namespace']/sparql:literal, '/', $i/sparql:binding[@name = 'localId']/sparql:literal)
    let $values := distinct-values($values)
    return if (not(empty($values))) then $values else ()
    else ()
let $isSamplingPointAvailable := count($samplingPointlD) > 0


let $invalidStationUsed  :=
    for $r in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed
       where $isSamplingPointAvailable
    return  if (empty(index-of($samplingPointlD, $r/fn:normalize-space(@xlink:href)))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                    <td title="aqd:SamplingPoint">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
         else ()

(:  G42 :)

let $invalidStationlUsed  :=
    for $r in $validAssessment_40/../aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationlUsed
        where $isAssessmentMethodsAvailable
        return  if ((empty(index-of($samplingPointAssessmentMetadata, $r/fn:normalize-space(@xlink:href))))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                    <td title="aqd:assessment">{data($r/../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                    <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
                else ()

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
            let $numerical := $x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numericalExceedance
            let $numbers := $x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numberExceedances
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
            let $numerical := $x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numericalExceedance
            let $numbers := $x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numberExceedances
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
let $invalidAqdAdjustmentType := distinct-values($docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType/fn:normalize-space(@xlink:href)!="http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/noneApplied"]/@gml:id)

(: G52 :)
let $invalidAreaClassificationAdjusmentCodes := xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:ExceedanceArea", "aqd:areaClassification",  $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)

(: G53 :)
let $resultXml := if (fn:string-length($countryCode) = 2) then query:getModel($modelCdrUrl) else ""
let $isModelAvailable := string-length($resultXml) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($resultXml, "xml"))
let $model := if($isModelCodesAvailable) then distinct-values(data(sparqlx:executeSparqlQuery($resultXml)//concat(sparql:binding[@name='namespace']/sparql:literal,"/",sparql:binding[@name='localId']/sparql:literal))) else ""
let $isModelAvailable := count($resultXml) > 0
let $invalidModel_53  :=
    for $r in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
       where $isModelAvailable
    return
         if ((empty(index-of($model , $r/fn:normalize-space(@xlink:href))))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                    <td title="aqd:Model">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
         else ()

(: G54  :)
    let $invalidModelUsed_54  :=
    for $r in $validAssessment_40/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
        where $isAssessmentMethodsAvailable
        return  if ((empty(index-of($assessmentMetadata, $r/fn:normalize-space(@xlink:href))))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                    <td title="aqd:assessment">{data($r/../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                    <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
                else ()
(: G55 :)
let $invalidStationUsed_55  :=
    for $r in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed
       where $isSamplingPointAvailable
    return  if (empty(index-of($samplingPointlD, $r/fn:normalize-space(@xlink:href)))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                    <td title="aqd:SamplingPoint">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
         else ()

(: G56 :)
let $invalidStationlUsed_56  :=
    for $r in $validAssessment_40/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationlUsed
        where $isAssessmentMethodsAvailable
        return  if ((empty(index-of($samplingPointAssessmentMetadata, $r/fn:normalize-space(@xlink:href))))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                    <td title="aqd:assessment">{data($r/../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                    <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>

                </tr>
                else ()


(: G57 :)
let $invalidAdjustmentReportingMetricG57 :=
    for $aqdAdjustmentReportingMetricG57 in $docRoot//aqd:AQD_Attainment
    let $reportingXlink:= fn:substring-after(data($aqdAdjustmentReportingMetricG57/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/fn:normalize-space(@xlink:href)),"reportingmetric/")
    where empty(index-of(data($aqdAdjustmentReportingMetricG57/aqd:pollutant/fn:normalize-space(@xlink:href)),"http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"))=false()
    return  if (empty(index-of(('aMean'),$reportingXlink))) then $reportingXlink else ()

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
        let $numerical := $x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numericalExceedance
        let $numbers := $x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numberExceedances
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
        let $numerical := $x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numericalExceedance
        let $numbers := $x/aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:numberExceedances
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
let $invalidExceedanceDescriptionAdjustmentType := xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentType", $vocabulary:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)

(: G62 :)
let $invalidExceedanceDescriptionAdjustmentSrc := xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentSource", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTSOURCE_IDS)

(: G63 :)
let $invalidExceedanceDescriptionAdjustmentAssessment := xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:AssessmentMethods", "aqd:assessmentType", $vocabulary:ASSESSMENTTYPE_VOCABULARY, $xmlconv:VALID_ASSESSMENTTYPE_IDS)

(: G64 :)
let $modelAssessmentMetadata_64 :=
   for $r in xmlconv:getValidDDConceptLimited($source_url, "aqd:exceedanceDescriptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentType", $vocabulary:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)
    let $root := $r/../../../../. (: aqd:AQD_Attainment :)
    let $meta :=  $root/aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:modelAssessmentMetadata
    where $isModelAvailable and string-length($meta/fn:normalize-space(@xlink:href))
   return
        if ((empty(index-of($model , $meta/fn:normalize-space(@xlink:href))))) then
            <tr>
                <td title="gml:id">{data($root/@gml:id)}</td>
                <td title="aqd:modelAssessmentMetadata">{data($meta/@xlink:href)}</td>
            </tr>
        else ()


(: G65 :)
let $invalidModelAssessmentMetadata_65  :=
    for $r in $validAssessment_40/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:modelAssessmentMetadata
      where $isAssessmentMethodsAvailable
        return  if ((empty(index-of($assessmentMetadata, $r/fn:normalize-space(@xlink:href))))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                    <td title="aqd:assessment">{data($r/../../../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                    <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
                else ()
(: G66 :)
let $samplingPointAssessmentMetadata_66 :=
   for $r in xmlconv:getValidDDConceptLimited($source_url, "aqd:exceedanceDescriG66ptionAdjustment", "aqd:AdjustmentMethod", "aqd:adjustmentType", $vocabulary:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)
    let $root := $r/../../../../. (: aqd:AQD_Attainment :)
    let $meta :=  $root//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata
   where $isSamplingPointAvailable and string-length($meta/fn:normalize-space(@xlink:href))
        return  if (empty(index-of($samplingPointlD, $meta/fn:normalize-space(@xlink:href)))) then
            <tr>
                <td title="gml:id">{data($root/@gml:id)}</td>
                <td title="aqd:modelAssessmentMetadata">{data($meta/@xlink:href)}</td>
            </tr>
        else ()
(: G67 :)
let $samplingPointAssessmentMetadata_67  :=
    for $r in $validAssessment_40/../aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata
       where $isAssessmentMethodsAvailable
        return  if ((empty(index-of($samplingPointAssessmentMetadata, $r/fn:normalize-space(@xlink:href))))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                    <td title="aqd:assessment">{data($r/../../../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                    <td title="aqd:samplingPointAssessmentMetadata">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
                else ()
(: G70 :)
let $aqdSurfaceArea := $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:surfaceArea[count(@uom)>0 and fn:normalize-space(@uom)!="http://dd.eionet.europa.eu/vocabulary/uom/area/km2" and fn:normalize-space(@uom)!="http://dd.eionet.europa.eu/vocabularyconcept/uom/area/km2"]/../../../../../@gml:id

(: G71 :)
let $aqdroadLength := $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:roadLength[count(@uom)>0 and fn:normalize-space(@uom)!="http://dd.eionet.europa.eu/vocabulary/uom/length/km" and fn:normalize-space(@uom)!="http://dd.eionet.europa.eu/vocabularyconcept/uom/length/km"]/../../../../../@gml:id

(: G72 :)
let $invalidAreaClassificationCode  := xmlconv:isinvalidDDConceptLimited($source_url, "aqd:exceedanceDescriptionFinal", "aqd:ExceedanceArea",  "aqd:areaClassification",  $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)

(: G73 :)
let $invalidModelUsed_73 :=
  for $x in $docRoot//aqd:AQD_Attainment/aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
    where $isModelCodesAvailable
    return  if (empty(index-of($modelLocallD, $x/fn:normalize-space(@xlink:href)))) then <tr>
        <td title="Feature type">{ "aqd:AQD_Attainment" }</td>
        <td title="gml:id">{data($x/../../../../../@gml:id)}</td>
        <td title="aqd:AQD_Model">{data($x/fn:normalize-space(@xlink:href))}</td>
    </tr>
    else ()


(: G74 :)
let $modelUsed_74  :=
    for $r in $validAssessment_40/../aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:modelUsed
       where $isAssessmentMethodsAvailable
        return  if ((empty(index-of($assessmentMetadata, $r/fn:normalize-space(@xlink:href))))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                    <td title="aqd:assessment">{data($r/../../../../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                    <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
                else ()
(: G75 :)
let $invalidStationUsed_75  :=
    for $r in $docRoot//aqd:AQD_Attainment//aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationUsed
       where $isSamplingPointAvailable
    return  if (empty(index-of($samplingPointlD, $r/fn:normalize-space(@xlink:href)))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../../../@gml:id)}</td>
                    <td title="aqd:stationUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
         else ()
(: G76 :)
let $stationlUsed_76  :=
    for $r in $validAssessment_40/../aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:stationlUsed
        where $isAssessmentMethodsAvailable
        return  if ((empty(index-of($samplingPointAssessmentMetadata, $r/fn:normalize-space(@xlink:href))))) then
                <tr>
                    <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                    <td title="aqd:assessment">{data($r/../../../../../../aqd:assessment/fn:normalize-space(@xlink:href))}</td>
                    <td title="aqd:stationlUsed">{data($r/fn:normalize-space(@xlink:href))}</td>
                </tr>
                else ()
(: G81 :)
let $invalidAdjustmentType := distinct-values($docRoot//aqd:AQD_Attainment[aqd:exceedanceDescriptionAdjustmen/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType/fn:normalize-space(@xlink:href)!="http://dd.eionet.europa.eu/vocabulary/aq/adjustmenttype/fullyCorrected"]/@gml:id)

(: G82 TODO :  Description is not logical!! :)
let $invalidAdjustmentType_82  :=
    for $r in $docRoot//aqd:AQD_Attainment//aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType

    return if (not(empty(index-of($xmlconv:ADJUSTMENTTYPES, $r/fn:normalize-space(@xlink:href))))) then
    <tr>
                    <td title="gml:id">{data($r/../../../../../@gml:id)}</td>
                    <td title="gml:id">{data($r/fn:normalize-space(@xlink:href))}</td>
    </tr>
    else ()
return
    <table class="maintable hover">
        {html:buildResultRows("G1", $labels:G1, $labels:G1_SHORT, $tblAllAttainments, "", string($countAttainments), "", "","error")}
        {html:buildResultRows("G2", $labels:G2, $labels:G2_SHORT, $newAttainments, "", string(count($newAttainments)), "", "","error")}
        {html:buildResultRows("G3", $labels:G3, $labels:G3_SHORT, $changedAttainments, "", string(count($changedAttainments)), "", "","error")}
        {html:buildResultRows("G4", $labels:G4, $labels:G4_SHORT, $tblAllAttainmentsG4, "", string(count($tblAllAttainmentsG4)), " ", "","error")}
        {html:buildResultRows("G5", $labels:G5, $labels:G5_SHORT, $tblAllExceedances, "", string(count($tblAllExceedances)), " exceedance", "", "error")}
        {html:buildResultRows("G6", $labels:G6, $labels:G6_SHORT, $tblG6, "", string(count($tblG6)), " attainment", "","error")}
        {html:buildResultRows("G7", $labels:G7, $labels:G7_SHORT, $tblDuplicateGmlIds, "", "No duplicates found", " duplicate", "", "error")}
        {html:buildResultRows("G8", $labels:G8, $labels:G8_SHORT, $invalidDuplicateLocalIds, "base:localId", "No duplicate values found", " duplicate value", "","error")}
        {html:buildResultRows("G9", $labels:G9, $labels:G9_SHORT, $tblG9, "", string(count($tblG9)), "", "", $errors:INFO)}
        {html:buildResultRows("G9.1", $labels:G9.1, $labels:G9.1_SHORT, $invalidNamespaces, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:buildResultRowsWithTotalCount_G("G10", <span>The content of /aqd:AQD_Attainment/aqd:pollutant xlink:xref shall resolve to a pollutant in
            <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G10", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS)}
            </span>, $labels:PLACEHOLDER, $invalidPollutantCodes, "aqd:pollutant", "", "", "", "error")}
        {html:buildResultRows("G11", <span>WHERE ./aqd:pollutant xlink:href attribute EQUALs  <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G11", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_11)} ./aqd:exceedanceDescriptionBase may occur</span>, $labels:PLACEHOLDER,
            $invalidExceedanceDescriptionBase, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G12", <span>WHERE ./aqd:pollutant xlink:href attribute EQUALs  <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G12", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_11)} ./aqd:exceedanceDescriptionAdjustment may occur</span>, $labels:PLACEHOLDER,
                $invalidExceedanceDescriptionAdjustment, "base:namespace", "All values are valid", " invalid value", "", "error")}
        {html:buildResultRows("G13", $labels:G13, $labels:G13_SHORT, $G13invalid, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultG14("G14", $labels:G14, $labels:G14_SHORT, $G14resultBC, $G14ResultG)}
        {html:buildResultRows("G15", $labels:G15, $labels:G15_SHORT, $invalidAssessmentZone, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G17", $labels:G17, $labels:G17_SHORT, $invalidPollutant, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G18", $labels:G18, $labels:G18_SHORT, $invalidObjectiveType, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRowsWithTotalCount_G("G19", <span>./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of
            <a href="{ $vocabulary:OBJECTIVETYPE_VOCABULARY }">{ $vocabulary:OBJECTIVETYPE_VOCABULARY }</a>
            Allowed items: {xmlconv:buildVocItemsList("G19", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_19)}</span>, $labels:PLACEHOLDER, $invalidObjectiveTypes_19, "aqd:objectivetype", "", "", "","error")}
        {html:buildResultRowsWithTotalCount_G("G20", <span>The content of ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G20", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_20)}</span>, $labels:PLACEHOLDER, $invalidReportingMetric, "aqd:reportingMetric", "", "", "","error")}
        {html:buildResultRows("G21", $labels:G21, $labels:G21_SHORT, $invalidobjectiveTypesForVEG, "", "No invalid objective types for Vegetation found", " invalid value", "","error")}
        {html:buildResultRows("G22", $labels:G22, $labels:G22_SHORT, $invalidobjectiveTypesForVEGG22, "", "No invalid objective types for Health found", " invalid value", "","error")}
        {html:buildResultRows("G23", <span>WHERE ./aqd:pollutant xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1 ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G23", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_23)}</span>, $labels:PLACEHOLDER,
                $invalidAqdReportingMetric, "aqd:reportingMetric", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G24", <span>WHERE ./aqd:pollutant xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5 ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one ofS
            {xmlconv:buildVocItemsList("G24", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_24)}</span>, $labels:PLACEHOLDER,
                $invalidAqdReportingMetricG24, "aqd:reportingMetric", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G25", <span>WHERE ./aqd:pollutant xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G25", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_25)}</span>, $labels:PLACEHOLDER,
                $invalidAqdReportingMetricG25, "aqd:reportingMetric", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G26", <span>WHERE ./aqd:pollutant xlink:href attribute resolves to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10 ./aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G26", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_26)}</span>, $labels:PLACEHOLDER,
                $invalidAqdReportingMetricG26, "aqd:reportingMetric", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G27", <span>./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute shall NOT EQUAL http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V and
            <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G27", $vocabulary:POLLUTANT_VOCABULARY, $xmlconv:VALID_POLLUTANT_IDS_27)}</span>, $labels:PLACEHOLDER,
                $invalidAqdReportingMetricG27, "aqd:reportingMetric", "All values are valid", " invalid value", "","error")}
        {html:buildResultRowsWithTotalCount_G("G28", <span>./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType xlink:href attribute shall resolve to one of
            <a href="{ $vocabulary:OBJECTIVETYPE_VOCABULARY }">{ $vocabulary:OBJECTIVETYPE_VOCABULARY }</a>
            Allowed items: {xmlconv:buildVocItemsList("G28", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_28)}</span>, $labels:PLACEHOLDER, invalidObjectiveTypes_28, "aqd:objectivetype", "", "", "","error")}
        {html:buildResultRowsWithTotalCount_G("G29", <span>The content of ./aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:EnvironmentalObjective/aqd:reportingMetric shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G29", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_29)}</span>, $labels:PLACEHOLDER, $invalidReportingMetric_29, "aqd:reportingMetric", "", "", "","error")}
        {html:buildResultRows("G30", $labels:G30, $labels:G30_SHORT, $invalidobjectiveTypesForCriticalL, "", "No invalid objective types for Vegetation found", " invalid", "","error")}
        {html:buildResultRows("G31", <span>The content of ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute shall EQUAL
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V and /aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric xlink:href attribute on shall resolve to a valid concept in
            <a href="{ $vocabulary:REPMETRIC_VOCABULARY }">{ $vocabulary:REPMETRIC_VOCABULARY }</a> that must be one of
        {xmlconv:buildVocItemsList("G31", $vocabulary:REPMETRIC_VOCABULARY, $xmlconv:VALID_REPMETRIC_IDS_31)}</span>, $labels:PLACEHOLDER,
                $invalidobjectiveTypesForAOT31, "aqd:reportingMetric", "", "", "","error")}
        {html:buildResultRows("G32", <span>The content of ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute shall EQUAL
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H AND /aqd:polluntant is NOT EQUAL to
            http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001 where ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType  xlink:href attribute on shall resolve to a valid concept in
            <a href="{ $vocabulary:OBJECTIVETYPE_VOCABULARY }">{ $vocabulary:OBJECTIVETYPE_VOCABULARY }</a> that must be one of
            {xmlconv:buildVocItemsList("G32", $vocabulary:OBJECTIVETYPE_VOCABULARY, $xmlconv:VALID_OBJECTIVETYPE_IDS_32)}</span>, $labels:PLACEHOLDER,
                $invalidobjectiveTypesForHealth, "aqd:reportingMetric",  "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G33", <span>./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/xlink:href  attribute   EQUALS
                http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV
                and the content of ./aqd:pollutant is EQUAL to http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001
            ./aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget xlink:href attribute EQUALS
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2
            http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H

            </span>, $labels:PLACEHOLDER,
                $invalidobjectiveTypesForLV, "aqd:reportingMetric", "All values are valid", " invalid value", "","error")}

        {html:buildResultRowsWithTotalCount_G("G38", <span>The content of /aqd:exceedanceDescriptionBase/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:areaClassification xlink:xref shall resolve to a areaClassification in
            <a href="{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}">{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G38", $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)}
        </span>, $labels:PLACEHOLDER, $invalidAreaClassificationCodes, "aqd:areaClassification", "", "", "","error")}
        {html:buildResultRows("G39", $labels:G39, $labels:G39_SHORT, $invalidAssessmentModel, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G40", $labels:G40, $labels:G40_SHORT, $invalidModelUsed, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G41", $labels:G41, $labels:G41_SHORT, $invalidStationUsed, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G42", $labels:G42, $labels:G42_SHORT, $invalidStationlUsed, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:build2("G44", $labels:G44, $labels:G44_SHORT, $G44invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G45", $labels:G45, $labels:G45_SHORT, $G45invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G46", $labels:G46, $labels:G46_SHORT, $G46invalid, "", "All values are valid", " invalid value", "", $errors:WARNING)}
        {html:buildResultRows("G47", $labels:G47, $labels:G47_SHORT, $invalidAqdAdjustmentType, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRowsWithTotalCount_G("G52", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:areaClassification xlink:xref shall resolve to a areaClassification in
            <a href="{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}">{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G52", $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)}
        </span>, $labels:PLACEHOLDER, $invalidAreaClassificationAdjusmentCodes, "aqd:areaClassification", "", "", "", $errors:ERROR)}
        {html:buildResultRows("G53", $labels:G53, $labels:G53_SHORT, $invalidModel_53, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G54", $labels:G54, $labels:G54_SHORT, $invalidModelUsed_54, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G55", $labels:G55, $labels:G55_SHORT, $invalidStationUsed_55, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G56", $labels:G56, $labels:G56_SHORT, $invalidStationlUsed_56, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:build2("G58", $labels:G58, $labels:G58_SHORT, $G58invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G59", $labels:G59, $labels:G59_SHORT, $G59invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("G60", $labels:G60, $labels:G60_SHORT, $G60invalid, "", "All values are valid", " invalid value", "", $errors:WARNING)}
        {html:buildResultRowsWithTotalCount_G("G61", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmentType xlink:xref shall resolve to a adjustmentType in
            <a href="{ $vocabulary:ADJUSTMENTTYPE_VOCABULARY}">{ $vocabulary:ADJUSTMENTTYPE_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G61", $vocabulary:ADJUSTMENTTYPE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTTYPE_IDS)}
        </span>, $labels:PLACEHOLDER, $invalidExceedanceDescriptionAdjustmentType, "aqd:areaClassification", "", "", "","error")}
        {html:buildResultRowsWithTotalCount_G("G62", <span>The content of /aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:adjustmenSource xlink:xref shall resolve to a adjustmenSource in
            <a href="{ $vocabulary:ADJUSTMENTSOURCE_VOCABULARY}">{ $vocabulary:ADJUSTMENTSOURCE_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G62", $vocabulary:ADJUSTMENTSOURCE_VOCABULARY, $xmlconv:VALID_ADJUSTMENTSOURCE_IDS)}
        </span>, $labels:PLACEHOLDER, $invalidExceedanceDescriptionAdjustmentSrc, "aqd:areaClassification", "", "", "","error")}
        {html:buildResultRowsWithTotalCount_G("G63", <span>The content of ./aqd:exceedanceDescriptionAdjustment/aqd:ExceedanceDescription/aqd:deductionAssessmentMethod/aqd:AdjustmentMethod/aqd:assessmentMethod/aqd:AssessmentMethods/aqd:assessmentType shall resolve to
            <a href="{  $vocabulary:ASSESSMENTTYPE_VOCABULARY}">{  $vocabulary:ASSESSMENTTYPE_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G63",  $vocabulary:ASSESSMENTTYPE_VOCABULARY, $xmlconv:VALID_ASSESSMENTTYPE_IDS)}
        </span>, $labels:PLACEHOLDER, $invalidExceedanceDescriptionAdjustmentAssessment, "aqd:areaClassification", "", "", "","error")}
        {html:buildResultRows("G64", $labels:G64, $labels:G64_SHORT, $modelAssessmentMetadata_64, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G65", $labels:G65, $labels:G65_SHORT, $invalidModelAssessmentMetadata_65, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G66", $labels:G66, $labels:G66_SHORT, $samplingPointAssessmentMetadata_66, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G67", $labels:G67, $labels:G67_SHORT, $samplingPointAssessmentMetadata_67, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G70", $labels:G70, $labels:G70_SHORT, $aqdSurfaceArea, "base:namespace", "All values are valid", " invalid value", "", "warning")}
        {html:buildResultRows("G71", $labels:G71, $labels:G71_SHORT, $aqdroadLength, "base:namespace", "All values are valid", " invalid value", "","warning")}
        {html:buildResultRowsWithTotalCount_G("G72", <span>The content of /aqd:exceedanceDescriptionFinal/aqd:ExceedanceDescription/aqd:exceedanceArea/aqd:ExceedanceArea/aqd:areaClassification  xlink:xref shall resolve to a areaClassification in
            <a href="{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}">{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY}</a> that must be one of
            {xmlconv:buildVocItemsList("G72", $vocabulary:AREA_CLASSIFICATION_VOCABULARY, $xmlconv:VALID_AREACLASSIFICATION_IDS_52)}
        </span>, $labels:PLACEHOLDER, $invalidAreaClassificationCode, "aqd:areaClassification", "", "", "","error")}
        {html:buildResultRows("G73", $labels:G73, $labels:G73_SHORT, $invalidModelUsed_73, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G74", $labels:G74, $labels:G74_SHORT, $modelUsed_74, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G75", $labels:G75, $labels:G75_SHORT, $invalidStationUsed_75, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G76", $labels:G76, $labels:G76_SHORT, $stationlUsed_76, "base:namespace", "All values are valid", " invalid value", "","error")}
        {html:buildResultRows("G81", $labels:G81, $labels:G81_SHORT, $invalidAqdAdjustmentType, "base:namespace", "All values are valid", " invalid value", "","error")}
        {$invalidAdjustmentType_82}
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