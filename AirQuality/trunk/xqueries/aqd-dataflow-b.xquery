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

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowB";
import module namespace common = "aqd-common" at "aqd-common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace query = "aqd-query" at "aqd-query.xquery";
import module namespace errors = "aqd-errors" at "aqd-errors.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";

declare namespace aqd = "http://dd.eionet.europa.eu/schemaset/id2011850eu-1.0";
declare namespace gml = "http://www.opengis.net/gml/3.2";
declare namespace am = "http://inspire.ec.europa.eu/schemas/am/3.0";
declare namespace ef = "http://inspire.ec.europa.eu/schemas/ef/3.0";
declare namespace base = "http://inspire.ec.europa.eu/schemas/base/3.3";
declare namespace gn = "urn:x-inspire:specification:gmlas:GeographicalNames:3.0";
declare namespace base2 = "http://inspire.ec.europa.eu/schemas/base2/1.0";
declare namespace sparql = "http://www.w3.org/2005/sparql-results#";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace ompr = "http://inspire.ec.europa.eu/schemas/ompr/2.0";

declare variable $xmlconv:AQ_MANAGEMENET_ZONE := "http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone";
declare variable $xmlconv:invalidCount as xs:integer := 0;
declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");
declare variable $xmlconv:OBLIGATIONS as xs:string* := ("http://rod.eionet.europa.eu/obligations/670", "http://rod.eionet.europa.eu/obligations/693");

(: Rule implementations :)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)
let $bdir := if (contains($source_url, "b_preliminary")) then "b_preliminary/" else "b/"
let $reportingYear := common:getReportingYear($docRoot)
let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesNamespaces := distinct-values($docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/base:namespace)

