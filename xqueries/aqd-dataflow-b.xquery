xquery version "3.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     20 June 2013
 : Copyright:   European Environment Agency
 :
 : XQuery script implements dataflow B tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Enriko Käsper
 : @author George Sofianos
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document
 :)

module namespace dataflowB = "http://converters.eionet.europa.eu/dataflowB";

import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace filter = "aqd-filter" at "aqd-filter.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace schemax = "aqd-schema" at "aqd-schema.xquery";
import module namespace geox = "aqd-geo" at "aqd-geo.xquery";
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


declare variable $dataflowB:invalidCount as xs:integer := 0;
declare variable $dataflowB:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
declare variable $dataflowB:OBLIGATIONS as xs:string* := ($vocabulary:ROD_PREFIX || "670", $vocabulary:ROD_PREFIX || "693");

(: Rule implementations :)
declare function dataflowB:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
let $ms1Total := prof:current-ms()

let $ms1GeneralParameters:= prof:current-ms()
let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $cdrUrl := common:getCdrUrl($countryCode)
let $bdir := if (contains($source_url, "b_preliminary")) then "b_preliminary/" else "b/"
let $reportingYear := common:getReportingYear($docRoot)
let $latestEnvelopeB := query:getLatestEnvelope($cdrUrl || $bdir, $reportingYear)
let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesNamespaces := distinct-values($docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/base:namespace)

let $headerBeginPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition
let $headerEndPosition := $docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:endPosition

let $ms2GeneralParameters:= prof:current-ms()
(: File prefix/namespace check :)
let $ns1NS := prof:current-ms()
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
let $ns2NS := prof:current-ms()
(: VOCAB check:)

let $ns1DVOCAB := prof:current-ms()

let $VOCABinvalid := checks:vocab($docRoot)

let $ns2DVOCAB := prof:current-ms()

(:VOCABALL check @goititer:)

let $ms1CVOCABALL := prof:current-ms()

let $VOCABALLinvalid := checks:vocaball($docRoot)

let $ms2CVOCABALL := prof:current-ms()

(: B0 :)
let $ns1B0 := prof:current-ms()

