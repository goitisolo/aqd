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
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";

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
declare namespace adms="http://www.w3.org/ns/adms#";
declare namespace prop = "http://dd.eionet.europa.eu/property/";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";

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
(: INFO: XML Validation check. This adds delay to the running scripts :)
let $validationResult := schemax:validateXmlSchema($source_url)

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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M0 :)
let $M0table :=
    try {
        if ($reportingYear = "") then
            <tr class="{$errors:ERROR}">
                <td title="Status">Reporting Year is missing.</td>
            </tr>
        else if (query:deliveryExists($xmlconv:OBLIGATIONS, $countryCode, "d/", $reportingYear)) then
            <tr class="{$errors:WARNING}">
                <td title="Status">Updating delivery for {$reportingYear}</td>
            </tr>
        else if (query:deliveryExists($xmlconv:OBLIGATIONS, $countryCode, "d1b/", $reportingYear)) then
            <tr class="{$errors:WARNING}">
                <td title="Status">Updating delivery for {$reportingYear}</td>
            </tr>
        else
            <tr class="{$errors:INFO}">
                <td title="Status">New delivery for {$reportingYear}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $isNewDelivery := errors:getMaxError($M0table) = $errors:INFO

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
        for $x in $MCombinations
        let $id := if (empty($x/@gml:id)) then "" else data($x/@gml:id)
        where empty(index-of($knownFeatures, $id))
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M3 :)
let $M3table :=
    try {
        for $x in $MCombinations
        let $id := if (empty($x/@gml:id)) then "" else data($x/@gml:id)
        where empty(index-of($knownFeatures, $id)) = false()
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
            </tr>
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
            return $aqdModel/ef:inspireId/base:Identifier/base:localId || "#" || $aqdModel/ompr:inspireId/base:Identifier/base:localId || "#" || $aqdModel/aqd:inspireId/base:Identifier/base:localId || "#" || $aqdModel/ef:name || "#" || $aqdModel/ompr:name

        let $allM4Combinations := fn:distinct-values($allM4Combinations)
        for $x in $allM4Combinations
        let $tokens := tokenize($x, "#")
        return
            <tr>
                <td title="ef:inspireId">{common:checkLink($tokens[1])}</td>
                <td title="ompr:inspireId">{common:checkLink($tokens[2])}</td>
                <td title="aqd:inspireId">{common:checkLink($tokens[3])}</td>
                <td title="ef:name">{common:checkLink($tokens[4])}</td>
                <td title="ompr:name">{common:checkLink($tokens[5])}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M5 :)
(: TODO: FIX TRY CATCH CODE :)
let $all1 := $MCombinations/lower-case(normalize-space(@gml:id))
let $part1 := distinct-values(
        for $id in $MCombinations/@gml:id
        where string-length(normalize-space($id)) > 0 and count(index-of($all1, lower-case(normalize-space($id)))) > 1
        return
            $id
)
let $part1 :=
    for $x in $part1
    return
        <tr>
            <td title="Duplicate records">@gml:id {$x}</td>
        </tr>
let $all2 := for $id in $MCombinations/ef:inspireId
return lower-case("[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]")

let $part2 := distinct-values(
        for $id in $MCombinations/ef:inspireId
        let $key := "[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]"
        where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($all2, lower-case($key))) > 1
        return
            $key
)
let $part2 :=
    for $x in $part2
    return
        <tr>
            <td title="Duplicate records">ef:inspireId {$x}</td>
        </tr>


let $all3 := for $id in $MCombinations/am:inspireId
return lower-case("[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]")
let $part3 := distinct-values(
        for $id in $MCombinations/am:inspireId
        let $key := "[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]"
        where  string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($all3, lower-case($key))) > 1
        return
            $key
)
let $part3 :=
    for $x in $part3
    return
        <tr>
            <td title="Duplicate records">am:inspireId {$x}</td>
        </tr>
let $all4 := for $id in $MCombinations/aqd:inspireId
return lower-case("[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]")
let $part4 := distinct-values(
        for $id in $MCombinations/aqd:inspireId
        let $key := "[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]"
        where  string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($all3, lower-case($key))) > 1
        return
            $key
)
let $part4 :=
    for $x in $part4
    return
        <tr>
            <td title="Duplicate records">aqd:inspireId {$x}</td>
        </tr>