(: Generic variables :)
let $knownZones := distinct-values(data(sparqlx:executeSimpleSparqlQuery(query:getAllZoneIds($nameSpaces))//sparql:binding[@name = 'inspireLabel']/sparql:literal))

(: B0 :)
let $B0invalid :=
    try {
        if (query:deliveryExists($xmlconv:OBLIGATIONS, $countryCode, $bdir, $reportingYear)) then
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

(: B1 :)
let $countZones := count($docRoot//aqd:AQD_Zone)

(: B2 :)
let $B2table :=
    try {
        for $zone in $docRoot//aqd:AQD_Zone
            let $id := $zone/am:inspireId/base:Identifier/base:namespace || "/" || $zone/am:inspireId/base:Identifier/base:localId
        where ($id = "/" or not($knownZones = $id))
        return
            <tr>
                <td title="base:localId">{$zone/am:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:predecessor">{if (empty($zone/aqd:predecessor)) then "not specified" else $zone/aqd:predecessor/aqd:AQD_Zone/@gml:id}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $B2errorLevel :=
    if (count($B2table) = $countZones) then
        $errors:ERROR
    else
        $errors:INFO

(: B3 :)
let $B3table :=
    try {
        for $zone in $docRoot//aqd:AQD_Zone
        let $id := $zone/am:inspireId/base:Identifier/base:namespace || "/" || $zone/am:inspireId/base:Identifier/base:localId
        where ($knownZones = $id)
        return
            <tr>
                <td title="base:localId">{$zone/am:inspireId/base:Identifier/base:localId/string()}</td>
                <td title="aqd:predecessor">{if (empty($zone/aqd:predecessor)) then "not specified" else $zone/aqd:predecessor/aqd:AQD_Zone/@gml:id}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B4 :)
let $B4table :=
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B6a :)
let $countZonesWithAmGeometry :=
    try {
        count($docRoot//aqd:AQD_Zone/am:geometry)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B6b :)
let $countZonesWithLAU :=
    try {
        count($docRoot//aqd:AQD_Zone[not(empty(aqd:LAU)) or not(empty(aqd:shapefileLink))])
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B7 - Compile & feedback a list of aqd:aqdZoneType, aqd:pollutantCode, aqd:protectionTarget combinations in the delivery :)
let $B7table :=
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B8 :)
(:TODO: ADD TRY CATCH :)
let $gmlIds := $docRoot//aqd:AQD_Zone/lower-case(normalize-space(@gml:id))
let $duplicateGmlIds := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/@gml:id
    where string-length(normalize-space($id)) > 0 and count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
    return
        $id
    )
let $amInspireIds := for $id in $docRoot//aqd:AQD_Zone/am:inspireId
                     return
                        lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateamInspireIds := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/am:inspireId
    let $key :=
        concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]")
    where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($amInspireIds, lower-case($key))) > 1
    return
        $key
    )


let $aqdInspireIds := for $id in $docRoot//aqd:AQD_Zone/aqd:inspireId
                     return
                        lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateaqdInspireIds := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/aqd:inspireId
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
let $B8invalid := $countGmlIdDuplicates + $countamInspireIdDuplicates + $countaqdInspireIdDuplicates

(: B9 The base:localId needs to be unique within namespace.  :)
let $duplicateAmInspireIds := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier
        where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
        return
            concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
)
let $B9invalid :=
    try {
        let $amInspireIds := $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
                lower-case(normalize-space(base:localId)))
        let $countAmInspireIdDuplicates := count($duplicateAmInspireIds)
        return $countAmInspireIdDuplicates
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B10 :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B10.1 :)
let $B10.1invalid :=
    try {
        common:checkNamespaces($source_url)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B13 :)
let $B13invalid :=
    try {
        let $langCodes := distinct-values(data(sparqlx:executeSimpleSparqlQuery(query:getLangCodesSparql())//sparql:binding[@name='code']/sparql:literal))

        return distinct-values($docRoot//aqd:AQD_Zone/am:name/gn:GeographicalName[string-length(normalize-space(gn:language)) > 0 and
                    empty(
                    index-of($langCodes, normalize-space(gn:language)))
                    and empty(index-of($langCodes, normalize-space(gn:language)))]/gn:language)
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
let $langSkippedMsg := ""
    (: TODO: FIX SKIPPED MESSAGE :)
    (: let $langSkippedMsg := "The test was skipped - ISO 639-3 and ISO 639-5 language codes are not available in Content Registry." :)


(: B18 :)
let $B18invalid :=
    try {
        $docRoot//aqd:AQD_Zone[string-length(am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)=0]/@gml:id
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B20 :)
let $B20invalid :=
    try {
        let $validSrsNames := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4326", "urn:ogc:def:crs:EPSG::4258")
        let $invalidPolygonName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Polygon) > 0 and not(am:geometry/gml:Polygon/@srsName = $validSrsNames)]/@gml:id)
        let $invalidPointName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Point) > 0 and not(am:geometry/gml:Point/@srsName = $validSrsNames)]/@gml:id)
        let $invalidMultiPointName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:MultiPoint) > 0 and not(am:geometry/gml:MultiPoint/@srsName = $validSrsNames)]/@gml:id)
        let $invalidMultiSurfaceName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:MultiSurface) > 0 and not(am:geometry/gml:MultiSurface/@srsName = $validSrsNames)]/@gml:id)
        let $invalidGridName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Grid) > 0 and not(am:geometry/gml:Grid/@srsName = $validSrsNames)]/@gml:id)
        let $invalidRectifiedGridName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:RectifiedGrid) > 0 and not(am:geometry/gml:RectifiedGrid/@srsName = $validSrsNames)]/@gml:id)
        return distinct-values(($invalidPolygonName, $invalidMultiPointName, $invalidPointName, $invalidMultiSurfaceName, $invalidGridName, $invalidRectifiedGridName))
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B21 :)
let $B21invalid  :=
    try {
        distinct-values($docRoot//aqd:AQD_Zone/am:geometry/gml:MultiSurface/gml:surfaceMember/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList[@srsDimension != "2"]/
        concat(../../../../../@gml:id, ": srsDimension=", @srsDimension))
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B22 - generalized by Hermann :)
let $B22invalid :=
    try {
        for $posList in $docRoot//gml:posList
        let $posListCount := count(fn:tokenize(normalize-space($posList), "\s+")) mod 2
        return if (not(empty($posList)) and $posListCount gt 0) then $posList/ancestor::*[@gml:id][1]/@gml:id else ()
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B23 - generalized by Hermann
 : In Europe, lat values tend to be bigger than lon values. We use this observation as a poor farmer's son test to check that in a coordinate value pair,
 : the lat value comes first, as defined in the GML schema
:)
let $B23invalid :=
    try {
        for $latLong in $docRoot//gml:posList
        let $latlongToken := fn:tokenize(normalize-space($latLong), "\s+")
        let $lat := number($latlongToken[1])
        let $long := number($latlongToken[2])
        return if ($long > $lat) then concat($latLong/ancestor::*[@gml:id][1]/@gml:id, ":first vertex:", $lat, " ", $long) else ()
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B24 :)
(: ./am:zoneType value shall resolve to http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone :)
 let $B24invalid  :=
     try {
         distinct-values($docRoot//aqd:AQD_Zone/am:zoneType[@xlink:href != $xmlconv:AQ_MANAGEMENET_ZONE]/
         concat(../@gml:id, ": zoneType=", @xlink:href))
     } catch * {
         <tr status="failed">
             <td title="Error code">{$err:code}</td>
             <td title="Error description">{$err:description}</td>
         </tr>
     }

