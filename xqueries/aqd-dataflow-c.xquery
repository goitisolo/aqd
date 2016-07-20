xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :
 : XQuery script implements dataflow C tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Enriko Käsper
 : @author George Sofianos
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document & polish some checks
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowC";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace filter = "aqd-filter" at "aqd-filter.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace skos="http://www.w3.org/2004/02/skos/core#";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace prop="http://dd.eionet.europa.eu/property/";

declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
declare variable $xmlconv:VALID_POLLUTANT_IDS as xs:string* := ("1", "7", "8", "9", "5", "6001", "10","20", "5012", "5014", "5015", "5018", "5029");
declare variable $xmlconv:VALID_POLLUTANT_IDS_18 as xs:string* := ("5014", "5015", "5018", "5029");
declare variable $xmlconv:MANDATORY_POLLUTANT_IDS_8 as xs:string* := ("1","7","8","9","5","6001","10","20","5012","5014","5015","5018","5029");
declare variable $xmlconv:UNIQUE_POLLUTANT_IDS_9 as xs:string* := ("1","7","8","9","5","6001","10","20","5012","5014","5015","5018","5029","1045",
"1046","1047","1771","1772","1629","1659","1657","1668","1631","2012","2014","2015","2018","7013","4013","4813","653","5013","5610","5617","5759",
"5626","5655","5763","7029","611","618","760","627","656","7419","20","428","430","432","503","505","394","447","6005","6006","6007","24","486",
"316","6008","6009","451","443","316","441","475","449","21","431","464","482","6011","6012","32","25");

declare variable $xmlconv:VALID_POLLUTANT_IDS_19 as xs:string* := ("1045","1046","1047","1771","1772","1629","1659","1657","1668","1631","2012","2014","2015","2018","7013","4013","4813","653","5013","5610","5617",
"5759","5626","5655","5763","7029","611","618","760","627","656","7419","428","430","432","503","505","394","447","6005","6006","6007","24","486","316","6008","6009","451","443","441","475","449","21","431","464",
"482","6011","6012","32","25");

declare variable $xmlconv:VALID_POLLUTANT_IDS_27 as xs:string* := ('1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
'5759','5626','5655','5763','7029','611','618','760','627','656','7419','20','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
'451','443','316','441','475','449','21','431','464','482','6011','6012','32','25','6001');

declare variable $xmlconv:VALID_POLLUTANT_IDS_40 as xs:string* := ($xmlconv:MANDATORY_POLLUTANT_IDS_8, $xmlconv:UNIQUE_POLLUTANT_IDS_9);

(:'1045','1046','1047','1771','1772','1629','1659','1657','1668','1631','2012','2014','2015','2018','7013','4013','4813','653','5013','5610','5617',
'5759','5626','5655','5763','7029','611','618','760','627','656','7419','428','430','432','503','505','394','447','6005','6006','6007','24','486','316','6008','6009',
'451','443','316','441','475','449','21','431','464','482','6011','6012','32','25':)

declare variable $xmlconv:VALID_POLLUTANT_IDS_21 as xs:string* := ("1","8","9","10","5","6001","5014","5018","5015","5029","5012","20");
declare variable $xmlconv:OBLIGATIONS as xs:string* := ("http://rod.eionet.europa.eu/obligations/671", "http://rod.eionet.europa.eu/obligations/694");
(: Rule implementations :)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