let $M5invalid := $part1 + $part2 + $part3 + $part4

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
        common:checkNamespaces($docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/base:namespaces, $countryCode)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M8 aqd:AQD_Model/ef:name shall return a string :)
let $M8invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Model[string(ef:name) = ""]
        return
            <tr>
                <td title="base:localId">{string($x/ef:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
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
        for $x in $docRoot//aqd:AQD_Model
        let $xlink := data($x/ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href)
        where not($xlink = $dd:VALIDPOLLUTANTS) or (count(distinct-values($xlink)) > 1)
        return
            <tr>
                <td title="aqd:AQD_Model">{data($x/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:observedProperty">{$xlink}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M19 :)
let $M19invalid :=
    try {
        let $all := data($docRoot//aqd:AQD_ModelArea/aqd:inspireId/base:Identifier/concat(base:namespace, "/", base:localId))

        for $x in $docRoot//aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
        let $xlink := data($x/@xlink:href)
        where not($xlink = $all)
        return
            <tr>
                <td title="aqd:AQD_Model">{data($x/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:featureOfInterest">{$xlink}</td>
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
        let $all :=
            for $x in doc($vocabulary:ENVIRONMENTALOBJECTIVE || "rdf")//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE]
            return $x/prop:relatedPollutant/@rdf:resource || "#" || $x/prop:hasObjectiveType/@rdf:resource || "#" || $x/prop:hasReportingMetric/@rdf:resource || "#" || $x/prop:hasProtectionTarget/@rdf:resource

        for $x in $docRoot//aqd:AQD_Model
        let $pollutant := $x/ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href
        let $objectiveType := $x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href
        let $reportingMetric := $x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href
        let $protectionTarget := $x/aqd:environmentalObjective/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href
        let $combination := $pollutant || "#" || $objectiveType || "#" || $reportingMetric || "#" || $protectionTarget
        where not($combination = $all)
        return
            <tr>
                <td title="aqd:AQD_Model">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="Pollutant">{data($pollutant)}</td>
                <td title="ReportingMetric">{data($reportingMetric)}</td>
                <td title="ProtectionTarget">{data($protectionTarget)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: M24 :)
let $M24invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Model/aqd:assessmentType
        let $xlink := data($x/@xlink:href)
        where not($xlink = $vocabulary:ASSESSMENTTYPE_VOCABULARY || "model") and not($xlink = $vocabulary:ASSESSMENTTYPE_VOCABULARY || "objective")
        return
            <tr>
                <td title="aqd:AQD_Model">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:assessmentType">{$xlink}</td>
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
        for $invalidZoneXlinks in $docRoot//aqd:AQD_Model/aqd:zone
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
        let $localModelProcessIds := $docRoot//aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier
        for $idModelProcessCode in $docRoot//aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier
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

(: M28 :)
let $M28.1invalid :=
    try {
        common:checkNamespaces($docRoot//aqd:AQD_ModelProcess/ef:inspireId/base:Identifier/base:namespaces, $countryCode)
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

(: M30 :)
let $M30invalid :=
    try {
        for $x in $docRoot//aqd:AQD_ModelProcess[string(ompr:name) = ""]
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($x/ompr:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: M34 :)
let $M34invalid :=
    try {
        for $x in $docRoot//aqd:AQD_ModelProcess[string(aqd:description) = ""]
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($x/ompr:inspireId/base:Identifier/base:localId)}</td>
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
        let $localModelAreaIds := $docRoot//aqd:AQD_ModelArea/ompr:inspireId/base:Identifier
        for $idModelAreaCode in $docRoot//aqd:AQD_ModelArea/ompr:inspireId/base:Identifier
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

(: M41 :)
let $M41.1invalid :=
    try {
        common:checkNamespaces($docRoot//aqd:AQD_ModelArea/ef:inspireId/base:Identifier/base:namespaces, $countryCode)
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
        {html:buildXML("XML", $labels:XML, $labels:XML_SHORT, $validationResult, "This XML passed validation.", "This XML file did NOT pass the XML validation", $errors:ERROR)}
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "", "All values are valid", "record", "", $errors:WARNING)}
        {html:build3("M0", $labels:M0, $labels:M0_SHORT, $M0table, string($M0table/td), errors:getMaxError($M0table))}
        {html:build2("M1", $labels:M1, $labels:M1_SHORT, $M1table, "", string(sum($countFeatureTypes)), "record", "",$errors:ERROR)}
        {html:build2("M2", $labels:M2, $labels:M2_SHORT, $M2table, "", string(count($M2table)), "record", "",$errors:ERROR)}
        {html:build2("M3", $labels:M3, $labels:M3_SHORT, $M3table, "", string(count($M3table)), "record", "",$errors:ERROR)}
        {html:build2("M4", $labels:M4, $labels:M4_SHORT, $M4table, "", string(count($M4table)), "record", "", $errors:INFO)}
        {html:build2("M5", $labels:M5, $labels:M5_SHORT, $M5invalid,  "", "All values are valid", "record", "", $errors:ERROR)}
        {html:buildUnique("M7", $labels:M7, $labels:M7_SHORT, $M7table, "", string(count($M7table)), "namespace", $errors:ERROR)}
        {html:build2("M7.1", $labels:M7.1, $labels:M7.1_SHORT, $M7.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:build2("M8", $labels:M8, $labels:M8_SHORT, $M8invalid, "", "All values are valid", "record", "", $errors:ERROR)}
        {html:build2("M15", $labels:M15, $labels:M15_SHORT, $M15invalid, "", concat(fn:string(count($M15invalid))," errors found"), "", "", $errors:ERROR)}
        {html:build2("M18", $labels:M18, $labels:M18_SHORT, $M18invalid, "ef:observedProperty", "All values are valid", "record", "", $errors:ERROR)}
        {html:build2("M19", $labels:M19, $labels:M19_SHORT, $M19invalid,"", "All values are valid", " invalid attribute", "", $errors:ERROR)}
        {html:build2("M23", $labels:M23, $labels:M23_SHORT, $M23invalid, "", "All values are valid", "record", "", $errors:ERROR)}
        {html:build2("M24", $labels:M24, $labels:M24_SHORT, $M24invalid, "", "All values are valid", "record", "", $errors:ERROR)}
        {html:build2("M26", $labels:M26, $labels:M26_SHORT, $M26invalid, "", concat(fn:string(count($M26invalid))," errors found"), "record", "", $errors:ERROR)}
        {html:build2("M27", $labels:M27, $labels:M27_SHORT, $M27invalid, "", concat(string(count($M27invalid))," errors found.") , "record", "", $errors:ERROR)}
        {html:buildUnique("M28", $labels:M28, $labels:M28_SHORT, $M28table, "", string(count($M28table)), "namespace", $errors:ERROR)}
        {html:build2("M28.1", $labels:M28.1, $labels:M28.1_SHORT, $M28.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:build2("M29", $labels:M29, $labels:M29_SHORT, $M29invalid, "aqd:AQD_ModelProcess/@gml:id","All attributes are valid"," invalid attribute", "", $errors:ERROR)}
        {html:build2("M30", $labels:M30, $labels:M30_SHORT, $M30invalid, "","All attributes are valid","record", "", $errors:WARNING)}
        {html:build2("M34", $labels:M34, $labels:M34_SHORT, $M34invalid, "","All attributes are valid","record", "", $errors:WARNING)}
        {html:build2("M39", $labels:M39, $labels:M39_SHORT, $M39invalid, "aqd:AQD_ModelProcess/@gml:id","All attributes are valid"," invalid attribute", "", $errors:ERROR)}
        {html:build2("M40", $labels:M40, $labels:M40_SHORT, $M40invalid, "", concat(string(count($M40invalid))," errors found.") , "record", "", $errors:ERROR)}
        {html:buildUnique("M41", $labels:M41, $labels:M41_SHORT, $M41table, "", string(count($M41table)), "namespace", $errors:ERROR)}
        {html:build2("M41.1", $labels:M41.1, $labels:M41.1_SHORT, $M41.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:build2("M43", $labels:M43, $labels:M43_SHORT, $M43invalid, "aqd:AQD_ModelArea/@gml:id","All srsDimension attributes are valid"," invalid attribute", "", $errors:ERROR)}
    </table>
};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countFeatures := count(doc($source_url)//descendant::*[
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