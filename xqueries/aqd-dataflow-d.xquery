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
 : @author Rait Väli and Enriko Käsper
 : @author George Sofianos
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document
 :)

module namespace dataflowD = "http://converters.eionet.europa.eu/dataflowD";

import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace geox = "aqd-geo" at "aqd-geo.xquery";
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
declare namespace prop = "http://dd.eionet.europa.eu/property/";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace adms = "http://www.w3.org/ns/adms#";

declare variable $dataflowD:ISO2_CODES as xs:string* := ("AL", "AD", "AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB", "GE", "GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $dataflowD:FEATURE_TYPES := ("aqd:AQD_Network", "aqd:AQD_Station", "aqd:AQD_SamplingPointProcess", "aqd:AQD_Sample",
"aqd:AQD_RepresentativeArea", "aqd:AQD_SamplingPoint");
declare variable $dataflowD:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "672");

(: Rule implementations :)
declare function dataflowD:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
let $ms1Total := prof:current-ms()

let $ms1GeneralParameters:= prof:current-ms()
let $docRoot := doc($source_url)
let $cdrUrl := common:getCdrUrl($countryCode)
let $reportingYear := common:getReportingYear($docRoot)

let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition

(: COMMON variables used in many QCs :)
let $countFeatureTypesMap :=
    map:merge((
    for $featureType in $dataflowD:FEATURE_TYPES
    return
        map:entry($featureType, count($docRoot//descendant::*[name()=$featureType]))
    ))
let $DCombinations :=
    for $featureType in $dataflowD:FEATURE_TYPES
    return
        doc($source_url)//descendant::*[name()=$featureType]

let $latestEnvelopeB := query:getLatestEnvelope($cdrUrl || "b/")
let $latestEnvelopeD := query:getLatestEnvelope($cdrUrl || "d/")

let $namespaces := distinct-values($docRoot//base:namespace)
let $knownFeatures := distinct-values(data(sparqlx:run(query:getAllFeatureIds($dataflowD:FEATURE_TYPES, $latestEnvelopeD, $namespaces))//sparql:binding[@name='inspireLabel']/sparql:literal))
let $SPOnamespaces := distinct-values($docRoot//aqd:AQD_SamplingPoint//base:Identifier/base:namespace)
let $SPPnamespaces := distinct-values($docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier/base:namespace)
let $networkNamespaces := distinct-values($docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/base:namespace)

let $sampleNamespaces := distinct-values($docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:namespace)
let $stationNamespaces := distinct-values($docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/base:namespace)


let $ms2GeneralParameters:= prof:current-ms()
(: File prefix/namespace check :)

let $ns1DNS := prof:current-ms()

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

    let $ns2DNS := prof:current-ms()

(: VOCAB check:)

let $ns1DVOCAB := prof:current-ms()

let $VOCABinvalid := checks:vocab($docRoot)

let $ns2DVOCAB := prof:current-ms()

(:VOCABALL check @goititer

let $ms1CVOCABALL := prof:current-ms()

let $VOCABALLinvalid := checks:vocaball($docRoot)

let $ms2CVOCABALL := prof:current-ms():)

(: D0 :)

let $ns1D0 := prof:current-ms()

let $D0table :=
    try {
        if ($reportingYear = "") then
            <tr class="{$errors:ERROR}">
                <td title="Status">Reporting Year is missing.</td>
            </tr>
        else if($headerBeginPosition > $headerEndPosition) then
            <tr class="{$errors:BLOCKER}">
                <td title="Status">Start position must be less than end position</td>
            </tr>
        else if (query:deliveryExists($dataflowD:OBLIGATIONS, $countryCode, "d/", $reportingYear)) then
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
let $isNewDelivery := errors:getMaxError($D0table) = $errors:INFO


let $ns2D0 := prof:current-ms()


let $D1sum := string(sum(
    for $featureType in $dataflowD:FEATURE_TYPES
    return
        count($docRoot//descendant::*[name()=$featureType])))
(: D01 :)

let $ns1D01 := prof:current-ms()

let $D01table :=
    try {

        for $featureType at $pos in $dataflowD:FEATURE_TYPES
        
        order by $featureType descending
        return
        if (map:get($countFeatureTypesMap, $featureType) > 0) then
        
        
            <tr>
                <td title="Feature type">{$featureType}</td>
                <td title="Total number">{map:get($countFeatureTypesMap, $featureType)}</td>
            </tr>
        else if ($featureType != "aqd:AQD_RepresentativeArea") then
       
            <tr class="{$errors:BLOCKER}">
                <td title="Feature type">{$featureType}</td>
                <td title="Total number">{map:get($countFeatureTypesMap, $featureType)}</td>
                
            </tr>
        

    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2D01 := prof:current-ms()

(: D02 -:)

let $ns1D02 := prof:current-ms()

let $D02table :=
    try {
        let $featureTypes := remove($dataflowD:FEATURE_TYPES, index-of($dataflowD:FEATURE_TYPES, "aqd:AQD_RepresentativeArea"))
        let $all := map:merge((
            for $featureType at $pos in $featureTypes
                let $count := count(
                for $x in $docRoot//descendant::*[name()=$featureType]
                    let $inspireId := $x//base:Identifier/base:namespace/string() || "/" || $x//base:Identifier/base:localId/string()
                where ($inspireId = "/" or not($knownFeatures = $inspireId))
                return
                    <tr>
                        <td title="base:localId">{$x//base:Identifier/base:localId/string()}</td>
                    </tr>)
            return map:entry($dataflowD:FEATURE_TYPES[$pos], $count)
        ))
        return
            map:for-each($all, function($name, $count) {
                if ($count > 0) then
                    <tr>
                        <td title="Feature type">{$name}</td>
                        <td title="Total number">{$count}</td>
                        <td title="Sparql getAllFeatureIds">{sparqlx:getLink(query:getAllFeatureIds($dataflowD:FEATURE_TYPES, $latestEnvelopeD, $namespaces))}</td>
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
let $D02errorLevel :=
    try {
        let $map1 := map:merge((
            for $x in $D02table
            return
                map:entry($x/td[1]/string(), $x/td[2]/number())
        ))
        return
            if ($errors:ERROR =
                    map:for-each($map1, function($name, $count) {
                        if ($count = map:get($countFeatureTypesMap, $name)) then
                            $errors:ERROR
                        else
                            $errors:INFO
                    })) then
                $errors:D02
            else
                $errors:INFO
    } catch * {
        $errors:FAILED
    }


let $ns2D02 := prof:current-ms()

(: D03 - :)

let $ns1D03 := prof:current-ms()

let $D03table :=
    try {
        let $featureTypes := remove($dataflowD:FEATURE_TYPES, index-of($dataflowD:FEATURE_TYPES, "aqd:AQD_RepresentativeArea"))
        let $all := map:merge((
            for $featureType at $pos in $featureTypes
            let $count := count(
                    for $x in $docRoot//descendant::*[name()=$featureType]
                    let $inspireId := $x//base:Identifier/base:namespace/string() || "/" || $x//base:Identifier/base:localId/string()
                    where ($knownFeatures = $inspireId)
                    return
                        <tr>
                            <td title="base:localId">{$x//base:Identifier/base:localId/string()}</td>
                        </tr>)
            return map:entry($featureTypes[$pos], $count)
        ))
        return
            map:for-each($all, function($name, $count) {
                    <tr isvalid="{not($count=0)}">
                        <td title="Feature type">{$name}</td>
                        <td title="Total number">{$count}</td>
                        <td title="Sparql getAllFeatureIds">{sparqlx:getLink(query:getAllFeatureIds($dataflowD:FEATURE_TYPES, $latestEnvelopeD, $namespaces))}</td>
                    </tr>
            })
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $D03errorLevel :=
    try {
        if (data($D03table/@isvalid) = "false") then
            $errors:D03
        else
            $errors:INFO
    } catch * {
        $errors:FAILED
    }
let $D3count :=
    try {
        string(sum($D03table/td[2]))
    } catch * {
        "NaN"
    }


let $ns2D03 := prof:current-ms()

(:D03b:)

let $ns1D03b := prof:current-ms()

let $D03bfunc := function() {
    let $featureTypes := remove($dataflowD:FEATURE_TYPES, index-of($dataflowD:FEATURE_TYPES, "aqd:AQD_RepresentativeArea"))
    let $currentIds :=
    for $featureType at $pos in $featureTypes
    for $x in $docRoot//descendant::*[name() = $featureType]
    let $inspireId := $x//base:Identifier/base:namespace/string() || "/" || $x//base:Identifier/base:localId/string()
    return $inspireId

    for $x in $knownFeatures
    where not($x = $currentIds)
    return
        <tr>
            <td title="inspireId">{$x}</td>
            <td title="Sparql getAllFeatureIds">{sparqlx:getLink(query:getAllFeatureIds($dataflowD:FEATURE_TYPES, $latestEnvelopeD, $namespaces))}</td>
        </tr>
}
let $D03binvalid := errors:trycatch($D03bfunc)

let $ns2D03b := prof:current-ms()

(: D04 :)

let $ns1D04 := prof:current-ms()

let $D04table :=
    try {
        let $allD4Combinations :=
            for $aqdModel in $DCombinations
            return concat(data($aqdModel/@gml:id), "#", $aqdModel/ef:inspireId/base:Identifier/base:localId, "#", $aqdModel/ompr:inspireId/base:Identifier/base:localId, "#", $aqdModel/ef:name, "#", $aqdModel/ompr:name)
        let $allD4Combinations := fn:distinct-values($allD4Combinations)
        for $rec in $allD4Combinations
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
                <td title="ef:inspireId/localId">{common:checkLink($inspireId)}</td>
                <td title="ompr:inspireId/localId">{common:checkLink($aqdInspireId)}</td>
                <td title="ef:name">{common:checkLink($efName)}</td>
                <td title="ompr:name">{common:checkLink($omprName)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2D04 := prof:current-ms()

(: D05 :)
(: TODO: FIX TRY CATCH :)

let $ns1D05 := prof:current-ms()

let $all1 := $DCombinations/lower-case(normalize-space(@gml:id))
let $part1 := distinct-values(
        for $id in $DCombinations/@gml:id
        where string-length(normalize-space($id)) > 0 and count(index-of($all1, lower-case(normalize-space($id)))) > 1
        return
            $id
)
let $part1 :=
    for $i in $part1
    return
        <tr>
            <td title="Duplicate records">@gml:id {$i}</td>
        </tr>

let $all2 := for $id in $DCombinations/ef:inspireId
return lower-case("[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]")
let $part2 := distinct-values(
        for $id in $DCombinations/ef:inspireId
        let $key := "[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]"
        where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($all2, lower-case($key))) > 1
        return
            $key
)
let $part2 :=
    for $i in $part2
    return
        <tr>
            
            <td title="Duplicate records">ef:inspireId {string($i)}</td>
        </tr>


let $all3 := for $id in $DCombinations/aqd:inspireId
return lower-case("[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]")

let $part3 := distinct-values(
        for $id in $DCombinations/aqd:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($all3, lower-case($key))) > 1
        return
            $key
)
let $part3 :=
    for $i in $part3
    return
   
        <tr>
            
            <td title="Duplicate records">aqd:inspireId {string($i)}</td>
        </tr>

let $countGmlIdDuplicates := count($part1)
let $countefInspireIdDuplicates := count($part2)
let $countaqdInspireIdDuplicates := count($part3)
(:let $D05invalid :=<tr><td title="Duplicate records">{$part1}{$part2}{$part3}</td></tr>:)
let $D05invalid :=$part1|$part2|$part3

let $ns2D05 := prof:current-ms()

(: D06 Done by Rait ./ef:inspireId/base:Identifier/base:localId shall be an unique code for AQD_network and unique within the namespace.:)
(: Changed by @diezzana 28 June 2021, issue #135478 :)

let $ns1D06 := prof:current-ms()
(:
    let $amInspireIds := $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
            lower-case(normalize-space(base:localId)))
    let $duplicateEUStationCode := distinct-values(
            for $identifier in $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier
            where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                    concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
            return
                concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
    )
    let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
    let $D06invalid := $countAmInspireIdDuplicates
:)

let $D06invalid :=
    try {
      let $amInspireIds := $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
              lower-case(normalize-space(base:localId)))

      for $identifier in $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier
      where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
              concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
      
        return
              <tr>
                  <td title="Repeated base:Identifier">{concat(normalize-space($identifier/base:namespace), ': ', normalize-space($identifier/base:localId))}</td>
                  <td title="base:localId">{normalize-space($identifier/base:localId)}</td>
                  <td title="base:namespace">{normalize-space($identifier/base:namespace)}</td>
              </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2D06 := prof:current-ms()

(: D07 :)

let $ns1D07 := prof:current-ms()

let $D07table :=
    try {
        for $id in $networkNamespaces
        let $localId := $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="feature">aqd:AQD_Network</td>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2D07 := prof:current-ms()

(: D07.1 :)

let $ns1D07.1 := prof:current-ms()

let $D07.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/base:namespace)
        where (not($x = $prefLabel) and not($x = $altLabel))
        return
            <tr>
                <td title="base:namespace">{$x}</td>
                <td title="base:pref">{$prefLabel}</td>
                <td title="base:alt">{$altLabel}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2D07.1 := prof:current-ms()

(: D08 :)

let $ns1D08 := prof:current-ms()

let $D08invalid :=
    try {
        let $valid := ($vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI || "air", $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI_UC || "air")
        for $x in $docRoot//aqd:AQD_Network/ef:mediaMonitored
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Network">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:mediaMonitored">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2D08 := prof:current-ms()

(: D09 :)

let $ns1D09 := prof:current-ms()

let $D09invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:ORGANISATIONAL_LEVEL_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_Network/ef:organisationLevel
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Network">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:organisationLevel">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2D09 := prof:current-ms()

(: D10 :)

let $ns1D10 := prof:current-ms()

let $D10invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:NETWORK_TYPE_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_Network/aqd:networkType
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Network">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:networkType">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ns2D10 := prof:current-ms()


let $ns1D11 := prof:current-ms()

let $D11invalid :=
    try {
        


  let $D11tmp_Network :=
        let $allEfOperationActivityPeriod :=
            for $allOperationActivityPeriod in $docRoot//aqd:AQD_Network/aqd:operationActivityPeriod
            where ($allOperationActivityPeriod/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition) != "unknown"]
                    or fn:string-length($allOperationActivityPeriod/gml:TimePeriod/gml:endPosition) > 0)
            return $allOperationActivityPeriod

        for $operationActivityPeriod in $allEfOperationActivityPeriod
        where ((geox:parseDateTime($operationActivityPeriod/gml:TimePeriod/gml:endPosition) < geox:parseDateTime($operationActivityPeriod/gml:TimePeriod/gml:beginPosition)) or ($operationActivityPeriod/gml:TimePeriod/gml:endPosition = "")or ($operationActivityPeriod/gml:TimePeriod/gml:beginPosition = "")or ($operationActivityPeriod/gml:TimePeriod/gml:beginPosition [normalize-space(@indeterminatePosition) = "unknown"]))
        
         return $operationActivityPeriod 



   let $D11tmp_SamplingPoint :=
        let $allEfOperationActivityPeriod :=
            for $allOperationActivityPeriod in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability
            where ($allOperationActivityPeriod/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition) != "unknown"]
                    or fn:string-length($allOperationActivityPeriod/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition) > 0)
            return $allOperationActivityPeriod

        for $operationActivityPeriod in $allEfOperationActivityPeriod
        where ((geox:parseDateTime($operationActivityPeriod/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition) < geox:parseDateTime($operationActivityPeriod/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition)) or ($operationActivityPeriod/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition = "")or ($operationActivityPeriod/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition = "")or ($operationActivityPeriod/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition [normalize-space(@indeterminatePosition) = "unknown"]))
       
         return $operationActivityPeriod 


    let $D11tmp_SamplingPoint2 :=
        let $allEfOperationActivityPeriod :=
            for $allOperationActivityPeriod in $docRoot//aqd:AQD_SamplingPoint/ef:operationalActivityPeriod
            where ($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition) != "unknown"]
                    or fn:string-length($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) > 0)
            return $allOperationActivityPeriod

        for $operationActivityPeriod in $allEfOperationActivityPeriod
        where ((geox:parseDateTime($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) < geox:parseDateTime($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition)) or ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition = "")or ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition = "")or ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition [normalize-space(@indeterminatePosition) = "unknown"]))
       
         return $operationActivityPeriod 


             
      let $D11tmp_Station :=
        let $allEfOperationActivityPeriod :=
            for $allOperationActivityPeriod in $docRoot//aqd:AQD_Station/ef:operationalActivityPeriod
            where ($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition) != "unknown"]
                    or fn:string-length($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) > 0)
            return $allOperationActivityPeriod

        for $operationActivityPeriod in $allEfOperationActivityPeriod
        where ((geox:parseDateTime($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) < geox:parseDateTime($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition)) or ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition = "")or ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition = "")or ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition [normalize-space(@indeterminatePosition) = "unknown"]))
        
        return $operationActivityPeriod 


       let $allRecords:=  ($D11tmp_Network,$D11tmp_SamplingPoint,$D11tmp_SamplingPoint2,$D11tmp_Station)
        
        

        for $x in $allRecords
        return
            <tr>
                 <td title="Feature Type">{data($x/../name())}</td>
                <td title="base:localId">{data($x/../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($x//gml:TimePeriod/@gml:id)}</td>
                <td title="gml:beginPosition">{$x//gml:TimePeriod/gml:beginPosition}</td>
                <td title="gml:endPosition">{$x//gml:TimePeriod/gml:endPosition}</td>
                
                
             
            </tr>

        
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2D11 := prof:current-ms()


(: D12  aqd:AQD_Network/ef:name shall return a string :)


let $ns1D12 := prof:current-ms()

let $D12invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Network[string(ef:name) = ""]
        return
            <tr>
                <td title="base:localId">{string($x/ef:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2D12 := prof:current-ms()

(: D14 - ./aqd:aggregationTimeZone attribute shall resolve to a valid code in http://dd.eionet.europa.eu/vocabulary/aq/timezone/ :)

let $ns1D14 := prof:current-ms()

let $D14invalid :=
    try {
        let $validTimezones := dd:getValidConcepts("http://dd.eionet.europa.eu/vocabulary/aq/timezone/rdf")
        for $x in $docRoot//aqd:AQD_Network
        let $timezone := $x/aqd:aggregationTimeZone/@xlink:href
        where not($timezone = $validTimezones)
        return
            <tr>
                <td title="Feature type">{$x/name()}</td>
                <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="ef:name">{data($x/ef:name)}</td>
                <td title="aqd:aggregationTimeZone" style="color:red">{string($timezone)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D14 := prof:current-ms()

(: D15 Done by Rait changed by @diezzana 21 June 2021, issue #135446 :)

let $ns1D15 := prof:current-ms()

(:let $D15invalid :=
    try {
        let $amInspireIds := $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
                lower-case(normalize-space(base:localId)))

        let $D15tmp := distinct-values(
                for $identifier in $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier
                where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                        concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
                return
                    concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
        )
        let $D15tmp :=
            for $i in $D15tmp
            return
                <tr>
                    <td title="id">{string($i)}</td>
                </tr>
        let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
        return $countAmInspireIdDuplicates
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }:)
    
let $D15invalid := try {
      let $baseLocalIds := $docRoot//gml:featureMember/aqd:AQD_Station/ef:inspireId/base:Identifier/normalize-space(base:localId)    
      for $id in distinct-values($baseLocalIds)
        let $ok := (
          count(index-of($baseLocalIds, $id)) = 1
        )
        let $stationIds := $docRoot//gml:featureMember/aqd:AQD_Station/ef:inspireId/base:Identifier[base:localId = $id]/../../../aqd:AQD_Station/@gml:id
        where not($ok) return 
          <tr> 
             <td title="Duplicated base:localId">{data($id)}</td>
             <td title="aqd:AQD_Station ID">{string-join(data($stationIds), '; ')}</td>
             <td title="Number of elements">{count(index-of($baseLocalIds, $id))}</td>
          </tr>    
} catch * {
    html:createErrorRow($err:code, $err:description)
}

let $ns2D15 := prof:current-ms()

(: D16 :)

let $ns1D16 := prof:current-ms()

let $D16table :=
    try {
        for $id in $networkNamespaces
        let $localId := $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="feature">Station(s)</td>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D16 := prof:current-ms()

(: D16.1 :)

let $ns1D16.1 := prof:current-ms()

let $D16.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/base:namespace)
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

let $ns2D16.1 := prof:current-ms()


(: D17 aqd:AQD_Station/ef:name shall return a string :)

let $ns1D17 := prof:current-ms()

let $D17invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Station[string(ef:name) = ""]
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


let $ns2D17 := prof:current-ms()

(: D18 Cross-check with AQD_Network (aqd:AQD_Station/ef:belongsTo shall resolve to a traversable local of global URI to ../AQD_Network) :)

let $ns1D18 := prof:current-ms()

let $D18invalid :=
    try {
        let $aqdNetworkLocal :=
            for $z in $docRoot//aqd:AQD_Network
            let $id := concat(data($z/ef:inspireId/base:Identifier/base:namespace), '/',
                    data($z/ef:inspireId/base:Identifier/base:localId))
            return $id

        for $x in $docRoot//aqd:AQD_Station[not(ef:belongsTo/@xlink:href = $aqdNetworkLocal)]
        return
            <tr>
                <td title="aqd:AQD_Station">{string($x/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:belongsTo">{string($x/ef:belongsTo/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D18 := prof:current-ms()

(: D19 :)

let $ns1D19 := prof:current-ms()

let $D19invalid :=
    try {
        let $valid := ($vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI || "air", $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI_UC || "air")
        for $x in $docRoot//aqd:AQD_Station/ef:mediaMonitored
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Station">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:networkType">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D19 := prof:current-ms()


(: D20 ./ef:geometry/gml:Points the srsName attribute shall be a recognisable URN :)

let $ns1D20 := prof:current-ms()

let $D20invalid :=
    try {
        let $D20validURN := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4258", "urn:ogc:def:crs:EPSG::4326")
        for $x in distinct-values($docRoot//aqd:AQD_Station[count(ef:geometry/gml:Point) > 0 and not(ef:geometry/gml:Point/@srsName = $D20validURN)]/ef:inspireId/base:Identifier/base:localId)
        return
            <tr>
                <td title="base:localId">{$x}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D20 := prof:current-ms()

(: D21 - The Dimension attribute shall resolve to "2.". Updated by @diezzana 29 July 2021 :)

let $ns1D21 := prof:current-ms()

let $invalidPosD21 :=
    try {
        let $allnot2 := distinct-values(
            for $x in $docRoot//aqd:AQD_Station/ef:geometry/gml:Point[gml:pos/@srsDimension != "2"]
            return $x/../../ef:inspireId/base:Identifier/base:localId/string() || "#" || $x/@gml:id || "#" || $x/gml:pos/@srsDimension || "#" || $x/gml:pos
        )
        
        let $all2 := distinct-values(
            for $x in $docRoot//aqd:AQD_Station/ef:geometry/gml:Point[gml:pos/@srsDimension = "2"]
            return $x/../../ef:inspireId/base:Identifier/base:localId/string() || "#" || $x/@gml:id || "#" || $x/gml:pos/@srsDimension || "#" || $x/gml:pos
        )

        let $NamespaceDD := 
         for $x in doc($vocabulary:AQD_Namespace || "rdf")//skos:Concept
          
            let $currentCountry := string(fn:upper-case($countryCode))
            let $countryyy := string($x/prop:inCountry/@rdf:resource)
            let $length := fn:string-length($countryyy) - 1
            let $sbst := fn:substring($countryyy, $length, 2)
            let $LongitudeMax :=  $x/prop:LongitudeMax
            let $LongitudeMin :=  $x/prop:LongitudeMin
            let $LatitudeMax :=  $x/prop:LatitudeMax
            let $LatitudeMin :=  $x/prop:LatitudeMin

            where ($currentCountry = $sbst)            

            return $LongitudeMax || "###"|| $LongitudeMin || "###"|| $LatitudeMax || "###"|| $LatitudeMin

    
            let $LongitudeMax := number(tokenize($NamespaceDD, "###")[1])
            let $LongitudeMin := number(tokenize($NamespaceDD, "###")[2])
            let $LatitudeMax := number(tokenize($NamespaceDD, "###")[3])
            let $LatitudeMin := number(tokenize($NamespaceDD, "###")[4])


        let $wrong2:= (for $i in $all2
                            let $position:= normalize-space(tokenize($i, "#")[4])
                            return if (count(tokenize($position," ")) != 2) then
                                        ( $i )
                                    else if (string(number(tokenize($position," ")[1])) = 'NaN' or string(number(tokenize($position," ")[2])) = 'NaN') then
                                        ( $i )
                                    else ()
                        )   
                    
                     
         let $invalidCoordinate := 
           (for $coord in $all2

              let $stationPos := tokenize($coord, "#")[4]
              let $stationLat := if (not(empty($stationPos))) then fn:substring-before($stationPos, " ") else ""
              let $stationLong := if (not(empty($stationPos))) then fn:substring-after($stationPos, " ") else ""
              let $stationLatNum := if ($stationLat castable as xs:decimal) then xs:decimal($stationLat) else 0.00
              let $stationLongNum := if ($stationLong castable as xs:decimal) then xs:decimal($stationLong) else 0.00
  
              return
                  if ( (string(number($stationLat))) = 'NaN' or (string(number($stationLong))) = 'NaN') then
                      $coord
                  else
                      if (not($stationLatNum <= $LatitudeMax and $stationLatNum >= $LatitudeMin) or
                      not($stationLongNum <= $LongitudeMax and $stationLongNum >=$LongitudeMin) and $countryCode != 'fr') then
                          $coord
                      else
                          ()
            )                  
                    
                    
        let $wrongRows := ($allnot2, $invalidCoordinate)  
          
        for $i in $wrongRows   
          return 
          <tr>
              <td title="aqd:AQD_Station">{tokenize($i, "#")[1]}</td>
              <td title="gml:Point">{tokenize($i, "#")[2]}</td>
              <td title="srsDimension">{tokenize($i, "#")[3]}</td>
              <td title="gml:pos (lat/long)">{tokenize($i, "#")[4]}</td>
          </tr>
        
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }


let $ns2D21 := prof:current-ms()

(: D23 Done by Rait changed by @goititer 13 May 2021 :)

let $ns1D23 := prof:current-ms()

(:let $D23invalid :=
    try {
        let $allEfOperationActivityPeriod :=
            for $allOperationActivityPeriod in $docRoot//aqd:AQD_Station/ef:operationalActivityPeriod
            where ($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition) != "unknown"]
                    or fn:string-length($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) > 0)
            return $allOperationActivityPeriod

        for $operationActivityPeriod in $allEfOperationActivityPeriod
        where ((geox:parseDateTime($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) < geox:parseDateTime($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition)) or ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition = "")or ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition = "")or ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition [normalize-space(@indeterminatePosition) = "unknown"]))
        return
            <tr>
                <td title="aqd:AQD_Station">{data($operationActivityPeriod/../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
                <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
                <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
                
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }:)

    let $D23invalid :=
    try {               

                 for $allStations in $docRoot//aqd:AQD_Station
                    let $belongsTo:= fn:substring-after(data($allStations/ef:belongsTo/@xlink:href), '/')
                    let $stationBeginPos:=$allStations/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition
                    let $stationEndPos:=$allStations/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition
               
                        for $x in $docRoot//aqd:AQD_Network
                        let $networkBeginPos:=$x/aqd:operationActivityPeriod/gml:TimePeriod/gml:beginPosition
                        let $networkEndPos:=$x/aqd:operationActivityPeriod/gml:TimePeriod/gml:endPosition                

                   where ( ($belongsTo!="")and ($belongsTo = data($x/@gml:id) ))

                    return
                    
                    if (($stationBeginPos < $networkBeginPos) or 
                        ($stationBeginPos="") or 
                        ($networkBeginPos="") or 
                        (($networkEndPos != "") and ($stationEndPos != "") and ($stationEndPos > $networkEndPos) ) or
                        (($networkEndPos != "") and(($stationEndPos[normalize-space(@indeterminatePosition) = "unknown"] )or ($stationEndPos = "")))    
                        )

                    then                 
        
            <tr>
                <td title="aqd:AQD_Station">{data($allStations/@gml:id)}</td>
                <td title="belongs to aqd:AQD_Network ">{$belongsTo}</td>
                <td title="Station beginPos">{$stationBeginPos}</td>
                <td title="Network beginPos">{$networkBeginPos}</td>
                <td title="Station endPos">{$stationEndPos}</td>
                <td title="Network endPos">{$networkEndPos}</td>
            </tr>

    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D23 := prof:current-ms()


(: D24 - List the total number of aqd:AQD_Station which are operational :)

let $ns1D24 := prof:current-ms()

let $D24table :=
    try {
        for $operationActivityPeriod in $docRoot//aqd:AQD_Station/ef:operationalActivityPeriod
        where $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition) = "unknown"]
                or fn:string-length($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) = 0
        return
            <tr>
                <td title="aqd:AQD_Station">{data($operationActivityPeriod/../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
                <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
                <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }


let $ns2D24 := prof:current-ms()


(: D25 - Station altitude must be provided as a number and unit of measurement according to vocabulary.:)

let $ns1D25 := prof:current-ms()

let $D25table :=
    try {
        for $altitude in $docRoot//aqd:AQD_Station/aqd:altitude
        let $uom:= data($altitude/@uom)
        let $status:=
        
            if (starts-with($uom,'http://') or starts-with($uom,'https://')) then (      
                   
                            let $request := <http:request href="{$uom}" method="HEAD"/>
                            let $response := http:send-request($request)[1]  

                            let $url := $request/@href 
                            let $message := $response/@message

                            return  $response/@status)
            else (

               0
                )
   
    
     
         where ((string(number(data($altitude)))= 'NaN') or (number(data($altitude))< -10) or (number(data($altitude)) > 5700 ) or ($status!=200))
        return
            <tr class="{$errors:BLOCKER}">
                <td title="aqd:AQD_Station">{data($altitude/../@gml:id)}</td>
                <td title="altitude">{data($altitude)}</td>                
                <td title="uom url">{$uom}</td>
               <!-- <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
                <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>-->
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }


let $ns2D25 := prof:current-ms()

(: D26 Done by Rait:)

let $ns1D26 := prof:current-ms()

let $D26invalid :=
    try {
        let $localEUStationCode := $docRoot//aqd:AQD_Station/upper-case(normalize-space(aqd:EUStationCode))
        for $EUStationCode in $docRoot//aqd:AQD_Station/aqd:EUStationCode
        where
            count(index-of($localEUStationCode, upper-case(normalize-space($EUStationCode)))) > 1 or
                    (
                        count(index-of($dataflowD:ISO2_CODES, substring(upper-case(normalize-space($EUStationCode)), 1, 2))) = 0
                    )
        return
            <tr>
                <td title="aqd:AQD_Station">{data($EUStationCode/../@gml:id)}</td>
                <td title="aqd:EUStationCode">{data($EUStationCode)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D26 := prof:current-ms()

(: D27 :)

let $ns1D27 := prof:current-ms()

let $D27invalid :=
    try {
        ()
        (:dataflowD:checkVocabulariesConceptEquipmentValues($source_url, "aqd:AQD_Station", "aqd:meteoParams", $vocabulary:METEO_PARAMS_VOCABULARY, "collection"):)
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D27 := prof:current-ms()

(: D28 :)

let $ns1D28 := prof:current-ms()

let $D28invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:AREA_CLASSIFICATION_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_Station/aqd:areaClassification
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Station">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:areaClassification">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D28 := prof:current-ms()

(: D29 :)

let $ns1D29 := prof:current-ms()

let $D29invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:DISPERSION_LOCAL_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_Station/aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionLocal
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Station">{data($x/../../../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:dispersionLocal">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D29 := prof:current-ms()

(: D30 :)

let $ns1D30 := prof:current-ms()

let $D30invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:DISPERSION_REGIONAL_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_Station/aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionRegional
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Station">{data($x/../../../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:dispersionRegional">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D30 := prof:current-ms()

(: D31 Done by Rait:)

let $ns1D31 := prof:current-ms()

let $D31invalid :=
    try {
        let $localSamplingPointIds := $docRoot//aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId
        for $idCode in $docRoot//aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId
        where
            count(index-of($localSamplingPointIds, normalize-space($idCode))) > 1
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($idCode/../../../@gml:id)}</td>
                <td title="base:localId">{data($idCode)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }


let $ns2D31 := prof:current-ms()

(: D32 :)

let $ns1D32 := prof:current-ms()

let $D32table :=
    try {
        for $id in $SPOnamespaces(:$networkNamespaces:)
        let $localId := $docRoot//aqd:AQD_SamplingPoint//base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="feature">SamplingPoint(s)</td>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D32 := prof:current-ms()

(: D32.1 :)

let $ns1D32.1 := prof:current-ms()

let $D32.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:namespace)
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

let $ns2D32.1 := prof:current-ms()

(: D33 :)

let $ns1D33 := prof:current-ms()

let $D33invalid :=
    try {
        let $valid := ($vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI || "air", $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI_UC || "air")
        for $x in $docRoot//aqd:AQD_SamplingPoint/ef:mediaMonitored
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:mediaMonitored">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }


let $ns2D33 := prof:current-ms()

(: D34 :)

let $ns1D34 := prof:current-ms()

let $D34invalid :=
    try {
        let $D34validURN := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4258", "urn:ogc:def:crs:EPSG::4326")
        for $x in distinct-values($docRoot//aqd:AQD_SamplingPoint[count(ef:geometry/gml:Point) > 0 and not(ef:geometry/gml:Point/@srsName = $D34validURN)]/ef:inspireId/base:Identifier/string(base:localId))
        return
            <tr>
                <td title="base:localId">{$x}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D34 := prof:current-ms()

(: D35 :)

let $ns1D35 := prof:current-ms()

let $D35invalid :=
    try {
        for $x in $docRoot//aqd:AQD_SamplingPoint
        let $missing := empty($x/ef:geometry/gml:Point/gml:pos)

         let $NamespaceDD := 
             for $x in doc($vocabulary:AQD_Namespace || "rdf")//skos:Concept
              
                let $currentCountry := string(fn:upper-case($countryCode))
                let $countryyy := string($x/prop:inCountry/@rdf:resource)
                let $length := fn:string-length($countryyy) - 1
                let $sbst := fn:substring($countryyy, $length, 2)
                let $LongitudeMax :=  $x/prop:LongitudeMax
                let $LongitudeMin :=  $x/prop:LongitudeMin
                let $LatitudeMax :=  $x/prop:LatitudeMax
                let $LatitudeMin :=  $x/prop:LatitudeMin

                where ($currentCountry = $sbst)            

                return $LongitudeMax || "###"|| $LongitudeMin || "###"|| $LatitudeMax || "###"|| $LatitudeMin
       
        let $LongitudeMax := number(tokenize($NamespaceDD, "###")[1])
        let $LongitudeMin := number(tokenize($NamespaceDD, "###")[2])
        let $LatitudeMax := number(tokenize($NamespaceDD, "###")[3])
        let $LatitudeMin := number(tokenize($NamespaceDD, "###")[4])


        let $invalid :=
        

            for $i in $x/ef:geometry/gml:Point/gml:pos
            let $latlongToken := tokenize($i, "\s+")
            let $lat := number($latlongToken[1])
            let $long := number($latlongToken[2])
            let $missing := string($lat) = 'NaN' or string($long) = 'NaN'
            where   not($lat <= $LatitudeMax and $lat >= $LatitudeMin) or
                    not($long <= $LongitudeMax and $long >=$LongitudeMin)  or $missing
            return 1
        where (not($countryCode = "fr") and ($x/ef:geometry/gml:Point/gml:pos/@srsDimension != "2" or $invalid = 1 or $missing))
        return
            <tr>
                <td title="base:localId">{string($x/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="@srsDimension">{string($x/ef:geometry/gml:Point/gml:pos/@srsDimension)}</td>
                <td title="Pos">{string($x/ef:geometry/gml:Point/gml:pos)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }
let $D35message :=
    if ($countryCode = "fr") then
        "Temporary turned off"
    else
        "All srsDimension attributes resolve to '2'"


let $ns2D35 := prof:current-ms()

(: D36 :)

let $ns1D36 := prof:current-ms()

let $D36invalid :=
    try {
        let $approximity := 0.0003

        (: StationID|long#lat :)
        let $aqdStationPos :=
            for $allPos in $docRoot//aqd:AQD_Station
            where not(empty($allPos/ef:geometry/gml:Point/gml:pos))
            return concat($allPos/ef:inspireId/base:Identifier/base:namespace, "/", $allPos/ef:inspireId/base:Identifier/base:localId, "|",
                    fn:substring-before(data($allPos/ef:geometry/gml:Point/gml:pos), " "), "#", fn:substring-after(data($allPos/ef:geometry/gml:Point/gml:pos), " "))


        for $gmlPos in $docRoot//aqd:AQD_SamplingPoint[ef:geometry/gml:Point/gml:pos]
        let $efBroader := $gmlPos/ef:broader/@xlink:href
        let $samplingStationId := data($efBroader)
        let $stationPos :=
            for $station in $aqdStationPos
            let $stationId := fn:substring-before($station, "|")
            return if ($stationId = $samplingStationId) then $station else ()

        let $stationLong := if (not(empty($stationPos))) then fn:substring-before(fn:substring-after($stationPos[1], "|"), "#") else ""
        let $stationLat := if (not(empty($stationPos))) then fn:substring-after(fn:substring-after($stationPos[1], "|"), "#") else ""

        let $samplingPos := data($gmlPos/ef:geometry/gml:Point/gml:pos)
        let $samplingLong := if (not(empty($samplingPos))) then fn:substring-before($samplingPos, " ") else ""
        let $samplingLat := if (not(empty($samplingPos))) then fn:substring-after($samplingPos, " ") else ""


        let $stationLong := if ($stationLong castable as xs:decimal) then xs:decimal($stationLong) else 0.00
        let $stationLat := if ($stationLat castable as xs:decimal) then xs:decimal($stationLat) else 0.00

        let $samplingLong := if ($samplingLong castable as xs:decimal) then xs:decimal($samplingLong) else 0.00
        let $samplingLat := if ($samplingLat castable as xs:decimal) then xs:decimal($samplingLat) else 0.00

        return
            if (abs($samplingLong - $stationLong) > $approximity or abs($samplingLat - $stationLat) > $approximity) then
                <tr>
                    <td title="@gml:id">{string($gmlPos/@gml:id)}</td>
                </tr>
            else
                ()
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }


let $ns2D36 := prof:current-ms()

(: D37b - check for invalid data or if beginPosition > endPosition :)

let $ns1D37b := prof:current-ms()

let $D37binvalid :=
    try {
      let $arrayMultipleOpActivs := $docRoot//aqd:AQD_SamplingPoint[count(ef:operationalActivityPeriod) > 1]
        
      where (count($arrayMultipleOpActivs) = 0 )     
      
        let $invalidPosition :=
             (:for  $timePeriod in $docRoot//aqd:AQD_Station/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod:)
           for $timePeriod in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
            (: XQ does not support 24h that is supported by xml schema validation :)
            (: TODO: comment by sofiageo - the above statement is not true, fix this if necessary :)
            let $beginDate := substring(normalize-space($timePeriod/gml:beginPosition), 1, 10)
            let $endDate := substring(normalize-space($timePeriod/gml:endPosition), 1, 10)
            let $beginPosition :=
                if ($beginDate castable as xs:date) then
                    xs:date($beginDate)
                    else if ($beginDate = "") then
                    "empty"
                else
                    "error"
            let $endPosition :=
                if ($endDate castable as xs:date) then
                    xs:date($endDate)
                else if ($endDate = "") then
                    "empty"
                else
                    "error"

            return
                if ((string($beginPosition) = "error" or string($endPosition) = "error" or string($beginPosition) = "empty") or
                        ($beginPosition instance of xs:date and $endPosition instance of xs:date and $beginPosition > $endPosition)) then
                    <tr>
                        <td title="aqd:AQD_SamplingPoint">{data($timePeriod/../../../../ef:inspireId/base:Identifier/base:localId)}</td>
                        <td title="gml:TimePeriod">{data($timePeriod/@gml:id)}</td>
                        <td title="gml:beginPosition">{$timePeriod/gml:beginPosition}</td>
                        <td title="gml:endPosition">{$timePeriod/gml:endPosition}</td>
                    </tr>

                else
                    ()
       
       (: if ((count($observingCapabilities)=1) and (($periodBeginPos!= $observingCapabilitiesBeginMin) or 
                    ($periodEndPos != $observingCapabilitiesEndMax))) then
                    fn:false()

                  else   if((count($observingCapabilities)>1) and (($periodBeginPos!= $observingCapabilities[1]/observingBeginPos) or 
                    ($periodEndPos != $observingCapabilitiesLastEnd))) then
                     fn:false():)
               (:) if (($periodBeginPos!= $observingCapabilitiesBeginMin) or 
                    ($periodEndPos != $observingCapabilitiesEndMax)) then:)

               (: if ($pos < count($observingCapabilities)) then :)
                    (:if ((($periodBeginPos!= $observingCapabilities[1]/observingBeginPos)and($observingCapabilities[1]=$observingCap)) or 
                        (($periodEndPos != $observingCapabilitiesLastEnd)and ($observingCapabilities[last()]=$observingCap))) then
                         
                        fn:false()
                     else :)

                       (: let $observingCapabilitiesBegin := $observingCap/observingBeginPos               

               let $observingCapabilitiesEnd:=                    
                    
                        if ( $observingCap/observingEndPos!="")
                        then xs:date( $observingCap/observingEndPos)
                        else
                        xs:date("2800-01-01")
:)
                   
         let $overlappingPeriods :=
            for $operationalPeriod in $docRoot//aqd:AQD_SamplingPoint

                       
                let $periodBeginPos:=                  
                    if ($operationalPeriod/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition!="")
                    then xs:date(substring(normalize-space($operationalPeriod/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition), 1, 10))
                    else  xs:date("1800-01-01")

                let $periodEndPos:=                  
                    if ($operationalPeriod/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition!="")
                    then xs:date(substring(normalize-space($operationalPeriod/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition), 1, 10))
                    else  xs:date("2800-01-01")

                let $observingCapabilities :=
                    for $cp in $operationalPeriod/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
                        order by $cp/gml:beginPosition
                        return                         
                        <result>
                            <localId>{$cp/../../../../ef:inspireId/base:Identifier/base:localId}</localId>
                            <observingBeginPos>{(substring(normalize-space($cp/gml:beginPosition), 1, 10))}</observingBeginPos>
                            <observingEndPos>{(substring(normalize-space($cp/gml:endPosition), 1, 10))}</observingEndPos>                                                       
                            <nextSiblingBegin>{(substring(normalize-space(($cp/../../../following-sibling::ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition)[1]), 1, 10))}</nextSiblingBegin>
                            <nextSiblingEnd>{(substring(normalize-space(($cp/../../../following-sibling::ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition)[1]), 1, 10))}</nextSiblingEnd>
                            <nextSiblingLocalId>{(($cp/../../../following-sibling::ef:observingCapability/../ef:inspireId/base:Identifier/base:localId)[1])}</nextSiblingLocalId>
                               
                       </result>

                  let $observingDatesBegin:=
                    for $x in $observingCapabilities
                    return
                        if (($x/observingDatesBegin!="")and($x/observingDatesBegin castable as xs:date))
                        then xs:date($x/observingEndPos)
                        else
                        xs:date("1800-01-01")

                
                let $observingCapabilitiesBeginMin:= min($observingDatesBegin)
           

                let $observingDatesEnd:=
                    for $x in $observingCapabilities
                    return
                        if (($x/observingEndPos!="")and($x/observingEndPos castable as xs:date))
                        then xs:date($x/observingEndPos)
                        else
                        xs:date("2800-01-01")

                
                let $observingCapabilitiesEndMax:= max($observingDatesEnd)
               
              for $observingCap at $pos in $observingCapabilities 

                           let $observingCapabilitiesLastEnd:=
                 if ( $observingCapabilities[last()]/observingEndPos!="")
                                        then xs:date( $observingCapabilities[last()]/observingEndPos)
                                        else
                                        xs:date("2800-01-01")
                
               (:) let $next_observingBeginPos :=xs:date($observingCap/nextSiblingBegin):)
                
                let $next_observingBeginPos :=
                    if ( $observingCap/nextSiblingBegin!="")
                                            then xs:date($observingCap/nextSiblingBegin)
                                            else
                                            xs:date("1800-01-01")
               

                let $next_observingEndPos :=
                    if ( $observingCap/nextSiblingEnd!="")
                                            then xs:date($observingCap/nextSiblingEnd)
                                            else
                                            xs:date("2800-01-01")

                let $observingBeginPos :=
                    if ( $observingCap/observingBeginPos!="")
                                            then xs:date($observingCap/observingBeginPos)
                                            else
                                            xs:date("1800-01-01")
               

                let $observingEndPos :=
                    if ( $observingCap/observingEndPos!="")
                                            then xs:date($observingCap/observingEndPos)
                                            else
                                            xs:date("2800-01-01")
               
               let $ok := 
              
                     if  (   ($periodBeginPos = xs:date("1800-01-01")) or
                            ($observingBeginPos = xs:date("1800-01-01")) or
                            (($observingBeginPos >= $next_observingBeginPos)and ($observingCap[$pos]/localId = $observingCap[$pos]/nextSiblingLocalId ))or
                            (($observingCap[$pos]/observingEndPos!="")and($observingCap[$pos]/observingEndPos > $next_observingBeginPos)and ($observingCap[$pos]/localId = $observingCap[$pos]/nextSiblingLocalId)) or
                            (($next_observingEndPos < $next_observingBeginPos)and ($observingCap[$pos]/localId = $observingCap[$pos]/nextSiblingLocalId))or
                            ($observingBeginPos > $periodEndPos) or
                            (($observingCap[$pos]/observingEndPos =  "") and ($observingCap[$pos+1]/observingEndPos =  ""))or
                            (($periodBeginPos!= $observingCapabilities[1]/observingBeginPos)and($observingCapabilities[1]=$observingCap)) or
                            (($periodEndPos != $observingCapabilitiesLastEnd)and ($observingCapabilities[last()]=$observingCap))
                            )
                            then 
                                fn:false() 

                    else fn:true()
                             
                            (:) )
                else fn:true():)

                    let $periodEndPos1:=  if ($periodEndPos = xs:date("2800-01-01")) then "" else $periodEndPos
                    let $observingCapabilitiesEndMax1:=  if ($observingCapabilitiesEndMax = xs:date("2800-01-01")) then "" else $observingCapabilitiesEndMax 
                    let $observingCapabilitiesBeginMin1:=  if ($observingCapabilitiesBeginMin = xs:date("1800-01-01")) then "" else $observingCapabilitiesBeginMin 
                    let $next_observingBeginPos1:=  if ($next_observingBeginPos = xs:date("1800-01-01")) then "" else $next_observingBeginPos
                    let $next_observingEndPos1:=  if ($next_observingEndPos = xs:date("2800-01-01")) then "" else $next_observingEndPos
                    let $periodBeginPos1:=  if ($periodBeginPos = xs:date("1800-01-01")) then "" else $periodBeginPos
                    let $observingBeginPos1:=  if ($observingBeginPos = xs:date("1800-01-01")) then "" else $observingBeginPos

               
        (:let $observingBeginPosW :=
                    if ( $observingCap/observingBeginPos!="")
                                            then xs:date($observingCap/observingBeginPos):)
                                            
               let $isWarning:=     
                if (($periodBeginPos != xs:date("1800-01-01"))and ($observingBeginPos!=xs:date("1800-01-01"))
                and ($observingBeginPos!=$periodBeginPos) and ($observingBeginPos < xs:date("2013-01-02"))
                and ($periodBeginPos < xs:date("2013-01-02")))  then
                true()
                else false()

           (: let $errorClassD37b :=
                if ($isWarning) then 
                $errors:WARNING
            else
                $errors:BLOCKER
           :)

            return if (not($ok)and not($isWarning))  then  

                <tr>
                    <td title="aqd:AQD_SamplingPoint">{$observingCap/localId}</td>
                    <td title="operational TimePeriod">{$periodBeginPos1 || "/" || $periodEndPos1}</td>
                    <td title="observing beginPosition">{$observingBeginPos1}</td>
                    <td title="observing endPosition">{$observingCap/observingEndPos}</td> 
                    <td title="next observing period begin date">{$next_observingBeginPos1}</td>                    
                    <td title="next observing period end date">{$next_observingEndPos1}</td>  
                    <td title="type of error">ERROR</td>
                    
                </tr>

                else if (not ($ok) and ($isWarning)) then

                <tr>
                    <td title="aqd:AQD_SamplingPoint">{$observingCap/localId}</td>
                    <td title="operational TimePeriod">{$periodBeginPos1 || "/" || $periodEndPos1}</td>
                    <td title="observing beginPosition">{$observingBeginPos1}</td>
                    <td title="observing endPosition">{$observingCap/observingEndPos}</td> 
                    <td title="next observing period begin date">{$next_observingBeginPos1}</td>                    
                    <td title="next observing period end date">{$next_observingEndPos1}</td> 
                    <td title="type of error">WARNING</td>  
                     
                               
                </tr>

    
        return (($invalidPosition), ($overlappingPeriods))




    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D37b := prof:current-ms()

(: D37a - Check if a SPO has more than one operational time activity. :)


let $ns1D37a := prof:current-ms()

let $D37afunc := function() {
   
for $operationalPeriod in $docRoot//aqd:AQD_SamplingPoint
    let $countOperationalPeriod := count($operationalPeriod/ef:operationalActivityPeriod)

    where ($countOperationalPeriod > 1 )
    return
        <tr>
            <td title="aqd:AQD_SamplingPoint">{data($operationalPeriod/@gml:id)}</td>
          
        </tr>

}
let $D37ainvalid := errors:trycatch($D37afunc)

let $ns2D37a := prof:current-ms()

(: D38 - Check if superseded Sampling Point can be found in the data flow D delivered in the past. :)

let $ns1D38 := prof:current-ms()

let $D38func := function() {
    let $historicSamplingPoints := data(sparqlx:run(query:getSamplingPoint($cdrUrl))/sparql:binding[@name = 'inspireLabel']/sparql:literal)
    for $x in $docRoot//aqd:AQD_SamplingPoint[ef:supersedes]
    let $xlink := string($x/ef:supersedes/@xlink:href)
    where $xlink = "" or not($xlink = $historicSamplingPoints)
    return
        <tr>
            <td title="aqd:AQD_SamplingPoint">{data($x/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="xlink:href">{$xlink}</td>
            <td title="Sparql">{sparqlx:getLink(query:getSamplingPoint($cdrUrl))}</td>
        </tr>

}
let $D38invalid := errors:trycatch($D38func)


let $ns2D38 := prof:current-ms()

(: D39 :)

let $ns1D39 := prof:current-ms()

let $D39invalid :=
    try {
        for $x in $docRoot//aqd:AQD_SamplingPoint
        where ($x/ef:supersedes) or ($x/ef:supersededBy)
        return
            <tr class="{$errors:BLOCKER}">
                <td title="aqd:AQD_SamplingPoint">{string($x/@gml:id)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D39 := prof:current-ms()


(: D40 :)

let $ns1D40 := prof:current-ms()

let $D40invalid :=
    try {
        for $x in $docRoot//aqd:AQD_SamplingPoint
        where (not($x/ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = $dd:VALIDPOLLUTANTS)) or
                (count(distinct-values(data($x/ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href))) > 1)
        return
            <tr>
                <td title="base:localId">{$x/ef:inspireId/base:Identifier/string(base:localId)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D40 := prof:current-ms()


(: D41 Updated by Jaume Targa following working logic of D44 :)

let $ns1D41 := prof:current-ms()

let $D41invalid :=
    try {
        let $aqdSampleLocal :=
            for $z in $docRoot//aqd:AQD_Sample
            let $id := concat(data($z/aqd:inspireId/base:Identifier/base:namespace), '/',
                    data($z/aqd:inspireId/base:Identifier/base:localId))
            return $id

        for $x in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
        where empty(index-of($aqdSampleLocal, fn:normalize-space($x/@xlink:href)))
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/../@gml:id)}</td>
                <td title="ef:featureOfInterest">{data(fn:normalize-space($x/@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }


let $ns2D41 := prof:current-ms()

(: D42 :)

let $ns1D42 := prof:current-ms()

let $D42invalid :=
    try {
        let $aqdProcessLocal :=
            for $allProcessLocal in $docRoot//aqd:AQD_SamplingPointProcess
            let $id := concat(data($allProcessLocal/ompr:inspireId/base:Identifier/base:namespace),
                    '/', data($allProcessLocal/ompr:inspireId/base:Identifier/base:localId))
            return $id

        for $x in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:procedure
        where empty(index-of($aqdProcessLocal, fn:normalize-space($x/@xlink:href)))
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/../../../@gml:id)}</td>
                <td title="ef:procedure">{data(fn:normalize-space($x/@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D42 := prof:current-ms()

(: D43 Updated by Jaume Targa following working logic of D44 :)

let $ns1D43 := prof:current-ms()

let $D43invalid :=
    try {
        let $aqdStationLocal :=
            for $z in $docRoot//aqd:AQD_Station
            let $id := concat(data($z/ef:inspireId/base:Identifier/base:namespace), '/',
                    data($z/ef:inspireId/base:Identifier/base:localId))
            return $id

        for $x in $docRoot//aqd:AQD_SamplingPoint/ef:broader
        where empty(index-of($aqdStationLocal, fn:normalize-space($x/@xlink:href)))
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/../@gml:id)}</td>
                <td title="ef:broader">{data(fn:normalize-space($x/@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D43 := prof:current-ms()


(: D44 :)

let $ns1D44 := prof:current-ms()

let $D44invalid :=
    try {
        let $aqdNetworkLocal :=
            for $z in $docRoot//aqd:AQD_Network
            let $id := concat(data($z/ef:inspireId/base:Identifier/base:namespace), '/',
                    data($z/ef:inspireId/base:Identifier/base:localId))
            return $id
        
        for $x in $docRoot//aqd:AQD_SamplingPoint

        let $el :=$x/ef:belongsTo
        where empty(index-of($aqdNetworkLocal, fn:normalize-space($el/@xlink:href))) or not(exists($el))
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/@gml:id)}</td>
                <td title="ef:belongsTo">{(fn:normalize-space($el/@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D44 := prof:current-ms()


(: D45 - Find all period with out end period :)

let $ns1D45 := prof:current-ms()



    let $D45invalid :=
    try { (:original commented on 20210810:)
        (:for $allSamplings in $docRoot//aqd:AQD_SamplingPoint
                    let $broader:= fn:substring-after(data($allSamplings/ef:broader/@xlink:href), '/')
                    let $samplingBeginPos:=$allSamplings/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:beginPosition
                    let $samplingEndPos:=$allSamplings/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod/gml:endPosition
               
                        for $x in $docRoot//aqd:AQD_Station 
                        let $stationBeginPos:=$x/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition
                        let $stationEndPos:=$x/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition                

                   where ( ($broader!="")and ($broader = data($x/ef:inspireId/base:Identifier/base:localId)))
   

                    return
                    
                    if (($samplingBeginPos < $stationBeginPos) or 
                        ($samplingBeginPos="") or 
                        ($stationBeginPos="") or 
                        (($stationEndPos != "") and ($samplingEndPos != "") and ($samplingEndPos > $stationEndPos) ) or
                        (($stationEndPos != "") and(($samplingEndPos[normalize-space(@indeterminatePosition) = "unknown"] )or ($samplingEndPos = "")))    
                        )

                    then                 
        
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($allSamplings/@gml:id)}</td>
                <td title="belongs to aqd:AQD_Station ">{$broader}</td>
                <td title="Sampling Point beginPos">{$samplingBeginPos}</td>
                <td title="Station beginPos">{$stationBeginPos}</td>
                <td title="Sampling Point endPos">{$samplingEndPos}</td>
                <td title="Station endPos">{$stationEndPos}</td>
            </tr>:)
            
            
            (:modified to improve the speed in August 2020 by @diezzana and @goititer, issue #131759:)
            let $aqdSamplings := 
              
                for $allSamplings in $docRoot//aqd:AQD_SamplingPoint
                    let $broader:= fn:substring-after(data($allSamplings/ef:broader/@xlink:href), '/')
                    let $operationalOccurrences:= count($allSamplings/ef:operationalActivityPeriod)

                    (: operationalActivityPeriod can be multiple: :)
                    for $x in $allSamplings/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod
                      let $samplingBeginPos:=$x/gml:beginPosition
                      let $samplingEndPos:=$x/gml:endPosition 
                      (: let $endDate := substring(normalize-space($timePeriod/gml:endPosition), 1, 10):) 
                    
                    return                         
                        <result>
                            <sampling>{data($allSamplings/@gml:id)}</sampling>
                            <broader>{$broader}</broader>
                            <samplingBeginPos>{$samplingBeginPos}</samplingBeginPos>
                            <samplingEndPos>{$samplingEndPos}</samplingEndPos>
                            <occurrences>{$operationalOccurrences}</occurrences>
                       </result>
                      
                    
               
           let $aqdStations := 
          
                for $x in $docRoot//aqd:AQD_Station 
                        let $stationBeginPos0 :=$x/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition
                        let $stationEndPos0 :=$x/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition
                        
                        (: regex expression to compare the $stationBeginPos and $stationEndPos dates format with the ISO 8601 extended format: 
                        2014-01-01T00:00:00+01:00 | 2014-01-01T00:00:00Z | 2020-10-07T20:20:05Z | 2014-01-01T00:00:00-01:00 :)  
                        let $stationBeginPos :=
                            (:if (matches($stationBeginPos0, "^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])T(00|0[0-9]|1[0-9]|2[0-4]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])((\+([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9]))|(\-([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9]))|(Z))$") ) then:)
                            if (matches($stationBeginPos0, "^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])T(00|0[0-9]|1[0-9]|2[0-4]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])(|(\+([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9]))|(\-([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9]))|(Z))$") ) then
                          
                                $stationBeginPos0
                            else
                              if($stationBeginPos0 != "") then 
                                xs:dateTime(concat(xs:string($stationBeginPos0),"T00:00:00+01:00"))
                              (:  xs:dateTime(xs:string($stationBeginPos0)):)
                                
                        let $stationEndPos :=
                            if (matches($stationEndPos0, "^\d\d\d\d-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])T(00|0[0-9]|1[0-9]|2[0-4]):([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9])(|(\+([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9]))|(\-([0-9]|[0-5][0-9]):([0-9]|[0-5][0-9]))|(Z))$") ) then
                                $stationEndPos0
                            else
                              if($stationEndPos0 != "") then
                                xs:dateTime(concat(xs:string($stationEndPos0),"T00:00:00+01:00"))  
                                (:xs:dateTime(xs:string($stationEndPos0)):)
                                               
                     return                         
                        <result>
                            <station>{data($x/@gml:id)}</station>
                            <stationBeginPos0>{$stationBeginPos0}</stationBeginPos0>
                            <stationEndPos0>{$stationEndPos0}</stationEndPos0>
                            <stationBeginPos>{$stationBeginPos}</stationBeginPos>
                            <stationEndPos>{$stationEndPos}</stationEndPos>
                            <stationLocalId>{data($x/ef:inspireId/base:Identifier/base:localId)}</stationLocalId>
                       </result>
            

          
          for $samp in $aqdSamplings
            for $stat in $aqdStations

            
                       
                   where ( ($samp/broader!="")and ($samp/broader = data($stat/stationLocalId)))
  
                    return
                    
                    if ( (($stat/stationBeginPos != "") and ($samp/samplingBeginPos != "") and ($samp/samplingBeginPos < $stat/stationBeginPos)) or 
                        ($samp/samplingBeginPos="") or 
                        ($stat/stationBeginPos="") or 
                        (($stat/stationEndPos != "") and ($samp/samplingEndPos != "") and ($samp/samplingEndPos > $stat/stationEndPos) ) or
                        (($stat/stationEndPos != "") and(($samp/samplingEndPos[normalize-space(@indeterminatePosition) = "unknown"] )or ($samp/samplingEndPos = "")))  
                        )   


                    then
        
                      <tr>
                          <td title="aqd:AQD_SamplingPoint">{$samp/sampling}</td>
                          <td title="belongs to aqd:AQD_Station ">{$samp/broader}</td>
                          <td title="Sampling Point beginPos">{$samp/samplingBeginPos}</td>
                          <td title="Station beginPos">{$stat/stationBeginPos0}</td>
                          <td title="Sampling Point endPos">{$samp/samplingEndPos}</td>
                          <td title="Station endPos">{$stat/stationEndPos0}</td>
                          <td title="Operational dates occurrences">{$samp/occurrences}</td>
                      </tr>

    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D45 := prof:current-ms()


(: D46 :)

let $ns1D46 := prof:current-ms()

let $D46invalid :=
    try {
        for $operationActivityPeriod in $docRoot//aqd:AQD_SamplingPoint/ef:operationalActivityPeriod
        where $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition) = "unknown"]
                or fn:string-length($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) = 0
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($operationActivityPeriod/../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
                <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
                <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D46 := prof:current-ms()

(: D48 :)

let $ns1D48 := prof:current-ms()

let $D48invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:ASSESSMENTTYPE_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:assessmentType
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="{$x/../name()}">{data($x/..//base:Identifier/base:localId)}</td>
                <td title="aqd:assessmentType">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D48 := prof:current-ms()

(: D49 :)

let $ns1D49 := prof:current-ms()



let $D49invalid :=
    try {
        let $validEmission := dd:getValidConcepts($vocabulary:EMISSION_SOURCE || "rdf")
        let $wrongEmissionURL:=
            for $x in $docRoot//aqd:relevantEmissions/aqd:RelevantEmissions/aqd:mainEmissionSources
            where not($x/@xlink:href = $validEmission)
            return $x/@xlink:href || "##" || $x/../../../ef:inspireId/base:Identifier/base:localId || "$$" || "aqd:mainEmissionSources"

        let $validStationClass := dd:getValidConcepts($vocabulary:STATION_CLASSIFICATION || "rdf")
        let $wrongStationClassURL:=
            for $x in $docRoot//aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification 
            where not($x/@xlink:href = $validStationClass)
            return $x/@xlink:href || "##" || $x/../../../ef:inspireId/base:Identifier/base:localId|| "$$" || "aqd:stationClassification"

        let $wrongUom:=
            for $uom in $docRoot//aqd:relevantEmissions/aqd:RelevantEmissions/aqd:distanceSource
            let $status:=
            
                if (starts-with($uom/@uom,'http://') or starts-with($uom/@uom,'https://')) then (      
                       
                                let $request := <http:request href="{$uom/@uom}" method="HEAD"/>
                                let $response := http:send-request($request)[1]  

                                let $url := $request/@href 
                                let $message := $response/@message

                                return  $response/@status)
                else (

                   0
                    )
                where not ($status = 200)
                return $uom/@uom || "##" || $uom/../../../ef:inspireId/base:Identifier/base:localId|| "$$" || "aqd:distanceSource"
   
    
     let $result:=($wrongEmissionURL,$wrongStationClassURL,$wrongUom)
        

       
        for $x in $result
        let $id:=substring-after($x, '##')
        
        return

      
            <tr>
               
               <td title="gml:id">{substring-before($id, '$$')}</td>
                <td title="url">{substring-before($x, '##')}</td>
                <td title="failing element">{substring-after($x, '$$')}</td>
                 
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D49 := prof:current-ms()

(: D50 :)

let $ns1D50 := prof:current-ms()

let $D50invalid :=
    try {
        let $rdf := doc("http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/rdf")
        let $all := data($rdf//skos:Concept[adms:status/@rdf:resource="http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"]/@rdf:about)

        for $x in $docRoot//aqd:AQD_SamplingPoint[not(aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href = $all)]
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="xlink:href">{data($x/aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D50 := prof:current-ms()


(: D51 :)

let $ns1D51 := prof:current-ms()

let $D51invalid :=
    try {
        let $exceptions := ($vocabulary:OBJECTIVETYPE_VOCABULARY || "MO")
        let $environmentalObjectiveCombinations := doc("http://dd.eionet.europa.eu/vocabulary/aq/environmentalobjective/rdf")
        for $x in $docRoot//aqd:AQD_SamplingPoint/aqd:environmentalObjective/aqd:EnvironmentalObjective
            for $z in $x/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href
            let $pollutant := data($z)
            let $objectiveType := data($x/aqd:objectiveType/@xlink:href)
            let $reportingMetric := data($x/aqd:reportingMetric/@xlink:href)
            let $protectionTarget := data($x/aqd:protectionTarget/@xlink:href)
        where not($objectiveType = $exceptions) and not($environmentalObjectiveCombinations//skos:Concept[prop:relatedPollutant/@rdf:resource = $pollutant and prop:hasProtectionTarget/@rdf:resource = $protectionTarget
                and prop:hasObjectiveType/@rdf:resource = $objectiveType and prop:hasReportingMetric/@rdf:resource = $reportingMetric])
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/../../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:observedProperty">{$pollutant}</td>
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

let $ns2D51 := prof:current-ms()


(: D53 :)

let $ns1D53 := prof:current-ms()

let $D53invalid :=
    try {
        let $zones := distinct-values(data(sparqlx:run(query:getZone($latestEnvelopeB))/sparql:binding[@name = 'inspireLabel']/sparql:literal))
        for $x in $docRoot//aqd:AQD_SamplingPoint/aqd:zone[not(@nilReason = 'inapplicable')]
        where not($x/@xlink:href = $zones)
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:zone">{data($x/@xlink:href)}</td>
                <td title="Sparql">{sparqlx:getLink(query:getZone($latestEnvelopeB))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D53 := prof:current-ms()


(: D54 - aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier/base:localId not unique codes :)

let $ns1D54 := prof:current-ms()

let $D54invalid :=
    try {
        let $localSamplingPointProcessIds := $docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier
        for $idSamplingPointProcessCode in $docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier
        where
            count(index-of($localSamplingPointProcessIds/base:localId, normalize-space($idSamplingPointProcessCode/base:localId))) > 1 and
                    count(index-of($localSamplingPointProcessIds/base:namespace, normalize-space($idSamplingPointProcessCode/base:namespace))) > 1
        return
            <tr>
                <td title="base:localId">{data($idSamplingPointProcessCode/base:localId)}</td>
                <td title="base:namespace">{data($idSamplingPointProcessCode/base:namespace)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D54 := prof:current-ms()

(: D55 :)

let $ns1D55 := prof:current-ms()

let $D55table :=
    try {
        for $id in $SPPnamespaces
        let $localId := $docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="feature">SamplingPointProcess(es)</td>
                <td title="base:namespace">{$id}</td>
                <td title="unique localId">{count($localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D55 := prof:current-ms()

(: D55.1 :)

let $ns1D55.1 := prof:current-ms()

let $D55.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//aqd:AQD_SamplingPointProcess/ef:inspireId/base:Identifier/base:namespace)
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

let $ns2D55.1 := prof:current-ms()


(: D56 :)

let $ns1D56 := prof:current-ms()

let $D56invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:MEASUREMENTTYPE_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_SamplingPointProcess/aqd:measurementType
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:measurementType">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D56 := prof:current-ms()


(: D57 :)

let $ns1D57 := prof:current-ms()

let $D57table :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:MEASUREMENTMETHOD_VOCABULARY || "rdf")
        for $process in doc($source_url)//aqd:AQD_SamplingPointProcess
        let $measurementType := data($process/aqd:measurementType/@xlink:href)
        let $measurementMethod := data($process/aqd:measurementMethod/aqd:MeasurementMethod/aqd:measurementMethod/@xlink:href)
        let $samplingMethod := data($process/aqd:samplingMethod/aqd:SamplingMethod/aqd:samplingMethod/@xlink:href)
        let $analyticalTechnique := data($process/aqd:analyticalTechnique/aqd:AnalyticalTechnique/aqd:analyticalTechnique/@xlink:href)
        where ($measurementType = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/automatic' or
                $measurementType = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/remote')
                and (
                    string-length($samplingMethod) > 0 or string-length($analyticalTechnique) > 0 or not($measurementMethod = $valid)
                )

        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($process/ompr:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:measurementType">{$measurementType}</td>
                <td title="aqd:measurementMethod">{$measurementMethod}</td>
                <td title="aqd:samplingMethod">{$samplingMethod}</td>
                <td title="aqd:analyticalTechnique">{$analyticalTechnique}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D57 := prof:current-ms()


(: D58 Done by Rait :)

let $ns1D58 := prof:current-ms()

let $D58table :=
    try {
        let $allConceptUrl58 :=
        for $conceptUrl in doc($source_url)//aqd:AQD_SamplingPointProcess/aqd:measurementType/@xlink:href
        where $conceptUrl = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/active' or
                $conceptUrl = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/passive'
        return $conceptUrl
        for $checkElements in $allConceptUrl58
            let $style1 := if(count($checkElements/../../aqd:samplingMethod) = 0 ) then "color:red;" else ""
            let $style2 := if(count($checkElements/../../aqd:analyticalTechnique) = 0) then "color:red;" else ""
            let $style3 := if(count($checkElements/../../aqd:measurementMethod) >= 1) then "color:red;" else ""
        where (count($checkElements/../../aqd:samplingMethod) = 0 or count($checkElements/../../aqd:analyticalTechnique) = 0)
                 or count($checkElements/../../aqd:measurementMethod) >= 1
        return
            <tr>
                <td title="gml:id">{data($checkElements/../../@gml:id)}</td>
                <td style="{$style1}" title="aqd:samplingMethod">{if(count($checkElements/../../aqd:samplingMethod) = 0 ) then "Error, shall  be provided." else "Valid."}</td>
                <td style="{$style2}" title="aqd:analyticalTechnique">{if(count($checkElements/../../aqd:analyticalTechnique) = 0) then "Error, shall  be provided." else "Valid."}</td>
                <td style="{$style3}" title="aqd:measurementMethod">{if(count($checkElements/../../aqd:measurementMethod) >= 1) then "Error, shall not be provided." else "Valid."}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D58 := prof:current-ms()


(: D59 Done by Rait:)
(: CORRECT PATH added by goititer:)

let $ns1D59 := prof:current-ms()

let $D59invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:ANALYTICALTECHNIQUE_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_SamplingPointProcess/aqd:analyticalTechnique/aqd:AnalyticalTechnique/aqd:analyticalTechnique
        where  not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/../../../ompr:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:measurementType">{data($x/@xlink:href)}</td>
               
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D59 := prof:current-ms()


(: D60a  :)

let $ns1D60a := prof:current-ms()

let $D60ainvalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:MEASUREMENTTYPE_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_SamplingPointProcess/aqd:measurementType
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/../ompr:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:measurementEquipment">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D60a := prof:current-ms()


(: D60b :)

let $ns1D60b := prof:current-ms()

let $D60binvalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:SAMPLINGEQUIPMENT_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_SamplingPointProcess/aqd:samplingEquipment/aqd:SamplingEquipment/aqd:equipment
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/../../../ompr:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:samplingEquipment">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D60b := prof:current-ms()


(: D61 :)

let $ns1D61 := prof:current-ms()

let $D61invalid :=
    try {
        for $x in $docRoot//aqd:AQD_SamplingPointProcess
        let $analyticalTechnique := $x/aqd:analyticalTechnique/aqd:AnalyticalTechnique/aqd:otherAnalyticalTechnique
        let $otherMeasurementMethod := $x/aqd:measurementMethod/aqd:MeasurementMethod/aqd:otherMeasurementMethod
        let $measurementEquipment := $x/aqd:measurementEquipment/aqd:MeasurementEquipment/aqd:otherEquipment
        let $otherSamplingMethod := $x/aqd:samplingMethod/aqd:SamplingMethod/aqd:otherSamplingMethod
        let $samplingEquipment := $x/aqd:SamplingEquipment/aqd:SamplingEquipment/aqd:otherEquipment
        where not(empty(($analyticalTechnique, $otherMeasurementMethod, $measurementEquipment, $otherSamplingMethod, $samplingEquipment)))
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/ompr:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:otherAnalyticalTechnique">{data($analyticalTechnique)}</td>
                <td title="aqd:otherMeasurementMethod">{data($otherMeasurementMethod)}</td>
                <td title="aqd:MeasurementEquipment">{data($measurementEquipment)}</td>
                <td title="aqd:otherSamplingMethod">{data($otherSamplingMethod)}</td>
                <td title="aqd:SamplingEquipment">{data($samplingEquipment)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D61 := prof:current-ms()


(: D62 - ./ompr:processParameter/ompr:ProcessParameter/ompr:name must correspond to a valid code under http://dd.eionet.europa.eu/vocabulary/aq/processparameter/ :)

let $ns1D62 := prof:current-ms()

let $D62func :=
    function() {
        let $valid := dd:getValidConcepts($vocabulary:PROCESS_PARAMETER || "rdf")
        for $x in $docRoot//ompr:ProcessParameter/ompr:name
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/../../../ompr:inspireId/base:Identifier/base:localId)}</td>
                <td title="ompr:name">{data($x/@xlink:href)}</td>
            </tr>
    }
let $D62invalid := errors:trycatch($D62func)

let $ns2D62 := prof:current-ms()

(: D63 :)

let $ns1D63 := prof:current-ms()

let $D63invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:UOM_CONCENTRATION_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:detectionLimit
        let $uom := string($x/@uom)
        where not ($uom = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{string($x/../../../ompr:inspireId/base:Identifier/base:localId)}</td>
                <td title="@uom">$uom</td>
            </tr>

    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D63 := prof:current-ms()


(: D65 :)

let $ns1D65 := prof:current-ms()

let $D65invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:UOM_TIME || "rdf")
        for $x in $docRoot//aqd:unit
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="{$x/../../../name()}">{data($x/../../..//base:Identifier/base:localId)}</td>
                <td title="aqd:unit">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D65 := prof:current-ms()


(: D67a :)

let $ns1D67a := prof:current-ms()

let $D67ainvalid :=
    try {
        let $rdf := doc("http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/rdf")
        let $all := data($rdf//skos:Concept[adms:status/@rdf:resource = "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"]/@rdf:about)
        let $wrongSPP :=
            for $x in $docRoot//aqd:AQD_SamplingPointProcess[not(string(aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href) = $all)]
            return string($x/ompr:inspireId/base:Identifier/base:namespace) || '/' || string($x/ompr:inspireId/base:Identifier/base:localId)

        for $x in $docRoot//aqd:AQD_SamplingPoint[aqd:usedAQD = "true"]
        let $xlink := data($x/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        where ($xlink = $wrongSPP)
        return
            <tr>
                <td title="gml:id">{data($x/@gml:id)}</td>
                <td title="base:localId">{data($x/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="base:namespace">{data($x/ef:inspireId/base:Identifier/base:namespace)}</td>
                <td title="ef:procedure">{$xlink}</td>
                <td title="ef:ObservingCapability">{data($x/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D67a := prof:current-ms()


(: D67b - ./aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated should resolve to
 : http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/ for all SamplingPointProcess :)

let $ns1D67b := prof:current-ms()

let $D67binvalid :=
    try {
        let $rdf := doc("http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/rdf")
        let $all := data($rdf//skos:Concept[adms:status/@rdf:resource = "http://dd.eionet.europa.eu/vocabulary/datadictionary/status/valid"]/@rdf:about)
        let $wrongSPP :=
            for $x in $docRoot//aqd:AQD_SamplingPointProcess[not(string(aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href) = $all)]
            return string($x/ompr:inspireId/base:Identifier/base:namespace) || '/' || string($x/ompr:inspireId/base:Identifier/base:localId)

        for $x in $docRoot//aqd:AQD_SamplingPoint
        let $xlink := data($x/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        where ($xlink = $wrongSPP)
        return
                <tr>
                    <td title="gml:id">{data($x/@gml:id)}</td>
                    <td title="base:localId">{data($x/ef:inspireId/base:Identifier/base:localId)}</td>
                    <td title="base:namespace">{data($x/ef:inspireId/base:Identifier/base:namespace)}</td>
                    <td title="ef:procedure">{$xlink}</td>
                    <td title="ef:ObservingCapability">{data($x/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>
                </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D67b := prof:current-ms()


(: D68 Jaume Targa :)

let $ns1D68 := prof:current-ms()

let $D68invalid :=
    try {
        let $allProcNotMatchingCondition68 :=
            for $proc in $docRoot//aqd:AQD_SamplingPointProcess
            let $demonstrated := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href)
            let $demonstrationReport := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport)
            where ($demonstrated = 'http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/yes' and fn:string-length($demonstrationReport) = 0)
            return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/', data($proc/ompr:inspireId/base:Identifier/base:localId))

        for $invalidTrueUsedAQD68 in $docRoot//aqd:AQD_SamplingPoint
        let $procIds68 := data($invalidTrueUsedAQD68/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed68 := $invalidTrueUsedAQD68/aqd:usedAQD = true()

        for $procId68 in $procIds68
        return
            if ($aqdUsed68 and not(empty(index-of($allProcNotMatchingCondition68, $procId68)))) then
                <tr>
                    <td title="gml:id">{data($invalidTrueUsedAQD68/@gml:id)}</td>
                    <td title="base:localId">{data($invalidTrueUsedAQD68/ef:inspireId/base:Identifier/base:localId)}</td>
                    <td title="base:namespace">{data($invalidTrueUsedAQD68/ef:inspireId/base:Identifier/base:namespace)}</td>
                    <td title="ef:procedure">{$procId68}</td>
                    <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD68/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>
                </tr>
            else
                ()
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D68 := prof:current-ms()


(: D69 :)

let $ns1D69 := prof:current-ms()

let $D69invalid :=
    try {
        let $all :=
            for $proc in $docRoot//aqd:AQD_SamplingPointProcess
            let $documentation := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:documentation)
            let $qaReport := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:qaReport)
            where (string-length($documentation) = 0) and (string-length($qaReport) = 0)
            return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))

        for $x in $docRoot//aqd:AQD_SamplingPoint[aqd:usedAQD = "true"]/ef:observingCapability[ef:ObservingCapability/ef:procedure/@xlink:href = $all]
        return
        <tr>
            <td title="base:localId">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($x/../ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{string($x/ef:ObservingCapability/ef:procedure/@xlink:href)}</td>
            <td title="ef:ObservingCapability">{data($x/ef:ObservingCapability/@gml:id)}</td>
        </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

let $ns2D69 := prof:current-ms()


(: D71 - ./aqd:inspireId/base:Identifier/base:localId shall be unique for AQD_Sample and unique within the namespace :)

let $ns1D71 := prof:current-ms()

let $D71invalid :=
    try {
        let $localSampleIds := data($docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:localId)
        let $D71namespaces := data($docRoot//base:namespace/../base:localId)
        for $x in $docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier
            let $id := string($x/base:localId)
        where count(index-of($localSampleIds, $id)) > 1 or count(index-of($D71namespaces, $id)) > 1
        return
            <tr>
                <td title="base:localId">{data($x/base:localId)}</td>
                <td title="base:namespace">{data($x/base:namespace)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D71 := prof:current-ms()

(: D72 - :)

let $ns1D72 := prof:current-ms()

let $D72table :=
    try {
        for $id in $sampleNamespaces
        let $localId := $docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D72 := prof:current-ms()

(: D72.1 :)

let $ns1D72.1 := prof:current-ms()

let $D72.1invalid :=
    try {
        let $vocDoc := doc($vocabulary:NAMESPACE || "rdf")
        let $prefLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:prefLabel[1]
        let $altLabel := $vocDoc//skos:Concept[adms:status/@rdf:resource = $dd:VALIDRESOURCE and @rdf:about = concat($vocabulary:NAMESPACE, $countryCode)]/skos:altLabel[1]
        for $x in distinct-values($docRoot//aqd:AQD_Sample/ef:inspireId/base:Identifier/base:namespace)
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

let $ns2D72.1 := prof:current-ms()


(: D73 :)

let $ns1D73 := prof:current-ms()

let $allGmlPoint := $docRoot//aqd:AQD_Sample/sams:shape/gml:Point
let $D73validURN := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4258", "urn:ogc:def:crs:EPSG::4326")
let $D73invalid :=
    try {
        for $point in $docRoot//aqd:AQD_Sample/sams:shape/gml:Point[not(@srsName = $D73validURN)]
        return
            <tr>
                <td title="aqd:AQD_Sample">{data($point/../../aqd:inspireId/base:Identifier/base:localId)}</td>
                <td title="gml:Point">{data($point/@gml:id)}</td>
                <td title="gml:Point/@srsName">{data($point/@srsName)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $isInvalidInvalidD73 := if (count($allGmlPoint) > 0) then fn:true() else fn:false()
let $errLevelD73 := if (count($allGmlPoint) > 0) then $errors:BLOCKER else $errors:WARNING
let $errMsg73 := if (count($allGmlPoint) > 0) then " errors found" else " gml:Point elements found"


let $ns2D73 := prof:current-ms()


(: D74 :)

let $ns1D74 := prof:current-ms()

let $D74invalid :=
    try {
        let $allnot2 := distinct-values(
            for $x in $docRoot//aqd:AQD_Sample/sams:shape/gml:Point[gml:pos/@srsDimension != "2"]
            return $x/../../aqd:inspireId/base:Identifier/base:localId/string() || "#" || $x/@gml:id || "#" || $x/gml:pos/@srsDimension || "#" || $x/gml:pos
        )
        let $all2 := distinct-values(
            for $x in $docRoot//aqd:AQD_Sample/sams:shape/gml:Point[gml:pos/@srsDimension = "2"]
            return $x/../../aqd:inspireId/base:Identifier/base:localId/string() || "#" || $x/@gml:id || "#" || $x/gml:pos/@srsDimension || "#" || $x/gml:pos
        )
        let $wrong2:= (for $i in $all2
                            let $position:= normalize-space(tokenize($i, "#")[4])
                            return if (count(tokenize($position," ")) != 2) then
                                        ( $i )
                                    else if (string(number(tokenize($position," ")[1])) = 'NaN' or string(number(tokenize($position," ")[2])) = 'NaN') then
                                        ( $i )
                                    else ()
                        )


        let $wrongRows := ($allnot2, $wrong2)

        for $i in $wrongRows
        return
            <tr>
                <td title="aqd:AQD_Sample">{tokenize($i, "#")[1]}</td>
                <td title="gml:Point">{tokenize($i, "#")[2]}</td>
                <td title="srsDimension">{tokenize($i, "#")[3]}</td>
                <td title="gml:pos">{tokenize($i, "#")[4]}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D74 := prof:current-ms()



(: D75 :)

let $ns1D75 := prof:current-ms()

let $D75invalid :=
    try {
        let $approximity := 0.0003

        (: SampleID|long#lat :)
        let $aqdSampleMap := map:merge((
            for $allPos in $docRoot//aqd:AQD_Sample[not(sams:shape/gml:Point/gml:pos = "")]
            let $id := concat($allPos/aqd:inspireId/base:Identifier/base:namespace, "/", $allPos/aqd:inspireId/base:Identifier/base:localId)
            let $pos := $allPos/sams:shape/gml:Point/string(gml:pos)
            return map:entry($id, $pos)
        ))
        for $x in $docRoot//aqd:AQD_SamplingPoint[not(ef:geometry/gml:Point/gml:pos = "")]/ef:observingCapability
        let $samplingPos := $x/../ef:geometry/gml:Point/string(gml:pos)
        let $xlink := ($x/ef:ObservingCapability/ef:featureOfInterest/@xlink:href)
        (: checks Sample map for value :)
        let $samplePos := map:get($aqdSampleMap, $xlink)
        let $sampleLong := geox:getX($samplePos)
        let $sampleLat := geox:getY($samplePos)
        let $samplingLong := geox:getX($samplingPos)
        let $samplingLat := geox:getY($samplingPos)

        let $sampleLong := if ($sampleLong castable as xs:decimal) then xs:decimal($sampleLong) else 0.00
        let $sampleLat := if ($sampleLat castable as xs:decimal) then xs:decimal($sampleLat) else 0.00

        let $samplingLong := if ($samplingLong castable as xs:decimal) then xs:decimal($samplingLong) else 0.00
        let $samplingLat := if ($samplingLat castable as xs:decimal) then xs:decimal($samplingLat) else 0.00

        where (abs($samplingLong - $sampleLong) > $approximity or abs($samplingLat - $sampleLat) > $approximity)
        return
            <tr>
                <td title="aqd:AQD_Sample">{string($xlink)}</td>
                <td title="aqd:AQD_SamplingPoint">{string($x/../ef:inspireId/base:Identifier/string(base:localId))}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D75 := prof:current-ms()


(: D76 :)

let $ns1D76 := prof:current-ms()

let $D76invalid :=
    try {
        let $sampleDistanceMap :=
            map:merge((
                for $x in $docRoot//aqd:AQD_Sample[not(string(aqd:buildingDistance) = "")]
                let $id := concat($x/aqd:inspireId/base:Identifier/base:namespace, "/", $x/aqd:inspireId/base:Identifier/base:localId)
                let $distance := string($x/aqd:buildingDistance)
                return map:entry($id, $distance)
            ))
        for $x in $docRoot//aqd:AQD_SamplingPoint[aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/traffic"]/ef:observingCapability
            let $xlink := string($x/ef:ObservingCapability/ef:featureOfInterest/@xlink:href)
            let $distance := map:get($sampleDistanceMap, $xlink)
        return
            if ($distance castable as xs:double) then
                ()
            else
                <tr>
                    <td title="AQD_Sample">{tokenize($xlink, "/")[last()]}</td>
                    <td title="AQD_SamplingPoint">{string($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D76 := prof:current-ms()


(: D77 :)

let $ns1D77 := prof:current-ms()

let $D77invalid :=
    try {
        let $sampleDistanceMap :=
            map:merge((
                for $x in $docRoot//aqd:AQD_Sample[not(string(aqd:kerbDistance) = "")]
                    let $id := concat($x/aqd:inspireId/base:Identifier/base:namespace, "/", $x/aqd:inspireId/base:Identifier/base:localId)
                    let $distance := string($x/aqd:kerbDistance)
                return map:entry($id, $distance)
            ))
        for $x in $docRoot//aqd:AQD_SamplingPoint[aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/traffic"]/ef:observingCapability
            let $xlink := string($x/ef:ObservingCapability/ef:featureOfInterest/@xlink:href)
            let $distance := map:get($sampleDistanceMap, $xlink)
        return
            if ($distance castable as xs:double) then
                ()
            else
                <tr>
                    <td title="aqd:AQD_Sample">{string($xlink)}</td>
                    <td title="aqd:AQD_SamplingPoint">{string($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D77 := prof:current-ms()

(: D78 :)

let $ns1D78 := prof:current-ms()

let $D78invalid :=
    try {
        for $inletHeigh in $docRoot//aqd:AQD_Sample/aqd:inletHeight

     
        return
            if (($inletHeigh/@uom != "http://dd.eionet.europa.eu/vocabulary/uom/length/m") or (common:is-a-number(data($inletHeigh)) = false())  or ($inletHeigh<0) or ($inletHeigh>30) ) then
                <tr>
                    <td title="@gml:id">{string($inletHeigh/../@gml:id)}</td>
                     <td title="aqd:inletHeight">{$inletHeigh}</td>
                </tr>
            else
                ()
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D78 := prof:current-ms()


(: D91 - Each aqd:AQD_Sample reported within the XML shall be xlinked (at least once) via aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/@xlink:href :)

let $ns1D91 := prof:current-ms()

let $D91invalid :=
    try {
        let $x := data($docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/@xlink:href)
        for $i in $docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier
            let $xlink := $i/base:namespace || "/" || $i/base:localId
        where not($xlink = $x)
        return
            <tr>
                <td title="AQD_Sample">{string($i/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D91 := prof:current-ms()

(: D92 - Each aqd:AQD_SamplingPointProcess reported within the XML shall be xlinked (at least once) via /aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href :)

let $ns1D92 := prof:current-ms()

let $D92invalid :=
    try {
        let $x := data($docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        for $i in $docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier
            let $xlink := $i/base:namespace || "/" || $i/base:localId
        where not($xlink = $x)
        return
            <tr>
                <td title="AQD_SamplingPointProcess">{string($i/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D92 := prof:current-ms()

(: D93 - Each aqd:AQD_Station reported within the XML shall be xlinked (at least once) via aqd:AQD_SamplingPoint/ef:broader/@xlink:href :)

let $ns1D93 := prof:current-ms()

let $D93invalid :=
    try {
        let $x := data($docRoot//aqd:AQD_SamplingPoint/ef:broader/@xlink:href)
        for $i in $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier
            let $xlink := $i/base:namespace || "/" || $i/base:localId
        where not($xlink = $x)
        return
            <tr>
                <td title="AQD_Station">{string($i/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D93 := prof:current-ms()

(: D94 - Each aqd:AQD_Netwok reported within the XML shall be xlinked (at least once) via /aqd:AQD_SamplingPoint/ef:belongsTo/@xlink:href or aqd:AQD_Station/ef:belongsTo/@xlink:href :)

let $ns1D94 := prof:current-ms()

let $D94invalid :=
    try {
        let $x := (data($docRoot//aqd:AQD_SamplingPoint/ef:belongsTo/@xlink:href), data($docRoot//aqd:AQD_Station/ef:belongsTo/@xlink:href))
        for $i in $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier
            let $xlink := $i/base:namespace || "/" || $i/base:localId
        where not($xlink = $x)
        return
            <tr>
                <td title="AQD_Network">{string($i/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2D94 := prof:current-ms()
let $ms2Total := prof:current-ms()
return
    <table class="maintable hover">
    <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
         <!--{html:build2("VOCABALL", $labels:VOCABALL, $labels:VOCABALL_SHORT, $VOCABALLinvalid, "All values are valid", "record", $errors:VOCABALL)}-->
       
      <!-- {html:buildNoCount2Sparql("VOCABALL", $labels:VOCABALL, $labels:VOCABALL_SHORT, $VOCABALLinvalid, "All values are valid", "Invalid urls found", $errors:VOCABALL)}-->
        

      {html:build3("D0", $labels:D0, $labels:D0_SHORT, $D0table, string($D0table/td), errors:getMaxError($D0table))}
        {html:build2("D01", $labels:D01, $labels:D01_SHORT, $D01table, "All values are valid", "", errors:getMaxError($D01table))}
        
        
       {html:buildSimpleSparql("D02", $labels:D02, $labels:D02_SHORT, $D02table, "", "feature type", $D02errorLevel)}
        {html:buildSimpleSparql("D03", $labels:D03, $labels:D03_SHORT, $D03table, $D3count, "feature type", $D03errorLevel)}
        {html:build2Sparql("D03b", $labels:D03b, $labels:D03b_SHORT, $D03binvalid, "All values are valid", "feature type", $errors:D03b)}
        {html:build1("D04", $labels:D04, $labels:D04_SHORT, $D04table, string(count($D04table)), "", "", "", $errors:D04)}
        {html:build2("D05", $labels:D05, $labels:D05_SHORT, $D05invalid, "All values are valid", "record", $errors:D05)}
        {html:buildInfoTR("Specific checks on AQD_Network feature(s) within this XML")}
        {html:build2Distinct("D06", $labels:D06, $labels:D06_SHORT, $D06invalid, "No duplicate values ", " ", $errors:D06)}
        {html:buildUnique("D07", $labels:D07, $labels:D07_SHORT, $D07table, "namespace", $errors:D07)}
        {html:build2("D07.1", $labels:D07.1, $labels:D07.1_SHORT, $D07.1invalid, "All values are valid", " invalid namespaces", $errors:D07.1)}
        {html:build2("D08", $labels:D08, $labels:D08_SHORT, $D08invalid, "", "", $errors:D08)}
        {html:build2("D09", $labels:D09, $labels:D09_SHORT, $D09invalid, "", "", $errors:D09)}
        {html:build2("D10", $labels:D10, $labels:D10_SHORT, $D10invalid, "", "", $errors:D10)}
        {html:build2("D11", $labels:D11, $labels:D11_SHORT, $D11invalid, "All attributes are valid", " invalid attribute ", $errors:D11)}
        {html:build2("D12", $labels:D12, $labels:D12_SHORT, $D12invalid, "All attributes are valid", " invalid attribute ", $errors:D12)}
        {html:build2("D14", $labels:D14, $labels:D14_SHORT, $D14invalid, "", "", $errors:D14)}
        {html:buildInfoTR("Specific checks on AQD_Station feature(s) within this XML")}
        <!-- {html:buildCountRow("D15", $labels:D15, $labels:D15_SHORT, $D15invalid, "All Ids are unique", (), ())} -->
        {html:build2Distinct("D15", $labels:D15, $labels:D15_SHORT, $D15invalid, "No duplicate values ", " ", $errors:D15)}
        {html:buildUnique("D16", $labels:D16, $labels:D16_SHORT, $D16table, "namespace", $errors:D16)}
        {html:build2("D16.1", $labels:D16.1, $labels:D16.1_SHORT, $D16.1invalid, "All values are valid", " invalid namespaces", $errors:D16.1)}
        {html:build2("D17", $labels:D17, $labels:D17_SHORT, $D17invalid, "All values are valid", "", $errors:D17)}
        {html:build2("D18", $labels:D18, $labels:D18_SHORT, $D18invalid, "All values are valid", "", $errors:D18)}
        {html:build2("D19", $labels:D19, $labels:D19_SHORT, $D19invalid, "All values are valid", "record", $errors:D19)}
        {html:build2("D20", $labels:D20, $labels:D20_SHORT, $D20invalid, "All smsName attributes are valid"," invalid attribute", $errors:D20)}
        {html:build2Distinct("D21", $labels:D21, $labels:D21_SHORT, $invalidPosD21, "All srsDimension attributes resolve to ""2""", " invalid attribute", $errors:D21)}
        {html:build2("D23", $labels:D23, $labels:D23_SHORT, $D23invalid, "All values are valid", "", $errors:D23)}
        {html:build1("D24", $labels:D24, $labels:D24_SHORT, $D24table, "", string(count($D24table)) || "records found", "record", "", $errors:D24)}
        {html:build2("D25", $labels:D25, $labels:D25_SHORT, $D25table, "All values are valid", "record",  $errors:D25)}
        {html:build2("D26", $labels:D26, $labels:D26_SHORT, $D26invalid, "All station codes are valid", " invalid station codes", $errors:D26)}
        {html:deprecated("D27", $labels:D27, $labels:D27_SHORT, $D27invalid, "aqd:meteoParams", "", "", "", $errors:D27)}
        {html:build2("D28", $labels:D28, $labels:D28_SHORT, $D28invalid, "All values are valid", "", $errors:D28)}
        {html:build2("D29", $labels:D29, $labels:D29_SHORT, $D29invalid, "All values are valid", "", $errors:D29)}
        {html:build2("D30", $labels:D30, $labels:D30_SHORT, $D30invalid, "All values are valid", "", $errors:D30)}
        {html:buildInfoTR("Specific checks on AQD_SamplingPoint feature(s) within this XML")}
        {html:build2("D31", $labels:D31, $labels:D31_SHORT, $D31invalid, "All values are valid", "", $errors:D31)}
        <!--{html:build2("D32", $labels:D32, $labels:D32_SHORT, $D32table, "All values are valid", "", $errors:D32)}-->
        {html:buildUnique2("D32", $labels:D32, $labels:D32_SHORT, $D32table, "namespace", $errors:D32)}
        {html:build2("D32.1", $labels:D32.1, $labels:D32.1_SHORT, $D32.1invalid, "All values are valid", " invalid namespaces", $errors:D32.1)}
        {html:build2("D33", $labels:D33, $labels:D33_SHORT, $D33invalid, "All values are valid", "", $errors:D33)}
        {html:build2("D34", $labels:D34, $labels:D34_SHORT, $D34invalid, "All values are valid", "", $errors:D34)}
        {html:build2("D35", $labels:D35, $labels:D35_SHORT, $D35invalid, $D35message, " invalid elements", $errors:D35)}
        {html:build2("D36", $labels:D36, $labels:D36_SHORT, $D36invalid, "All attributes are valid", " invalid attribute", $errors:D36)}
        {html:build2("D37a", $labels:D37a, $labels:D37a_SHORT, $D37ainvalid, "All values are valid", "", $errors:D37a)}
        {html:build2("D37b", $labels:D37b, $labels:D37b_SHORT, $D37binvalid, "All values are valid or D37b is skipped because of D37a", "",$errors:D37b)}
        
        {html:build2Sparql("D38", $labels:D38, $labels:D38_SHORT, $D38invalid, "All values are valid", "", $errors:D38)}
        {html:build2("D39", $labels:D39, $labels:D39_SHORT, $D39invalid, "All values are valid", "", $errors:D39)}
        {html:build2("D40", $labels:D40, $labels:D40_SHORT, $D40invalid, "All values are valid", "invalid pollutant", $errors:D40)}
        {html:buildInfoTR("Internal XML cross-checks between AQD_SamplingPoint and AQD_Sample;AQD_SamplingPointProcess;AQD_Station;AQD_Network")}
        {html:buildInfoTR("Please note that the qa might give you warning if different features have been submitted in separate XMLs")}
        {html:build2("D41", $labels:D41, $labels:D41_SHORT, $D41invalid, "All attributes are valid", " invalid attribute", $errors:D41)}
        {html:build2("D42", $labels:D42, $labels:D42_SHORT, $D42invalid, "All attributes are valid", " invalid attribute", $errors:D42)}
        {html:build2("D43", $labels:D43, $labels:D43_SHORT, $D43invalid, "All attributes are valid", " invalid attribute", $errors:D43)}
        {html:build2("D44", $labels:D44, $labels:D44_SHORT, $D44invalid, "All attributes are valid", " invalid attribute", $errors:D44)}
        {html:build2("D45", $labels:D45, $labels:D45_SHORT, $D45invalid, "All values are valid", "", $errors:D45)}
        {html:build2("D46", $labels:D46, $labels:D46_SHORT, $D46invalid, "All values are valid", "", $errors:D46)}
        {html:build2("D48", $labels:D48, $labels:D48_SHORT, $D48invalid, "All values are valid", "record", $errors:D48)}
        {html:build2("D49", $labels:D49, $labels:D49_SHORT, $D49invalid, "All values are valid", "record", $errors:D49)}
        {html:build2("D50", $labels:D50, $labels:D50_SHORT, $D50invalid, "All values are valid", "", $errors:D50)}
        {html:build2("D51", $labels:D51, $labels:D51_SHORT, $D51invalid, "All values are valid", " invalid attribute", $errors:D51)}
        {html:build2Sparql("D53", $labels:D53, $labels:D53_SHORT, $D53invalid, "All values are valid", " invalid attribute", $errors:D53)}
        {html:build2("D54", $labels:D54, $labels:D54_SHORT, $D54invalid, "All values are valid", " invalid attribute", $errors:D54)}
        {html:buildInfoTR("Specific checks on AQD_SamplingPointProcess feature(s) within this XML")}
        {html:buildUnique("D55", $labels:D55, $labels:D55_SHORT, $D55table, "namespace", $errors:D55)}
        {html:build2("D55.1", $labels:D55.1, $labels:D55.1_SHORT, $D55.1invalid, "All values are valid", " invalid namespaces", $errors:D55.1)}
        {html:build2("D56", $labels:D56, $labels:D56_SHORT, $D56invalid, "All values are valid", "",$errors:D56)}
        {html:build2("D57", $labels:D57, $labels:D57_SHORT, $D57table, "All values are valid", "", $errors:D57)}
        {html:build2("D58", $labels:D58, $labels:D58_SHORT, $D58table, "All values are valid", " invalid attribute", $errors:D58)}
        {html:build2("D59", $labels:D59, $labels:D59_SHORT, $D59invalid, "All values are valid", "", $errors:D59)}
        {html:build2("D60a", $labels:D60a, $labels:D60a_SHORT, $D60ainvalid, "All values are valid", "", $errors:D60a)}
        {html:build2("D60b", $labels:D60b, $labels:D60b_SHORT, $D60binvalid, "All values are valid", "", $errors:D60b)}
        {html:build2("D61", $labels:D61, $labels:D61_SHORT, $D61invalid, "All values are valid", "record", $errors:D61)}
        {html:build2("D62", $labels:D62, $labels:D62_SHORT, $D62invalid, "All values are valid", "invalid record", $errors:D62)}
        {html:build2("D63", $labels:D63, $labels:D63_SHORT, $D63invalid, "All values are valid", "invalid record", $errors:D63)}
        {html:buildInfoTR("Checks on SamplingPointProcess(es) where the xlinked SamplingPoint has aqd:AQD_SamplingPoint/aqd:usedAQD equals TRUE (D67 to D70):")}
        {html:build2("D65", $labels:D65, $labels:D65_SHORT, $D65invalid, "All values are valid", "record", $errors:D65)}
        {html:build2("D67a", $labels:D67a, $labels:D67a_SHORT, $D67ainvalid, "All values are valid", "", $errors:D67a)}
        {html:build2("D67b", $labels:D67b, $labels:D67b_SHORT, $D67binvalid, "All values are valid", "", $errors:D67b)}
        {html:build2("D68", $labels:D68, $labels:D68_SHORT, $D68invalid, "All values are valid", "record", $errors:D68)}
        {html:build2("D69", $labels:D69, $labels:D69_SHORT, $D69invalid, "All values are valid", "record", $errors:D69)}
        {html:buildInfoTR("Specific checks on AQD_Sample feature(s) within this XML")}
        {html:build2("D71", $labels:D71, $labels:D71_SHORT, $D71invalid, "All values are valid", "", $errors:D71)}
        {html:buildUnique("D72", $labels:D72, $labels:D72_SHORT, $D72table, "namespace", $errors:D72)}
        {html:build2("D72.1", $labels:D72.1, $labels:D72.1_SHORT, $D72.1invalid, "All values are valid", " invalid namespaces", $errors:D72.1)}
        {html:build2("D73", $labels:D73, $labels:D73_SHORT, $D73invalid, concat(string(count($D73invalid)), $errMsg73), "", $errLevelD73)}
        {html:build2("D74", $labels:D74, $labels:D74_SHORT, $D74invalid, "All srsDimension attributes are valid"," invalid attribute", $errors:D74)}
        {html:build2("D75", $labels:D75, $labels:D75_SHORT, $D75invalid, "All attributes are valid", " invalid attribute", $errors:D75)}
        {html:build2("D76", $labels:D76, $labels:D76_SHORT, $D76invalid, "All attributes are valid", " invalid attribute", $errors:D76)}
        {html:build2("D77", $labels:D77, $labels:D77_SHORT, $D77invalid, "All attributes are valid", " invalid attribute", $errors:D77)}
        {html:build2("D78", $labels:D78, $labels:D78_SHORT, $D78invalid, "All values are valid"," invalid attribute", $errors:D78)}
        {html:build2("D91", $labels:D91, $labels:D91_SHORT, $D91invalid, "All values are valid"," invalid attribute", $errors:D91)}
        {html:build2("D92", $labels:D92, $labels:D92_SHORT, $D92invalid, "All values are valid"," invalid attribute", $errors:D92)}
        {html:build2("D93", $labels:D93, $labels:D93_SHORT, $D93invalid, "All values are valid"," invalid attribute", $errors:D93)}
        {html:build2("D94", $labels:D94, $labels:D94_SHORT, $D94invalid, "All values are valid"," invalid attribute", $errors:D94)}
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
       {common:runtime("NS", $ns1DNS, $ns2DNS)}
       {common:runtime("VOCAB", $ns1DVOCAB, $ns2DVOCAB)}
       <!--{common:runtime("VOCABALL", $ms1CVOCABALL, $ms2CVOCABALL)}-->


       {common:runtime("D0",  $ns1D0, $ns2D0)}
       {common:runtime("D01", $ns1D01, $ns2D01)}
     {common:runtime("D02", $ns1D02, $ns2D02)}
       {common:runtime("D03", $ns1D03, $ns2D03)}
       {common:runtime("D03b", $ns1D03b, $ns2D03b)}
       {common:runtime("D04",  $ns1D04, $ns2D04)}
       {common:runtime("D05", $ns1D05, $ns2D05)}
       {common:runtime("D06",  $ns1D06, $ns2D06)}
       {common:runtime("D07",  $ns1D07, $ns2D07)}
       {common:runtime("D07.1",  $ns1D07.1, $ns2D07.1)}
       {common:runtime("D08",  $ns1D08, $ns2D08)}
       {common:runtime("D09",  $ns1D09, $ns2D09)}
       {common:runtime("D10",  $ns1D10, $ns2D10)}
       {common:runtime("D11",  $ns1D11, $ns2D11)}
       {common:runtime("D12",  $ns1D12, $ns2D12)}
       {common:runtime("D14",  $ns1D14, $ns2D14)}
       {common:runtime("D15",  $ns1D15, $ns2D15)}
       {common:runtime("D16",  $ns1D16, $ns2D16)}
       {common:runtime("D16.1",  $ns1D16.1, $ns2D16.1)}
       {common:runtime("D17",  $ns1D17, $ns2D17)}
       {common:runtime("D18",  $ns1D18, $ns2D18)}
       {common:runtime("D19",  $ns1D19, $ns2D19)}
       {common:runtime("D20", $ns1D20, $ns2D20)}
       {common:runtime("D21",  $ns1D21, $ns2D21)}
       {common:runtime("D23",  $ns1D23, $ns2D23)}
       {common:runtime("D24",  $ns1D24, $ns2D24)}
       {common:runtime("D25",  $ns1D25, $ns2D25)}
       {common:runtime("D26",  $ns1D26, $ns2D26)}
       {common:runtime("D27",  $ns1D27, $ns2D27)}
       {common:runtime("D28",  $ns1D28, $ns2D28)}
       {common:runtime("D29",  $ns1D29, $ns2D29)}
       {common:runtime("D30",  $ns1D30, $ns2D30)}
       {common:runtime("D31",  $ns1D31, $ns2D31)}
       {common:runtime("D32",  $ns1D32, $ns2D32)}
       {common:runtime("D32.1",  $ns1D32.1, $ns2D32.1)}
       {common:runtime("D33",  $ns1D33, $ns2D33)}
       {common:runtime("D34",  $ns1D34, $ns2D34)}
       {common:runtime("D35",  $ns1D35, $ns2D35)}
       {common:runtime("D36",  $ns1D36, $ns2D36)}
       {common:runtime("D37a",  $ns1D37a, $ns2D37a)}
       {common:runtime("D37a",  $ns1D37a, $ns2D37a)}
       {common:runtime("D37b",  $ns1D37b, $ns2D37b)}
       
       {common:runtime("D38",  $ns1D38, $ns2D38)}
       {common:runtime("D39",  $ns1D39, $ns2D39)}
       {common:runtime("D40",  $ns1D40, $ns2D40)}
       {common:runtime("D41",  $ns1D41, $ns2D41)}
       {common:runtime("D42",  $ns1D42, $ns2D42)}
       {common:runtime("D43",  $ns1D43, $ns2D43)}
       {common:runtime("D44",  $ns1D44, $ns2D44)}
       {common:runtime("D45",  $ns1D45, $ns2D45)}
       {common:runtime("D46",  $ns1D46, $ns2D46)}
       {common:runtime("D48",  $ns1D48, $ns2D48)}
       {common:runtime("D49",  $ns1D49, $ns2D49)}
       {common:runtime("D50",  $ns1D50, $ns2D50)}
       {common:runtime("D51",  $ns1D51, $ns2D51)}
       {common:runtime("D53",  $ns1D53, $ns2D53)}
       {common:runtime("D54",  $ns1D54, $ns2D54)}
       {common:runtime("D55",  $ns1D55, $ns2D55)}
       {common:runtime("D55.1",  $ns1D55.1, $ns2D55.1)}
       {common:runtime("D56",  $ns1D56, $ns2D56)}
       {common:runtime("D57",  $ns1D57, $ns2D57)}
       {common:runtime("D58",  $ns1D58, $ns2D58)}
       {common:runtime("D50",  $ns1D59, $ns2D59)}
       {common:runtime("D60a",  $ns1D60a, $ns2D60a)}
       {common:runtime("D60b",  $ns1D60b, $ns2D60b)}
       {common:runtime("D61",  $ns1D61, $ns2D61)}
       {common:runtime("D62",  $ns1D62, $ns2D62)}
       {common:runtime("D63",  $ns1D63, $ns2D63)}
       {common:runtime("D65",  $ns1D65, $ns2D65)}
       {common:runtime("D67a",  $ns1D67a, $ns2D67a)}
       {common:runtime("D67b",  $ns1D67b, $ns2D67b)}
       {common:runtime("D68",  $ns1D68, $ns2D68)}
       {common:runtime("D69",  $ns1D69, $ns2D69)}
       {common:runtime("D71",  $ns1D71, $ns2D71)}
       {common:runtime("D72",  $ns1D72, $ns2D72)}
       {common:runtime("D72.1",  $ns1D72.1, $ns2D72.1)}
       {common:runtime("D73",  $ns1D73, $ns2D73)}
       {common:runtime("D74",  $ns1D74, $ns2D74)}
       {common:runtime("D75",  $ns1D75, $ns2D75)}
       {common:runtime("D76",  $ns1D76, $ns2D76)}
       {common:runtime("D77",  $ns1D77, $ns2D77)}
       {common:runtime("D78",  $ns1D78, $ns2D78)}
       {common:runtime("D91",  $ns1D91, $ns2D91)}
       {common:runtime("D92",  $ns1D92, $ns2D92)}
       {common:runtime("D93",  $ns1D93, $ns2D93)}
       {common:runtime("D94",  $ns1D94, $ns2D94)}

       {common:runtime("Total time",  $ms1Total, $ms2Total)}
    </table>
    </table>
};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function dataflowD:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countFeatures := count(doc($source_url)//descendant::*[$dataflowD:FEATURE_TYPES = name()])
let $result := if ($countFeatures > 0) then dataflowD:checkReport($source_url, $countryCode) else ()
let $meta := map:merge((
    map:entry("count", $countFeatures),
    map:entry("header", "Check environmental monitoring feature types"),
    map:entry("dataflow", "Dataflow D"),
    map:entry("zeroCount", <p>No environmental monitoring feature type elements ({string-join($dataflowD:FEATURE_TYPES, ", ")}) found in this XML.</p>),
    map:entry("report", <p>This feedback report provides a summary overview of feature types reported and some consistency checks defined in Dataflow D as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
))
return
    html:buildResultDiv($meta, $result)
};