(: SETUP COMMON VARIABLES :)
let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $cdrUrl := common:getCdrUrl($countryCode)
let $bDir := if (contains($source_url, "c_preliminary")) then "b_preliminary/" else "b/"
let $cdir := if (contains($source_url, "c_preliminary")) then "c_preliminary/" else "c/"
let $zonesUrl := concat($cdrUrl, $bDir)
let $reportingYear := common:getReportingYear($docRoot)
let $latestEnvelopeB := query:getLatestEnvelopeByYear($zonesUrl, $reportingYear)
let $namespaces := distinct-values($docRoot//base:namespace)

let $zoneIds := if ((fn:string-length($countryCode) = 2) and exists($latestEnvelopeB)) then distinct-values(data(sparqlx:executeSparqlQuery(query:getZones($latestEnvelopeB))//sparql:binding[@name = 'inspireLabel']/sparql:literal)) else ()
let $countZoneIds1 := count($zoneIds)
let $countZoneIds2 := count(distinct-values($docRoot//aqd:AQD_AssessmentRegime/aqd:zone/@xlink:href))

let $latestenvelopeB := query:getLatestEnvelopeS($cdrUrl || "b/")
let $latestenvelopeC := query:getLatestEnvelopeByYear($cdrUrl || "c/", $reportingYear)
let $latestMenvelope := query:getLatestEnvelopeS($cdrUrl || "d/")
let $knownRegimes := if (exists($latestenvelopeC)) then query:getLatestRegimeIds($latestenvelopeC) else ()
let $allRegimes := query:getAllRegimeIds($namespaces)
let $countRegimes := count($docRoot//aqd:AQD_AssessmentRegime)

(: INFO: XML Validation check. This adds delay to the running scripts :)
let $validationResult := schemax:validateXmlSchema($source_url)

(: C0 :)
let $C0invalid :=
    try {
        if (query:deliveryExists($xmlconv:OBLIGATIONS, $countryCode, $cdir, $reportingYear)) then
            <tr>
                <td title="base:namespace">{$docRoot//aqd:AQD_ReportingHeader/aqd:inspireId/base:Identifier/base:namespace/string()}</td>
                <td title="base:localId">{$docRoot//aqd:AQD_ReportingHeader/aqd:inspireId/base:Identifier/base:localId/string()}</td>
            </tr>
        else
            ()
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C1 :)
let $C1table :=
    try {
        for $rec in $docRoot//aqd:AQD_AssessmentRegime
        return
            <tr>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="base:localId">{data($rec/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($rec/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="aqd:zone">{common:checkLink(data($rec/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($rec/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($rec/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C2 :)
let $C2table :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime
        let $id := $x/aqd:inspireId/base:Identifier/base:namespace || "/" || $x/aqd:inspireId/base:Identifier/base:localId
        where (not($knownRegimes = $id))
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="base:localId">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($x/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="aqd:zone">{common:checkLink(data($x/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($x/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($x/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $C2errorLevel :=
    if (empty($C0invalid) and count(
        for $x in $docRoot//aqd:AQD_AssessmentRegime
        let $id := $x/aqd:inspireId/base:Identifier/base:namespace || "/" || $x/aqd:inspireId/base:Identifier/base:localId
        where ($allRegimes = $id)
        return 1) > 0) then
            $errors:ERROR
    else
        $errors:INFO

(: C3 :)
let $C3table :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime
        let $id := $x/aqd:inspireId/base:Identifier/base:namespace || "/" || $x/aqd:inspireId/base:Identifier/base:localId
        where ($knownRegimes = $id)
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="base:localId">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:versionId">{data($x/aqd:inspireId/base:Identifier/base:versionId)}</td>
                <td title="base:namespace">{data($x/aqd:inspireId/base:Identifier/base:namespace)}</td>
                <td title="aqd:zone">{common:checkLink(data($x/aqd:zone/@xlink:href))}</td>
                <td title="aqd:pollutant">{common:checkLink(data($x/aqd:pollutant/@xlink:href))}</td>
                <td title="aqd:protectionTarget">{common:checkLink(data($x/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $C3errorLevel :=
    if (exists($C0invalid) and count($C3table) = 0) then
        $errors:ERROR
    else
        $errors:INFO

(: C4 - duplicate @gml:ids :)
let $C4invalid :=
    try {
        let $gmlIds := $docRoot//aqd:AQD_AssessmentRegime/lower-case(normalize-space(@gml:id))
        for $id in $docRoot//aqd:AQD_AssessmentRegime/@gml:id
        where count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
        return
            <tr>
                <td title="@gml:id">{$id}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: C5 - duplicate ./aqd:inspireId/base:Identifier/base:localId :)
let $C5invalid :=
    try {
        let $localIds := $docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/lower-case(normalize-space(base:localId))
        for $id in $docRoot//aqd:inspireId/base:Identifier/base:localId
        where count(index-of($localIds, lower-case(normalize-space($id)))) > 1
        return
            <tr>
                <td title="base:localId">{$id}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C6 - :)
let $C6table :=
    try {
        let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:namespace)
        for $id in $allBaseNamespace
        let $localId := $docRoot//aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
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
        
(: C6.1 :)
let $C6.1invalid :=
    try {
        common:checkNamespacesFromFile($source_url)
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C7 :)
let $C7invalid :=
    try {
        for $aqdAQD_AssessmentRegim in $docRoot//aqd:AQD_AssessmentRegime
        where $aqdAQD_AssessmentRegim[count(aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href) = 0]
        return
            <tr>
                <td title="base:localId">{string($aqdAQD_AssessmentRegim/aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C8 - if a regime is missing for a pollutant in the list, warning should be thrown :)
let $C8invalid :=
    try {
        let $mandatory := ("1","7","8","9","5","6001","10","20","5012","5014","5015","5018","5029")
        let $pollutants :=
            if ($countryCode = "gi") then remove($mandatory, index-of($mandatory, "9"))
            else $mandatory
        for $code in $pollutants
        let $pollutantLink := $vocabulary:POLLUTANT_VOCABULARY || $code
        where count($docRoot//aqd:AQD_AssessmentRegime/aqd:pollutant[@xlink:href = $pollutantLink]) < 1
        return
            <tr>
                <td title="Pollutant"><a href="{$pollutantLink}">{$code}</a></td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C9 - Provides a count of unique pollutants and lists them :)
let $C9table :=
    try {
        let $pollutants :=
            for $x in $docRoot//aqd:AQD_AssessmentRegime[aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO"]
            return $x/aqd:pollutant/@xlink:href/string()
        for $i in distinct-values($pollutants)
        return
            <tr>
                <td title="pollutant">{$i}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C10 :)
let $C10invalid :=
    try {
        for $aqdPollutantC10 in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant) > 0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
                or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                        or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove")
                        or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL")
                        or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))
                and
                (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL")
                        or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/wMean")
                        or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))
        (: Please add following combination: aqd:objectiveType xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT aqd:reportingMetric xlink:href attribute shall resolve to one of
http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove aqd:protectionTarget xlink:href attribute shall resolve to one of  http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H
:)
                and
                (($aqdPollutantC10/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT")
                        or ($aqdPollutantC10/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove")
                        or ($aqdPollutantC10/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC10/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C11 :)
let $C11invalid :=
    try {
        for $aqdPollutantC11 in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant) > 0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV")
                or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr")
                or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO")
                        or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove")
                        or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV")
                        or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5yr")
                        or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))
                and
                (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO")
                        or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c")
                        or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))
        (: 2 additional combinations based on #21117 :)
                and
                (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/INT")
                        or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
                        or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC11/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT")
                        or ($aqdPollutantC11/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
                        or ($aqdPollutantC11/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC11/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C12 :)
let $C12invalid :=
    try {
        for $aqdPollutantC12 in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant) > 0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
                or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                        or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))

        (: 3 additional based on #21117 :)
                and
                (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT")
                        or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT")
                        or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
                        or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ALT")
                        or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/3hAbove")
                        or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))

                and
                (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")
                        or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC12/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVmaxMOT")
                        or ($aqdPollutantC12/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove")
                        or ($aqdPollutantC12/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC12/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C13 :)
let $C13invalid :=
    try {
        for $aqdPollutantC13 in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant) > 0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where (($aqdPollutantC13/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL")
                or ($aqdPollutantC13/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                or ($aqdPollutantC13/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))
                and
                (($aqdPollutantC13/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
                        or ($aqdPollutantC13/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
                        or ($aqdPollutantC13/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))

        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC13/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: C14 :)
let $C14invalid :=
    try {
        for $aqdPollutantC14 in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant) > 0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where (($aqdPollutantC14/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                or ($aqdPollutantC14/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove")
                or ($aqdPollutantC14/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC14/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                        or ($aqdPollutantC14/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC14/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC14/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C15 :)
let $C15invalid :=
    try {
        for $aqdPollutantC15 in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant) > 0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO")
                or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI")
                or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                        or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
        (: 2 additional in #21117 :)
                and
                (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV")
                        or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT")
                        or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))

                and
                (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LVMOT")
                        or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1"))

                and
                (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                        or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1"))

                and
                (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                        or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                        or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2"))
        (: another addition by JT :)
                and
                (($aqdPollutantC15/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
                        or ($aqdPollutantC15/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
                        or ($aqdPollutantC15/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))
        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC15/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: C16 :)
let $C16invalid :=
    try {
        for $aqdPollutantC16 in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant) > 0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where ($aqdPollutantC16/aqd:objectiveType/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                or ($aqdPollutantC16/aqd:reportingMetric/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove")
                or ($aqdPollutantC16/aqd:protectionTarget/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC16/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C17 :)
let $C17invalid :=
    try {
        for $aqdPollutantC17 in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant) > 0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012" or aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where (($aqdPollutantC17/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV")
                or ($aqdPollutantC17/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                or ($aqdPollutantC17/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC17/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
                        or ($aqdPollutantC17/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
                        or ($aqdPollutantC17/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))

        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC17/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C18 :)
let $C18invalid :=
    try {
        for $aqdPollutantC18 in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:pollutant) > 0 and aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014" or aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018"
                or aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015" or aqd:pollutant/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029"]/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where (($aqdPollutantC18/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV")
                or ($aqdPollutantC18/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean")
                or ($aqdPollutantC18/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H"))
                and
                (($aqdPollutantC18/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
                        or ($aqdPollutantC18/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
                        or ($aqdPollutantC18/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))

        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC18/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C19 :)
let $C19invalid :=
    try {
        for $aqdPollutantC19 in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        let $pollutantXlinkC19 := fn:substring-after(data($aqdPollutantC19/../../../../aqd:pollutant/@xlink:href), "pollutant/")
        where empty(index-of(('1045', '1046', '1047', '1771', '1772', '1629', '1659', '1657', '1668', '1631', '2012', '2014', '2015', '2018', '7013', '4013', '4813', '653', '5013', '5610', '5617',
        '5759', '5626', '5655', '5763', '7029', '611', '618', '760', '627', '656', '7419', '428', '430', '432', '503', '505', '394', '447', '6005', '6006', '6007', '24', '486', '316', '6008', '6009',
        '451', '443', '316', '441', '475', '449', '21', '431', '464', '482', '6011', '6012', '32', '25'), $pollutantXlinkC19)) = false() and
                (($aqdPollutantC19/aqd:objectiveType/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO")
                        or ($aqdPollutantC19/aqd:reportingMetric/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA")
                        or ($aqdPollutantC19/aqd:protectionTarget/fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA"))
        return
            <tr>
                <td title="base:localId">{string($aqdPollutantC19/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C20 :)
let $C20invalid :=
    try {
        let $rdf := doc("http://dd.eionet.europa.eu/vocabulary/aq/environmentalobjective/rdf")
        let $rdf := distinct-values(
            for $x in $rdf//skos:Concept[string-length(prop:exceedanceThreshold) > 0]
            where not($x/prop:hasObjectiveType/@rdf:resource = ($vocabulary:OBJECTIVETYPE_VOCABULARY || "MO", $vocabulary:OBJECTIVETYPE_VOCABULARY || "LVMOT", $vocabulary:OBJECTIVETYPE_VOCABULARY || "LVmaxMOT"))
            return $x/prop:relatedPollutant/@rdf:resource || "#" || $x/prop:hasObjectiveType/@rdf:resource || "#" || $x/prop:hasReportingMetric/@rdf:resource || "#" || $x/prop:hasProtectionTarget/@rdf:resource
        )

        for $i in $rdf
            let $tokens := tokenize($i, "#")
        where count($docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/
                aqd:environmentalObjective/aqd:EnvironmentalObjective[concat(../../../../aqd:pollutant/@xlink:href, "#", aqd:objectiveType/@xlink:href, "#", aqd:reportingMetric/@xlink:href, "#", aqd:protectionTarget/@xlink:href) = $i]) = 0
        return
            <tr>
                <td title="pollutant">{$tokens[1]}</td>
                <td title="objectiveType">{$tokens[2]}</td>
                <td title="reportingMetric">{$tokens[3]}</td>
                <td title="hasProtectionTarget">{$tokens[4]}</td>
            </tr>

    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C21 :)
let $C21invalid :=
    try {
        let $environmentalObjectiveCombinations :=
            doc("http://dd.eionet.europa.eu/vocabulary/aq/environmentalobjective/rdf")
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective
        let $pollutant := string($x/../../../../aqd:pollutant/@xlink:href)
        let $objectiveType := string($x/aqd:objectiveType/@xlink:href)
        let $reportingMetric := string($x/aqd:reportingMetric/@xlink:href)
        let $protectionTarget := string($x/aqd:protectionTarget/@xlink:href)
        let $exceedance := string($x/../../aqd:exceedanceAttainment/@xlink:href)
        where (not($environmentalObjectiveCombinations//skos:Concept[prop:relatedPollutant/@rdf:resource = $pollutant and prop:hasProtectionTarget/@rdf:resource = $protectionTarget
                and prop:hasObjectiveType/@rdf:resource = $objectiveType and prop:hasReportingMetric/@rdf:resource = $reportingMetric
                and prop:assessmentThreshold/@rdf:resource = $exceedance]))
        return
            <tr>
                <td title="base:localId">{string($x/../../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C23a :)
let $C23ainvalid :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime[count(aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType/@xlink:href) > 0]/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:assessmentType
        where $x/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/fixed"
                and $x/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/model"
                and $x/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/indicative"
                and $x/@xlink:href != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/objective"
        return
            <tr>
                <td title="base:localId">{string($x/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:assessmentType">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C23B - Warning :)
let $C23binvalid :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods
            let $type := $x/aqd:assessmentType/@xlink:href
            let $desc := $x/aqd:assessmentTypeDescription
        where empty($desc) or data($desc = "")
        return
            <tr>
                <td title="base:localId">{string($x/../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:assessmentType">{data($type)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $C24invalid :=
    try {
        let $valid := data(sparqlx:run(query:getG86Models($latestMenvelope))/sparql:binding[@name='inspireLabel']/sparql:literal)
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMetadata
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime">{string($x/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:modelAssessmentMetadata">{data($x/@xlink:href)}</td>
            </tr>

    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $C25invalid :=
    let $valid := data(sparqlx:run(query:getG86Stations($latestMenvelope))/sparql:binding[@name='inspireLabel']/sparql:literal)
    for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata
    where not($x/@xlink:href = $valid)
    return
        <tr>
            <td title="aqd:AQD_AssessmentRegime">{string($x/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
            <td title="aqd:samplingPointAssessmentMetadata">{data($x/@xlink:href)}</td>
        </tr>

(: C26 - :)
let $C26table :=
    try {
        let $startDate := substring(data($docRoot//aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition),1,10)
        let $endDate := substring(data($docRoot//aqd:reportingPeriod/gml:TimePeriod/gml:endPosition),1,10)

        let $latestDEnvelopes := distinct-values(data(sparqlx:executeSparqlQuery(query:getLatestDEnvelope($cdrUrl))//sparql:binding[@name='dataset']/sparql:uri))
        let $modelMethods := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getModelEndPosition($latestDEnvelopes, $startDate, $endDate))//sparql:binding[@name='inspireLabel']/sparql:literal)) else ()
        let $sampingPointMethods := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getSamplingPointEndPosition($latestDEnvelopes,$startDate,$endDate))//sparql:binding[@name='inspireLabel']/sparql:literal)) else ()

        for $method in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods
        let $modelMetaCount := count($method/aqd:modelAssessmentMetadata)
        let $samplingPointMetaCount := count($method/aqd:samplingPointAssessmentMetadata)

        let $invalidModel :=
            for $meta1 in $method/aqd:modelAssessmentMetadata
            where (empty(index-of($modelMethods, data($meta1/@xlink:href))))
            return
                <tr>
                    <td title="AQD_AssessmentRegime">{data($meta1/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:modelAssessmentMetadata">{data($meta1/@xlink:href)}</td>
                    <td title="aqd:samplingPointAssessmentMetadata"></td>
                </tr>

        let $invalidSampingPoint :=
            for $meta2 in $method/aqd:samplingPointAssessmentMetadata
            where (empty(index-of($sampingPointMethods, data($meta2/@xlink:href))))
            return
                <tr>
                    <td title="AQD_AssessmentRegime">{data($meta2/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:modelAssessmentMetadata"></td>
                    <td title="aqd:samplingPointAssessmentMetadata">{data($meta2/@xlink:href)}</td>
                </tr>

        return
            if ($modelMetaCount = 0 and $samplingPointMetaCount = 0) then
                <tr>
                    <td title="AQD_AssessmentRegime">{data($method/../../aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:modelAssessmentMetadata">None specified</td>
                    <td title="aqd:samplingPointAssessmentMetadata">None specified</td>
                </tr>
            else
                (($invalidModel), ($invalidSampingPoint))
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C27 - return all zones listed in the doc :)
let $C27table :=
    try {
        (: return zones not listed in B :)
        let $invalidEqual :=
            for $regime in $docRoot//aqd:AQD_AssessmentRegime
            let $zoneId := string($regime/aqd:zone/@xlink:href)
            where ($zoneId != "" and not($zoneIds = $zoneId))
            return
                <tr>
                    <td title="AQD_AssessmentRegime">{data($regime/aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:zoneId">{$zoneId}</td>
                    <td title="AQD_Zone">Not existing</td>
                </tr>
        let $invalidEqual2 :=
            for $zoneId in $zoneIds
            where ($zoneId != "" and count($docRoot//aqd:AQD_AssessmentRegime/aqd:zone[@xlink:href = $zoneId]) = 0)
            return
                <tr>
                    <td title="AQD_AssessmentRegime">Not existing</td>
                    <td title="aqd:zoneId"></td>
                    <td title="AQD_Zone">{$zoneId}</td>
                </tr>

        return (($invalidEqual), ($invalidEqual2))
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C29 - :)
let $C29invalid :=
    try {
        let $validZones :=
            for $zoneId in $zoneIds
            return
                if ($zoneId != "" and count($docRoot//aqd:AQD_AssessmentRegime/aqd:zone[@xlink:href = $zoneId]) > 0) then
                    $zoneId
                else
                    ()
        let $combinations := if (fn:string-length($countryCode) = 2) then sparqlx:executeSparqlQuery(query:getPollutantCodeAndProtectionTarge($cdrUrl, $bDir)) else ()
        let $validRows :=
            for $rec in $combinations
            return
                concat(data($rec//sparql:binding[@name = 'inspireLabel']/sparql:literal), "#", data($rec//sparql:binding[@name = 'pollutantCode']/sparql:uri), "#", data($rec//sparql:binding[@name = 'protectionTarget']/sparql:uri))
        let $validRows := distinct-values($validRows)

        let $exceptionPollutantIds := ("6001")

            for $x in $docRoot//aqd:AQD_AssessmentRegime[aqd:zone/@xlink:href = $validZones]
            let $pollutantCode := fn:substring-after(data($x//aqd:pollutant/@xlink:href), "pollutant/")
            let $key :=
                if (not(empty(index-of($exceptionPollutantIds, $pollutantCode))) and data($x//aqd:zone/@nilReason) = "inapplicable") then
                    "EXC"
                else
                    concat(data($x//aqd:zone/@xlink:href), '#', data($x//aqd:pollutant/@xlink:href), '#', data($x//aqd:protectionTarget/@xlink:href))
            where empty(index-of($validRows, $key)) and not(empty(index-of($xmlconv:MANDATORY_POLLUTANT_IDS_8, $pollutantCode))) and ($key != "EXC")
            return
                <tr>
                    <td title="AQD_AssessmentRegime">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:zone">{data($x//aqd:zone/@xlink:href)}</td>
                    <td title="aqd:pollutant">{data($x//aqd:pollutant/@xlink:href)}</td>
                    <td title="aqd:protectionTarget">{data($x//aqd:protectionTarget/@xlink:href)}</td>
                </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C28 If ./aqd:zone xlink:href shall be current, then ./AQD_zone/aqd:operationActivityPeriod/gml:endPosition shall be equal to “9999-12-31 23:59:59Z” or nulled (blank)  :)
let $C28invalid :=
    try {
        for $zone in $docRoot//aqd:zone[@xlink:href = '.']/aqd:AQD_Zone
        let $endPosition := normalize-space($zone/aqd:operationActivityPeriod/gml:endPosition)
        where upper-case($endPosition) != '9999-12-31 23:59:59Z' and $endPosition != ''
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:localId">{data($zone/../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId">{data($zone/am:inspireId/base:Identifier/base:localId)}</td>
                {html:getErrorTD(data($endPosition), "gml:endPosition", fn:true())}
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C31 :)
let $C31table :=
    try {
        let $C31ResultB :=
            for $i in sparqlx:run(query:getC31($latestenvelopeB))
            return
                <result>
                    <pollutantName>{string($i/sparql:binding[@name = "Pollutant"]/sparql:literal)}</pollutantName>
                    <protectionTarget>{string($i/sparql:binding[@name = "ProtectionTarget"]/sparql:uri)}</protectionTarget>
                    <count>{
                        let $x := string($i/sparql:binding[@name = "countOnB"]/sparql:literal)
                        return if ($x castable as xs:integer) then xs:integer($x) else 0
                    }</count>
                </result>

        let $C31tmp :=
            for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/
                    aqd:EnvironmentalObjective/aqd:protectionTarget[not(../string(aqd:objectiveType/@xlink:href) = ("http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO",
                    "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO"))]
            let $pollutant := string($x/../../../../../aqd:pollutant/@xlink:href)
            let $zone := string($x/../../../../../aqd:zone/@xlink:href)
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
        let $C31ResultC := filter:filterByName($C31tmp, "pollutantCode", (
            "1", "7", "8", "9", "5", "6001", "10", "20", "5012", "5018", "5014", "5015", "5029"
        ))
        let $errorTmp :=
            for $x in $C31ResultC
            let $vsName := string($x/pollutantName)
            let $vsCode := string($x/pollutantCode)
            let $protectionTarget := string($x/protectionTarget)
            let $countC := number($x/count)
            let $countB := number($C31ResultB[pollutantName = $vsName and protectionTarget = $protectionTarget]/count)
            return
                if ((string($countC), string($countB)) = "NaN") then $errors:ERROR
                else if ($countC > $countB) then $errors:ERROR
                else if ($countB > $countC) then $errors:WARNING
                else ()
        let $errorClass :=
            if (empty($C31ResultB)) then $errors:ERROR
            else if ($errorTmp = $errors:ERROR) then $errors:ERROR
            else if ($errorTmp = $errors:WARNING) then $errors:WARNING
            else $errors:INFO
        for $x in $C31ResultC
            let $vsName := string($x/pollutantName)
            let $vsCode := string($x/pollutantCode)
            let $protectionTarget := string($x/protectionTarget)
            let $countC := string($x/count)
            let $countB := string($C31ResultB[pollutantName = $vsName and protectionTarget = $protectionTarget]/count)
        order by $vsName
        return
            <tr class="{$errorClass}">
                <td title="Pollutant Name">{$vsName}</td>
                <td title="Pollutant Code">{$vsCode}</td>
                <td title="Protection Target">{$protectionTarget}</td>
                <td title="Count C">{$countC}</td>
                <td title="Count B">{$countB}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C32 - :)
let $C32table :=
    try {
        let $samplingPointSparqlC32 :=
            if (fn:string-length($countryCode) = 2) then
                query:getAssessmentTypeSamplingPoint($cdrUrl)
            else
                ""
        let $aqdSamplingPointAssessMEntTypes :=
            for $i in sparqlx:executeSparqlQuery($samplingPointSparqlC32)
            let $ii := concat($i/sparql:binding[@name = 'inspireLabel']/sparql:literal, "#", $i/sparql:binding[@name = 'assessmentType']/sparql:uri)
            return $ii

        let $modelSparql :=
            if (fn:string-length($countryCode) = 2) then
                query:getAssessmentTypeModel($cdrUrl)
            else
                ""
        let $aqdModelAssessMentTypes :=
            for $i in sparqlx:executeSparqlQuery($modelSparql)
            let $ii := concat($i/sparql:binding[@name = 'inspireLabel']/sparql:literal, "#", $i/sparql:binding[@name = 'assessmentType']/sparql:uri)
            return $ii

        let $allAssessmentTypes := ($aqdSamplingPointAssessMEntTypes, $aqdModelAssessMentTypes)
        for $sMetadata in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata
        let $id := string($sMetadata/@xlink:href)
        let $docType := string($sMetadata/../aqd:assessmentType/@xlink:href)
        where (not(xmlconv:isValidAssessmentTypeCombination($id, $docType, $allAssessmentTypes)))
        return
            <tr>
                <td title="AQD_AssessmentRegime">{string($sMetadata/../../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:samplingPointAssessmentMetadata">{$id}</td>
                <td title="aqd:assessmentType">{substring-after($docType, $vocabulary:ASSESSMENTTYPE_VOCABULARY)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
        

(: C33 If The lifecycle information of ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href shall be current,
    then /AQD_SamplingPoint/aqd:operationActivityPeriod/gml:endPosition or /AQD_ModelType/aqd:operationActivityPeriod/gml:endPosition shall be equal to “9999-12-31 23:59:59Z” or nulled (blank):)
let $C33invalid :=
    try {
        for $assessmentMetadata in $docRoot//aqd:assessmentMethods/aqd:AssessmentMethods/*[ends-with(local-name(), 'AssessmentMetadata') and @xlink:href = '.']

        let $endPosition :=
            if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                normalize-space($assessmentMetadata/aqd:AQD_Model/aqd:operationActivityPeriod/gml:endPosition)
            else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                normalize-space($assessmentMetadata/aqd:AQD_SamplingPoint/aqd:operationActivityPeriod/gml:endPosition)
            else
                ""
        where upper-case($endPosition) != '9999-12-31 23:59:59Z' and $endPosition != ''
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:localId">{data($assessmentMetadata/../../../aqd:inspireId/base:Identifier/base:localId)}</td>{
                if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id">{data($assessmentMetadata/aqd:AQD_Model/@gml:id)}</td>,
                    html:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
                    , <td title="aqd:AQD_SamplingPoint/ @gml:id"/>, <td title="gml:endPosition"/>)
                else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id"/>, <td title="gml:endPosition"/>,
                    <td title="aqd:AQD_SamplingPoint/ @gml:id">{data($assessmentMetadata/aqd:AQD_SamplingPoint/@gml:id)}</td>,
                    html:getErrorTD(data($endPosition), "gml:endPosition", fn:true())
                    )
                else
                    ()
            }
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: C35 /aqd:AQD_SamplingPoint/aqd:usedAQD or /aqd:AQD_ModelType/aqd:used shall EQUAL “true” for all ./aqd:assessmentMethods/aqd:AssessmentMethods/aqd:*AssessmentMetadata xlink:href citations :)
let $C35invalid :=
    try {
        for $assessmentMetadata in $docRoot//aqd:assessmentMethods/aqd:AssessmentMethods/*[ends-with(local-name(), 'AssessmentMetadata') and @xlink:href = '.']

        let $used :=
            if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                normalize-space($assessmentMetadata/aqd:AQD_Model/aqd:used)
            else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                normalize-space($assessmentMetadata/aqd:AQD_SamplingPoint/aqd:usedAQD)
            else
                ""

        where $used != 'true'
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:localId">{data($assessmentMetadata/../../../aqd:inspireId/base:Identifier/base:localId)}</td>{
                if ($assessmentMetadata/local-name() = 'modelAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id">{data($assessmentMetadata/aqd:AQD_Model/@gml:id)}</td>,
                    html:getErrorTD(data($used), "aqd:used", fn:true())
                    , <td title="aqd:AQD_SamplingPoint/ @gml:id"/>, <td title="aqd:usedAQD"/>)
                else if ($assessmentMetadata/local-name() = 'samplingPointAssessmentMetadata') then
                    (<td title="aqd:AQD_Model/ @gml:id"/>, <td title="aqd:used"/>,
                    <td title="aqd:AQD_SamplingPoint/ @gml:id">{data($assessmentMetadata/aqd:AQD_SamplingPoint/@gml:id)}</td>,
                    html:getErrorTD(data($used), "aqd:usedAQD", fn:true())
                    )
                else
                    ()
            }
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C37 - :)
let $C37invalid :=
    try {
        let $reportingMetric := $docRoot//aqd:AQD_AssessmentRegime[aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI"]/@gml:id
        return
            if (count($reportingMetric) > 1) then
                for $i in $reportingMetric
                return
                    <tr><td title="@gml:id">{string($i)}</td></tr>
            else
                ()
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C38 :)
let $C38invalid :=
    try {
        let $aqdSamplingPointID := if (fn:string-length($countryCode) = 2) then distinct-values(data(sparqlx:executeSparqlQuery(query:getSamplingPointInspireLabel($cdrUrl))//sparql:binding[@name = 'inspireLabel']/sparql:literal)) else ()

        let $aqdSamplingPointAssessmentMetadata :=
            for $aqdAssessmentRegime in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric
            where $aqdAssessmentRegime/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI"
            return $aqdAssessmentRegime/../../../../../aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata/fn:normalize-space(@xlink:href)

        for $x in $aqdSamplingPointAssessmentMetadata
        where empty(index-of($aqdSamplingPointID, $x))
        return
            <tr>
                <td title="">{$x}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C40 :)
let $C40invalid :=
    try {
        for $aqdPollutantC40 in $docRoot//aqd:AQD_AssessmentRegime
        let $pollutantXlinkC40 := fn:substring-after(data($aqdPollutantC40/aqd:pollutant/@xlink:href), "pollutant/")
        where not(empty(index-of($xmlconv:VALID_POLLUTANT_IDS_40, $pollutantXlinkC40))) and not((count($aqdPollutantC40/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:samplingPointAssessmentMetadata) >= 1
                or count($aqdPollutantC40/aqd:assessmentMethods/aqd:AssessmentMethods/aqd:modelAssessmentMetadata) >= 1))
        return
            <tr>
                <td title="@gml:id">{string($aqdPollutantC40/@gml:id)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C41 gml:timePosition MUST be provided and must be equal or greater than (aqd:reportingPeriod – 5 years) included in the ReportingHeader :)
let $C41invalid :=
    try {
        let $C41minYear := if ($reportingYear castable as xs:integer) then xs:integer($reportingYear) - 5 else ()
        for $x in $docRoot//aqd:AQD_AssessmentRegime[aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:classificationDate/gml:TimeInstant[gml:timePosition castable as xs:integer]/xs:integer(gml:timePosition) < $C41minYear]
        return
            <tr>
                <td title="aqd:AQD_AssessmentRegime/aqd:inspireId/base:Identifier/base:localId">{string($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title=""></td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: C42 - :)
let $C42invalid :=
    try {
        for $x in $docRoot//aqd:AQD_AssessmentRegime/aqd:assessmentThreshold/aqd:AssessmentThreshold/aqd:classificationReport
        where (string($x) = "") or (not(common:includesURL($x)))
        return
            <tr>
                <td title="base:localId">{$x/../../../aqd:inspireId/base:Identifier/base:localId}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

return
    <table class="maintable hover">
        {html:buildXML("XML", $labels:XML, $labels:XML_SHORT, $validationResult, "This XML passed validation.", "This XML file did NOT pass the XML validation", $errors:ERROR)}
        {html:buildExists("C0", $labels:C0, $labels:C0_SHORT, $C0invalid, "New Delivery for " || $reportingYear, "Updated Delivery for " || $reportingYear, $errors:WARNING)}
        {html:build1("C1", $labels:C1, $labels:C1_SHORT, $C1table, "", string(count($C1table)), "", "", $errors:ERROR)}
        {html:buildSimple("C2", $labels:C2, $labels:C2_SHORT, $C2table, "", "record", $C2errorLevel)}
        {html:buildSimple("C3", $labels:C3, $labels:C3_SHORT, $C3table, "", "record", $C3errorLevel)}
        {html:buildResultRows("C4", $labels:C4, $labels:C4_SHORT, $C4invalid, "@gml:id", "No duplicates found", " duplicate", "",$errors:ERROR)}
        {html:buildResultRows("C5", $labels:C5, $labels:C5_SHORT, $C5invalid, "base:localId", "No duplicates found", " duplicate", "",$errors:ERROR)}
        {html:buildResultRows("C6", $labels:C6, $labels:C6_SHORT, $C6table, "", string(count($C6table)), "", "",$errors:INFO)}
        {html:buildResultRows("C6.1", $labels:C6.1, $labels:C6.1_SHORT, $C6.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:buildResultRows("C7", $labels:C7, $labels:C7_SHORT, $C7invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C8", $labels:C8, $labels:C8_SHORT, $C8invalid, "", "All values are valid", " missing pollutant", "", $errors:ERROR)}
        {html:build0("C9", $labels:C9, $labels:C9_SHORT, $C9table, "", string(count($C9table)), "pollutant")}
        {html:buildResultRows("C10", $labels:C10, $labels:C10_SHORT, $C10invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C11", $labels:C11, $labels:C11_SHORT, $C11invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C12", $labels:C12, $labels:C12_SHORT, $C12invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C13", $labels:C13, $labels:C13_SHORT, $C13invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C14", $labels:C14, $labels:C14_SHORT, $C14invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C15", $labels:C15, $labels:C15_SHORT, $C15invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C16", $labels:C16, $labels:C16_SHORT, $C16invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C17", $labels:C17, $labels:C17_SHORT, $C17invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C18", $labels:C18, $labels:C18_SHORT, $C18invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C19", $labels:C19, $labels:C19_SHORT, $C19invalid, "aqd:reportingMetric", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:build2("C20", $labels:C20, $labels:C20_SHORT, $C20invalid, "", "All combinations have been found", "record", "", $errors:WARNING)}
        {html:buildResultRows("C21", $labels:C21, $labels:C21_SHORT, $C21invalid, "aqd:reportingMetric", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows("C23a", $labels:C23a, $labels:C23a_SHORT, $C23ainvalid, "aqd:AQD_AssesmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows("C23b", $labels:C23b, $labels:C23b_SHORT, $C23binvalid, "aqd:AQD_AssesmentRegime", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:build2("C24", $labels:C24, $labels:C24_SHORT, $C24invalid, "", "All values are valid", "", "", $errors:ERROR)}
        {html:build2("C25", $labels:C25, $labels:C25_SHORT, $C25invalid, "", "All values are valid", " ", "",$errors:ERROR)}
        {html:build2("C26", $labels:C26, $labels:C26_SHORT, $C26table, "", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:build2("C27", labels:interpolate($labels:C27, ($countZoneIds2, $countZoneIds1)), $labels:C27_SHORT, $C27table, "Count of unique zones matches", "", " not unique zone",  "", $errors:WARNING)}
        {html:buildResultRows("C28", $labels:C28, $labels:C28_SHORT, $C28invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:ERROR)}
        {html:build2("C29", $labels:C29, $labels:C29_SHORT,  $C29invalid, "", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:build2("C31", $labels:C31, $labels:C31_SHORT, $C31table, "", "", "record", "", errors:getMaxError($C31table))}
        {html:build2("C32", $labels:C32, $labels:C32_SHORT, $C32table, "", "All values are valid", " invalid value",  "", $errors:WARNING)}
        {html:buildResultRows("C33", $labels:C33, $labels:C33_SHORT, $C33invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows("C35", $labels:C35, $labels:C35_SHORT, $C35invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows("C37", $labels:C37, $labels:C37_SHORT, $C37invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows("C38", $labels:C38, $labels:C38_SHORT, $C38invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows("C40", $labels:C40, $labels:C40_SHORT, $C40invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows("C41", $labels:C41, $labels:C41_SHORT, $C41invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows("C42", $labels:C42, $labels:C42_SHORT, $C42invalid, "aqd:AQD_AssessmentRegime", "All values are valid", " invalid value", "",$errors:WARNING)}
    </table>
};

declare function xmlconv:buildItemsList($ruleId as xs:string, $vocabularyUrl as xs:string, $ids as xs:string*) as element(div) {
    let $list :=
        for $id in $ids
        let $refUrl := concat($vocabularyUrl, $id)
        return
            <p>{ $refUrl }</p>

    return
        <div>
            <a id='vocLink-{$ruleId}' href='javascript:toggleItem("vocValuesDiv","vocLink", "{$ruleId}", "combination")'>Show combinations</a>
            <div id="vocValuesDiv-{$ruleId}" style="display:none">{ $list }</div>
        </div>
};

declare function xmlconv:buildVocItemsList($ruleId as xs:string, $vocabularyUrl as xs:string, $ids as xs:string*) as element(div) {
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

declare function xmlconv:buildPollutantResultRows($ruleCode as xs:string,  $records as element(tr)*, $invalidMsg as xs:string, $errorLevel as xs:string) as element(tr)* {

    let $msg :=
        if (count($records) > 0) then
            "Assessment regime(s) not found for the following pollutant(s):"
        else
            "Assessment regimes reported for all expected pollutants"
    let $records := xmlconv:buildVocItemRows($vocabulary:POLLUTANT_VOCABULARY, $records)
    return
        html:buildResultRows($ruleCode, <span>{$msg}</span>, <span>{$msg}</span>, $records, "", "", " missing pollutant", "",$errors:WARNING)
};

declare function xmlconv:buildVocItemRows($vocabularyUrl as xs:string, $codes as xs:string*) as element(tr)* {
    for $code in $codes
    let $vocLink := concat($vocabularyUrl, $code)
    return
        <tr>
            <td title="Pollutant"><a href="{$vocLink}">{$vocLink}</a></td>
        </tr>
};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $doc := doc($source_url)
let $countZones := count($doc//aqd:AQD_AssessmentRegime)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url, $countryCode) else ()

return
    <div>
        <h2>Check air quality assessment regimes - Dataflow C</h2>
        {
        if ( $countZones = 0) then
            <p>No aqd:AQD_AssessmentRegime elements found from this XML.</p>
        else
        <div>
            {
                if ($result//div/@class = 'error') then
                    <p class="error" style="color:red"><strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[@class = 'error'], ',')}</strong></p>
                else
                    <p>This XML file passed all crucial checks.</p>
            }
            {
                if ($result//div/@class = 'warning') then
                    <p class="warning" style="color:orange"><strong>This XML file generated warnings during the following check(s): {string-join($result//div[@class = 'warning'], ',')}</strong></p>
                else
                    ()
            }
            <p>This check evaluated the delivery by executing tier-1 tests on air quality assessment regimes data in Dataflow C as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
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

declare function xmlconv:isValidAssessmentTypeCombination($id as xs:string, $type as xs:string, $allCombinations as xs:string*) as xs:boolean {
    let $typeInDoc := lower-case(substring-after($type, $vocabulary:ASSESSMENTTYPE_VOCABULARY))
    let $combination := concat($id, "#", $type)
    let $combinationFixed := concat($id, "#", $vocabulary:ASSESSMENTTYPE_VOCABULARY, "fixed")
    let $combinationIndicative := concat($id, "#", $vocabulary:ASSESSMENTTYPE_VOCABULARY, "indicative")
    let $combinationModel := concat($id, "#", $vocabulary:ASSESSMENTTYPE_VOCABULARY, "model")
    let $combinationObjective := concat($id, "#", $vocabulary:ASSESSMENTTYPE_VOCABULARY, "objective")
    
    let $combinationOk := 
        if ($typeInDoc = ("fixed", "model")) then
            if ($combination = $allCombinations) then
                true()
            else
                false()
        else if ($typeInDoc = "indicative") then
            if ($allCombinations = ($combinationFixed, $combinationIndicative)) then
                true()
            else
                false()
        else if ($typeInDoc = "objective") then
            if ($allCombinations = ($combinationFixed, $combinationIndicative, $combinationModel, $combinationObjective)) then
                true()
            else
                false()   
        else
            false()
    return $combinationOk
};