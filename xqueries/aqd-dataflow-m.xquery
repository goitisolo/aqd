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

module namespace dataflowM = "http://converters.eionet.europa.eu/dataflowM";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
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

declare variable $dataflowM:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $dataflowM:FEATURE_TYPES := ("aqd:AQD_Model", "aqd:AQD_ModelProcess", "aqd:AQD_ModelArea");
declare variable $dataflowM:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "672", $vocabulary:ROD_PREFIX || "742");

(: Rule implementations :)
declare function dataflowM:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

let $ms1Total := prof:current-ms()  
let $ms1GeneralParameters:= prof:current-ms()
  
let $docRoot := doc($source_url)
let $cdrUrl := common:getCdrUrl($countryCode)
let $reportingYear := common:getReportingYear($docRoot)

let $latestEnvelopeB := query:getLatestEnvelope($cdrUrl || "b/")
let $latestEnvelopeD1b := query:getLatestEnvelope($cdrUrl || "d1b/")

let $modelNamespaces := distinct-values($docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/base:namespace)
let $modelProcessNamespaces := distinct-values($docRoot//aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier/base:namespace)
let $modelAreaNamespaces := distinct-values($docRoot//aqd:AQD_ModelArea/aqd:inspireId/base:Identifier/base:namespace)
let $namespaces := distinct-values($docRoot//base:namespace)
let $knownFeatures := distinct-values(data(sparqlx:run(query:getAllFeatureIds($dataflowM:FEATURE_TYPES, $latestEnvelopeD1b, $namespaces))//sparql:binding[@name = 'inspireLabel']/sparql:literal))

let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition

let $MCombinations :=
    for $featureType in $dataflowM:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

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

(: M0 :)
let $ms1M0 := prof:current-ms()
let $M0table :=
    try {
        if ($reportingYear = "") then
            <tr class="{$errors:ERROR}">
                <td title="Status">Reporting Year is missing.</td>
            </tr>
        else if($headerBeginPosition > $headerEndPosition) then
            <tr class="{$errors:BLOCKER}">
                <td title="Status">Start position must be less than end position</td>
            </tr>
        else if (query:deliveryExists($dataflowM:OBLIGATIONS, $countryCode, "d/", $reportingYear)) then
            <tr class="{$errors:WARNING}">
                <td title="Status">Updating delivery for {$reportingYear}</td>
            </tr>
        else if (query:deliveryExists($dataflowM:OBLIGATIONS, $countryCode, "d1b/", $reportingYear)) then
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
       
let $isNewDelivery := errors:getMaxError($M0table) = $errors:INFO

let $ms2M0 := prof:current-ms() 

(: M01 :)
let $countFeatureTypes :=
    for $featureType in $dataflowM:FEATURE_TYPES
    return
        count(doc($source_url)//gml:featureMember/descendant::*[name()=$featureType])        
let $ms1M01 := prof:current-ms()        
let $M01table :=
    try {
        for $featureType at $pos in $dataflowM:FEATURE_TYPES
        let $errorClass :=
            if ($countFeatureTypes[$pos] > 0) then
                $errors:INFO
            else
                $errors:M01
        return
            <tr class="{$errorClass}">
                <td title="Feature type">{$featureType}</td>
                <td title="Total number">{$countFeatureTypes[$pos]}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M01 := prof:current-ms() 

(: M02 - :)
let $ms1M02 := prof:current-ms() 
let $M02table :=
    try {
        for $featureType at $pos in $dataflowM:FEATURE_TYPES
        let $countAll := count($docRoot//descendant::*[name()=$featureType])
        let $count := count(
                for $x in $docRoot//descendant::*[name()=$featureType]
                let $inspireId := $x//base:Identifier/base:namespace/string() || "/" || $x//base:Identifier/base:localId/string()
                where ($inspireId = "/" or not($knownFeatures = $inspireId))
                return
                    <tr>
                        <td title="base:localId">{$x//base:Identifier/base:localId/string()}</td>
                    </tr>)
        let $errorClass :=
            if ($countAll = $count or $count = 0) then
                $errors:WARNING
            else
                $errors:INFO
        return
            <tr class="{$errorClass}">
                <td title="Feature type">{$featureType}</td>
                <td title="Total number">{$count}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
    
let $M02count :=
    try {
        string(sum($M02table/td[2]))
    } catch * {
        "NaN"
    }
    
let $ms2M02 := prof:current-ms()    

(: M03 - :)
let $ms1M03 := prof:current-ms()
let $M03table :=
    try {
        let $featureTypes := $dataflowM:FEATURE_TYPES
        for $featureType at $pos in $featureTypes
        let $count := count(
                for $x in $docRoot//descendant::*[name()=$featureType]
                let $inspireId := $x//base:Identifier/base:namespace/string() || "/" || $x//base:Identifier/base:localId/string()
                where ($knownFeatures = $inspireId)
                return
                    <tr>
                        <td title="Feature type">{string($x/name())}</td>
                        <td title="base:localId">{$x//base:Identifier/base:localId/string()}</td>
                    </tr>)
        let $errorClass :=
            if ($count = 0) then
                $errors:WARNING
            else
                $errors:INFO
        return
            <tr class="{$errorClass}">
                <td title="Feature type">{$featureType}</td>
                <td title="Total number">{$count}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $M03count :=
    try {
        string(sum($M03table/td[2]))
    } catch * {
        "NaN"
    }
let $ms2M03 := prof:current-ms()    

(: M04 :)
let $ms1M04 := prof:current-ms()
let $M04table :=
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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M04 := prof:current-ms()

(: M05 :)
(: TODO: FIX TRY CATCH CODE :)
let $ms1M05 := prof:current-ms()
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

let $M05invalid := ($part1, $part2, $part3, $part4)
let $ms2M05 := prof:current-ms()

(: M06 - ./ef:inspireId/base:Identifier/base:localId shall be an unique code for AQD_Model and unique within the namespace.
 It is recommended to start with “MOD” and may include ISO2-country code (e.g.: MOD-ES0001) :)
let $ms1M06 := prof:current-ms()
let $M06invalid :=
    try {
        let $all := $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/concat(base:namespace, base:localId)
        for $x in $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier
        let $namespace := string($x/base:namespace)
        let $localId := string($x/base:localId)
        let $count := count(index-of($all, $namespace || $localId))
        where $count > 1
        return
            <tr>
                <td title="base:namespace">{$namespace}</td>
                <td title="base:localId">{$localId}</td>
                <td title="Count">{$count}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M06 := prof:current-ms()

(: M07 :)
let $ms1M07 := prof:current-ms()
let $M07table :=
    try {
        for $id in $modelNamespaces
        let $localId := $docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
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
let $ms2M07 := prof:current-ms()

(: M07.1 :)
let $ms1M07.1 := prof:current-ms()
let $M07.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//aqd:AQD_Model/ef:inspireId/base:Identifier/base:namespaces)
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
let $ms2M07.1 := prof:current-ms()

(: M08 aqd:AQD_Model/ef:name shall return a string :)
let $ms1M08 := prof:current-ms()
let $M08invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Model[string(ef:name) = ""]
        return
            <tr>
                <td title="base:localId">{string($x/ef:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }
let $ms2M08 := prof:current-ms()

(: M15 :)
let $ms1M15 := prof:current-ms()
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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M15 := prof:current-ms()

(: M18 :)
let $ms1M18 := prof:current-ms()
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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M18 := prof:current-ms()

(: M19 :)
let $ms1M19 := prof:current-ms()
let $M19invalid :=
    try {
        let $all := data($docRoot//aqd:AQD_ModelArea/aqd:inspireId/base:Identifier/concat(base:namespace, "/", base:localId))

        for $x in $docRoot//aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
        let $xlink := data($x/@xlink:href)
        where not($xlink = $all)
        return
            <tr>
                <td title="aqd:AQD_Model">{data($x/../../../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:featureOfInterest">{$xlink}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M19 := prof:current-ms()

(: M20 :)
let $ms1M20 := prof:current-ms()
let $M20invalid :=
    try {
        let $all := $docRoot//aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier/concat(base:namespace, "/", base:localId)
        for $x in $docRoot//aqd:AQD_Model/ef:observingCapability/ef:ObservingCapability/ef:procedure
        let $xlink := data($x/@xlink:href)
        where not($xlink = $all)
        return
            <tr>
                <td title="aqd:AQD_Model">{data($x/../../../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:procedure">{$xlink}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M20 := prof:current-ms()

(: M23 :)
let $ms1M23 := prof:current-ms()
let $M23invalid :=
    try {
        let $exceptions := ($vocabulary:OBJECTIVETYPE_VOCABULARY || "MO")
        let $all :=
            for $x in doc($vocabulary:ENVIRONMENTALOBJECTIVE || "rdf")//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE]
            return $x/prop:relatedPollutant/@rdf:resource || "#" || $x/prop:hasObjectiveType/@rdf:resource || "#" || $x/prop:hasReportingMetric/@rdf:resource || "#" || $x/prop:hasProtectionTarget/@rdf:resource

        for $x in $docRoot//aqd:AQD_Model
        for $z in $x/ef:observingCapability
        for $y in $x/aqd:environmentalObjective
        let $pollutant := $z/ef:ObservingCapability/ef:observedProperty/@xlink:href
        let $objectiveType := $y/aqd:EnvironmentalObjective/aqd:objectiveType/@xlink:href
        let $reportingMetric := $y/aqd:EnvironmentalObjective/aqd:reportingMetric/@xlink:href
        let $protectionTarget := $y/aqd:EnvironmentalObjective/aqd:protectionTarget/@xlink:href
        let $combination := $pollutant || "#" || $objectiveType || "#" || $reportingMetric || "#" || $protectionTarget
        where not($objectiveType = $exceptions) and not($combination = $all)
        return
            <tr>
                <td title="aqd:AQD_Model">{data($x/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="Pollutant">{data($pollutant)}</td>
                <td title="ObjectiveType">{data($objectiveType)}</td>
                <td title="ReportingMetric">{data($reportingMetric)}</td>
                <td title="ProtectionTarget">{data($protectionTarget)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M23 := prof:current-ms()

(: M24 :)
let $ms1M24 := prof:current-ms()
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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M24 := prof:current-ms()

(: M26 :)
let $ms1M26 := prof:current-ms()
let $M26invalid :=
    try {
        let $all := data(sparqlx:run(query:getZone($latestEnvelopeB))//sparql:binding[@name = 'inspireLabel']/sparql:literal)
        for $x in $docRoot//aqd:AQD_Model/aqd:zone
        let $xlink := data($x/@xlink:href)
        where not($x/@nilReason = "inapplicable") and not($xlink = $all)
        return
            <tr>
                <td title="gml:id">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:zone">{$xlink}</td>
                <td title="Sparql">{sparqlx:getLink(query:getZone($latestEnvelopeB))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M26 := prof:current-ms()

(: M27 - :)
let $ms1M27 := prof:current-ms()
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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M27 := prof:current-ms()

(: M28 :)
let $ms1M28 := prof:current-ms()
let $M28table :=
    try {
        for $id in $modelProcessNamespaces
        let $localId := $docRoot//aqd:AQD_ModelProcess/ompr:inspireId/base:Identifier[base:namespace = $id]/base:localId
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
let $ms2M28 := prof:current-ms()

(: M28 :)
let $ms1M28.1 := prof:current-ms()
let $M28.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//aqd:AQD_ModelProcess/ef:inspireId/base:Identifier/base:namespaces)
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
let $ms2M28.1 := prof:current-ms()

(: M29 :)
let $ms1M29 := prof:current-ms()
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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M29 := prof:current-ms()

(: M30 :)
let $ms1M30 := prof:current-ms()
let $M30invalid :=
    try {
        for $x in $docRoot//aqd:AQD_ModelProcess[string(ompr:name) = ""]
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($x/ompr:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M30 := prof:current-ms()

(: M34 :)
let $ms1M34 := prof:current-ms()
let $M34invalid :=
    try {
        for $x in $docRoot//aqd:AQD_ModelProcess[string(aqd:description) = ""]
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($x/ompr:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M34 := prof:current-ms()

(: M35 :)
let $ms1M35 := prof:current-ms()
let $M35invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:UOM_TIME || "rdf")
        for $x in $docRoot//aqd:AQD_ModelProcess
        let $xlink := data($x/aqd:temporalResolution/aqd:TimeReferences/aqd:unit/@xlink:href)
        where not($xlink = $valid)
        return
            <tr>
                <td title="aqd:AQD_ModelProcess">{data($x/ompr:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:unit">{$xlink}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M35 := prof:current-ms()

(: M39 :)
let $ms1M39 := prof:current-ms()
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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M39 := prof:current-ms()

(: M40 - :)
let $ms1M40 := prof:current-ms()
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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M40 := prof:current-ms()

(: M41 - :)
let $ms1M41 := prof:current-ms()
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
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M41 := prof:current-ms()

(: M41 :)
let $ms1M41.1 := prof:current-ms()
let $M41.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//aqd:AQD_ModelArea/ef:inspireId/base:Identifier/base:namespaces)
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
let $ms2M41.1 := prof:current-ms()

(: M43 :)
let $ms1M43 := prof:current-ms()
let $M43invalid :=
    try {
        let $valid := ("urn:ogc:def:crs:EPSG::4258", "urn:ogc:def:crs:EPSG::4326", "urn:ogc:def:crs:EPSG::3035")
        for $x in $docRoot//aqd:AQD_ModelArea[count(sams:shape) > 0]
            for $z in data($x/sams:shape//@srsName)
        where not($z = $valid)
        return
            <tr>
                <td title="aqd:AQD_ModelArea">{data($x/aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="@srsName">{$z}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M43 := prof:current-ms()

(: M45 :)
let $ms1M45 := prof:current-ms()
let $M45invalid :=
    try {
        for $posList in $docRoot//gml:posList
        let $posListCount := count(fn:tokenize(normalize-space($posList), "\s+")) mod 2
        where (not(empty($posList)) and $posListCount > 0)
        return
            <tr>
                <td title="Polygon">{string($posList/../../../@gml:id)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $ms2M45 := prof:current-ms()
    
(:
 : M46 - generalized by Hermann
 : In Europe, lat values tend to be bigger than lon values. We use this observation as a poor farmer's son test to check that in a coordinate value pair,
 : the lat value comes first, as defined in the GML schema
:)
let $ms1M46 := prof:current-ms()
let $M46invalid :=
    try {
        for $latLong in $docRoot//gml:posList
        let $latlongToken := fn:tokenize(normalize-space($latLong), "\s+")
        let $lat := number($latlongToken[1])
        let $long := number($latlongToken[2])
        where (not($countryCode = "fr") and ($long > $lat))
        return
            <tr>
                <td title="Polygon">{string($latLong/../../../@gml:id)}</td>
                <td title="First vertex">{string($lat) || string($long)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $M46message :=
    if ($countryCode = "fr") then
        "Temporary turned off"
    else
        "All values are valid"
let $ms2M46 := prof:current-ms()

let $ms2Total := prof:current-ms()

    return
    <table class="maintable hover">
    <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:WARNING)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
        {html:build3("M0", $labels:M0, $labels:M0_SHORT, $M0table, string($M0table/td), errors:getMaxError($M0table))}
        {html:build2("M01", $labels:M01, $labels:M01_SHORT, $M01table, "All values are valid", "record", errors:getMaxError($M01table))}
        {html:buildSimple("M02", $labels:M02, $labels:M02_SHORT, $M02table, $M02count, "feature type", errors:getMaxError($M02table))}
        {html:buildSimple("M03", $labels:M03, $labels:M03_SHORT, $M03table, $M03count, "feature type", errors:getMaxError($M03table))}
        {html:build2("M04", $labels:M04, $labels:M04_SHORT, $M04table, "All values are valid", "record", $errors:M04)}
        {html:build2("M05", $labels:M05, $labels:M05_SHORT, $M05invalid, "All values are valid", "record", $errors:M05)}
        {html:build2("M06", $labels:M06, $labels:M06_SHORT, $M06invalid, "All values are valid", "record", $errors:M06)}
        {html:buildInfoTR("Specific checks on AQD_Models")}
        {html:buildUnique("M07", $labels:M07, $labels:M07_SHORT, $M07table, "namespace", $errors:M07)}
        {html:build2("M07.1", $labels:M07.1, $labels:M07.1_SHORT, $M07.1invalid, "All values are valid", " invalid namespaces", $errors:M07.1)}
        {html:build2("M08", $labels:M08, $labels:M08_SHORT, $M08invalid, "All values are valid", "record", $errors:M08)}
        {html:build2("M15", $labels:M15, $labels:M15_SHORT, $M15invalid, "All values are valid", "", $errors:M15)}
        {html:build2("M18", $labels:M18, $labels:M18_SHORT, $M18invalid, "All values are valid", "record", $errors:M18)}
        {html:build2("M19", $labels:M19, $labels:M19_SHORT, $M19invalid, "All values are valid", " invalid attribute", $errors:M19)}
        {html:build2("M20", $labels:M20, $labels:M20_SHORT, $M20invalid, "All values are valid", "record", $errors:M20)}
        {html:build2("M23", $labels:M23, $labels:M23_SHORT, $M23invalid, "All values are valid", "record", $errors:M23)}
        {html:build2("M24", $labels:M24, $labels:M24_SHORT, $M24invalid, "All values are valid", "record", $errors:M24)}
        {html:build2Sparql("M26", $labels:M26, $labels:M26_SHORT, $M26invalid, "All values are valid", "record", $errors:M26)}
        {html:buildInfoTR("Specific checks on AQD_ModelProcess")}
        {html:build2("M27", $labels:M27, $labels:M27_SHORT, $M27invalid, "All values are valid", "record", $errors:M27)}
        {html:buildUnique("M28", $labels:M28, $labels:M28_SHORT, $M28table, "namespace", $errors:M28)}
        {html:build2("M28.1", $labels:M28.1, $labels:M28.1_SHORT, $M28.1invalid, "All values are valid", " invalid namespaces", $errors:M28.1)}
        {html:build2("M29", $labels:M29, $labels:M29_SHORT, $M29invalid, "All attributes are valid"," invalid attribute", $errors:M29)}
        {html:build2("M30", $labels:M30, $labels:M30_SHORT, $M30invalid, "All attributes are valid","record", $errors:M30)}
        {html:build2("M34", $labels:M34, $labels:M34_SHORT, $M34invalid, "All attributes are valid","record", $errors:M34)}
        {html:build2("M35", $labels:M35, $labels:M35_SHORT, $M35invalid, "All attributes are valid","record", $errors:M35)}
        {html:build2("M39", $labels:M39, $labels:M39_SHORT, $M39invalid, "All attributes are valid"," invalid attribute", $errors:M39)}
        {html:buildInfoTR("Specific checks on AQD_ModelArea")}
        {html:build2("M40", $labels:M40, $labels:M40_SHORT, $M40invalid, "All values are valid", "record", $errors:M40)}
        {html:buildUnique("M41", $labels:M41, $labels:M41_SHORT, $M41table, "namespace", $errors:M41)}
        {html:build2("M41.1", $labels:M41.1, $labels:M41.1_SHORT, $M41.1invalid, "All values are valid", " invalid namespaces", $errors:M41.1)}
        {html:build2("M43", $labels:M43, $labels:M43_SHORT, $M43invalid, "All records are valid", "record", $errors:M43)}
        {html:build2("M45", $labels:M45, $labels:M45_SHORT, $M45invalid, "All records are valid", "record", $errors:M45)}
        {html:build2("M46", $labels:M46, $labels:M46_SHORT, $M46invalid, $M46message, "record", $errors:M46)}
    </table>
    <table>
        <br/>
        <caption> {$labels:TIMINGTABLEHEADER} </caption>
        <tr>
            <th>Query</th>
            <th>Process time in miliseconds</th>
            <th>Process time in seconds</th>
        </tr>
       {common:runtime("Common Variables", $ms1GeneralParameters, $ms2GeneralParameters)}
       {common:runtime("NS", $ms1NS, $ms2NS)}
       {common:runtime("VOCAB", $ms1VOCAB, $ms2VOCAB)}
       {common:runtime("M0",  $ms1M0, $ms2M0)}
       {common:runtime("M01", $ms1M01, $ms2M01)}
       {common:runtime("M02", $ms1M02, $ms2M02)}
       {common:runtime("M03", $ms1M03, $ms2M03)}
       {common:runtime("M04",  $ms1M04, $ms2M04)}
       {common:runtime("M05", $ms1M05, $ms2M05)}
       {common:runtime("M06",  $ms1M06, $ms2M06)}
       {common:runtime("M07",  $ms1M07, $ms2M07)}
       {common:runtime("M07.1",  $ms1M07.1, $ms2M07.1)}
       {common:runtime("M08",  $ms1M08, $ms2M08)}
       {common:runtime("M15",  $ms1M15, $ms2M15)}
       {common:runtime("M18",  $ms1M18, $ms2M18)}
       {common:runtime("M19",  $ms1M19, $ms2M19)}
       {common:runtime("M20", $ms1M20, $ms2M20)}
       {common:runtime("M23",  $ms1M23, $ms2M23)}
       {common:runtime("M24",  $ms1M24, $ms2M24)}
       {common:runtime("M26",  $ms1M26, $ms2M26)}
       {common:runtime("M27",  $ms1M27, $ms2M27)}
       {common:runtime("M28",  $ms1M28, $ms2M28)}
       {common:runtime("M28.1",  $ms1M28.1, $ms2M28.1)}
       {common:runtime("M29",  $ms1M29, $ms2M29)}
       {common:runtime("M30",  $ms1M30, $ms2M30)}
       {common:runtime("M34",  $ms1M34, $ms2M34)}
       {common:runtime("M35",  $ms1M35, $ms2M35)}
       {common:runtime("M39",  $ms1M39, $ms2M39)}
       {common:runtime("M40",  $ms1M40, $ms2M40)}
       {common:runtime("M41",  $ms1M41, $ms2M41)}
       {common:runtime("M41.1",  $ms1M41.1, $ms2M41.1)}
       {common:runtime("M43",  $ms1M43, $ms2M43)}
       {common:runtime("M45",  $ms1M45, $ms2M45)}
       {common:runtime("M46",  $ms1M43, $ms2M46)}
       {common:runtime("Total", $ms1Total, $ms2Total)}
    </table>
    </table>
};

declare function dataflowM:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countFeatures := count(doc($source_url)//descendant::*[$dataflowM:FEATURE_TYPES = name()])
let $result := if ($countFeatures > 0) then dataflowM:checkReport($source_url, $countryCode) else ()
let $meta := map:merge((
    map:entry("count", $countFeatures),
    map:entry("header", "Check environmental monitoring feature types"),
    map:entry("dataflow", "Dataflow D on Models and Objective Estimation"),
    map:entry("zeroCount", <p>No environmental monitoring feature type elements ({string-join($dataflowM:FEATURE_TYPES, ", ")}) found from this XML.</p>),
    map:entry("report", <p>This feedback report provides a summary overview of feature types reported and some consistency checks defined in Dataflow D on Models and Objective Estimation as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
))
return
    html:buildResultDiv($meta, $result)
};