(: B25 :)
(: ./am:designationPeriod/gml:TimePeriod/gml:beginPosition shall be less than ./am:designationPeri/gml:TimePeriod/gml:endPosition. :)
 let $B25invalid  :=
     try {
         for $timePeriod in $docRoot//aqd:AQD_Zone/am:designationPeriod/gml:TimePeriod
         (: XQ does not support 24h that is supported by xsml schema validation :)
         (: TODO: comment by sofiageo - the above statement is not true, fix this if necessary :)
         let $beginDate := substring(normalize-space($timePeriod/gml:beginPosition), 1, 10)
         let $endDate := substring(normalize-space($timePeriod/gml:endPosition), 1, 10)
         let $beginPosition := if ($beginDate castable as xs:date) then xs:date($beginDate) else ()
         let $endPosition := if ($endDate castable as xs:date) then xs:date($endDate) else ()
         return
         (:  concat($timePeriod/../../@gml:id, ": gml:beginPosition=", $beginPosition, ": gml:endPosition=", $endPosition) :)

             if (not(empty($beginPosition)) and not(empty($endPosition)) and $beginPosition > $endPosition) then
                 concat($timePeriod/../../@gml:id, ": gml:beginPosition=", $beginPosition, ": gml:endPosition=", $endPosition)
             else
                 ()
     } catch * {
         <tr status="failed">
             <td title="Error code">{$err:code}</td>
             <td title="Error description">{$err:description}</td>
         </tr>
     }

