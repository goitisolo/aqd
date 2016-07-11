xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :
 : XQuery script implements dataflow M tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Juri Tõnisson
 : @author George Sofianos
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowM";
import module namespace common = "aqd-common" at "aqd_check_common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace ompr="http://inspire.ec.europa.eu/schemas/ompr/2.0";
declare namespace sams="http://www.opengis.net/samplingSpatial/2.0";
declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $xmlconv:FEATURE_TYPES := ("aqd:AQD_Model", "aqd:AQD_ModelProcess", "aqd:AQD_ModelArea");
declare variable $xmlconv:OBLIGATIONS as xs:string* := ("http://rod.eionet.europa.eu/obligations/672");

(: Rule implementations :)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
let $docRoot := doc($source_url)
let $reportingYear := common:getReportingYear($docRoot)
let $modelNamespaces := distinct-values($docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/base:namespace)
let $modelProcessNamespaces := distinct-values($docRoot//aqd:AQD_ModelProcess/ompr:inspireld/base:Identifier/base:namespace)
let $modelAreaNamespaces := distinct-values($docRoot//aqd:AQD_ModelArea/aqd:inspireId/base:Identifier/base:namespace)
let $namespaces := distinct-values($docRoot//base:namespace)
let $knownFeatures := distinct-values(data(sparqlx:executeSparqlQuery(query:getAllFeatureIds($xmlconv:FEATURE_TYPES, $namespaces))//sparql:binding[@name = 'inspireLabel']/sparql:literal))

let $MCombinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

(: M0 :)
let $M0invalid :=
    try {
        if (query:deliveryExists($xmlconv:OBLIGATIONS, $countryCode, $reportingYear)) then
            <tr>
                <td title="base:localId">{$docRoot//aqd:AQD_ReportingHeader/aqd:inspireId/base:Identifier/base:namespace/string()}</td>
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

(: M1 :)
let $countFeatureTypes :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        count(doc($source_url)//gml:featureMember/descendant::*[name()=$featureType])
let $M1table :=
    try {
        for $featureType at $pos in $xmlconv:FEATURE_TYPES
        where $countFeatureTypes[$pos] > 0
        return
            <tr>
                <td title="Feature type">{$featureType}</td>
                <td title="Total number">{$countFeatureTypes[$pos]}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M2 :)
let $M2table :=
    try {
        let $unknownZones :=
            for $zone in $MCombinations
            let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
            where empty(index-of($knownFeatures, $id))
            return $zone

        for $rec in $unknownZones
        return
            $rec/@gml:id
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M3 :)
let $M3table :=
    try {
        let $unknownZones :=
            for $zone in $MCombinations
            let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
            where empty(index-of($knownFeatures, $id)) = false()
            return $zone

        for $rec in $unknownZones
        return
            $rec/@gml:id
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M4 :)
let $M4table :=
    try {
        let $allM4Combinations :=
            for $aqdModel in $MCombinations
            return concat(data($aqdModel/@gml:id), "#", $aqdModel/ef:inspireId, "#", $aqdModel/ompr:inspireId, "#", $aqdModel/ef:name, "#", $aqdModel/ompr:name)

        let $allM4Combinations := fn:distinct-values($allM4Combinations)
        for $rec in $allM4Combinations
        let $modelType := substring-before($rec, "#")
        let $tmpStr := substring-after($rec, concat($modelType, "#"))
        let $inspireId := substring-before($tmpStr, "#")
        let $tmpInspireId := substring-after($tmpStr, concat($inspireId, "#"))
        let $aqdInspireId := substring-before($tmpInspireId, "#")
        let $tmpEfName := substring-after($tmpInspireId, concat($aqdInspireId, "#"))
        let $efName := substring-before($tmpEfName, "#")
        let $omprName := substring-after($tmpEfName, concat($efName, "#"))
        return
            <tr>
                <td title="gml:id">{common:checkLink($modelType)}</td>
                <td title="ef:inspireId">{common:checkLink($inspireId)}</td>
                <td title="ompr:inspireId">{common:checkLink($aqdInspireId)}</td>
                <td title="ef:name">{common:checkLink($efName)}</td>
                <td title="ompr:name">{common:checkLink($omprName)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M5 :)
(: TODO: FIX TRY CATCH CODE :)
let $gmlIds := $MCombinations/lower-case(normalize-space(@gml:id))
let $duplicateGmlIds := distinct-values(
        for $id in $MCombinations/@gml:id
        where string-length(normalize-space($id)) > 0 and count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
        return
            $id
)
let $amInspireIds := for $id in $MCombinations/ef:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateamInspireIds := distinct-values(
        for $id in $MCombinations/ef:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($amInspireIds, lower-case($key))) > 1
        return
            $key
)


let $aqdInspireIds := for $id in $MCombinations/ef:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateaqdInspireIds := distinct-values(
        for $id in $MCombinations/ef:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where  string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($aqdInspireIds, lower-case($key))) > 1
        return
            $key
)


let $countGmlIdDuplicates := count($duplicateGmlIds)
let $countamInspireIdDuplicates := count($duplicateamInspireIds)
let $countaqdInspireIdDuplicates := count($duplicateaqdInspireIds)
let $M5invalid := $countGmlIdDuplicates + $countamInspireIdDuplicates + $countaqdInspireIdDuplicates

(: M6 :)
let $M6invalid :=
    try {
        let $amInspireIds := $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
                lower-case(normalize-space(base:localId)))
        let $duplicateEUStationCode := distinct-values(
                for $identifier in $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier
                where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                        concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
                return
                    concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
        )
        let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
        return $countAmInspireIdDuplicates
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M7 :)
let $M7table :=
    try {
        for $id in $modelNamespaces
        let $localId := $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
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

(: M7.1 :)
let $M7.1invalid :=
    try {
        common:checkNamespaces($source_url)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M12 :)
let $M12invalid :=
    try {
        distinct-values($docRoot//aqd:AQD_Model[count(ef:geometry) >0 and ef:geometry/@srsName != "urn:ogc:def:crs:EPSG::4258" and ef:geometry/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M15 :)
let $M15invalid :=
    try {
        let $allNotNullEndPeriods :=
            for $allPeriod in $docRoot//aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
            where ($allPeriod/gml:endPosition[normalize-space(@indeterminatePosition) != "unknown"]
                    or fn:string-length($allPeriod/gml:endPosition) > 0)
            return $allPeriod

        for $observingCapabilityPeriod in $allNotNullEndPeriods
        where ((xs:dateTime($observingCapabilityPeriod/gml:endPosition) < xs:dateTime($observingCapabilityPeriod/gml:beginPosition)))
        return
            <tr>
                <td title="aqd:AQD_Model">{data($observingCapabilityPeriod/../../../../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($observingCapabilityPeriod/@gml:id)}</td>
                <td title="gml:beginPosition">{$observingCapabilityPeriod/gml:beginPosition}</td>
                <td title="gml:endPosition">{$observingCapabilityPeriod/gml:endPosition}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M18 :)
let $M18invalid :=
    try {
        xmlconv:checkVocabularyConceptValues($source_url, "ef:ObservingCapability", "ef:observedProperty", $vocabulary:POLLUTANT_VOCABULARY)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M19 :)
let $M19invalid :=
    try {
        let $aqdModelArea :=
            for $allModelArea in $docRoot//aqd:AQD_ModelArea
            return $allModelArea/@gml:id

        for $x in $docRoot//aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
        where empty(index-of($aqdModelArea, fn:normalize-space(fn:substring-after($x/@xlink:href, "/"))))
        return
            <tr>
                <td title="aqd:AQD_AQD_Model">{data($x/../../../@gml:id)}</td>
                <td title="ef:featureOfInterest">{data(fn:normalize-space(fn:substring-after($x/@xlink:href, "/")))}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M23 :)
let $M23invalid :=
    try {
        for $oPC in $docRoot//gml:featureMember/aqd:AQD_Model/aqd:environmentalObjective/aqd:EnvironmentalObjective
        where
            (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1" and
                    not(
                            (($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                    or
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                    or
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                                    or
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/wMean" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                            )
                    )
            )
                    or
                    ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/7" and
                            not(
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove-3yr" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c-5yr" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LTO" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AOT40c" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                            )
                    )
                    or

                    ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8" and
                            not(
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/hrsAbove" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                            ))
                    or
                    ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9" and
                            not(
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/CL" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/MO" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/NA" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/NA")
                            ))
                    or
                    ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5" and
                            not(
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                            )
                    )
                    or

                    ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/6001" and
                            not(
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/ECO" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/AEI" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S1")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H-S2")
                                            or
                                            ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                                    $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                                    $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                            )
                    )
                    or
                    ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/10" and
                            not(
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/daysAbove" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                            ))
                    or
                    (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012" or
                            ($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5012")) and
                            not(
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/LV" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                            ))
                    or
                    (($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5014" or
                            $oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5018" or
                            $oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5015" or
                            $oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5029") and
                            not(
                                    ($oPC/aqd:objectiveType/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/objectivetype/TV" and
                                            $oPC/aqd:reportingMetric/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/reportingmetric/aMean" and
                                            $oPC/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                            )
                    )
            )
        return
            <tr>
                <td title="gml:id">{data($oPC/../../@gml:id)}</td>
                <td title="ef:observedProperty">{data($oPC/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($oPC/aqd:objectiveType/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($oPC/aqd:reportingMetric/@xlink:href)}</td>
                <td title="aqd:objectiveType">{data($oPC/aqd:protectionTarget/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M24 :)
let $M24invalid :=
    try {
        $docRoot//aqd:AQD_Model/aqd:assessmentType[fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/model" and fn:normalize-space(@xlink:href) != "http://dd.eionet.europa.eu/vocabulary/aq/assessmenttype/objective"]/../@gml:id
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M25 :)
let $M25invalid :=
    try {
        let $allTrueUsedAQD :=
            for $trueUsedAQD in $docRoot//gml:featureMember/aqd:AQD_Model
            where $trueUsedAQD/aqd:usedAQD = true()
            return $trueUsedAQD

        for $invalidTrueUsedAQD in $allTrueUsedAQD
        where
            count(sparqlx:executeSparqlQuery(query:getSamplingPointAssessment($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:localId, $invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:namespace))/*) = 0
        return
            <tr>
                <td title="gml:id">{data($invalidTrueUsedAQD/@gml:id)}</td>
                <td title="base:localId">{data($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($invalidTrueUsedAQD/ef:inspireId/base:Identifier/base:namespace)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M26 Amended by Jaume Targa to add nilReason; also updated line 978 to pick $allInvalZoneXlinks :)
let $M26invalid :=
    try {
        for $invalidZoneXlinks in $docRoot//gml:featureMember/aqd:AQD_Model/aqd:zone
        where count(sparqlx:executeSparqlQuery(query:getSamplingPointZone($invalidZoneXlinks/@xlink:href))/*) = 0

        return if (not($invalidZoneXlinks/@nilReason = "inapplicable")) then
            (<tr>
                <td title="gml:id">{data($invalidZoneXlinks/../@gml:id)}</td>
                <td title="aqd:zone">{data($invalidZoneXlinks/@xlink:href)}</td>
            </tr>)
        else ()
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M27 - :)
let $M27invalid :=
    try {
        let $localModelProcessIds := $docRoot//gml:featureMember/aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier
        for $idModelProcessCode in $docRoot//gml:featureMember/aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier
        where
            count(index-of($localModelProcessIds/base:localId, normalize-space($idModelProcessCode/base:localId))) > 1 and
                    count(index-of($localModelProcessIds/base:namespace, normalize-space($idModelProcessCode/base:namespace))) > 1
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($idModelProcessCode/../../@gml:id)}</td>
                <td title="base:localId">{data($idModelProcessCode/base:localId)}</td>
                <td title="base:namespace">{data($idModelProcessCode/base:namespace)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M28 :)
let $M28table :=
    try {
        for $id in $modelProcessNamespaces
        let $localId := $docRoot//aqd:AQD_ModelProcess/ompr:inspireld/base:Identifier[base:namespace = $id]/base:localId
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

(: M29 :)
let $M29invalid :=
    try {
        for $baseLink in $docRoot//aqd:AQD_ModelProcess/ompr:documentation/base2:DocumentationCitation/base2:link
        let $invalidLink := fn:substring-before($baseLink, ":")
        where (fn:lower-case($invalidLink) != "http") and (fn:lower-case($invalidLink) != "https")
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($baseLink/../../../@gml:id)}</td>
                <td title="base2:link">{data($baseLink)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M39 :)
let $M39invalid :=
    try {
        for $dataQualityReport in $docRoot//aqd:AQD_ModelProcess/dataQualityReport
        let $invalidLink := fn:substring-before($dataQualityReport, ":")
        where (fn:lower-case($invalidLink) != "http") and (fn:lower-case($invalidLink) != "https")
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($dataQualityReport/../@gml:id)}</td>
                <td title="base2:link">{data($dataQualityReport)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M40 - :)
let $M40invalid :=
    try {
        let $localModelAreaIds := $docRoot//gml:featureMember/aqd:AQD_ModelArea/ompr:inspireId/base:Identifier
        for $idModelAreaCode in $docRoot//gml:featureMember/aqd:AQD_ModelArea/ompr:inspireId/base:Identifier
        where
            count(index-of($localModelAreaIds/base:localId, normalize-space($idModelAreaCode/base:localId))) > 1 and
                    count(index-of($localModelAreaIds/base:namespace, normalize-space($idModelAreaCode/base:namespace))) > 1
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($idModelAreaCode/../../@gml:id)}</td>
                <td title="base:localId">{data($idModelAreaCode/base:localId)}</td>
                <td title="base:namespace">{data($idModelAreaCode/base:namespace)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M41 - :)
let $M41table :=
    try {
        for $id in $modelAreaNamespaces
        let $localId := $docRoot//aqd:AQD_ModelArea/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
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

(: M43 :)
let $M43invalid :=
    try {
        distinct-values($docRoot//aqd:AQD_Sample[count(sams:shape) >0 and sams:shape/@srsName != "urn:ogc:def:crs:EPSG::4258" and sams:shape/@srsName != "urn:ogc:def:crs:EPSG::4326"]/@gml:id)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    return
    <table class="maintable hover">
        {html:buildExists("M0", $labels:M0, $labels:M0_SHORT, $M0invalid, "New Delivery", "Updated Delivery", $errors:WARNING)}
        {html:buildResultRows("M1", $labels:M1, $labels:M1_SHORT, $M1table, "", string(sum($countFeatureTypes)), "", "",$errors:ERROR)}
        {html:buildResultRows("M2", $labels:M2, $labels:M2_SHORT, (), "", string(count($M2table)), "", "",$errors:ERROR)}
        {html:buildResultRows("M3", $labels:M3, $labels:M3_SHORT, (), "", string(count($M3table)), "", "",$errors:ERROR)}
        {html:buildResultRows("M4", $labels:M4, $labels:M4_SHORT, $M4table, "", string(count($M4table)), "", "",$errors:ERROR)}
        {html:buildCountRow("M5", $labels:M5, $labels:M5_SHORT, $M5invalid,  (), "duplicate", ())}
        {html:buildConcatRow($duplicateGmlIds, "aqd:AQD_Model/@gml:id -")}
        {html:buildConcatRow($duplicateamInspireIds, "am:inspireId - ")}
        {html:buildConcatRow($duplicateaqdInspireIds, "aqd:inspireId - ")}
        {html:buildCountRow("M6", $labels:M6, $labels:M6_SHORT, $M6invalid, (), (), ())}
        {html:buildResultRows("M7", $labels:M7, $labels:M7_SHORT, $M7table, "", string(count($M7table)), "", "",$errors:ERROR)}
        {html:buildResultRows("M7.1", $labels:M7.1, $labels:M7.1_SHORT, $M7.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:buildResultRows("M12", $labels:M12, $labels:M12_SHORT, $M12invalid, "aqd:AQD_Model/@gml:id","All srsName attributes are valid"," invalid attribute","",$errors:ERROR)}
        {html:buildResultRows("M15", $labels:M15, $labels:M15_SHORT, $M15invalid, "", concat(fn:string(count($M15invalid))," errors found"), "", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_M("M18", $labels:M18, $labels:M18_SHORT, $M18invalid, "ef:observedProperty", "", "", "", $errors:ERROR)}
        {html:buildResultRows("M19", $labels:M19, $labels:M19_SHORT, $M19invalid,"aqd:AQD_Model/@gml:id", "All attributes is invalid", " invalid attribute", "",$errors:WARNING)}
        {html:buildResultRows("M23", $labels:M23, $labels:M23_SHORT, $M23invalid, "", concat(fn:string(count($M23invalid))," errors found"), "", "",$errors:ERROR)}
        {html:buildResultRows("M24", $labels:M24, $labels:M24_SHORT, $M24invalid, "", concat(fn:string(count($M24invalid))," errors found"), "", "",$errors:ERROR)}
        {html:buildResultRows("M25", $labels:M25, $labels:M25_SHORT, $M25invalid, "", concat(fn:string(count($M25invalid))," errors found"), "", "",$errors:WARNING)}
        {html:buildResultRows("M26", $labels:M26, $labels:M26_SHORT, $M26invalid, "", concat(fn:string(count($M26invalid))," errors found"), "", "",$errors:ERROR)}
        {html:buildResultRows("M27", $labels:M27, $labels:M27_SHORT, $M27invalid, "", concat(string(count($M27invalid))," errors found.") , "", "",$errors:ERROR)}
        {html:buildResultRows("M28", $labels:M28, $labels:M28_SHORT, $M28table, "", string(count($M28table)), "", "",$errors:ERROR)}
        {html:buildResultRows("M29", $labels:M29, $labels:M29_SHORT, $M29invalid, "aqd:AQD_ModelProcess/@gml:id","All attributes are valid"," invalid attribute", "",$errors:ERROR)}
        {html:buildResultRows("M39", $labels:M39, $labels:M39_SHORT, $M39invalid, "aqd:AQD_ModelProcess/@gml:id","All attributes are valid"," invalid attribute", "",$errors:ERROR)}
        {html:buildResultRows("M40", $labels:M40, $labels:M40_SHORT, $M40invalid, "", concat(string(count($M40invalid))," errors found.") , "", "",$errors:ERROR)}
        {html:buildResultRows("M41", $labels:M41, $labels:M41_SHORT, $M41table, "", string(count($M41table)), "", "",$errors:ERROR)}
        {html:buildResultRows("M43", $labels:M43, $labels:M43_SHORT, $M43invalid, "aqd:AQD_ModelArea/@gml:id","All srsDimension attributes are valid"," invalid attribute", "",$errors:ERROR)}
    </table>
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string) as element(tr)* {
    xmlconv:checkVocabularyConceptValues($source_url, $featureType, $element, $vocabularyUrl, "")
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                query:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                query:getConceptUrlSparqlB($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0

        return
            <tr isvalid="{xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl)}">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{$element}" style="color:red">{$conceptUrl}</td>
            </tr>
        else
            ()
};

declare function xmlconv:checkVocabularyConceptValues2($source_url as xs:string, $concept , $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                query:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                query:getConceptUrlSparqlB($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in $concept/ancestor::*[name()=$featureType]
        for $conceptUrl in $concept
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0

        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
        else
            ()
};

declare function xmlconv:checkVocabularyConceptValues3($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                query:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                query:getConceptUrlSparqlB($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]
        where  not(xmlconv:isMatchingVocabCode($crConcepts, normalize-space($conceptUrl/@xlink:href)))
        return
            $conceptUrl
        else
            ()
};


declare function xmlconv:checkVocabularyaqdAnalyticalTechniqueValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if(doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                query:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                query:getConceptUrlSparqlB($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]/aqd:AnalyticalTechnique/child::*[name() = $element]/@xlink:href
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0
        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
        else
            ()
};


declare function xmlconv:checkVocabularyConceptEquipmentValues($source_url as xs:string,  $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                query:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                query:getConceptUrlSparqlB($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]/*/aqd:equipment/@xlink:href
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0
        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="ef:name">{data($rec/ef:name)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};
declare function xmlconv:checkMeasurementMethodLinkValues($source_url as xs:string,  $concept,$featureType as xs:string,  $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                query:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                query:getConceptUrlSparqlB($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $conceptUrl in $concept/../../aqd:measurementMethod/aqd:MeasurementMethod/aqd:measurementMethod/@xlink:href
            let $measurementMethodStyle := if(xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl))then "" else "color:red"
            let $analyticalTechniqueStyle := if(count($conceptUrl/../../../../*[name(.) = "aqd:analyticalTechnique"])=0)then "" else "color:red"
            let $samplingMethod := if(count($conceptUrl/../../../../*[name(.) = "aqd:samplingMethod"])=0)then "" else "color:red"
        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) and count($conceptUrl/../../../../*[name(.) = "aqd:analyticalTechnique"])=0  and count($conceptUrl/../../../../*[name(.) = "aqd:samplingMethod"])=0}">
                <td title="gml:id">{data($conceptUrl/../../../../@gml:id)}</td>
                <td style="{$measurementMethodStyle}" title="{name($conceptUrl/..)}" >{data($conceptUrl)}</td>
                <td style="{$analyticalTechniqueStyle}" title=" aqd:analyticalTechnique " >{if(count($conceptUrl/../../../../*[name(.) = "aqd:analyticalTechnique"])=0)then "Valid." else "Error, shall not be provided."}</td>
                <td style="{$samplingMethod}" title=" aqd:samplingMethod " >{if(count($conceptUrl/../../../../*[name(.) = "aqd:samplingMethod"])=0)then "Valid." else "Error, shall not be provided."}</td>
            </tr>
    else
        ()
};

declare function xmlconv:isMatchingVocabCode($crConcepts as element(sparql:result)*, $concept as xs:string) as xs:boolean {
    count($crConcepts/sparql:binding[@name="concepturl" and sparql:uri=$concept]) > 0
};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countFeatures := count(doc($source_url)//gml:featureMember/descendant::*[
    not(empty(index-of($xmlconv:FEATURE_TYPES, name())))]
    )
let $result := if ($countFeatures > 0) then xmlconv:checkReport($source_url, $countryCode) else ()

return
    <div>
        <h2>Check environmental monitoring feature types - Dataflow D on Models and Objective Estimation</h2>
        {
        if ( $countFeatures = 0) then
            <p>No environmental monitoring feature type elements ({string-join($xmlconv:FEATURE_TYPES, ", ")}) found from this XML.</p>
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
            <p>This feedback report provides a summary overview of feature types reported and some consistency checks defined in Dataflow D on Models and Objective Estimation as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
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
                <p>Click on the "{$labels:SHOWRECORDS}" link to see more details about the test result.</p>
            </fieldset>
            <h3>Test results</h3>
            {$result}
        </div>
        }
    </div>
};