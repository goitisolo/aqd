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

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowD";
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
declare namespace skos="http://www.w3.org/2004/02/skos/core#";
declare namespace prop="http://dd.eionet.europa.eu/property/";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace adms="http://www.w3.org/ns/adms#";

declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL", "AD", "AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $xmlconv:FEATURE_TYPES := ("aqd:AQD_Network", "aqd:AQD_Station", "aqd:AQD_SamplingPointProcess", "aqd:AQD_Sample",
"aqd:AQD_RepresentativeArea", "aqd:AQD_SamplingPoint");
declare variable $xmlconv:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "672");

(: Rule implementations :)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

let $docRoot := doc($source_url)
let $reportingYear := common:getReportingYear($docRoot)

(: COMMON variables used in many QCs :)
let $countFeatureTypesMap :=
    map:merge((
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        map:entry($featureType, count($docRoot//descendant::*[name()=$featureType]))
    ))
let $DCombinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//descendant::*[name()=$featureType]
let $namespaces := distinct-values($docRoot//base:namespace)
let $knownFeatures := distinct-values(data(sparqlx:executeSparqlQuery(query:getAllFeatureIds($xmlconv:FEATURE_TYPES, $namespaces))//sparql:binding[@name='inspireLabel']/sparql:literal))
let $SPOnamespaces := distinct-values($docRoot//aqd:AQD_SamplingPoint//base:Identifier/base:namespace)
let $SPPnamespaces := distinct-values($docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier/base:namespace)
let $networkNamespaces := distinct-values($docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/base:namespace)
let $sampleNamespaces := distinct-values($docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:namespace)
let $stationNamespaces := distinct-values($docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/base:namespace)

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

(: D0 :)
let $D0table :=
    try {
        if ($reportingYear = "") then
            <tr class="{$errors:ERROR}">
                <td title="Status">Reporting Year is missing.</td>
            </tr>
        else if (query:deliveryExists($xmlconv:OBLIGATIONS, $countryCode, "d/", $reportingYear)) then
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
let $isNewDelivery := errors:getMaxError($D0table) = $errors:INFO


let $D1sum := string(sum(
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        count($docRoot//descendant::*[name()=$featureType])))
(: D1 :)
let $D1table :=
    try {
        for $featureType at $pos in $xmlconv:FEATURE_TYPES
        order by $featureType descending
        where map:get($countFeatureTypesMap, $featureType) > 0
        return
            <tr>
                <td title="Feature type">{$featureType}</td>
                <td title="Total number">{map:get($countFeatureTypesMap, $featureType)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D2 - :)
let $D2table :=
    try {
        let $all := map:merge((
            for $featureType at $pos in $xmlconv:FEATURE_TYPES
                let $count := count(
                for $x in $docRoot//descendant::*[name()=$featureType]
                    let $inspireId := $x//base:Identifier/base:namespace/string() || "/" || $x//base:Identifier/base:localId/string()
                where ($inspireId = "/" or not($knownFeatures = $inspireId))
                return
                    <tr>
                        <td title="base:localId">{$x//base:Identifier/base:localId/string()}</td>
                    </tr>)
            return map:entry($xmlconv:FEATURE_TYPES[$pos], $count)
        ))
        return
            map:for-each($all, function($name, $count) {
                if ($count > 0) then
                    <tr>
                        <td title="Feature type">{$name}</td>
                        <td title="Total number">{$count}</td>
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
let $D2errorLevel :=
    try {
        let $map1 := map:merge((
            for $x in $D2table
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
                $errors:ERROR
            else
                $errors:INFO
    } catch * {
        $errors:FAILED
    }

(: D3 - :)
let $D3table :=
    try {
        let $featureTypes := remove($xmlconv:FEATURE_TYPES, index-of($xmlconv:FEATURE_TYPES, "aqd:AQD_RepresentativeArea"))
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
                    </tr>
            })
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $D3errorLevel :=
    try {
        if (data($D3table/@isvalid) = "false") then
            $errors:ERROR
        else
            $errors:INFO
    } catch * {
        $errors:FAILED
    }
let $D3count :=
    try {
        string(sum($D3table/td[2]))
    } catch * {
        "NaN"
    }


(: D4 :)
let $D4table :=
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D5 :)
(: TODO: FIX TRY CATCH :)
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
let $D5invalid := $part1 + $part2 + $part3


(: D6 Done by Rait ./ef:inspireId/base:Identifier/base:localId shall be an unique code for AQD_network and unique within the namespace.:)
(: TODO FIX TRY CATCH :)
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
    let $D6invalid := $countAmInspireIdDuplicates

(: D7 :)
let $D7table :=
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D7.1 :)
let $D7.1invalid :=
    try {
        common:checkNamespaces(distinct-values($docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/base:namespace), $countryCode)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D8 :)
let $D8invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Network/ef:mediaMonitored
        where not($x/@xlink:href = $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI || "air")
        return
            <tr>
                <td title="aqd:AQD_Network">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:mediaMonitored">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D9 :)
let $D9invalid :=
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D10 :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D11 :)
let $D11invalid :=
    try {
        let $D11tmp := distinct-values(
                $docRoot//aqd:AQD_Network/aqd:operationActivityPeriod/gml:TimePeriod[((gml:beginPosition >= gml:endPosition)
                        and (gml:endPosition != ""))]/../../ef:inspireId/base:Identifier/base:localId)
        for $x in $D11tmp
        return
            <tr>
                <td title="base:localId">{$x}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D12 aqd:AQD_Network/ef:name shall return a string :)
let $D12invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Network[string(ef:name) = ""]
        return
            <tr>
                <td title="base:localId">{string($x/ef:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D14 - ./aqd:aggregationTimeZone attribute shall resolve to a valid code in http://dd.eionet.europa.eu/vocabulary/aq/timezone/ :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }
(: D15 Done by Rait :)
let $D15invalid :=
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D16 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D16.1 :)
let $D16.1invalid :=
    try {
        common:checkNamespaces(distinct-values($docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/base:namespace), $countryCode)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D17 aqd:AQD_Station/ef:name shall return a string :)
let $D17invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Station[string(ef:name) = ""]
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

(: D18 Cross-check with AQD_Network (aqd:AQD_Station/ef:belongsTo shall resolve to a traversable local of global URI to ../AQD_Network) :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }
(: D19 :)
let $D19invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Station/ef:mediaMonitored
        where not($x/xlink:href = $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI || "air")
        return
            <tr>
                <td title="aqd:AQD_Station">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:networkType">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D20 ./ef:geometry/gml:Points the srsName attribute shall be a recognisable URN :)
let $D20invalid :=
    try {
        let $D20validURN := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4258", "urn:ogc:def:crs:EPSG::4326")
        for $x in distinct-values($docRoot//aqd:AQD_Station[count(ef:geometry/gml:Point) > 0 and not(ef:geometry/gml:Point/@srsName = $D20validURN)]/ef:inspireId/base:Identifier/base:localId)
        return
            <tr>
                <td title="base:localId">{$x}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }


(: D21 - The Dimension attribute shall resolve to "2." :)
let $invalidPosD21 :=
    try {
        let $D21tmp := distinct-values($docRoot//aqd:AQD_Station/ef:geometry/gml:Point/gml:pos[@srsDimension != "2"]/
        concat(../../../ef:inspireId/base:Identifier/base:localId, ": srsDimension=", @srsDimension))
        let $invalidPos_srsDim :=
            for $i in $D21tmp
            return
                <tr>
                    <td title="dimension">{string($i)}</td>
                </tr>


        let $aqdStationPos :=
            for $allPos in $docRoot//aqd:AQD_Station
            where not(empty($allPos/ef:geometry/gml:Point/gml:pos))
            return concat($allPos/ef:inspireId/base:Identifier/base:namespace, "/", $allPos/ef:inspireId/base:Identifier/base:localId, "|",
                    fn:substring-before(data($allPos/ef:geometry/gml:Point/gml:pos), " "), "#", fn:substring-after(data($allPos/ef:geometry/gml:Point/gml:pos), " "))


        let $invalidPos_order :=
            for $gmlPos in $docRoot//aqd:AQD_SamplingPoint

            let $samplingPos := data($gmlPos/ef:geometry/gml:Point/gml:pos)
            let $samplingLat := if (not(empty($samplingPos))) then fn:substring-before($samplingPos, " ") else ""
            let $samplingLong := if (not(empty($samplingPos))) then fn:substring-after($samplingPos, " ") else ""


            let $samplingLat := if ($samplingLat castable as xs:decimal) then xs:decimal($samplingLat) else 0.00
            let $samplingLong := if ($samplingLong castable as xs:decimal) then xs:decimal($samplingLong) else 0.00

            return
                if ($samplingLat < $samplingLong and $countryCode != 'FR') then
                    <tr>
                        <td title="lat/long">{concat($gmlPos/ef:inspireId/base:Identifier/base:localId, " : lat=", string($samplingLat), " :long=", string($samplingLong))}</td>
                    </tr>
                else
                    ()
        return (($invalidPos_srsDim), ($invalidPos_order))
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D23 Done by Rait :)
let $D23invalid :=
    try {
        let $allEfOperationActivityPeriod :=
            for $allOperationActivityPeriod in $docRoot//aqd:AQD_Station/ef:operationalActivityPeriod
            where ($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition) != "unknown"]
                    or fn:string-length($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) > 0)
            return $allOperationActivityPeriod

        for $operationActivityPeriod in $allEfOperationActivityPeriod
        where ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition < $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition) and ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition != "")
        return
            <tr>
                <td title="aqd:AQD_Station">{data($operationActivityPeriod/../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
                <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
                <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D24 - List the total number of aqd:AQD_Station which are operational :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D26 Done by Rait:)
let $D26invalid :=
    try {
        let $localEUStationCode := $docRoot//aqd:AQD_Station/upper-case(normalize-space(aqd:EUStationCode))
        for $EUStationCode in $docRoot//aqd:AQD_Station/aqd:EUStationCode
        where
            count(index-of($localEUStationCode, upper-case(normalize-space($EUStationCode)))) > 1 or
                    (
                        count(index-of($xmlconv:ISO2_CODES, substring(upper-case(normalize-space($EUStationCode)), 1, 2))) = 0
                    )
        return
            <tr>
                <td title="aqd:AQD_Station">{data($EUStationCode/../@gml:id)}</td>
                <td title="aqd:EUStationCode">{data($EUStationCode)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D27 :)
let $D27invalid :=
    try {
        ()
        (:xmlconv:checkVocabulariesConceptEquipmentValues($source_url, "aqd:AQD_Station", "aqd:meteoParams", $vocabulary:METEO_PARAMS_VOCABULARY, "collection"):)
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D28 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D29 :)
let $D29invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:DISPERSION_LOCAL_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_Station/aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionLocal
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Station">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:dispersionLocal">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D30 :)
let $D30invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:DISPERSION_REGIONAL_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_Station/aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionRegional
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_Station">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:dispersionRegional">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D31 Done by Rait:)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D32 :)
let $D32table :=
    try {
        for $id in $networkNamespaces
        let $localId := $docRoot//aqd:AQD_SamplingPoint//base:Identifier[base:namespace = $id]/base:localId
        return
            <tr>
                <td title="feature">SamplingPoint(s)</td>
                <td title="base:namespace">{$id}</td>
                <td title="base:localId">{count($localId)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D32.1 :)
let $D32.1invalid :=
    try {
        common:checkNamespaces(distinct-values($docRoot//aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:namespace), $countryCode)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D33 :)
let $D33invalid :=
    try {
        for $x in $docRoot//aqd:AQD_SamplingPoint/ef:mediaMonitored
        where not($x/@xlink:href = $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI || "air")
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:mediaMonitored">{data($x/@xlink:href)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D34 :)
let $D34invalid :=
    try {
        let $D34validURN := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4258", "urn:ogc:def:crs:EPSG::4326")
        for $x in distinct-values($docRoot//aqd:AQD_SamplingPoint[count(ef:geometry/gml:Point) > 0 and not(ef:geometry/gml:Point/@srsName = $D34validURN)]/ef:inspireId/base:Identifier/string(base:localId))
        return
            <tr>
                <td title="base:localId">{$x}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D35 :)
let $D35invalid :=
    try {
        for $x in $docRoot//aqd:AQD_SamplingPoint
        let $invalidOrder :=
            for $i in $x/ef:geometry/gml:Point/gml:pos
            let $latlongToken := tokenize($i, "\s+")
            let $lat := number($latlongToken[1])
            let $long := number($latlongToken[2])
            where ($long > $lat)
            return 1
        where (not($countryCode = "fr") and ($x/ef:geometry/gml:Point/gml:pos/@srsDimension != "2" or $invalidOrder = 1))
        return
            <tr>
                <td title="base:localId">{string($x/ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="@srsDimension">{string($x/ef:geometry/gml:Point/gml:pos/@srsDimension)}</td>
                <td title="Pos">{string($x/ef:geometry/gml:Point/gml:pos)}</td>
            </tr>
    }  catch * {
        <tr status="failed">
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

(: D36 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D37 - check for invalid data or if beginPosition > endPosition :)
let $D37invalid :=
    try {
        let $invalidPosition :=
            for $timePeriod in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
            (: XQ does not support 24h that is supported by xml schema validation :)
            (: TODO: comment by sofiageo - the above statement is not true, fix this if necessary :)
            let $beginDate := substring(normalize-space($timePeriod/gml:beginPosition), 1, 10)
            let $endDate := substring(normalize-space($timePeriod/gml:endPosition), 1, 10)
            let $beginPosition :=
                if ($beginDate castable as xs:date) then
                    xs:date($beginDate)
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
                if ((string($beginPosition) = "error" or string($endPosition) = "error") or
                        ($beginPosition instance of xs:date and $endPosition instance of xs:date and $beginPosition > $endPosition)) then
                    <tr>
                        <td title="aqd:AQD_SamplingPoint">{data($timePeriod/../../../../ef:inspireId/base:Identifier/base:localId)}</td>
                        <td title="gml:TimePeriod">{data($timePeriod/@gml:id)}</td>
                        <td title="gml:beginPosition">{$timePeriod/gml:beginPosition}</td>
                        <td title="gml:endPosition">{$timePeriod/gml:endPosition}</td>
                    </tr>

                else
                    ()


        (: sort by begin and find if end is greater than next end :)
        let $overlappingPeriods :=
            for $rec in $docRoot//aqd:AQD_SamplingPoint
            let $observingCapabilities :=
                for $cp in $rec/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
                order by $cp/gml:beginPosition
                return $cp

            for $period at $pos in $observingCapabilities

            let $ok := if ($pos < count($observingCapabilities))
            then
                if ($period/gml:endPosition castable as xs:dateTime and $observingCapabilities[$pos + 1]/gml:beginPosition castable as xs:dateTime) then
                    if (xs:dateTime($period/gml:endPosition) > xs:dateTime($observingCapabilities[$pos + 1]/gml:beginPosition)) then fn:false() else fn:true()
                else
                    fn:true()
            else
                fn:true()

            return if ($ok) then () else

                <tr>
                    <td title="aqd:AQD_SamplingPoint">{data($period/../../../../ef:inspireId/base:Identifier/base:localId)}</td>
                    <td title="gml:TimePeriod">{data($period/@gml:id)}</td>
                    <td title="gml:beginPosition">{$period/gml:beginPosition}</td>
                    <td title="gml:endPosition">{$period/gml:endPosition}</td>
                </tr>


        return (($invalidPosition), ($overlappingPeriods))
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D40 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D41 Updated by Jaume Targa following working logic of D44 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D42 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D43 Updated by Jaume Targa following working logic of D44 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D44 :)
let $D44invalid :=
    try {
        let $aqdNetworkLocal :=
            for $z in $docRoot//aqd:AQD_Network
            let $id := concat(data($z/ef:inspireId/base:Identifier/base:namespace), '/',
                    data($z/ef:inspireId/base:Identifier/base:localId))
            return $id
        
        for $x in $docRoot//aqd:AQD_SamplingPoint/ef:belongsTo
        where empty(index-of($aqdNetworkLocal, fn:normalize-space($x/@xlink:href)))
        return
            <tr>
                <td title="aqd:AQD_SamplingPoint">{data($x/../@gml:id)}</td>
                <td title="ef:belongsTo">{data(fn:normalize-space($x/@xlink:href))}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D45 - Find all period with out end period :)
let $D45invalid :=
    try {
        let $allNotNullEndOperationActivityPeriods :=
            for $allOperationActivityPeriod in $docRoot//aqd:AQD_SamplingPoint/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod
            where ($allOperationActivityPeriod/gml:endPosition[normalize-space(@indeterminatePosition) != "unknown"]
                    or fn:string-length($allOperationActivityPeriod/gml:endPosition) > 0)

            return $allOperationActivityPeriod

        for $operationActivitPeriod in $allNotNullEndOperationActivityPeriods
        where ((xs:dateTime($operationActivitPeriod/gml:endPosition) < xs:dateTime($operationActivitPeriod/gml:beginPosition)))
        return
            <tr>
                <td title="aqd:AQD_Station">{data($operationActivitPeriod/../../../../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($operationActivitPeriod/@gml:id)}</td>
                <td title="gml:beginPosition">{$operationActivitPeriod/gml:beginPosition}</td>
                <td title="gml:endPosition">{$operationActivitPeriod/gml:endPosition}</td>
            </tr>
    }  catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D46 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }
(: D48 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: D50 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D51 :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D53 Done by Rait :)
let $D53invalid :=
    try {
        for $invalidZoneXlinks in $docRoot//aqd:AQD_SamplingPoint/aqd:zone[not(@nilReason = 'inapplicable')]
        where
            count(sparqlx:executeSparqlQuery(query:getSamplingPointZone(string($invalidZoneXlinks/@xlink:href)))/*) = 0
        return
            <tr>
                <td title="base:localId">{data($invalidZoneXlinks/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:zone">{data($invalidZoneXlinks/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D54 - aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier/base:localId not unique codes :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D55 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }
(: D55.1 :)
let $D55.1invalid :=
    try {
        common:checkNamespaces(distinct-values($docRoot//aqd:AQD_SamplingPointProcess/ef:inspireId/base:Identifier/base:namespace), $countryCode)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D56 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D57 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D58 Done by Rait :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D59 Done by Rait:)
(: TODO FIND OUT WHAT IS CORRECT PATH:)
let $D59invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:ANALYTICALTECHNIQUE_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:SamplingPointProcess/aqd:analyticalTechnique/aqd:AnalyticalTechnique/aqd:analyticalTechnique
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:measurementType">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D60a  :)
let $D60ainvalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:MEASUREMENTEQUIPMENT_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_SamplingPointProcess/aqd:measurementEquipment
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:measurementEquipment">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D60b :)
let $D60binvalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:SAMPLINGEQUIPMENT_VOCABULARY || "rdf")
        for $x in $docRoot//aqd:AQD_SamplingPointProcess/aqd:samplingEquipment
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:samplingEquipment">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D61 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D62 :)
let $D62invalid :=
    try {
        let $valid := dd:getValidConcepts($vocabulary:PROCESS_PARAMETER || "rdf")
        for $x in $docRoot//ompr:name
        where not($x/@xlink:href = $valid)
        return
            <tr>
                <td title="aqd:AQD_SamplingPointProcess">{data($x/../../../ompr:inspireId/base:Identifier/base:localId)}</td>
                <td title="ompr:name">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D63 :)
(: TODO CHECK IF THIS IS DEPRECATED :)
let $D63invalid :=
    try {
        ()
        (:let $valid := dd:getValidConcepts($vocabulary:UOM_CONCENTRATION_VOCABULARY || "rdf")
        for $x in $docRoot//
        where not($)
        xmlconv:checkVocabularyConceptValuesUom($source_url, "aqd:DataQuality", "aqd:detectionLimit", ):)
    } catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D65 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D67a :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D67b - ./aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated should resolve to
 : http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/ for all SamplingPointProcess :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D68 Jaume Targa :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D69 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
            <td></td>
        </tr>
    }

(: D71 - ./aqd:inspireId/base:Identifier/base:localId shall be unique for AQD_Sample and unique within the namespace :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D72 - :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: D72.1 :)
let $D72.1invalid :=
    try {
        common:checkNamespaces(distinct-values($docRoot//aqd:AQD_Sample/ef:inspireId/base:Identifier/base:namespace), $countryCode)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D73 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $isInvalidInvalidD73 := if (count($allGmlPoint) > 0) then fn:true() else fn:false()
let $errLevelD73 := if (count($allGmlPoint) > 0) then $errors:ERROR else $errors:WARNING
let $errMsg73 := if (count($allGmlPoint) > 0) then " errors found" else " gml:Point elements found"

(: D74 :)
let $D74invalid :=
    try {
        let $all := distinct-values(
            for $x in $docRoot//aqd:AQD_Sample/sams:shape/gml:Point[@srsDimension != "2"]
            return $x/../../aqd:inspireId/base:Identifier/base:localId/string() || "#" || $x/@gml:id || "#" || $x/@srsDimension
        )
        for $i in $all
        return
            <tr>
                <td title="aqd:AQD_Sample">{tokenize($i, "#")[1]}</td>
                <td title="gml:Point">{tokenize($i, "#")[2]}</td>
                <td title="srsDimension">{tokenize($i, "#")[3]}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D75 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D76 :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D77 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: D78 :)
let $D78invalid :=
    try {
        for $inletHeigh in $docRoot//aqd:AQD_Sample/aqd:inletHeight
        return
            if (($inletHeigh/@uom != "http://dd.eionet.europa.eu/vocabulary/uom/length/m") or (common:is-a-number(data($inletHeigh)) = false())) then
                <tr>
                    <td title="@gml:id">{string($inletHeigh/../@gml:id)}</td>
                </tr>
            else
                ()
    } catch * {
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: D91 - Each aqd:AQD_Sample reported within the XML shall be xlinked (at least once) via aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/@xlink:href :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: D92 - Each aqd:AQD_SamplingPointProcess reported within the XML shall be xlinked (at least once) via /aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: D93 - Each aqd:AQD_Station reported within the XML shall be xlinked (at least once) via aqd:AQD_SamplingPoint/ef:broader/@xlink:href :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: D94 - Each aqd:AQD_Netwok reported within the XML shall be xlinked (at least once) via /aqd:AQD_SamplingPoint/ef:belongsTo/@xlink:href or aqd:AQD_Station/ef:belongsTo/@xlink:href :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

return
    <table class="maintable hover">
        {html:buildXML("XML", $labels:XML, $labels:XML_SHORT, $validationResult, "This XML passed validation.", "This XML file did NOT pass the XML validation", $errors:ERROR)}
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "", "All values are valid", "record", "", $errors:WARNING)}
        {html:build3("D0", $labels:D0, $labels:D0_SHORT, $D0table, string($D0table/td), errors:getMaxError($D0table))}
        {html:build1("D1", $labels:D1, $labels:D1_SHORT, $D1table, "", $D1sum, "", "",$errors:ERROR)}
        {html:buildSimple("D2", $labels:D2, $labels:D2_SHORT, $D2table, "", "feature type", $D2errorLevel)}
        {html:buildSimple("D3", $labels:D3, $labels:D3_SHORT, $D3table, $D3count, "feature type", $D3errorLevel)}
        {html:build1("D4", $labels:D4, $labels:D4_SHORT, $D4table, string(count($D4table)), "", "", "",$errors:ERROR)}
        {html:build2("D5", $labels:D5, $labels:D5_SHORT, $D5invalid, "", "All values are valid", "record", "", $errors:ERROR)}
        {html:buildInfoTR("Specific checks on AQD_Network feature(s) within this XML")}
        {html:buildCountRow("D6", $labels:D6, $labels:D6_SHORT, $D6invalid, (), (), ())}
        {html:buildUnique("D7", $labels:D7, $labels:D7_SHORT, $D7table, "", string(count($D7table)), "namespace", $errors:ERROR)}
        {html:build2("D7.1", $labels:D7.1, $labels:D7.1_SHORT, $D7.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:buildResultRowsWithTotalCount_D("D8", $labels:D8, $labels:D8_SHORT, $D8invalid, "ef:mediaMonitored", "", "", "", $errors:WARNING)}
        {html:buildResultRowsWithTotalCount_D("D9", $labels:D9, $labels:D9_SHORT, $D9invalid, "ef:organisationLevel", "", "", "",$errors:WARNING)}
        {html:buildResultRowsWithTotalCount_D("D10", $labels:D10, $labels:D10_SHORT, $D10invalid, "aqd:networkType", "", "", "",$errors:WARNING)}
        {html:build2("D11", $labels:D11, $labels:D11_SHORT, $D11invalid, "aqd:AQD_Network/@gml:id", "All attributes are valid", " invalid attribute ", "", $errors:ERROR)}
        {html:build2("D12", $labels:D12, $labels:D12_SHORT, $D12invalid, "aqd:AQD_Network/ef:inspireId/base:Identifier/base:localId", "All attributes are valid", " invalid attribute ", "", $errors:WARNING)}
        {html:build2("D14", $labels:D14, $labels:D14_SHORT, $D14invalid, "aqd:aggregationTimeZone", "", "", "",$errors:ERROR)}
        {html:buildInfoTR("Specific checks on AQD_Station feature(s) within this XML")}
        {html:buildCountRow("D15", $labels:D15, $labels:D15_SHORT, $D15invalid, "All Ids are unique", (), ())}
        {html:buildUnique("D16", $labels:D16, $labels:D16_SHORT, $D16table, "", string(count($D16table)), "namespace", $errors:ERROR)}
        {html:build2("D16.1", $labels:D16.1, $labels:D16.1_SHORT, $D16.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:build2("D17", $labels:D17, $labels:D17_SHORT, $D17invalid, "", "All values are valid", "", "",$errors:ERROR)}
        {html:build2("D18", $labels:D18, $labels:D18_SHORT, $D18invalid, "", "All values are valid", "", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_D("D19", $labels:D19, $labels:D19, $D19invalid, "ef:mediaMonitored", "", "", "",$errors:WARNING)}
        {html:build2("D20", $labels:D20, $labels:D20_SHORT, $D20invalid, "aqd:AQD_Station/ef:inspireId/base:Identifier/base:localId","All smsName attributes are valid"," invalid attribute","", $errors:ERROR)}
        {html:build2("D21", $labels:D21, $labels:D21_SHORT, $invalidPosD21, "aqd:AQD_Zone/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "",$errors:ERROR)}
        {html:build2("D23", $labels:D23, $labels:D23_SHORT, $D23invalid, "", fn:string(count($D23invalid)), "", "",$errors:ERROR)}
        {html:build1("D24", $labels:D24, $labels:D24_SHORT, $D24table, "", string(count($D24table)) || "records found", "record", "", $errors:WARNING)}
        {html:build2("D26", $labels:D26, $labels:D26_SHORT, $D26invalid, "", "All station codes are valid", " invalid station codes", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_D("D27", $labels:D27, $labels:D27_SHORT, $D27invalid, "aqd:meteoParams", "", "", "",$errors:WARNING)}
        {html:buildResultRowsWithTotalCount_D("D28", $labels:D28, $labels:D28_SHORT, $D28invalid, "aqd:areaClassification", "", "", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_D("D29", $labels:D29, $labels:D29_SHORT, $D29invalid, "aqd:dispersionLocal", "", "", "",$errors:WARNING)}
        {html:buildResultRowsWithTotalCount_D("D30", $labels:D30, $labels:D30_SHORT, $D30invalid, "aqd:dispersionRegional", "", "", "",$errors:WARNING)}
        {html:build2("D31", $labels:D31, $labels:D31_SHORT, $D31invalid, "", concat(string(count($D31invalid))," errors found.") , "", "",$errors:ERROR)}
        {html:buildUnique("D32", $labels:D32, $labels:D32_SHORT, $D32table, "", string(count($D32table)), "namespace", $errors:ERROR)}
        {html:build2("D32.1", $labels:D32.1, $labels:D32.1_SHORT, $D32.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:buildResultRowsWithTotalCount_D("D33", $labels:D33, $labels:D33_SHORT, $D33invalid, "ef:mediaMonitored", "", "", "",$errors:WARNING)}
        {html:build2("D34", $labels:D34, $labels:D34_SHORT, $D34invalid, "", "All values are valid", "", "", $errors:ERROR)}
        {html:build2("D35", $labels:D35, $labels:D35_SHORT, $D35invalid, "aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId", $D35message, " invalid elements", "",$errors:ERROR)}
        {html:build2("D36", $labels:D36, $labels:D36_SHORT, $D36invalid, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "",$errors:WARNING)}
        {html:build2("D37", $labels:D37, $labels:D37_SHORT, $D37invalid, "", concat(fn:string(count($D37invalid))," errors found"), "", "",$errors:ERROR)}
        {html:build2("D40", $labels:D40, $labels:D40_SHORT, $D40invalid, "ef:observedProperty", "All values are valid", "invalid pollutant", "",$errors:ERROR)}
        {html:buildInfoTR("Internal XML cross-checks between AQD_SamplingPoint and AQD_Sample;AQD_SamplingPointProcess;AQD_Station;AQD_Network")}
        {html:buildInfoTR("Please note that the qa might give you warning if different features have been submitted in separate XMLs")}
        {html:build2("D41", $labels:D41, $labels:D41_SHORT, $D41invalid,"aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "",$errors:ERROR)}
        {html:build2("D42", $labels:D42, $labels:D42_SHORT, $D42invalid, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "",$errors:ERROR)}
        {html:build2("D43", $labels:D43, $labels:D43_SHORT, $D43invalid, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "",$errors:ERROR)}
        {html:build2("D44", $labels:D44, $labels:D44_SHORT, $D44invalid, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "",$errors:ERROR)}
        {html:build2("D45", $labels:D45, $labels:D45_SHORT, $D45invalid, "", concat(fn:string(count($D45invalid))," errors found"), "", "", $errors:ERROR)}
        {html:build2("D46", $labels:D46, $labels:D46_SHORT, $D46invalid, "", "", "", "","info")}
        {html:build2("D48", $labels:D48, $labels:D48_SHORT, $D48invalid, "", "All values are valid", "record", "", $errors:WARNING)}
        {html:build2("D50", $labels:D50, $labels:D50_SHORT, $D50invalid, "", concat(fn:string(count($D50invalid))," errors found"), "", "",$errors:ERROR)}
        {html:build2("D51", $labels:D51, $labels:D51_SHORT, $D51invalid, "", concat(fn:string(count($D51invalid))," errors found"), " invalid attribute", "", $errors:WARNING)}
        {html:build2("D53", $labels:D53, $labels:D53_SHORT, $D53invalid, "", concat(fn:string(count($D53invalid))," errors found"), " invalid attribute", "", $errors:ERROR)}
        {html:build2("D54", $labels:D54, $labels:D54_SHORT, $D54invalid, "", concat(string(count($D54invalid))," errors found.") , " invalid attribute", "",$errors:ERROR)}
        {html:buildInfoTR("Specific checks on AQD_SamplingPointProcess feature(s) within this XML")}
        {html:buildUnique("D55", $labels:D55, $labels:D55_SHORT, $D55table, "", string(count($D55table)), "namespace", $errors:INFO)}
        {html:build2("D55.1", $labels:D55.1, $labels:D55.1_SHORT, $D55.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:buildResultRowsWithTotalCount_D("D56", $labels:D56, $labels:D56_SHORT, $D56invalid, "aqd:measurementType", "", "", "",$errors:ERROR)}
        {html:build2("D57", $labels:D57, $labels:D57_SHORT, $D57table, "", concat(string(count($D57table)), " errors found"), "", "", $errors:WARNING)}
        {html:build2("D58", $labels:D58, $labels:D58_SHORT, $D58table, "", concat(fn:string(count($D58table))," errors found"), " invalid attribute", "",$errors:WARNING)}
        {html:buildResultRowsWithTotalCount_D("D59", $labels:D59, $labels:D59_SHORT, $D59invalid, "aqd:analyticalTechnique", "", "", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_D("D60a", $labels:D60a, $labels:D60a_SHORT, $D60ainvalid, "aqd:measurementEquipment", "", "", "",$errors:ERROR)}
        {html:buildResultRowsWithTotalCount_D("D60b", $labels:D60b, $labels:D60b_SHORT, $D60binvalid, "aqd:samplingEquipment", "", "", "",$errors:ERROR)}
        {html:build2("D61", $labels:D61, $labels:D61_SHORT, $D61invalid, "", "All values are valid", "record", "", $errors:WARNING)}
        {html:build2("D62", $labels:D62, $labels:D62_SHORT, $D62invalid, "", "All values are valid", "invalid record", "", $errors:WARNING)}
        <!--{xmlconv:buildResultRows("D61", "Total number ./aqd:dataQuality/aqd:DataQuality/aqd:detectionLimit witch does not contain an integer, fixed point or floating point number ",
                (), $allInvalid61, "", concat(fn:string(count($allInvalid61))," errors found"), "", "", ())}-->
        {html:buildResultRowsWithTotalCount_D("D63", $labels:D63, $labels:D63_SHORT, $D63invalid, "aqd:detectionLimit", "", "", "",$errors:ERROR)}
        {html:buildInfoTR("Checks on SamplingPointProcess(es) where the xlinked SamplingPoint has aqd:AQD_SamplingPoint/aqd:usedAQD equals TRUE (D67 to D70):")}
        {html:build2("D65", $labels:D65, $labels:D65_SHORT, $D65invalid, "", "All values are valid", "record", "", $errors:WARNING)}
        {html:build2("D67a", $labels:D67a, $labels:D67a_SHORT, $D67ainvalid, "", concat(fn:string(count($D67ainvalid))," errors found"), "", "", $errors:ERROR)}
        {html:build2("D67b", $labels:D67b, $labels:D67b_SHORT, $D67binvalid, "", concat(fn:string(count($D67binvalid))," errors found"), "", "", $errors:WARNING)}
        {html:build2("D68", $labels:D68, $labels:D68_SHORT, $D68invalid, "", concat(fn:string(count($D68invalid))," errors found"), "record", "", $errors:WARNING)}
        {html:build2("D69", $labels:D69, $labels:D69_SHORT, $D69invalid, "", concat(fn:string(count($D69invalid))," errors found"), "record", "", $errors:WARNING)}
        {html:buildInfoTR("Specific checks on AQD_Sample feature(s) within this XML")}
        {html:build2("D71", $labels:D71, $labels:D71_SHORT, $D71invalid, "", concat(string(count($D71invalid))," errors found.") , "", "",$errors:ERROR)}
        {html:buildUnique("D72", $labels:D72, $labels:D72_SHORT, $D72table, "", string(count($D72table)), "namespace", $errors:ERROR)}
        {html:build2("D72.1", $labels:D72.1, $labels:D72.1_SHORT, $D72.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:build2("D73", $labels:D73, $labels:D73_SHORT, $D73invalid, "", concat(string(count($D73invalid)), $errMsg73), "", "",$errLevelD73)}
        {html:build2("D74", $labels:D74, $labels:D74_SHORT, $D74invalid, "aqd:AQD_Sample/@gml:id","All srsDimension attributes are valid"," invalid attribute","",$errors:ERROR)}
        {html:build2("D75", $labels:D75, $labels:D75_SHORT, $D75invalid, "aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:localId", "All attributes are valid", " invalid attribute","",$errors:WARNING)}
        {html:build2("D76", $labels:D76, $labels:D76_SHORT, $D76invalid, "aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:localId", "All attributes are valid", " invalid attribute","",$errors:WARNING)}
        {html:build2("D77", $labels:D77, $labels:D77_SHORT, $D77invalid, "aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:localId", "All attributes are valid", " invalid attribute","",$errors:WARNING)}
        {html:build2("D78", $labels:D78, $labels:D78_SHORT, $D78invalid, "aqd:AQD_Sample/@gml:id","All values are valid"," invalid attribute","", $errors:WARNING)}
        {html:build2("D91", $labels:D91, $labels:D91_SHORT, $D91invalid, "", "All values are valid"," invalid attribute","", $errors:ERROR)}
        {html:build2("D92", $labels:D92, $labels:D92_SHORT, $D92invalid, "", "All values are valid"," invalid attribute","", $errors:ERROR)}
        {html:build2("D93", $labels:D93, $labels:D93_SHORT, $D93invalid, "", "All values are valid"," invalid attribute","", $errors:ERROR)}
        {html:build2("D94", $labels:D94, $labels:D94_SHORT, $D94invalid, "", "All values are valid"," invalid attribute","", $errors:ERROR)}
        <!--{xmlconv:buildResultRowsWithTotalCount("D67", <span>The content of ./aqd:AQD_SamplingPoint/aqd:samplingEquipment shall resolve to any concept in
            <a href="{ $xmlconv:UOM_CONCENTRATION_VOCABULARY }">{ $xmlconv:UOM_CONCENTRATION_VOCABULARY }</a></span>,
                (), (), "aqd:samplingEquipment", "", "", "",$allInvalid67 )} -->
    </table>
};

(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)
declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countFeatures := count(doc($source_url)//descendant::*[$xmlconv:FEATURE_TYPES = name()])
let $result := if ($countFeatures > 0) then xmlconv:checkReport($source_url, $countryCode) else ()
let $meta := map:merge((
    map:entry("count", $countFeatures),
    map:entry("header", "Check environmental monitoring feature types"),
    map:entry("dataflow", "Dataflow D"),
    map:entry("zeroCount", <p>No environmental monitoring feature type elements ({string-join($xmlconv:FEATURE_TYPES, ", ")}) found in this XML.</p>),
    map:entry("report", <p>This feedback report provides a summary overview of feature types reported and some consistency checks defined in Dataflow D as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
))
return
    html:buildResultDiv($meta, $result)
};