(: B28 - ./am:beginLifespanVersion shall be a valid historical date for the start of the version of the zone in extended ISO format.
If an am:endLifespanVersion exists its value shall be greater than the am:beginLifespanVersion :)
let $B28invalid :=
    try {
        for $rec in $docRoot//aqd:AQD_Zone
        let $beginDate := substring(normalize-space($rec/am:beginLifespanVersion), 1, 10)
        let $endDate := substring(normalize-space($rec/am:endLifespanVersion), 1, 10)
        let $beginPeriod := if ($beginDate castable as xs:date) then xs:date($beginDate) else ()
        let $endPeriod := if ($endDate castable as xs:date) then xs:date($endDate) else ()

        return
            if ((not(empty($beginPeriod)) and not(empty($endPeriod)) and $beginPeriod > $endPeriod) or empty($beginPeriod)) then
                concat($rec/@gml:id, ": am:beginLifespanVersion=", data($rec/am:beginLifespanVersion),
                        if (not(empty($endPeriod))) then concat(": am:endLifespanVersion=", data($rec/am:endLifespanVersion)) else "")
            else
                ()
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B31 :)
let $B31invalid :=
    try {
        distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:name) != "2011/850/EC"]/
        concat(../../@gml:id, ": base2:name=", if (string-length(base2:name) > 20) then concat(substring(base2:name, 1, 20), "...") else base2:name))
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }
(: B32 :)
let $B32invalid :=
    try {
        distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:date) != "2011-12-12"]/
        concat(../../@gml:id, ": base2:date=", if (string-length(base2:date) > 20) then concat(substring(base2:date, 1, 20), "...") else base2:date))
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B33 :)
let $B33invalid :=
    try {
        distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:link) != "http://rod.eionet.europa.eu/instruments/650"]/
        concat(../../@gml:id, ": base2:link=", if (string-length(base2:link) > 40) then concat(substring(base2:link, 1, 40), "...") else base2:link))
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B35 :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B36 :)
let $B36invalid :=
    try {
        distinct-values($docRoot//aqd:AQD_Zone[not(count(aqd:residentPopulation)>0 and aqd:residentPopulation castable as xs:integer and number(aqd:residentPopulation) >= 0)]/
        concat(@gml:id, ": aqd:residentPopulation=", if (string-length(aqd:residentPopulation) = 0) then "missing" else aqd:residentPopulation))
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B37 - ./aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition shall cite the year in which the resident population was estimated in yyyy format :)
let $B37invalid :=
    try {
        for $zone in $docRoot//aqd:AQD_Zone
        return
            if (xmlconv:isInvalidYear(data($zone/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition))) then
                concat($zone/@gml:id, ": gml:timePosition=", data($zone/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition))
            else ()
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B38 :)
let $B38invalid :=
    try {
        distinct-values($docRoot//aqd:AQD_Zone[not(count(aqd:area)>0 and number(aqd:area) and number(aqd:area) > 0)]/
        concat(@gml:id, ": aqd:area=", if (string-length(aqd:area) = 0) then "missing" else aqd:area))
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B39a - Find invalid combinations :)
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
(: B39b - Count combination occurrences  :)
let $B39binvalid :=
    try {
        let $pollutantOccurrences := <results> {
            for $x in $pollutantCombinations//combination
            let $code := concat($pollutantCodeVocabulary, $x/code)
            let $target := concat($pollutantTargetVocabulary, $x/target)
            let $count := count($docRoot//aqd:AQD_Zone/aqd:pollutants/aqd:Pollutant[aqd:pollutantCode/@xlink:href = $code and aqd:protectionTarget/@xlink:href = $target])
            let $warning :=
                if ($count = 0) then
                    if ($countryCode = "gb") then 0 else 1
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B39c - Combination cannot be repeated in individual zone :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B40 - /aqd:timeExtensionExemption attribute must resolve to one of concept within http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/ :)
let $B40invalid :=
    try {
        let $year := xs:integer(substring($docRoot//aqd:AQD_ReportingHeader/aqd:reportingPeriod/gml:TimePeriod/gml:beginPosition, 1, 4))
        let $valid :=
            if ($year > 2015) then
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B41 :)
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
        <tr status="failed">
            <td title="Error code"> {$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B42 :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }


(: B43 :)
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
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B45 :)
let $B45invalid :=
    try {
        for $x in $docRoot//aqd:AQD_Zone[count(am:geometry/@xlink:href) > 0]
        return
            <tr>
                <td title="base:localId">{string($x/am:inspireId/base:Identifier/base:localId)}</td>
            </tr>
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B46 - Where ./aqd:shapefileLink has been used the xlink should return a link to a valid and existing file located in the same cdr envelope as this XML :)
let $B46invalid :=
    try {
        let $aqdShapeFileLink := $docRoot//aqd:AQD_Zone[not(normalize-space(aqd:shapefileLink) = '')]/aqd:shapefileLink

        for $link in $aqdShapeFileLink
        let $correctLink := common:getEnvelopeXML($source_url)
        return
            if (count(doc($correctLink)/envelope/file[replace(@link, "https://", "http://") = replace($link, "https://", "http://")]) = 0) then
                concat($link/../@gml:id, ' ', $link)
            else ()
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

(: B47 :)
let $B47invalid :=
    try {
        xmlconv:checkVocabularyConceptValues($source_url, "", "aqd:AQD_Zone", "aqd:aqdZoneType", $vocabulary:ZONETYPE_VOCABULARY, (), "")
    } catch * {
        <tr status="failed">
            <td title="Error code">{$err:code}</td>
            <td title="Error description">{$err:description}</td>
        </tr>
    }

return
    <table class="maintable hover">
        {html:buildExists("B0", $labels:B0, $labels:B0_SHORT, $B0invalid, "New Delivery", "Updated Delivery", $errors:WARNING)}
        {html:buildCountRow0("B1", $labels:B1, $labels:B1_SHORT, $countZones, "", "record", $errors:INFO)}
        {html:buildSimple("B2", $labels:B2, $labels:B2_SHORT, $B2table, "", "record", $B2errorLevel)}
        {html:build0("B3", $labels:B3, $labels:B3_SHORT, $B3table, "", "", "record")}
        {html:build0("B4", $labels:B4, $labels:B4_SHORT, $B4table, "", string(count($B4table)), "record")}
        {html:buildResultsSimpleRow("B6a", $labels:B6a, $labels:B6a_SHORT, $countZonesWithAmGeometry, $errors:INFO)}
        {html:buildResultsSimpleRow("B6b", $labels:B6b, $labels:B6b_SHORT, $countZonesWithLAU, $errors:INFO )}
        {html:build0("B7", $labels:B7, $labels:B7_SHORT, $B7table, "", string(count($B7table)), "record")}
        {html:buildCountRow("B8", $labels:B8, $labels:B8_SHORT, $B8invalid, (), "duplicate", $errors:WARNING)}
        {html:buildConcatRow($duplicateGmlIds, "aqd:AQD_Zone/@gml:id - ")}
        {html:buildConcatRow($duplicateamInspireIds, "am:inspireId - ")}
        {html:buildConcatRow($duplicateaqdInspireIds, "aqd:inspireId - ")}
        {html:buildCountRow("B9", $labels:B9, $labels:B9_SHORT, $B9invalid, (), (), ())}
        {html:buildConcatRow($duplicateAmInspireIds, "Duplicate base:namespace:base:localId - ")}
        {html:build0("B10", $labels:B10, $labels:B10_SHORT, $B10table, "", string(count($B10table)), "record")}
        {html:buildResultRows_B("B10.1", $labels:B10.1, $labels:B10.1_SHORT, $B10.1invalid, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", $errors:ERROR)}
        {html:buildResultRows_B("B13", $labels:B13, $labels:B13_SHORT, $B13invalid, "/aqd:AQD_Zone/am:name/gn:GeographicalName/gn:language", "All values are valid", " invalid value", $langSkippedMsg,$errors:WARNING)}
        {html:buildResultRows_B("B18", $labels:B18, $labels:B18_SHORT, $B18invalid, "aqd:AQD_Zone/@gml:id","All text are valid"," invalid attribute","", $errors:ERROR)}
        {html:buildResultRows_B("B20", $labels:B20, $labels:B20_SHORT, $B20invalid, "aqd:AQD_Zone/@gml:id","All srsName attributes are valid"," invalid attribute","", $errors:ERROR)}
        {html:buildResultRows_B("B21", $labels:B21, $labels:B21_SHORT, $B21invalid, "aqd:AQD_Zone/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "",$errors:WARNING)}
        {html:buildResultRows_B("B22", $labels:B22, $labels:B22_SHORT, $B22invalid, "gml:Polygon/@gml:id", "All values are valid", " invalid attribute", "",$errors:ERROR)}
        {html:buildResultRows_B("B23", $labels:B23, $labels:B23_SHORT, $B23invalid, "gml:Polygon", "All values are valid", " invalid attribute", "",$errors:ERROR)}
        {html:buildResultRows_B("B24", $labels:B24, $labels:B24_SHORT, $B24invalid, "aqd:AQD_Zone/@gml:id", "All zoneType attributes are valid", " invalid attribute", "",$errors:WARNING)}
        {html:buildResultRows_B("B25", $labels:B25, $labels:B25_SHORT, $B25invalid, "gml:TimePeriod gml:id", "All positions are valid", " invalid position", "",$errors:ERROR)}
        {html:buildResultRows_B("B28", $labels:B28, $labels:B28_SHORT, $B28invalid, "gml:id", "All LifespanVersion values are valid", " invalid value", "",$errors:ERROR)}
        {html:buildResultRows_B("B31", $labels:B31, $labels:B31_SHORT, $B31invalid, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows_B("B32", $labels:B32, $labels:B32_SHORT, $B32invalid, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows_B("B33", $labels:B33, $labels:B33_SHORT, $B33invalid, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildCountRow("B35", $labels:B35, $labels:B35_SHORT, $countB35duplicates, (), (), ())}
        {html:buildConcatRow($dublicateAmNamespaceAndaqdZoneCodeIds, "Duplicate base:namespace:aqd:zoneCode - ")}
        {html:buildResultRows_B("B36", $labels:B36, $labels:B36_SHORT, $B36invalid, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:buildResultRows_B("B37", $labels:B37, $labels:B37_SHORT, $B37invalid, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows_B("B38", $labels:B38, $labels:B38_SHORT, $B38invalid, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:buildResultRows("B39a", $labels:B39a, <span>{$labels:B39a_SHORT} - {html:buildInfoTable("B39a", $B39aItemsList)}</span>, $B39ainvalid, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", $errors:WARNING)}
        {html:buildResultTable("B39b", $labels:B39b, $labels:B39b_SHORT, $B39binvalid, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " missing value", "", $errors:ERROR)}
        {html:buildResultTable("B39c", $labels:B39c, $labels:B39c_SHORT, $B39cinvalid, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:build2("B40", $labels:B40, $labels:B40_SHORT, $B40invalid, "aqd:timeExtensionExemption", "All values are valid", "record", "", $errors:ERROR)}
        {html:buildResultTable("B41", $labels:B41, $labels:B41_SHORT, $B41invalid, "", "All values are valid", " invalid value", "", $errors:ERROR)}
        {html:buildResultTable("B42", $labels:B42, $labels:B42_SHORT, $B42invalid, "", "All values are valid", " crucial invalid value", "", $errors:ERROR)}
        {html:buildResultTable("B43", $labels:B43, $labels:B43_SHORT, $B43invalid, "", "All values are valid", " crucial invalid value", "", $errors:ERROR)}
        {html:buildResultRows("B45", $labels:B45, $labels:B45_SHORT, $B45invalid, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "",$errors:WARNING)}
        {html:buildResultRows_B("B46", $labels:B46, $labels:B46_SHORT, $B46invalid, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", $errors:ERROR)}
        {xmlconv:buildResultRowsWithTotalCount("B47", $labels:B47, $labels:B47_SHORT, $B47invalid, "aqd:reportingMetric", "", "", "")}
    </table>
};

declare function xmlconv:buildResultRowsWithTotalCount($ruleCode as xs:string, $longText, $text, $records as element(tr)*,
        $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg)
as element(tr)*{

    let $countCheckedRecords := count($records)
    let $invalidValues := $records[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:buildResultRows($ruleCode, $longText, $text, $invalidValues, $valueHeading, $validMsg, $invalidMsg, $skippedMsg, $errors:ERROR)
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*, $vocabularyType as xs:string)
as element(tr)*{

    let $sparql :=
        if ($vocabularyType = "collection") then
            query:getCollectionConceptUrlSparql($vocabularyUrl)
        else
            query:getConceptUrlSparqlB($vocabularyUrl)
    let $crConcepts := sparqlx:executeSimpleSparqlQuery($sparql)

    let $allRecords :=
    if ($parentObject != "") then
        doc($source_url)//descendant::*[name()=$parentObject]/descendant::*[name()=$featureType]
    else
        doc($source_url)//descendant::*[name()=$featureType]

    for $rec in $allRecords
    for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href
    let $conceptUrl := normalize-space($conceptUrl)

    where string-length($conceptUrl) > 0

    return
        <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) and xmlconv:isValidLimitedValue($conceptUrl, $vocabularyUrl, $limitedIds) }">
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="{ $element }" style="color:red">{$conceptUrl}</td>
        </tr>

};


declare function xmlconv:isValidLimitedValue($conceptUrl as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*) as xs:boolean {
    let $limitedUrls :=
        for $id in $limitedIds
        return concat($vocabularyUrl, $id)
    return
        empty($limitedIds) or not(empty(index-of($limitedUrls, $conceptUrl)))
};


declare function xmlconv:isMatchingVocabCode($crConcepts as element(sparql:results), $concept as xs:string)
as xs:boolean
{
    count($crConcepts//sparql:result/sparql:binding[@name="concepturl" and sparql:uri=$concept]) > 0
};

declare function xmlconv:isInvalidYear($value as xs:string?) {
    let $year := if (empty($value)) then ()
    else
        if ($value castable as xs:integer) then xs:integer($value) else ()

    return
        if ((empty($year) and empty($value)) or (not(empty($year)) and $year > 1800 and $year < 9999)) then fn:false() else fn:true()

};
(:
 : ======================================================================
 : Main function
 : ======================================================================
 :)

declare function xmlconv:proceed($source_url as xs:string, $countryCode as xs:string) {

let $countZones := count(doc($source_url)//aqd:AQD_Zone)
let $result := if ($countZones > 0) then xmlconv:checkReport($source_url, $countryCode) else ()

return
    <div>
        <h2>Check air quality zones - Dataflow B</h2>
        {
        if ( $countZones = 0) then
            <p>No aqd:Zone elements found from this XML.</p>
        else
            <div>
                {
                    if ($result//div/@class = $errors:ERROR) then
                        <p class="{$errors:ERROR}" style="color:red"><strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[@class=$errors:ERROR], ',')}</strong></p>
                    else
                        <p>This XML file passed all crucial checks.</p>
                }
                {
                    if ($result//div/@class = 'warning') then
                        <p class="warning" style="color:orange"><strong>This XML file generated warnings during the following check(s): {string-join($result//div[@class = 'warning'], ',')}</strong></p>
                    else
                        ()
                }
                <p>This check evaluated the delivery by executing tier-1 tests on air quality zones data in Dataflow B as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
                <div><a id='legendLink' href="javascript: showLegend()" style="padding-left:10px;">How to read the test results?</a></div>
                <fieldset style="font-size: 90%; display:none" id="legend">
                    <legend>How to read the test results</legend>
                    All test results are labeled with coloured bullets. The number in the bullet reffers to the rule code. The background colour of the bullets means:
                    <ul style="list-style-type: none;">
                        <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Blue', $errors:INFO)}</div> - the data confirms to the rule, but additional feedback could be provided in QA result.</li>
                        <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Red', $errors:ERROR)}</div> - the crucial check did NOT pass and errenous records found from the delivery.</li>
                        <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Orange', $errors:WARNING)}</div> - the non-crucial check did NOT pass.</li>
                        <li><div style="width:50px; display:inline-block;margin-left:10px">{html:getBullet('Grey', $errors:SKIPPED)}</div> - the check was skipped due to no relevant values found to check.</li>
                    </ul>
                    <p>Click on the "{$labels:SHOWRECORDS}" link to see more details about the test result.</p>
                </fieldset>
                <h3>Test results</h3>
                {$result}
            </div>
        }
    </div>

};