let $B0table :=
    try {
        if ($reportingYear = "") then
            <tr class="{$errors:ERROR}">
                <td title="Status">Reporting Year is missing.</td>
            </tr>
        else if($headerBeginPosition > $headerEndPosition) then
            <tr class="{$errors:BLOCKER}">
                <td title="Status">Start position must be less than end position</td>
                <!-- <td title="Sparql">{sparqlx:getLink(query:deliveryExistsQuery($dataflowB:OBLIGATIONS, $countryCode, "b/", $reportingYear))}</td> -->
            </tr>
        else if (query:deliveryExists($dataflowB:OBLIGATIONS, $countryCode, "b/", $reportingYear)) then
            <tr class="{$errors:WARNING}">
                <td title="Status">Updating delivery for {$reportingYear}</td>
                <!-- <td title="Sparql">{sparqlx:getLink(query:deliveryExistsQuery($dataflowB:OBLIGATIONS, $countryCode, "b/", $reportingYear))}</td> -->
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
let $isNewDelivery := errors:getMaxError($B0table) = $errors:INFO
let $ns2B0 := prof:current-ms()

(: Generic variables :)
let $knownZones :=
    if ($isNewDelivery) then
        distinct-values(data(sparqlx:run(query:getZone(query:getLatestEnvelope($cdrUrl || $bdir, string(number($reportingYear) - 1))))//sparql:binding[@name = 'inspireLabel']/sparql:literal))
    else
        distinct-values(data(sparqlx:run(query:getZone($latestEnvelopeB))//sparql:binding[@name = 'inspireLabel']/sparql:literal))
        
let $knownZones2 :=
    if ($isNewDelivery) then
        sparqlx:getLink(query:getZone(query:getLatestEnvelope($cdrUrl || $bdir, string(number($reportingYear) - 1))))
    else
        sparqlx:getLink(query:getZone($latestEnvelopeB))

(: B01 :)

let $ns1B01 := prof:current-ms()

let $countZones := count($docRoot//aqd:AQD_Zone)

let $ns2B01 := prof:current-ms()

(: B02 :)
let $ns1B02 := prof:current-ms()

let $B02table :=
    try {
        for $zone in $docRoot//aqd:AQD_Zone
            let $id := $zone/am:inspireId/base:Identifier/base:namespace || "/" || $zone/am:inspireId/base:Identifier/base:localId
        where ($id = "/" or not($knownZones = $id))
        return
            <tr>
                <td title="base:localId">{$zone/am:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="zoneName">{data($zone/am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)}</td>
                <td title="zoneCode">{data($zone/aqd:zoneCode)}</td>
                <td title="aqd:predecessor">{if (empty($zone/aqd:predecessor)) then "not specified" else data($zone/aqd:predecessor/@xlink:href)}</td>
                <!-- <td title="Sparql getZone">{$knownZones2}</td> -->
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $B02errorLevel :=
    if (count($B02table) = $countZones) then
        $errors:B02
    else
        $errors:INFO

let $ns2B02 := prof:current-ms()

(: B03 :)
let $ns1B03 := prof:current-ms()
let $B03table :=
    try {
        for $zone in $docRoot//aqd:AQD_Zone
            let $id := $zone/am:inspireId/base:Identifier/base:namespace || "/" || $zone/am:inspireId/base:Identifier/base:localId
        where ($knownZones = $id)
        return
            <tr>
                <td title="base:localId">{$zone/am:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="zoneName">{data($zone/am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)}</td>
                <td title="zoneCode">{data($zone/aqd:zoneCode)}</td>
                <td title="aqd:predecessor">{if (empty($zone/aqd:predecessor)) then "not specified" else data($zone/aqd:predecessor/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B03 := prof:current-ms()

(: B04 :)
let $ns1B04 := prof:current-ms()

let $B04table :=
    try {
        for $rec in $docRoot//aqd:AQD_Zone
        return
            <tr>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="namespace/localId">{concat(data($rec/am:inspireId/base:Identifier/base:namespace), '/', data($rec/am:inspireId/base:Identifier/base:localId))}</td>
                <td title="zoneName">{data($rec/am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)}</td>
                <td title="zoneCode">{data($rec/aqd:zoneCode)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B04 := prof:current-ms()

(:B05a:)

let $ns1B05a := prof:current-ms()

let $B05ainvalid :=
    try {
        for $zone in $docRoot//aqd:AQD_Zone
            let $id := $zone/am:inspireId/base:Identifier/base:namespace || "/" || $zone/am:inspireId/base:Identifier/base:localId
            let $protectionTarget := 
                    for $pollutant in $zone/aqd:pollutants
                        let $protectiontargetValue := $pollutant/aqd:Pollutant/aqd:protectionTarget/@xlink:href
                    return $protectiontargetValue

        where ($id = "/" or not($knownZones = $id) and empty($zone/aqd:predecessor) and $protectionTarget = 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H')
        return
            <tr>
                <td title="base:localId">{$zone/am:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="zoneName">{data($zone/am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)}</td>
                <td title="zoneCode">{data($zone/aqd:zoneCode)}</td>
                <td title="aqd:predecessor">{if (empty($zone/aqd:predecessor)) then "not specified" else data($zone/aqd:predecessor/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B05a := prof:current-ms()
   
(:B05b:)

let $ns1B05b := prof:current-ms()

let $B05binvalid :=
    try {
        for $zone in $docRoot//aqd:AQD_Zone
            let $id := $zone/am:inspireId/base:Identifier/base:namespace || "/" || $zone/am:inspireId/base:Identifier/base:localId
            let $protectionTarget := 
                    for $pollutant in $zone/aqd:pollutants
                        let $protectiontargetValue := $pollutant/aqd:Pollutant/aqd:protectionTarget/@xlink:href
                    return $protectiontargetValue
            let $protectionTargetVegetetation := 
                    for $pollutant in $zone/aqd:pollutants
                        let $protectiontargetValue := $pollutant/aqd:Pollutant/aqd:protectionTarget[@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"]/@xlink:href
                    return $protectiontargetValue
        where ($id = "/" or not($knownZones = $id) and empty($zone/aqd:predecessor) and $protectionTarget = 'http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V' and count($protectionTarget) = count($protectionTargetVegetetation))
        return
            <tr>
                <td title="base:localId">{$zone/am:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="zoneName">{data($zone/am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)}</td>
                <td title="zoneCode">{data($zone/aqd:zoneCode)}</td>
                <td title="aqd:predecessor">{if (empty($zone/aqd:predecessor)) then "not specified" else data($zone/aqd:predecessor/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B05b := prof:current-ms()

(: B06a :)

let $ns1B06a := prof:current-ms()

let $countZonesWithAmGeometry :=
    try {
        count($docRoot//aqd:AQD_Zone/am:geometry)
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B06a := prof:current-ms()

(: B06b :)

let $ns1B06b := prof:current-ms()

let $countZonesWithLAU :=
    try {
        count($docRoot//aqd:AQD_Zone[not(empty(aqd:LAU)) or not(empty(aqd:shapefileLink))])
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B06b := prof:current-ms()

(: B07 - Compile & feedback a list of aqd:aqdZoneType, aqd:pollutantCode, aqd:protectionTarget combinations in the delivery :)

let $ns1B07 := prof:current-ms()

let $B07table :=
    try {
        let $allB7Combinations :=
            for $pollutant in $docRoot//aqd:Pollutant
            return concat(data($pollutant/../../aqd:aqdZoneType/@xlink:href), "#", data($pollutant/aqd:pollutantCode/@xlink:href), "#", data($pollutant/aqd:protectionTarget/@xlink:href))

        let $allB7Combinations := fn:distinct-values($allB7Combinations)
        for $rec in $allB7Combinations
        let $zoneType := substring-before($rec, "#")
        let $tmpStr := substring-after($rec, concat($zoneType, "#"))
        let $pollutant := substring-before($tmpStr, "#")
        let $protTarget := substring-after($tmpStr, "#")
        return
            <tr>
                <td title="aqd:aqdZoneType">{common:checkLink($zoneType)}</td>
                <td title="aqd:pollutantCode">{common:checkLink($pollutant)}</td>
                <td title="aqd:protectionTarget">{common:checkLink($protTarget)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ns2B07 := prof:current-ms()

(: B08 :)
let $ns1B08 := prof:current-ms()

let $B08table :=
    try {
        let $B08tmp :=
            for $x in $docRoot//aqd:AQD_Zone
                let $beginPosition := geox:parseDateTime($x/am:designationPeriod//gml:beginPosition)
                let $endPosition := geox:parseDateTime($x/am:designationPeriod//gml:endPosition)
                for $pollutantNode in $x/aqd:pollutants/aqd:Pollutant
                let $pollutant := string($pollutantNode/aqd:pollutantCode/@xlink:href)
                let $zone := string($pollutantNode/../../am:inspireId/base:Identifier/base:localId)
                let $protectionTarget := string($pollutantNode/aqd:protectionTarget/@xlink:href)
                let $key := string-join(($zone, $pollutant, $protectionTarget), "#")
           where common:isDateTimeIncludedB11B12New($reportingYear, $beginPosition, $endPosition)
            group by $pollutant, $protectionTarget
            return
                <result>
                    <pollutantName>{dd:getNameFromPollutantCode($pollutant)}</pollutantName>
                    <pollutantCode>{tokenize($pollutant, "/")[last()]}</pollutantCode>
                    <protectionTarget>{$protectionTarget}</protectionTarget>
                    <count>{count(distinct-values($key))}</count>
                </result>
        let $combinations :=
            <combinations>
                <combination pollutant="1" protectionTarget="H"/><combination pollutant="1" protectionTarget="V"/>
                <combination pollutant="7" protectionTarget="H"/><combination pollutant="7" protectionTarget="V"/>
                <combination pollutant="8" protectionTarget="H"/>
                <combination pollutant="9" protectionTarget="V"/>
                <combination pollutant="5" protectionTarget="H"/>
                <combination pollutant="6001" protectionTarget="H"/>
                <combination pollutant="10" protectionTarget="H"/>
                <combination pollutant="20" protectionTarget="H"/>
                <combination pollutant="5012" protectionTarget="H"/>
                <combination pollutant="5018" protectionTarget="H"/>
                <combination pollutant="5014" protectionTarget="H"/>
                <combination pollutant="5015" protectionTarget="H"/>
                <combination pollutant="5029" protectionTarget="H"/>
            </combinations>

        for $x in $combinations/combination
            let $pollutant := $x/@pollutant
            let $protectionTarget := $vocabulary:PROTECTIONTARGET_VOCABULARY || $x/@protectionTarget
            let $elem := $B08tmp[pollutantCode = $pollutant and protectionTarget = $protectionTarget]
            let $count := string($elem/count)
            let $vsName := dd:getNameFromPollutantCode($pollutant)
            let $vsCode := string($vocabulary:POLLUTANT_VOCABULARY || $pollutant)
            let $errorClass :=
                if ($countryCode = "gi" and (($x/@pollutant = "1" and $x/@protectionTarget = "V") or ($x/@pollutant = "9" and $x/@protectionTarget = "V"))) then
                    $errors:INFO
                else if ($count = "" or $count = "NaN" or $count = "0") then
                    $errors:B08
                else
                    $errors:INFO
            order by $vsName
            return
                <tr class="{$errorClass}">
                    <td title="Pollutant Name">{$vsName}</td>
                    <td title="Pollutant Code">{$vsCode}</td>
                    <td title="Protection Target">{$protectionTarget}</td>
                    <td title="Count">{$count}</td>


                </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ns2B08 := prof:current-ms()

(: B09 :)
(:TODO: ADD TRY CATCH :)

let $ns1B09 := prof:current-ms()

let $all1 := $docRoot//aqd:AQD_Zone/lower-case(@gml:id)
let $part1 := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/@gml:id
    where string-length($id) > 0 and count(index-of($all1, lower-case($id))) > 1
    return
        $id
    )
let $part1 :=
    for $x in $part1
    return
        <tr>
            <td title="Duplicate records">@gml:id [{$x}]</td>
        </tr>

let $all2 :=
    for $id in $docRoot//aqd:AQD_Zone/am:inspireId
    return lower-case("[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]")
let $part2 := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/am:inspireId
    let $key := "[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]"
    where string-length($id/base:Identifier/base:localId) > 0 and count(index-of($all2, lower-case($key))) > 1
    return
        $key
    )
let $part2 :=
    for $x in $part2
    return
        <tr>
            <td title="Duplicate records">am:inspireId {$x}</td>
        </tr>

let $all3 :=
    for $id in $docRoot//aqd:AQD_Zone/aqd:inspireId
    return lower-case("[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]")
let $part3 := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/aqd:inspireId
    let $key := "[" || $id/base:Identifier/base:localId || ", " || $id/base:Identifier/base:namespace || ", " || $id/base:Identifier/base:versionId || "]"
    where  string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($all3, lower-case($key))) > 1
    return
        $key
    )
let $part3 :=
    for $x in $part3
    return
        <tr>
            <td title="Duplicate records">aqd:inspireId {$x}</td>
        </tr>

let $countGmlIdDuplicates := count($part1)
let $countamInspireIdDuplicates := count($part2)
let $countaqdInspireIdDuplicates := count($part3)
let $B09invalid := ($part1, $part2, $part3)

let $ns2B09 := prof:current-ms()

(: B10 :)

let $ns1B10 := prof:current-ms()

let $B10table :=
    try {
        for $id in $zonesNamespaces
        let $localId := $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier[base:namespace = $id]/base:localId
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

let $ns2B10 := prof:current-ms()

(: B10.1 :)

let $ns1B10.1 := prof:current-ms()

let $B10.1invalid :=
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


let $combinations :=
            <combinations>
                <combination pollutant="1" protectionTarget="H"/>
                <combination pollutant="7" protectionTarget="H"/>
                <combination pollutant="8" protectionTarget="H"/>
                <combination pollutant="5" protectionTarget="H"/>
                <combination pollutant="6001" protectionTarget="H"/>
                <combination pollutant="10" protectionTarget="H"/>
                <combination pollutant="20" protectionTarget="H"/>
                <combination pollutant="5012" protectionTarget="H"/>
                <combination pollutant="5018" protectionTarget="H"/>
                <combination pollutant="5014" protectionTarget="H"/>
                <combination pollutant="5015" protectionTarget="H"/>
                <combination pollutant="5029" protectionTarget="H"/>
            </combinations>

let $conbicount := 
    for $x in $combinations/combination
        return count($x)

let $ns2B10.1 := prof:current-ms()

(: B11 :)

let $ns1B11 := prof:current-ms()

let $B11table :=

    try {
        let $B11tmp :=
            for $x in $docRoot//aqd:AQD_Zone
                let $beginPosition := geox:parseDateTime($x/am:designationPeriod//gml:beginPosition)
                let $endPosition := geox:parseDateTime($x/am:designationPeriod//gml:endPosition)
                let $population := $x/aqd:residentPopulation
                    for $pollutantNode in $x/aqd:pollutants/aqd:Pollutant
                    let $pollutant := string($pollutantNode/aqd:pollutantCode/@xlink:href)
                    let $zone := string($pollutantNode/../../am:inspireId/base:Identifier/base:localId)
                    let $protectionTarget := string($pollutantNode/aqd:protectionTarget/@xlink:href)
                    let $key := string-join(($zone, $pollutant, $protectionTarget), "#")
                    
                    
            (:where common:isDateTimeIncludedB11B12($reportingYear, $beginPosition, $endPosition) and $x/am:designationPeriod//gml:endPosition[@indeterminatePosition]:)
            where common:isDateTimeIncludedB11B12New($reportingYear, $beginPosition, $endPosition)
            (:group by $pollutant, $protectionTarget:)
            return
                <result>
                    <pollutantName>{dd:getNameFromPollutantCode($pollutant)}</pollutantName>
                    <pollutantCode>{tokenize($pollutant, "/")[last()]}</pollutantCode>
                    <protectionTarget>{$protectionTarget}</protectionTarget>
                    <population>{$population}</population>
                    <count>{count(distinct-values($key))}</count>
                </result>

        

            let $NamespaceDD := 
             for $x in doc($vocabulary:AQD_Namespace || "rdf")//skos:Concept
              
                let $currentCountry := string(fn:upper-case($countryCode))
                let $countryyy := string($x/prop:inCountry/@rdf:resource)
                let $length := fn:string-length($countryyy) - 1
                let $sbst := fn:substring($countryyy, $length, 2)
                let $population :=  $x/prop:Population
                
                where ($currentCountry = $sbst)            

                return $population
            
           
            
            for $x in $combinations/combination
                let $pollutant := $x/@pollutant
                let $protectionTarget := $vocabulary:PROTECTIONTARGET_VOCABULARY || $x/@protectionTarget
                let $elem := $B11tmp[pollutantCode = $pollutant and protectionTarget = $protectionTarget]
                let $count := string($elem/count)
                let $pupulation := $elem/population 
                let $pupulationSum := sum($pupulation)
                let $pop5less := fn:round(distinct-values($NamespaceDD) * 0.95)
                let $pop5more := fn:round(distinct-values($NamespaceDD) * 1.05)
                let $goodOrNo := 
                                let $test := sum($pupulation) > $pop5less and sum($pupulation) < $pop5more
                                return  if(empty($pupulation) and $pupulationSum = 0) then 
                                            "..."
                                        else if($test = false())then 
                                            "Fail"
                                        else("OK")
                
                let $goodOrNocount := $goodOrNo 
               return 
                    if(count($goodOrNo = "OK" or $goodOrNo = "...") != 0 )then (:Revisar este If, proque sale siempre el error:)
                <tr>
                    <td title="pollutant">{data($pollutant)}</td> 
                    <td title="protectionTarget">{$protectionTarget}</td>
                    <td title="PopulationSum">{$pupulationSum}</td>
                    <td title="Status">{$goodOrNo}</td>
                    <td title="PopulationDD-5">{$pop5less}</td>
                    <td title="PopulationDD+5">{$pop5more}</td>
                </tr>
                else()
                
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $B11count := 
                    for $x in $B11table/td[4]
                            where $x = "OK" or $x = "..."
                            return count($x)

    let $B11errorLevel :=
         
        if (sum($B11count) = sum($conbicount)) then
            $errors:INFO
        else
            $errors:B11

let $ns2B11 := prof:current-ms()
    

(:B12:)
let $ns1B12 := prof:current-ms()

let $B12table :=

    try {
        let $B12tmp :=
            for $x in $docRoot//aqd:AQD_Zone
                let $beginPosition := geox:parseDateTime($x/am:designationPeriod//gml:beginPosition)
                let $endPosition := geox:parseDateTime($x/am:designationPeriod//gml:endPosition)
                let $area := $x/aqd:area
                
                    for $pollutantNode in $x/aqd:pollutants/aqd:Pollutant
                    let $pollutant := string($pollutantNode/aqd:pollutantCode/@xlink:href)
                    let $zone := string($pollutantNode/../../am:inspireId/base:Identifier/base:localId)
                    let $protectionTarget := string($pollutantNode/aqd:protectionTarget/@xlink:href)
                    let $key := string-join(($zone, $pollutant, $protectionTarget), "#")
                    
                    
            (:where common:isDateTimeIncludedB11B12($reportingYear, $beginPosition, $endPosition) and $x/am:designationPeriod//gml:endPosition[@indeterminatePosition]:)
            where common:isDateTimeIncludedB11B12New($reportingYear, $beginPosition, $endPosition)
            (:group by $pollutant, $protectionTarget:)
            return
                <result>
                    <pollutantName>{dd:getNameFromPollutantCode($pollutant)}</pollutantName>
                    <pollutantCode>{tokenize($pollutant, "/")[last()]}</pollutantCode>
                    <protectionTarget>{$protectionTarget}</protectionTarget>
                    <area>{$area}</area>
                    <count>{count(distinct-values($key))}</count>
                </result>

            let $NamespaceDD := 
             for $x in doc($vocabulary:AQD_Namespace || "rdf")//skos:Concept
              
                let $currentCountry := string(fn:upper-case($countryCode))
                let $countryyy := string($x/prop:inCountry/@rdf:resource)
                let $length := fn:string-length($countryyy) - 1
                let $sbst := fn:substring($countryyy, $length, 2)
                let $area :=  $x/prop:SurfaceArea
                
                where ($currentCountry = $sbst)            

                return $area


            for $x in $combinations/combination
                let $pollutant := $x/@pollutant
                let $protectionTarget := $vocabulary:PROTECTIONTARGET_VOCABULARY || $x/@protectionTarget
                let $elem := $B12tmp[pollutantCode = $pollutant and protectionTarget = $protectionTarget]
                let $count := string($elem/count)
                let $area := $elem/area 
                let $areaSum := sum($area)
                let $area5less := round-half-to-even(distinct-values($NamespaceDD) * 0.995, 2)
                let $area5more := round-half-to-even(distinct-values($NamespaceDD) * 1.005, 2)
                let $goodOrNo := 
                                let $test := sum($areaSum) > $area5less and sum($areaSum) < $area5more
                                return  if(empty($area) and $areaSum = 0) then 
                                            "..."
                                        else if($test = false())then 
                                            "Fail"
                                        else("OK")
                
                let $goodOrNocount := $goodOrNo 
                return

                 <tr>
                    <td title="pollutant">{data($pollutant)}</td> 
                    <td title="protectionTarget">{$protectionTarget}</td>
                    <td title="Area">{$areaSum}</td>
                    <td title="Status">{$goodOrNo}</td>
                    <td title="AreaDD-0.5%">{$area5less}</td>
                    <td title="AreaDD+0.5%">{$area5more}</td>
                </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $B12count := 
           for $x in $B12table/td[4]
                    where $x = "OK" or $x = "..."
                    return count($x)

    let $B12errorLevel :=
     
        if (sum($B12count) = sum($conbicount)) then
            $errors:INFO
        else
            $errors:B12

    let $ns2B12 := prof:current-ms()

(:B12b:)
let $ns1B12b := prof:current-ms()

let $B12btable :=

    try {
        let $B12btmp :=
            for $x in $docRoot//aqd:AQD_Zone
                let $beginPosition := geox:parseDateTime($x/am:designationPeriod//gml:beginPosition)
                let $endPosition := geox:parseDateTime($x/am:designationPeriod//gml:endPosition)
                let $area := $x/aqd:area
                
                    for $pollutantNode in $x/aqd:pollutants/aqd:Pollutant
                    let $pollutant := string($pollutantNode/aqd:pollutantCode/@xlink:href)
                    let $zone := string($pollutantNode/../../am:inspireId/base:Identifier/base:localId)
                    let $protectionTarget := string($pollutantNode/aqd:protectionTarget/@xlink:href)
                    let $key := string-join(($zone, $pollutant, $protectionTarget), "#")
                    
                    
            (:where common:isDateTimeIncludedB11B12($reportingYear, $beginPosition, $endPosition) and $x/am:designationPeriod//gml:endPosition[@indeterminatePosition]:)
            where common:isDateTimeIncludedB11B12New($reportingYear, $beginPosition, $endPosition)
            (:group by $pollutant, $protectionTarget:)
            return
                <result>
                    <pollutantName>{dd:getNameFromPollutantCode($pollutant)}</pollutantName>
                    <pollutantCode>{tokenize($pollutant, "/")[last()]}</pollutantCode>
                    <protectionTarget>{$protectionTarget}</protectionTarget>
                    <area>{$area}</area>
                    <count>{count(distinct-values($key))}</count>
                </result>

            let $NamespaceDD := 
             for $x in doc($vocabulary:AQD_Namespace || "rdf")//skos:Concept
              
                let $currentCountry := string(fn:upper-case($countryCode))
                let $countryyy := string($x/prop:inCountry/@rdf:resource)
                let $length := fn:string-length($countryyy) - 1
                let $sbst := fn:substring($countryyy, $length, 2)
                let $area :=  $x/prop:AreaDifference
                
                where ($currentCountry = $sbst)            

                return $area

            let $arrayAreas := array {
              for $x in $combinations/combination
                  let $pollutant := $x/@pollutant
                  let $protectionTarget := $vocabulary:PROTECTIONTARGET_VOCABULARY || $x/@protectionTarget
                  let $elem := $B12btmp[pollutantCode = $pollutant and protectionTarget = $protectionTarget]
                  let $count := string($elem/count)
                  let $area := $elem/area 
                  let $areaSum := sum($area)
                  
                  return $areaSum
             }     
             
                let $minSumArea := distinct-values(min($arrayAreas))
                let $maxSumArea := distinct-values(max($arrayAreas))
                let $difference := $maxSumArea - $minSumArea
                
                where $difference > $NamespaceDD return 
                 <tr>
                    <td title="Minimum area">{$minSumArea}</td>
                    <td title="Maximum area">{$maxSumArea}</td>
                    <td title="Area difference">{$difference}</td>
                 </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $B12bcount := 
           for $x in $B12btable/td[4]
                    where $x = "OK" or $x = "..."
                    return count($x)

    let $B12berrorLevel :=
     
        if (sum($B12bcount) = sum($conbicount)) then
            $errors:INFO
        else
            $errors:B12b

let $ns2B12b := prof:current-ms()

(: B13 :)

let $ns1B13 := prof:current-ms()

let $B13invalid :=
    try {
        let $langSkippedMsg := "The test was skipped - ISO 639-3 and ISO 639-5 language codes are not available in Content Registry."
        let $langCodes := distinct-values(data(sparqlx:run(query:getLangCodesSparql())//sparql:binding[@name='code']/sparql:literal))

        for $x in $docRoot//aqd:AQD_Zone/am:name/gn:GeographicalName/gn:language
        where not($x = $langCodes)
        return
            <tr>
                <td title="aqd:AQD_Zone">{data($x/../../../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="gn:language">{data($x)}</td>
                <td title="Sparql">{sparqlx:getLink(query:getLangCodesSparql())}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ns2B13 := prof:current-ms()

(: B18 :)

let $ns1B18 := prof:current-ms()

let $B18invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone[string(am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text) = ""]
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/am:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B18 := prof:current-ms()

(: B20 :)

let $ns1B20 := prof:current-ms()

let $B20invalid :=
    try {
        let $validSrsNames := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4326", "urn:ogc:def:crs:EPSG::4258")
        let $invalidPolygonName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Polygon) > 0 and not(am:geometry/gml:Polygon/@srsName = $validSrsNames)]/am:inspireId/base:Identifier/base:localId)
        let $invalidPointName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Point) > 0 and not(am:geometry/gml:Point/@srsName = $validSrsNames)]/am:inspireId/base:Identifier/base:localId)
        let $invalidMultiPointName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:MultiPoint) > 0 and not(am:geometry/gml:MultiPoint/@srsName = $validSrsNames)]/am:inspireId/base:Identifier/base:localId)
        let $invalidMultiSurfaceName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:MultiSurface) > 0 and not(am:geometry/gml:MultiSurface/@srsName = $validSrsNames)]/am:inspireId/base:Identifier/base:localId)
        let $invalidGridName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Grid) > 0 and not(am:geometry/gml:Grid/@srsName = $validSrsNames)]/am:inspireId/base:Identifier/base:localId)
        let $invalidRectifiedGridName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:RectifiedGrid) > 0 and not(am:geometry/gml:RectifiedGrid/@srsName = $validSrsNames)]/am:inspireId/base:Identifier/base:localId)
        for $x in distinct-values(($invalidPolygonName, $invalidMultiPointName, $invalidPointName, $invalidMultiSurfaceName, $invalidGridName, $invalidRectifiedGridName))
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B20 := prof:current-ms()

(: B21 :)

let $ns1B21 := prof:current-ms()

let $B21invalid  :=
    try {
        let $count := count($docRoot//aqd:AQD_Zone/am:geometry//gml:posList[@srsDimension != "2"])
        let $metadata := html:createMetadataTR($count)
        let $result :=
        for $x in $docRoot//aqd:AQD_Zone/am:geometry//gml:posList[@srsDimension != "2"]
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/ancestor::aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId)}</td>
                <td title="Polygon">{string($x/ancestor::gml:Polygon/@gml:id)}</td>
                <td title="srsDimension">{string($x/@srsDimension)}</td>
            </tr>
        return ($metadata, $result)
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B21 := prof:current-ms()

(: B22 - generalized by Hermann :)

let $ns1B22 := prof:current-ms()

let $B22invalid :=
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

    let $ns2B22 := prof:current-ms()

(: B23 - generalized by Hermann
 : In Europe, lat values tend to be bigger than lon values. We use this observation as a poor farmer's son test to check that in a coordinate value pair,
 : the lat value comes first, as defined in the GML schema
:)

let $ns1B23 := prof:current-ms()

let $B23invalid :=
    try {
        for $latLong in $docRoot//gml:posList
        let $latlongToken := fn:tokenize(normalize-space($latLong), "\s+")
        let $lat := number($latlongToken[1])
        let $long := number($latlongToken[2])
        let $srsName := string($latLong/../../../@srsName)
        where (not($countryCode = "fr") and not(geox:compareLatLong($srsName, $lat, $long)))
        return
            <tr>
                <td title="Polygon">{string($latLong/../../../@gml:id)}</td>
                <td title="srsName">{$srsName}</td>
                <td title="First vertex">{string($lat) || string($long)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $B23message :=
    if ($countryCode = "fr") then
        "Temporary turned off"
    else
        "All values are valid"

let $ns2B23 := prof:current-ms()

(: B24 - ./am:zoneType value shall resolve to http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone :)

let $ns1B24 := prof:current-ms()

 let $B24invalid  :=
     try {
         for $x in $docRoot//aqd:AQD_Zone/am:zoneType
         where not($x/@xlink:href = $vocabulary:AQ_MANAGEMENET_ZONE) and not($x/@xlink:href = $vocabulary:AQ_MANAGEMENET_ZONE_LC)
         return
             <tr>
                <td title="aqd:AQD_Zone">{string($x/../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="zoneType">{string($x/@xlink:href)}</td>
             </tr>
     } catch * {
         <tr class="{$errors:FAILED}">
             <td title="Error code">{$err:code}</td>
             <td title="Error description">{$err:description}</td>
         </tr>
     }

let $ns2B24 := prof:current-ms()

(: B25 :)
(: ./am:designationPeriod/gml:TimePeriod/gml:beginPosition shall be less than ./am:designationPeri/gml:TimePeriod/gml:endPosition. :)

let $ns1B25 := prof:current-ms()

 let $B25invalid  :=
     try {
         for $timePeriod in $docRoot//aqd:AQD_Zone/am:designationPeriod/gml:TimePeriod
         (: XQ does not support 24h that is supported by xsml schema validation :)
         (: TODO: comment by sofiageo - the above statement is not true, fix this if necessary :)
         let $beginDate := substring(normalize-space($timePeriod/gml:beginPosition), 1, 10)
         let $endDate := substring(normalize-space($timePeriod/gml:endPosition), 1, 10)
         let $beginPosition := if ($beginDate castable as xs:date) then xs:date($beginDate) else ()
         let $endPosition := if ($endDate castable as xs:date) then xs:date($endDate) else ()
         where (not(empty($beginPosition)) and not(empty($endPosition)) and $beginPosition > $endPosition)
         return
         (:  concat($timePeriod/../../@gml:id, ": gml:beginPosition=", $beginPosition, ": gml:endPosition=", $endPosition) :)
            <tr>
                <td title="aqd:AQD_Zone">{string($timePeriod/../../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="gml:beginPosition">{$beginPosition}</td>
                <td title="gml:endPosition">{$endPosition}</td>
            </tr>
     } catch * {
         <tr class="{$errors:FAILED}">
             <td title="Error code">{$err:code}</td>
             <td title="Error description">{$err:description}</td>
         </tr>
     }

let $ns2B25 := prof:current-ms()

(: B28 - ./am:beginLifespanVersion shall be a valid historical date for the start of the version of the zone in extended ISO format.
If an am:endLifespanVersion exists its value shall be greater than the am:beginLifespanVersion :)

let $ns1B28 := prof:current-ms()

let $B28invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone
        let $beginDate := substring(normalize-space($x/am:beginLifespanVersion), 1, 10)
        let $endDate := substring(normalize-space($x/am:endLifespanVersion), 1, 10)
        let $beginPeriod := if ($beginDate castable as xs:date) then xs:date($beginDate) else ()
        let $endPeriod := if ($endDate castable as xs:date) then xs:date($endDate) else ()
        where ((not(empty($beginPeriod)) and not(empty($endPeriod)) and $beginPeriod > $endPeriod) or empty($beginPeriod))
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/am:inspireId/base:Identifier/base:localId)}</td>
                <td title="am:beginLifespanVersion">{data($x/am:beginLifespanVersion)}</td>
                <td title="am:endLifespanVersion">{data($x/am:endLifespanVersion)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B28 := prof:current-ms()

(: B30 :)

let $ns1B30 := prof:current-ms()

let $B30invalid :=
    try {
        for $x in $docRoot//am:environmentalDomain
        where not(starts-with($x/@xlink:href, $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI) or starts-with($x/@xlink:href, $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI_UC))
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="am:environmentalDomain">{data($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

    let $ns2B30 := prof:current-ms()

(: B31 :)

let $ns1B31 := prof:current-ms()

let $B31invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:name) != "2011/850/EC"]
        let $base2 := if (string-length($x/base2:name) > 20) then concat(substring($x/base2:name, 1, 20), "...") else $x/base2:name
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/../../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="base2:name">{string($base2)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B31 := prof:current-ms()

(: B32 :)

let $ns1B32 := prof:current-ms()

let $B32invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:date) != "2011-12-12"]
        let $base2 := if (string-length($x/base2:date) > 20) then concat(substring($x/base2:date, 1, 20), "...") else $x/base2:date
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/../../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="base2:date">{string($base2)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B32 := prof:current-ms()

(: B33 :)

let $ns1B33 := prof:current-ms()

let $B33invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:link) != "http://rod.eionet.europa.eu/instruments/650"]
        let $base2 := if (string-length($x/base2:link) > 40) then concat(substring($x/base2:link, 1, 40), "...") else $x/base2:link
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/../../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="base2:link">{string($base2)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B33 := prof:current-ms()

(: B34 :)

let $ns1B34 := prof:current-ms()

let $B34invalid :=
    try {
        for $x in $docRoot//base2:level
        where not(starts-with($x/@xlink:href, $vocabulary:LEGISLATION_LEVEL) or starts-with($x/@xlink:href, $vocabulary:LEGISLATION_LEVEL_LC))
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/../../../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="base2:level">{string($x/@xlink:href)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B34 := prof:current-ms()


(: B35 :)

let $ns1B35 := prof:current-ms()

let $amNamespaceAndaqdZoneCodeIds := $docRoot//aqd:AQD_Zone/concat(am:inspireId/base:Identifier/lower-case(normalize-space(base:namespace)), '##', lower-case(normalize-space(aqd:zoneCode)))
let $dublicateAmNamespaceAndaqdZoneCodeIds := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Zone
        where string-length(normalize-space($identifier/am:inspireId/base:Identifier/base:namespace)) > 0 and count(index-of($amNamespaceAndaqdZoneCodeIds,
                concat($identifier/am:inspireId/base:Identifier/lower-case(normalize-space(base:namespace)), '##', $identifier/lower-case(normalize-space(aqd:zoneCode))))) > 1
        return
            concat(normalize-space($identifier/am:inspireId/base:Identifier/base:namespace), ':', normalize-space($identifier/aqd:zoneCode))
)
let $countB35duplicates :=
    try {
        let $countAmNamespaceAndaqdZoneCodeDuplicates := count($dublicateAmNamespaceAndaqdZoneCodeIds)
        return $countAmNamespaceAndaqdZoneCodeDuplicates
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B35 := prof:current-ms()

(: B36 :)

let $ns1B36 := prof:current-ms()

let $B36invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone[not(count(aqd:residentPopulation)>0 and aqd:residentPopulation castable as xs:integer and number(aqd:residentPopulation) >= 0)]
        let $residentPopulation := if (string-length($x/aqd:residentPopulation) = 0) then "missing" else $x/aqd:residentPopulation
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/am:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:residentPopulation">{string($residentPopulation)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B36 := prof:current-ms()


(: B37 - ./aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition shall cite the year in which the resident population was estimated in yyyy format :)

let $ns1B37 := prof:current-ms()

let $B37invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone
        where (common:isInvalidYear(data($x/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition)))
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/am:inspireId/base:Identifier/base:localId)}</td>
                <td title="gml:timePosition">{data($x/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B37 := prof:current-ms()

(: B38 :)


let $ns1B38 := prof:current-ms()

let $B38invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone[not(count(aqd:area)>0 and number(aqd:area) and number(aqd:area) > 0)]
        let $area := if (string-length($x/aqd:area) = 0) then "missing" else $x/aqd:area
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/am:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:area">{data($area)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B38 := prof:current-ms()

(: B39a - Find invalid combinations :)

let $ns1B39a := prof:current-ms()

let $pollutantCombinations :=
    <combinations>
        <combination>
            <code>1</code>
            <target>H</target>
        </combination>
        <combination>
            <code>1</code>
            <target>V</target>
        </combination>
        <combination>
            <code>7</code>
            <target>H</target>
        </combination>
        <combination>
            <code>7</code>
            <target>V</target>
        </combination>
        <combination>
            <code>8</code>
            <target>H</target>
        </combination>
        <combination>
            <code>9</code>
            <target>V</target>
        </combination>
        <combination>
            <code>5</code>
            <target>H</target>
        </combination>
        <combination>
            <code>6001</code>
            <target>H</target>
        </combination>
        <combination>
            <code>10</code>
            <target>H</target>
        </combination>
        <combination>
            <code>20</code>
            <target>H</target>
        </combination>
        <combination>
            <code>5012</code>
            <target>H</target>
        </combination>
        <combination>
            <code>5018</code>
            <target>H</target>
        </combination>
        <combination>
            <code>5014</code>
            <target>H</target>
        </combination>
        <combination>
            <code>5015</code>
            <target>H</target>
        </combination>
        <combination>
            <code>5029</code>
            <target>H</target>
        </combination>
    </combinations>
let $pollutantCodeVocabulary := "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/"
let $pollutantTargetVocabulary := "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/"
let $B39aItemsList :=
    <table>
        <caption>Allowed Pollutant / Target combinations: </caption>
        <thead>
            <tr>
                <th>Pollutant</th>
                <th>Protection target</th>
            </tr>
        </thead>
        <tbody>{
            for $i in $pollutantCombinations//combination
            return
                <tr>
                    <td>{concat($pollutantCodeVocabulary, $i/code)}</td>
                    <td>{concat($pollutantTargetVocabulary, $i/target)}</td>
                </tr>
        }</tbody>
    </table>



(: B39a :)



let $B39ainvalid :=
    for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant
        let $code := string($x/aqd:pollutantCode/@xlink:href)
        let $target := string($x/aqd:protectionTarget/@xlink:href)
    where not($pollutantCombinations//combination[concat($pollutantCodeVocabulary, code) = $code and concat($pollutantTargetVocabulary, target) = $target])
    return
        <tr>
            <td title="base:localId">{string($x/../../am:inspireId/base:Identifier/base:localId)}</td>
            <td title="Pollutant">{string($code)}</td>
            <td title="Protection target">{string($target)}</td>
        </tr>

let $ns2B39a := prof:current-ms()

(: B39b - Count combination occurrences  :)


let $ns1B39b := prof:current-ms()

let $B39binvalid :=
    try {
        let $pollutantOccurrences := <results> {
            for $x in $pollutantCombinations//combination
            let $code := concat($pollutantCodeVocabulary, $x/code)
            let $target := concat($pollutantTargetVocabulary, $x/target)
            let $count := count($docRoot//aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant[aqd:pollutantCode/@xlink:href = $code and aqd:protectionTarget/@xlink:href = $target])
            let $warning :=
                if ($count = 0) then
                    if ($countryCode = "gi") then
                        if ((($code = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/1") and ($target = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V")) or
                        (($code = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/9") and ($target = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/V"))) then
                            0 else 1
                    else 1
                else 0
            return
                <result>
                    <code>{$code}</code>
                    <target>{$target}</target>
                    <warning>{$warning}</warning>
                </result>
        }</results>
        for $x in $pollutantOccurrences//result[warning = 1]
        return
            <tr>
                <td title="Pollutant">{data($x/code)}</td>
                <td title="Protection target">{data($x/target)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B39b := prof:current-ms()

(: B39c - Combination cannot be repeated in individual zone :)

let $ns1B39c := prof:current-ms()

let $B39cinvalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone
        let $codes :=
            for $y in $pollutantCombinations//combination
            let $code := concat($pollutantCodeVocabulary, $y/code)
            let $target := concat($pollutantTargetVocabulary, $y/target)
            let $count := count($x/aqd:pollutants/aqd:Pollutant[aqd:pollutantCode/@xlink:href = $code and aqd:protectionTarget/@xlink:href = $target])
            where $count > 1
            return $code
        let $codes := distinct-values($codes)
        where not(empty($codes))
        return
            <tr>
                <td title="base:localId">{data($x/am:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B39c := prof:current-ms()

(: B40 - /aqd:timeExtensionExemption attribute must resolve to one of concept within http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/ :)

let $ns1B40 := prof:current-ms()

let $B40invalid :=
    try {
        let $year := xs:integer(common:getReportingYear($docRoot))
        let $valid :=
            if ($year >= 2015) then
                "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/none"
            else
                dd:getValidConcepts("http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/rdf")
            for $x in $docRoot//aqd:AQD_Zone/aqd:timeExtensionExemption/@xlink:href
            where (not($x = $valid))
            return
                <tr>
                    <td title="aqd:AQD_Zone">{string($x/../../am:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:timeExtensionExemption">{string($x)}</td>
                </tr>

    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B40 := prof:current-ms()

(: B41 :)

let $ns1B41 := prof:current-ms()

let $B41invalid :=
    try {
        let $zoneIds :=
            for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants
            where ($x/aqd:Pollutant/aqd:pollutantCode/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8" and $x/aqd:Pollutant/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                    and ($x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-1h"
                            or $x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-annual")
            return
                string($x/../am:inspireId/base:Identifier/base:localId)

        for $y in $docRoot//aqd:AQD_Zone[aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-1h"
                or aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-annual"]
        where empty(index-of($zoneIds, string($y/am:inspireId/base:Identifier/base:localId)))
        return
            <tr>
                <td title="base:localId">{data($y/am:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:pollutantCode">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8")}</td>
                <td title="aqd:protectionTarget">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B41 := prof:current-ms()


(: B42 :)

let $ns1B42 := prof:current-ms()

let $B42invalid :=
    try {
        let $zoneIds :=
            for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants
            where ($x/aqd:Pollutant/aqd:pollutantCode/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5" and $x/aqd:Pollutant/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                    and ($x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-24h"
                            or $x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-annual")
            return string($x/../am:inspireId/base:Identifier/base:localId)


        for $y in $docRoot//aqd:AQD_Zone[aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-24h"
                or aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-annual"]
        where (not($zoneIds = string($y/am:inspireId/base:Identifier/base:localId)))
        return
            <tr>
                <td title="base:localId">{data($y/am:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:pollutantCode">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5")}</td>
                <td title="aqd:protectionTarget">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B42 := prof:current-ms()

(: B43 :)

let $ns1B43 := prof:current-ms()

let $B43invalid :=
    try {
        let $zoneIds :=
            for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants
            where (($x/aqd:Pollutant/aqd:pollutantCode/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20" and $x/aqd:Pollutant/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
                    and ($x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/C6H6-annual"))
            return string($x/../am:inspireId/base:Identifier/base:localId)

        for $y in $docRoot//aqd:AQD_Zone[aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/C6H6-annual"]
        where (not($zoneIds = string($y/am:inspireId/base:Identifier/base:localId)))
        return
            <tr>
                <td title="base:localid">{data($y/am:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:pollutantCode">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20")}</td>
                <td title="aqd:protectionTarget">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B43 := prof:current-ms()

(: B45 :)

let $ns1B45 := prof:current-ms()

let $B45invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone[count(am:geometry/@xlink:href) > 0]
        return
            <tr>
                <td title="base:localId">{string($x/am:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B45 := prof:current-ms()

(: B46 - Where ./aqd:shapefileLink has been used the xlink should return a link to a valid and existing file located in the same cdr envelope as this XML :)

let $ns1B46 := prof:current-ms()

let $B46invalid :=
    try {
        let $aqdShapeFileLink := $docRoot//aqd:AQD_Zone[not(normalize-space(aqd:shapefileLink) = '')]/aqd:shapefileLink

        for $link in $aqdShapeFileLink
        let $correctLink := common:getEnvelopeXML($source_url)
        return
            if (count(doc($correctLink)/envelope/file[replace(@link, "https://", "http://") = replace($link, "https://", "http://")]) = 0) then
                <tr>
                    <td title="aqd:AQD_Zone">{data($link/../am:inspireId/base:Identifier/base:localId)}</td>
                    <td title="aqd:shapefileLink">{data($link)}</td>
                </tr>
            else
                ()
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

let $ns2B46 := prof:current-ms()

(: B47 :)


let $ns1B47 := prof:current-ms()

let $B47invalid :=
    try {
        let $all := dd:getValidConcepts($vocabulary:ZONETYPE_VOCABULARY || "rdf")
        (:for $x in $docRoot//aqd:aqdZoneType:)
        for $x in $docRoot/gml:FeatureCollection/gml:featureMember/aqd:AQD_Zone/aqd:aqdZoneType/@xlink:href
        where not($x = $all)
        return
            <tr>
                <td title="aqd:AQD_Zone">{string($x/../../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="aqd:aqdZoneType">{data($x)}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B47 := prof:current-ms()

(: B48 - Date :)

let $ns1B48 := prof:current-ms()

let $B48invalid :=
    try {
         for $timePeriod in $docRoot//aqd:AQD_Zone/am:designationPeriod/gml:TimePeriod
         (: XQ does not support 24h that is supported by xsml schema validation :)
         (: TODO: comment by sofiageo - the above statement is not true, fix this if necessary :)
         let $beginDate := $timePeriod/gml:beginPosition
         let $endDate := $timePeriod/gml:endPosition
         where (not($endDate = "") and not($endDate castable as xs:dateTime)) or (not($beginDate = "") and not($beginDate castable as xs:dateTime)) 
         return
             <tr>
                <td title="aqd:AQD_Zone">{string($timePeriod/../../am:inspireId/base:Identifier/base:localId)}</td>
                <td title="gml:beginPosition">{$beginDate}</td>
                <td title="gml:endPosition">{$endDate}</td>
            </tr>
    } catch * {
        <tr class="{$errors:FAILED}">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


let $ns2B48 := prof:current-ms()

  let $ms2Total := prof:current-ms()

return
    <table class="maintable hover">
    <table>
        {html:build2("NS", $labels:NAMESPACES, $labels:NAMESPACES_SHORT, $NSinvalid, "All values are valid", "record", $errors:NS)}
        {html:build2("VOCAB", $labels:VOCAB, $labels:VOCAB_SHORT, $VOCABinvalid, "All values are valid", "record", $errors:VOCAB)}
         {html:buildNoCount2Sparql("VOCABALL", $labels:VOCABALL, $labels:VOCABALL_SHORT, $VOCABALLinvalid, "All values are valid", "Invalid urls found", $errors:VOCABALL)}
        {html:build3("B0", $labels:B0, $labels:B0_SHORT, $B0table, string($B0table/td), errors:getMaxError($B0table))}
        {html:buildCountRow0("B01", $labels:B01, $labels:B01_SHORT, $countZones, "", "record", $errors:B01)}
        {html:buildSimpleSparql("B02", $labels:B02, $labels:B02_SHORT, $B02table, "", "record", $B02errorLevel)}
        {html:build0("B03", $labels:B03, $labels:B03_SHORT, $B03table, "record")}
        {html:build0("B04", $labels:B04, $labels:B04_SHORT, $B04table, "record")} 
        {html:build2("B05a", $labels:B05a, $labels:B05a_SHORT, $B05ainvalid, "All values are valid", " invalid value", $errors:B05a)}
        {html:build2("B05b", $labels:B05b, $labels:B05b_SHORT, $B05binvalid, "All values are valid", " invalid value", $errors:B05b)}
        {html:buildResultsSimpleRow("B06a", $labels:B06a, $labels:B06a_SHORT, $countZonesWithAmGeometry, $errors:B06a)}
        {html:buildResultsSimpleRow("B06b", $labels:B06b, $labels:B06b_SHORT, $countZonesWithLAU, $errors:B06b)}
        {html:build0("B07", $labels:B07, $labels:B07_SHORT, $B07table, "record")}
        {html:build2("B08", $labels:B08, $labels:B08_SHORT, $B08table, "", "record", errors:getMaxError($B08table))}
        {html:build2("B09", $labels:B09, $labels:B09_SHORT, $B09invalid, "All values are valid", "record", $errors:B09)}
        {html:buildUnique("B10", $labels:B10, $labels:B10_SHORT, $B10table, "record", $errors:B10)}
        {html:build2("B10.1", $labels:B10.1, $labels:B10.1_SHORT, $B10.1invalid, "All values are valid", " invalid namespaces", $errors:B10.1)}
        {html:build2("B11", $labels:B11, $labels:B11_SHORT, $B11table, "", "record", $B11errorLevel)}
        {html:build2("B12", $labels:B12, $labels:B12_SHORT, $B12table, "All values are valid", "record", $B12errorLevel)}
        {html:build2("B12b", $labels:B12b, $labels:B12b_SHORT, $B12btable, "All values are valid", "record", $B12berrorLevel)}
        {html:build2Sparql("B13", $labels:B13, $labels:B13_SHORT, $B13invalid, "All values are valid", " invalid value", $errors:B13)}
        {html:build2("B18", $labels:B18, $labels:B18_SHORT, $B18invalid, "All text are valid"," invalid attribute", $errors:B18)}
        {html:build2("B20", $labels:B20, $labels:B20_SHORT, $B20invalid, "All srsName attributes are valid"," invalid attribute", $errors:B20)}
        {html:build2("B21", $labels:B21, $labels:B21_SHORT, $B21invalid, "All srsDimension attributes resolve to ""2""", " invalid attribute", $errors:B21)}
        {html:build2("B22", $labels:B22, $labels:B22_SHORT, $B22invalid, "All values are valid", " invalid attribute", $errors:B22)}
        {html:build2("B23", $labels:B23, $labels:B23_SHORT, $B23invalid, $B23message, " invalid attribute", $errors:B23)}
        {html:build2("B24", $labels:B24, $labels:B24_SHORT, $B24invalid, "All zoneType attributes are valid", " invalid attribute", $errors:B24)}
        {html:build2("B25", $labels:B25, $labels:B25_SHORT, $B25invalid, "All positions are valid", " invalid position", $errors:B25)}
        {html:build2("B28", $labels:B28, $labels:B28_SHORT, $B28invalid, "All LifespanVersion values are valid", " invalid value", $errors:B28)}
        {html:build2("B30", $labels:B30, $labels:B30_SHORT, $B30invalid, "All values are valid", " invalid value", $errors:B30)}
        {html:build2("B31", $labels:B31, $labels:B31_SHORT, $B31invalid, "All values are valid", " invalid value", $errors:B31)}
        {html:build2("B32", $labels:B32, $labels:B32_SHORT, $B32invalid, "All values are valid", " invalid value", $errors:B32)}
        {html:build2("B33", $labels:B33, $labels:B33_SHORT, $B33invalid, "All values are valid", " invalid value", $errors:B33)}
        {html:build2("B34", $labels:B34, $labels:B34_SHORT, $B34invalid, "All values are valid", " invalid value", $errors:B34)}
        {html:buildCountRow("B35", $labels:B35, $labels:B35_SHORT, $countB35duplicates, (), (), ())}
        {html:buildConcatRow($dublicateAmNamespaceAndaqdZoneCodeIds, "Duplicate base:namespace:aqd:zoneCode - ")}
        {html:build2("B36", $labels:B36, $labels:B36_SHORT, $B36invalid, "All values are valid", " invalid value", $errors:B36)}
        {html:build2("B37", $labels:B37, $labels:B37_SHORT, $B37invalid, "All values are valid", " invalid value", $errors:B37)}
        {html:build2("B38", $labels:B38, $labels:B38_SHORT, $B38invalid, "All values are valid", " invalid value", $errors:B38)}
        {html:build2("B39a", $labels:B39a, <span>{$labels:B39a_SHORT} - {html:buildInfoTable("B39a", $B39aItemsList)}</span>, $B39ainvalid, "All values are valid", " invalid value", $errors:B39a)}
        {html:build2("B39b", $labels:B39b, $labels:B39b_SHORT, $B39binvalid, "All values are valid", " missing value", $errors:B39b)}
        {html:build2("B39c", $labels:B39c, $labels:B39c_SHORT, $B39cinvalid, "All values are valid", " invalid value", $errors:B39c)}
        {html:build2("B40", $labels:B40, $labels:B40_SHORT, $B40invalid, "All values are valid", "record", $errors:B40)}
        {html:build2("B41", $labels:B41, $labels:B41_SHORT, $B41invalid, "All values are valid", " invalid value", $errors:B41)}
        {html:build2("B42", $labels:B42, $labels:B42_SHORT, $B42invalid, "All values are valid", " crucial invalid value", $errors:B42)}
        {html:build2("B43", $labels:B43, $labels:B43_SHORT, $B43invalid, "All values are valid", " crucial invalid value", $errors:B43)}
        {html:build2("B45", $labels:B45, $labels:B45_SHORT, $B45invalid, "All values are valid", " invalid value", $errors:B45)}
        {html:build2("B46", $labels:B46, $labels:B46_SHORT, $B46invalid, "All values are valid", " invalid value", $errors:B46)}
        {html:build2("B47", $labels:B47, $labels:B47_SHORT, $B47invalid, "All values are valid", "invalid value", $errors:B47)}
        {html:build2("B48", $labels:B48, $labels:B48_SHORT, $B48invalid, "All values are valid", "invalid value", $errors:B48)}
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
       {common:runtime("NS", $ns1NS, $ns2NS)}
       {common:runtime("VOCAB", $ns1DVOCAB, $ns1DVOCAB)}
       {common:runtime("VOCABALL", $ms1CVOCABALL, $ms2CVOCABALL)}
       {common:runtime("B0",  $ns1B0, $ns2B0)}
       {common:runtime("B01", $ns1B01, $ns2B01)}
       {common:runtime("B02", $ns1B02, $ns2B02)}
       {common:runtime("B03", $ns1B03, $ns2B03)}
       {common:runtime("B04",  $ns1B04, $ns2B04)}
       {common:runtime("B05a", $ns1B05a, $ns2B05a)}
       {common:runtime("B05b", $ns1B05b, $ns2B05b)}
       {common:runtime("B06a",  $ns1B06a, $ns2B06a)}
       {common:runtime("B06b",  $ns1B06b, $ns2B06b)}
       {common:runtime("B07",  $ns1B07, $ns2B07)}
       {common:runtime("B08",  $ns1B08, $ns2B08)}
       {common:runtime("B09",  $ns1B09, $ns2B09)}
       {common:runtime("B10",  $ns1B10, $ns2B10)}
       {common:runtime("B10.1",  $ns1B10.1, $ns2B10.1)}
       {common:runtime("B11",  $ns1B11, $ns2B11)}
       {common:runtime("B12",  $ns1B12, $ns2B12)}
       {common:runtime("B12b",  $ns1B12b, $ns2B12b)}
       {common:runtime("B13",  $ns1B13, $ns2B13)}
       {common:runtime("B18",  $ns1B18, $ns2B18)}
       {common:runtime("B20", $ns1B20, $ns2B20)}
       {common:runtime("B21",  $ns1B21, $ns2B21)}
       {common:runtime("B22",  $ns1B22, $ns2B22)}
       {common:runtime("B23",  $ns1B23, $ns2B23)}
       {common:runtime("B24",  $ns1B24, $ns2B24)}
       {common:runtime("B25",  $ns1B25, $ns2B25)}
       {common:runtime("B28",  $ns1B28, $ns2B28)}
       {common:runtime("B30",  $ns1B30, $ns2B30)}
       {common:runtime("B31",  $ns1B31, $ns2B31)}
       {common:runtime("B32",  $ns1B32, $ns2B32)}
       {common:runtime("B33",  $ns1B33, $ns2B33)}
       {common:runtime("B34",  $ns1B34, $ns2B34)}
       {common:runtime("B35",  $ns1B35, $ns2B35)}
       {common:runtime("B36",  $ns1B36, $ns2B36)}
       {common:runtime("B37",  $ns1B37, $ns2B37)}
       {common:runtime("B38",  $ns1B38, $ns2B38)}
       {common:runtime("B39a",  $ns1B39a, $ns2B39a)}
       {common:runtime("B39b",  $ns1B39b, $ns2B39b)}
       {common:runtime("B39c",  $ns1B39c, $ns2B39c)}
       {common:runtime("B40",  $ns1B40, $ns2B40)}
       {common:runtime("B41",  $ns1B41, $ns2B41)}
       {common:runtime("B42",  $ns1B42, $ns2B42)}
       {common:runtime("B43",  $ns1B43, $ns2B43)}
       {common:runtime("B45",  $ns1B45, $ns2B45)}
       {common:runtime("B46",  $ns1B46, $ns2B46)}
       {common:runtime("B47",  $ns1B47, $ns2B47)}
       {common:runtime("B48",  $ns1B48, $ns2B48)}
       
       {common:runtime("Total time",  $ms1Total, $ms2Total)}
    </table>
    </table>
};
declare function dataflowB:proceed($source_url as xs:string, $countryCode as xs:string) as element(div) {

let $countZones := count(doc($source_url)//aqd:AQD_Zone)
let $result := if ($countZones > 0) then dataflowB:checkReport($source_url, $countryCode) else ()
let $meta := map:merge((
    map:entry("count", $countZones),
    map:entry("header", "Check air quality zones"),
    map:entry("dataflow", "Dataflow B"),
    map:entry("zeroCount", <p>No aqd:AQD_Zone elements found in this XML.</p>),
    map:entry("report", <p>This check evaluated the delivery by executing tier-1 tests on air quality zones data in Dataflow B as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>)
))
return
    html:buildResultDiv($meta, $result)
};
