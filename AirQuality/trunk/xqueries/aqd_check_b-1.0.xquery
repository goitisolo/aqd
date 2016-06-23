xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     20 June 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script implements dataflow B tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Enriko Käsper
 : @author George Sofianos
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowB";
import module namespace common = "aqd-common" at "aqd_check_common.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
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
declare namespace ompr = "http://inspire.ec.europa.eu/schemas/ompr/2.0";

declare variable $xmlconv:AQ_MANAGEMENET_ZONE := "http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone";
declare variable $xmlconv:invalidCount as xs:integer := 0;
declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL","AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

(: Rule implementations :)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {

let $envelopeUrl := common:getEnvelopeXML($source_url)
let $docRoot := doc($source_url)

(: B1 :)
let $countZones := count($docRoot//aqd:AQD_Zone)

(: B2 :)
let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := query:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(sparqlx:executeSimpleSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
for $zone in $docRoot//gml:featureMember/aqd:AQD_Zone
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))
    return $zone

let $tblB2 :=
    for $rec in $unknownZones
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="aqd:predecessor">{if (empty($rec/aqd:predecessor)) then "not specified" else data($rec/aqd:predecessor/aqd:AQD_Zone/@gml:id)}</td>
        </tr>

(: B3 :)
let $countZonesWithAmGeometry := count($docRoot//aqd:AQD_Zone/am:geometry)
(: B4 :)
let $countZonesWithLAU := count($docRoot//aqd:AQD_Zone[not(empty(aqd:LAU)) or not(empty(aqd:shapefileLink))])

(: B6 :)

(:
let $allB6Combinations :=
for $aqdZone in $docRoot//aqd:AQD_Zone
return concat(data($aqdZone/@gml:id), "#", $aqdZone/am:inspireId, "#", $aqdZone/aqd:inspireId, "#", $aqdZone/ef:name, "#", $aqdZone/ompr:name )
let $allB6Combinations := fn:distinct-values($allB6Combinations)
:)

let $allB6Combinations := $docRoot//aqd:AQD_Zone

let $tblB6 :=
    for $rec in $allB6Combinations
    (:
    let $zoneType := substring-before($rec, "#")
    let $tmpStr := substring-after($rec, concat($zoneType, "#"))
    let $inspireId := substring-before($tmpStr, "#")
    let $tmpInspireId := substring-after($tmpStr, concat($inspireId, "#"))
    let $aqdInspireId := substring-before($tmpInspireId, "#")
    let $tmpEfName := substring-after($tmpInspireId, concat($aqdInspireId, "#"))
    let $efName := substring-before($tmpEfName, "#")
    let $omprName := substring-after($tmpEfName,concat($efName,"#"))
    :)
    return
        <tr>
            <td title="gml:id">{data($rec/@gml:id)}</td>
            <td title="namespace/localId">{concat(data($rec/am:inspireId/base:Identifier/base:namespace),'/', data($rec/am:inspireId/base:Identifier/base:localId))}</td>
            <td title="zoneName">{data($rec/am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)}</td>
            <td title="zoneCode">{data($rec/aqd:zoneCode)}</td>
        </tr>

(: B7 :)
(: Compile & feedback a list of aqd:aqdZoneType, aqd:pollutantCode, aqd:protectionTarget combinations in the delivery :)
let $allB7Combinations :=
    for $pollutant in $docRoot//aqd:Pollutant
    return concat(data($pollutant/../../aqd:aqdZoneType/@xlink:href), "#", data($pollutant/aqd:pollutantCode/@xlink:href), "#",data($pollutant/aqd:protectionTarget/@xlink:href))

let $allB7Combinations := fn:distinct-values($allB7Combinations)
let $tblB7 :=
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

(: B8 :)
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
let $countB8duplicates := $countGmlIdDuplicates + $countamInspireIdDuplicates + $countaqdInspireIdDuplicates

(: B9 The base:localId needs to be unique within namespace.  :)
let $amInspireIds := $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
    lower-case(normalize-space(base:localId)))
let $duplicateAmInspireIds := distinct-values(
    for $identifier in $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier
    where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
        concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
    return
        concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
    )

(: FIXME  :)
(: wrong rule here.
The element that "shall be an unique code for network starting with ISO2-country code" is aqd:zoneCode
with the exception of UnitedKingdom that might use UK instead of GB

let $invalidIsoAmInspireIds := distinct-values(
    for $id in $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId
    where string-length(normalize-space($id)) > 0 and (string-length(normalize-space($id)) < 2 or
        count(index-of($xmlconv:ISO2_CODES , substring(upper-case(normalize-space($id)), 1, 2))) = 0)
    return
        $id
    )
:)
let $countAmInspireIdDuplicates := count($duplicateAmInspireIds)
let $countB9duplicates := $countAmInspireIdDuplicates

(: B10 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier/base:namespace)
let  $tblB10 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Zone/am:inspireId/base:Identifier[base:namespace = $id]/base:localId
 return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: B10.1 :)
let $invalidNamespaces := common:checkNamespaces($source_url) 

(: B11 :)


(: B13 :)
let $langCodeSparql := query:getLangCodesSparql()
let $isLangCodesAvailable := string-length($langCodeSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($langCodeSparql, "xml"))
let $langCodes := if ($isLangCodesAvailable) then distinct-values(data(sparqlx:executeSimpleSparqlQuery($langCodeSparql)//sparql:binding[@name='code']/sparql:literal)) else ()
let $isLangCodesAvailable := count($langCodes) > 0

let $invalidLangCode := if ($isLangCodesAvailable) then
        distinct-values($docRoot//aqd:AQD_Zone/am:name/gn:GeographicalName[string-length(normalize-space(gn:language)) > 0 and
            empty(
            index-of($langCodes, normalize-space(gn:language)))
            and empty(index-of($langCodes, normalize-space(gn:language)))]/gn:language)
    else
        ()

let $langSkippedMsg :=
    if (not($isLangCodesAvailable)) then "The test was skipped - ISO 639-3 and ISO 639-5 language codes are not available in Content Registry."
    else ""

(: B14 :)
(:
let $unknownNativeness := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:nativeness[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
:)
(: B15 :)
(:
let $unknownNameStatus := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:nameStatus[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
:)
(: B16 :)
(:
let $unknownSourceOfName := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:sourceOfName[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
:)
(: B17 :)
(:
let $unknownPronunciation  := distinct-values($docRoot//aqd:AQD_Zone[count(am:name/gn:GeographicalName/gn:pronunciation[@xsi:nil="true" and @nilReason="unknown"])>0]/@gml:id)
:)
(: B18 :)
let $invalidgnSpellingOfName := $docRoot//aqd:AQD_Zone[string-length(am:name/gn:GeographicalName/gn:spelling/gn:SpellingOfName/gn:text)=0]/@gml:id

(: B20 :)

let $validSrsNames := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4326", "urn:ogc:def:crs:EPSG::4258") 
let $invalidPolygonName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Polygon) >0 and not(am:geometry/gml:Polygon/@srsName = $validSrsNames)]/@gml:id)
let $invalidPointName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Point) >0 and not(am:geometry/gml:Point/@srsName = $validSrsNames)]/@gml:id)
let $invalidMultiPointName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:MultiPoint) >0 and not(am:geometry/gml:MultiPoint/@srsName = $validSrsNames)]/@gml:id)
let $invalidMultiSurfaceName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:MultiSurface) >0 and not(am:geometry/gml:MultiSurface/@srsName = $validSrsNames)]/@gml:id)
let $invalidGridName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:Grid) >0 and not(am:geometry/gml:Grid/@srsName = $validSrsNames)]/@gml:id)
let $invalidRectifiedGridName := distinct-values($docRoot//aqd:AQD_Zone[count(am:geometry/gml:RectifiedGrid) >0 and not(am:geometry/gml:RectifiedGrid/@srsName = $validSrsNames)]/@gml:id)
let $invalidGmlIdsB20 := distinct-values(($invalidPolygonName, $invalidMultiPointName, $invalidPointName, $invalidMultiSurfaceName, $invalidGridName, $invalidRectifiedGridName))

(: B21 :)
let $invalidPosListDimension  := distinct-values($docRoot//aqd:AQD_Zone/am:geometry/gml:MultiSurface/gml:surfaceMember/gml:Polygon/gml:exterior/gml:LinearRing/gml:posList[@srsDimension != "2"]/
            concat(../../../../../@gml:id, ": srsDimension=", @srsDimension))

(: B22 - generalized by Hermann :)

let $invalidPosListCount :=
for $posList in  $docRoot//gml:posList
let $posListCount := count(fn:tokenize(normalize-space($posList),"\s+")) mod 2
return if (not(empty($posList)) and $posListCount gt 0) then $posList/ancestor::*[@gml:id][1]/@gml:id else ()

(: B23 - generalized by Hermann
 : In Europe, lat values tend to be bigger than lon values. We use this observation as a poor farmer's son test to check that in a coordinate value pair,
 : the lat value comes first, as defined in the GML schema
:)

let $invalidLatLong :=
for $latLong in $docRoot//gml:posList
let $latlongToken := fn:tokenize(normalize-space($latLong),"\s+")
let $lat := number($latlongToken[1])
let $long := number($latlongToken[2])
return if ($long > $lat) then concat($latLong/ancestor::*[@gml:id][1]/@gml:id, ":first vertex:", $lat, " ", $long) else ()

(: B24 :)
(: ./am:zoneType value shall resolve to http://inspire.ec.europa.eu/codeList/ZoneTypeCode/airQualityManagementZone :)
 let $invalidManagementZones  := distinct-values($docRoot//aqd:AQD_Zone/am:zoneType[@xlink:href != $xmlconv:AQ_MANAGEMENET_ZONE]/
            concat(../@gml:id, ": zoneType=", @xlink:href))

(: B25 :)
(: ./am:designationPeriod/gml:TimePeriod/gml:beginPosition shall be less than ./am:designationPeri/gml:TimePeriod/gml:endPosition. :)
 let $invalidPosition  :=
    for $timePeriod in $docRoot//aqd:AQD_Zone/am:designationPeriod/gml:TimePeriod
        (: XQ does not support 24h that is supported by xsml schema validation :)
        let $beginDate := substring(normalize-space($timePeriod/gml:beginPosition),1,10)
        let $endDate := substring(normalize-space($timePeriod/gml:endPosition),1,10)
        let $beginPosition := if ($beginDate castable as xs:date) then xs:date($beginDate) else ()
        let $endPosition := if ($endDate castable as xs:date) then xs:date($endDate) else ()
        return
            (:  concat($timePeriod/../../@gml:id, ": gml:beginPosition=", $beginPosition, ": gml:endPosition=", $endPosition) :)

        if (not(empty($beginPosition)) and not(empty($endPosition)) and $beginPosition > $endPosition) then
            concat($timePeriod/../../@gml:id, ": gml:beginPosition=", $beginPosition, ": gml:endPosition=", $endPosition)
        else
            ()


 (: B25 :)

            (:) let $allAmDesignationPeriods :=
 for $designationPeriods in $docRoot//aqd:AQD_Zone/am:designationPeriod
 where $designationPeriods/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)="unknown"]
 return
       <tr>
         <td title="aqd:AQD_Zone">{data($designationPeriods/../@gml:id)}</td>
         <td title="gml:TimePeriod">{data($designationPeriods/gml:TimePeriod/@gml:id)}</td>
         <td title="gml:beginPosition">{$designationPeriods/gml:TimePeriod/gml:beginPosition}</td>
         <td title="gml:endPosition">{$designationPeriods/gml:TimePeriod/gml:endPosition}</td>
     </tr> :)


(: B28 :)
(: ./am:beginLifespanVersion shall be a valid historical date for the start of the version of the zone in extended ISO format.
If an am:endLifespanVersion exists its value shall be greater than the am:beginLifespanVersion :)
let $invalidLifespanVer  :=
    for $rec in $docRoot//aqd:AQD_Zone

        let $beginDate := substring(normalize-space($rec/am:beginLifespanVersion),1,10)
        let $endDate := substring(normalize-space($rec/am:endLifespanVersion),1,10)
        let $beginPeriod := if ($beginDate castable as xs:date) then xs:date($beginDate) else ()
        let $endPeriod := if ($endDate castable as xs:date) then xs:date($endDate) else ()

        return
        if ((not(empty($beginPeriod)) and not(empty($endPeriod)) and $beginPeriod > $endPeriod) or empty($beginPeriod)) then
            concat($rec/@gml:id, ": am:beginLifespanVersion=", data($rec/am:beginLifespanVersion),
            if (not(empty($endPeriod))) then concat(": am:endLifespanVersion=", data($rec/am:endLifespanVersion)) else "")
        else
            ()
(: B29 :)
(: ./am:beginLifespanVersion shall be LESS THAN OR EQUAL TO ./am:designationPeriod/gml:TimePeriod/gml:endPosition
./am:beginLifespanVersion shall be GREATER THAN OR EQUAL TO
./am:designationPeriod/gml:TimePeriod/gml:beginPosition
:)
(:
let $invalidLifespanVerB29  :=
    for $rec in $docRoot//aqd:AQD_Zone
        let $beginPeriodDate := substring-before(normalize-space($rec/am:beginLifespanVersion), 'T')
        let $beginPeriod := if ($beginPeriodDate castable as xs:date) then xs:date($beginPeriodDate) else ()
        let $beginPosition := if (normalize-space($rec/am:designationPeriod/gml:TimePeriod/gml:beginPosition) castable as xs:date) then xs:date($rec/am:designationPeriod/gml:TimePeriod/gml:beginPosition) else ()
        let $endPosition := if (normalize-space($rec/am:designationPeriod/gml:TimePeriod/gml:endPosition)  castable as xs:date) then xs:date($rec/am:designationPeriod/gml:TimePeriod/gml:endPosition) else ()

        return
        if (
        (not(empty($beginPeriod)) and not(empty($endPosition)) and $beginPeriod > $endPosition) or
         (not(empty($beginPeriod)) and not(empty($beginPosition)) and $beginPeriod < $beginPosition)
        ) then
            concat($rec/@gml:id, ": am:beginLifespanVersion=", data($rec/am:beginLifespanVersion),
                " gml:beginPosition=", $beginPosition," gml:endPosition=", $endPosition)
        else
            ()
:)

(: B31 :)
let $invalidLegalBasisName  := distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:name) != "2011/850/EC"]/
            concat(../../@gml:id, ": base2:name=", if (string-length(base2:name) > 20) then concat(substring(base2:name, 1, 20), "...") else base2:name))
(: B32 :)
let $invalidLegalBasisDate  := distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:date) != "2011-12-12"]/
            concat(../../@gml:id, ": base2:date=", if (string-length(base2:date) > 20) then concat(substring(base2:date, 1, 20), "...") else base2:date))
(: B33 :)
let $invalidLegalBasisLink  := distinct-values($docRoot//aqd:AQD_Zone/am:legalBasis/base2:LegislationCitation[normalize-space(base2:link) != "http://rod.eionet.europa.eu/instruments/650"]/
            concat(../../@gml:id, ": base2:link=", if (string-length(base2:link) > 40) then concat(substring(base2:link, 1, 40), "...") else base2:link))

(: B35 :)
let $amNamespaceAndaqdZoneCodeIds := $docRoot//aqd:AQD_Zone/concat(am:inspireId/base:Identifier/lower-case(normalize-space(base:namespace)), '##', lower-case(normalize-space(aqd:zoneCode)))

let $dublicateAmNamespaceAndaqdZoneCodeIds := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Zone
where string-length(normalize-space($identifier/am:inspireId/base:Identifier/base:namespace)) > 0 and count(index-of($amNamespaceAndaqdZoneCodeIds,
        concat($identifier/am:inspireId/base:Identifier/lower-case(normalize-space(base:namespace)), '##', $identifier/lower-case(normalize-space(aqd:zoneCode))))) > 1
return
    concat(normalize-space($identifier/am:inspireId/base:Identifier/base:namespace), ':', normalize-space($identifier/aqd:zoneCode))
)

let $countAmNamespaceAndaqdZoneCodeDuplicates := count($dublicateAmNamespaceAndaqdZoneCodeIds)
let $countB35duplicates := $countAmNamespaceAndaqdZoneCodeDuplicates

(: B36 :)
let $invalidResidentPopulation  := distinct-values($docRoot//aqd:AQD_Zone[not(count(aqd:residentPopulation)>0 and aqd:residentPopulation castable as xs:integer and number(aqd:residentPopulation) >= 0)]/
            concat(@gml:id, ": aqd:residentPopulation=", if (string-length(aqd:residentPopulation) = 0) then "missing" else aqd:residentPopulation))

(: B37 :)
(: ./aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition shall cite the year in which the resident population was estimated in yyyy format :)
let $invalidPopulationYear :=
for $zone in $docRoot//aqd:AQD_Zone
return
    if (xmlconv:isInvalidYear(data($zone/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition))) then
        concat($zone/@gml:id, ": gml:timePosition=",data($zone/aqd:residentPopulationYear/gml:TimeInstant/gml:timePosition))
    else ()

(: B38 :)
let $invalidArea  := distinct-values($docRoot//aqd:AQD_Zone[not(count(aqd:area)>0 and number(aqd:area) and number(aqd:area) > 0)]/
            concat(@gml:id, ": aqd:area=", if (string-length(aqd:area) = 0) then "missing" else aqd:area))

(:~
    B39a - Find invalid combinations
 :)
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


let $invalidPollutantCombinations :=
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
let $invalidPollutantOccurences :=
    for $x in $pollutantOccurrences//result[warning = 1]
    return
        <tr>
            <td title="Pollutant">{data($x/code)}</td>
            <td title="Protection target">{data($x/target)}</td>
        </tr>

(: B39c - Combination cannot be repeated in individual zone :)
let $invalidPollutantRepeated :=
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

(: B40 - :)
let $tempStr := xmlconv:checkVocabularyConceptValues($source_url, "", "aqd:AQD_Zone", "aqd:timeExtensionExemption", "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/")
let $invalidTimeExtensionExemption := $tempStr

(: B41 :)
let $zoneIds :=
for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants
where ($x/aqd:Pollutant/aqd:pollutantCode/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8" and $x/aqd:Pollutant/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
       and ($x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-1h"
        or $x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-annual")
return
    data($x/../@gml:id)


let $invalidPollutansB41 :=
    for $y in $docRoot//aqd:AQD_Zone[aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-1h"
            or aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/NO2-annual"]
    where empty(index-of($zoneIds,$y/@gml:id))
return
        <tr>
            <td title="gml:id">{data($y/@gml:id)}</td>
            <td title="aqd:pollutantCode">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/8")}</td>
            <td title="aqd:protectionTarget">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")}</td>
        </tr>

(: B42 :)
let $zoneIds :=
    for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants
    where ($x/aqd:Pollutant/aqd:pollutantCode/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5" and $x/aqd:Pollutant/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
            and ($x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-24h"
                    or $x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-annual")
    return $x/../@gml:id

let $aqdInvalidPollutansB42 :=
    for $y in $docRoot//aqd:AQD_Zone[aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-24h"
            or aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/PM10-annual"]
    where empty(index-of($zoneIds,$y/@gml:id))
    return
        <tr>
            <td title="gml:id">{data($y/@gml:id)}</td>
            <td title="aqd:pollutantCode">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/5")}</td>
            <td title="aqd:protectionTarget">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")}</td>
        </tr>


(: B43 :)
let $zoneIds :=
    for $x in $docRoot//aqd:AQD_Zone/aqd:pollutants
    where (($x/aqd:Pollutant/aqd:pollutantCode/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20" and $x/aqd:Pollutant/aqd:protectionTarget/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")
            and ($x/../aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/C6H6-annual"))
    return $x/../@gml:id

let $aqdInvalidPollutansBenzene :=
    for $y in $docRoot//aqd:AQD_Zone[aqd:timeExtensionExemption/fn:normalize-space(@xlink:href) = "http://dd.eionet.europa.eu/vocabulary/aq/timeextensiontypes/C6H6-annual"]
    where empty(index-of($zoneIds,$y/@gml:id))
    return
      <tr>
            <td title="gml:id">{data($y/@gml:id)}</td>
            <td title="aqd:pollutantCode">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/pollutant/20")}</td>
            <td title="aqd:protectionTarget">{common:checkLink("http://dd.eionet.europa.eu/vocabulary/aq/protectiontarget/H")}</td>
        </tr>

 (: B44 :)

(:
let $lau2Sparql := if (fn:string-length($countryCode) = 2) then xmlconv:getLau2Sparql($countryCode) else ""
let $isLau2CodesAvailable := string-length($lau2Sparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($lau2Sparql, "xml"))
let $lau2Codes := if ($isLau2CodesAvailable) then distinct-values(data(sparqlx:executeSimpleSparqlQuery($lau2Sparql)//sparql:binding[@name='concepturl']/sparql:uri)) else ()
let $isLau2CodesAvailable := count($lau2Codes) > 0

let $lau1Sparql := if (fn:string-length($countryCode) = 2) then xmlconv:getLau1Sparql($countryCode) else ""
let $isLau1CodesAvailable := string-length($lau1Sparql) > 0 and doc-available(xmlconv:getSparqlEndpointUrl($lau1Sparql, "xml"))
let $lau1Codes := if ($isLau1CodesAvailable) then distinct-values(data(sparqlx:executeSimpleSparqlQuery($lau1Sparql)//sparql:binding[@name='concepturl']/sparql:uri)) else ()
let $isLau1CodesAvailable := count($lau1Codes) > 0

let $nutsSparql := if (fn:string-length($countryCode) = 2) then xmlconv:getNutsSparql($countryCode) else ""
let $isNutsCodesAvailable := doc-available(xmlconv:getSparqlEndpointUrl($nutsSparql, "xml"))
let $nutsCodes := if ($isNutsCodesAvailable) then  distinct-values(data(sparqlx:executeSimpleSparqlQuery($nutsSparql)//sparql:binding[@name='concepturl']/sparql:uri)) else ()
let $isNutsAvailable := count($nutsSparql) > 0

let $invalidLau := if ($isLau2CodesAvailable and $isNutsAvailable and $isLau1CodesAvailable) then
        distinct-values($docRoot//aqd:AQD_Zone/aqd:LAU[string-length(normalize-space(@xlink:href)) > 0 and
            empty(index-of($lau2Codes, normalize-space(@xlink:href))) and empty(index-of($nutsCodes, normalize-space(@xlink:href))) and empty(index-of($lau1Codes, normalize-space(@xlink:href)))]/@xlink:href)
    else
        ()
let $lauSkippedMsg := if (fn:string-length($countryCode) != 2) then "The test was skipped - reporting country code not found."
    else if (not($isLau2CodesAvailable)) then "The test was skipped - LAU2 concepts are not available in CR."
    else if (not($isNutsAvailable)) then "The test was skipped - NUTS concepts are not available in CR."
    else if (not($isLau1CodesAvailable)) then "The test skipped - LAU1 concepts are not available in CR"
    else ""
:)

(: B45 :)

let $amGeometry := $docRoot//aqd:AQD_Zone[count(am:geometry/@xlink:href)>0]/@gml:id
let $invalidGeometry :=
for $x in $amGeometry
    where (empty($amGeometry)=false())
return $x

(: B46 - Where ./aqd:shapefileLink has been used the xlink should return a link to a valid and existing file located in the same cdr envelope as this XML :)

let $aqdShapeFileLink := $docRoot//aqd:AQD_Zone[not(normalize-space(aqd:shapefileLink) = '')]/aqd:shapefileLink

let $invalidLink :=
for $link in $aqdShapeFileLink    
    let $correctLink := common:getEnvelopeXML($source_url)
    return
    if (count(doc($correctLink)/envelope/file[replace(@link, "https://", "http://")=replace($link,"https://", "http://")]) = 0) then
        concat($link/../@gml:id, ' ', $link)
    else ()


(: B47 :)
let $invalidZoneType := xmlconv:checkVocabularyConceptValues($source_url, "", "aqd:AQD_Zone", "aqd:aqdZoneType", $vocabulary:ZONETYPE_VOCABULARY)

return
    <table class="hover">
        {html:buildResultsSimpleRow("B1", $labels:B1, $labels:B1_SHORT, $countZones, "info")}
        {html:buildResultRows("B2", $labels:B2, $labels:B2_SHORT, (), (), "", string(count($tblB2)), "", "", "error", $tblB2)}
        {html:buildResultsSimpleRow("B3", $labels:B3, $labels:B3_SHORT, $countZonesWithAmGeometry, "info")}
        {html:buildResultsSimpleRow("B4", $labels:B4, $labels:B4_SHORT, $countZonesWithLAU, "info" )}
        {html:buildResultRows("B6", $labels:B6, $labels:B6_SHORT, (), (), "", string(count($tblB6)), "", "", "error", $tblB6)}
        {html:buildResultRows("B7", $labels:B7, $labels:B7_SHORT, (), (), "", string(count($tblB7)), "", "", "error", $tblB7)}
        {html:buildCountRow("B8", $countB8duplicates, $labels:B8_SHORT, (), " duplicate", $errors:WARNING)}
        {html:buildConcatRow($duplicateGmlIds, "aqd:AQD_Zone/@gml:id - ")}
        {html:buildConcatRow($duplicateamInspireIds, "am:inspireId - ")}
        {html:buildConcatRow($duplicateaqdInspireIds, "aqd:inspireId - ")}
        {html:buildCountRow("B9", $countB9duplicates, $labels:B9_SHORT, (), (), ())}
        {html:buildConcatRow($duplicateAmInspireIds, "Duplicate base:namespace:base:localId - ")}
        {html:buildResultRows("B10", $labels:B10, $labels:B10_SHORT, (), (), "", string(count($tblB10)), "", "", "error", $tblB10)}
        {html:buildResultRows_B("B10.1", $labels:B10.1, $labels:B10.1_SHORT, $invalidNamespaces, "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", "error")}
        {html:buildResultRows_B("B13", $labels:B13, $labels:B13_SHORT, $invalidLangCode, "/aqd:AQD_Zone/am:name/gn:GeographicalName/gn:language", "All values are valid", " invalid value", $langSkippedMsg,"warning")}
        {html:buildResultRows_B("B18", $labels:B18, $labels:B18_SHORT, $invalidgnSpellingOfName, "aqd:AQD_Zone/@gml:id","All text are valid"," invalid attribute","", "error")}
        {html:buildResultRows_B("B20", $labels:B20, $labels:B20_SHORT, $invalidGmlIdsB20, "aqd:AQD_Zone/@gml:id","All srsName attributes are valid"," invalid attribute","", "error")}
        {html:buildResultRows_B("B21", $labels:B21, $labels:B21_SHORT, $invalidPosListDimension, "aqd:AQD_Zone/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "","warning")}
        {html:buildResultRows_B("B22", $labels:B22, $labels:B22_SHORT, $invalidPosListCount, "gml:Polygon/@gml:id", "All values are valid", " invalid attribute", "","error")}
        {html:buildResultRows_B("B23", $labels:B23, $labels:B23_SHORT, $invalidLatLong, "gml:Polygon", "All values are valid", " invalid attribute", "","error")}
        {html:buildResultRows_B("B24", $labels:B24, $labels:B24_SHORT, $invalidManagementZones, "aqd:AQD_Zone/@gml:id", "All zoneType attributes are valid", " invalid attribute", "","warning")}
        {html:buildResultRows_B("B25", $labels:B25, $labels:B25_SHORT, $invalidPosition, "gml:TimePeriod gml:id", "All positions are valid", " invalid position", "","error")}
        {html:buildResultRows_B("B28", $labels:B28, $labels:B28_SHORT, $invalidLifespanVer, "gml:id", "All LifespanVersion values are valid", " invalid value", "","error")}
        {html:buildResultRows_B("B31", $labels:B31, $labels:B31_SHORT, $invalidLegalBasisName, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "","warning")}
        {html:buildResultRows_B("B32", $labels:B32, $labels:B32_SHORT, $invalidLegalBasisDate, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "","warning")}
        {html:buildResultRows_B("B33", $labels:B33, $labels:B33_SHORT, $invalidLegalBasisLink, "aqd:AQD_Zone/@gml:id", "All values are valid", " invalid value", "","warning")}
        {html:buildCountRow("B35", $countB35duplicates, $labels:B35_SHORT, (), (), ())}
        {html:buildConcatRow($dublicateAmNamespaceAndaqdZoneCodeIds, "Duplicate base:namespace:aqd:zoneCode - ")}
        {html:buildResultRows_B("B36", $labels:B36, $labels:B36_SHORT, $invalidResidentPopulation, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", "error")}
        {html:buildResultRows_B("B37", $labels:B37, $labels:B37_SHORT, $invalidPopulationYear, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "","warning")}
        {html:buildResultRows_B("B38", $labels:B38, $labels:B38_SHORT, $invalidArea, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", "error")}
        {html:buildResultRows("B39a", $labels:B39a, <span>{$labels:B39a_SHORT} - {html:buildInfoTable("B39a", $B39aItemsList)}</span>, (), (), "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", "error", $invalidPollutantCombinations)}
        {html:buildResultTable("B39b", $labels:B39b, $labels:B39b_SHORT, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " missing value", "", "error", $invalidPollutantOccurences)}
        {html:buildResultTable("B39c", $labels:B39c, $labels:B39c_SHORT, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", "error", $invalidPollutantRepeated)}
        {xmlconv:buildResultRowsWithTotalCount("B40", $labels:B40, $labels:B40_SHORT ,(), (), "aqd:timeExtensionExemption", "", "", "", $invalidTimeExtensionExemption)}
        {html:buildResultTable("B41", $labels:B41, $labels:B41_SHORT, (), "All values are valid", " invalid value", "", "error", $invalidPollutansB41)}
        {html:buildResultTable("B42", $labels:B42, $labels:B42_SHORT, (), "All values are valid", " crucial invalid value", "", "error", $aqdInvalidPollutansB42)}
        {html:buildResultTable("B43", $labels:B43, $labels:B43_SHORT, (), "All values are valid", " crucial invalid value", "", "error", $aqdInvalidPollutansBenzene)}
        {html:buildResultRows_B("B45", $labels:B45, $labels:B45_SHORT, $invalidGeometry, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "","warning")}
        {html:buildResultRows_B("B46", $labels:B46, $labels:B46_SHORT, $invalidLink, "aqd:AQD_Zone/am:inspireId/base:Identifier/base:localId", "All values are valid", " invalid value", "", "error")}
        {xmlconv:buildResultRowsWithTotalCount("B47", $labels:B47, $labels:B47_SHORT, (), (), "aqd:reportingMetric", "", "", "", $invalidZoneType)}
    </table>
};

declare function xmlconv:buildResultRowsWithTotalCount($ruleCode as xs:string, $longText, $text, $invalidStrValues as xs:string*, $invalidValues as element()*,
    $valueHeading as xs:string, $validMsg as xs:string, $invalidMsg as xs:string, $skippedMsg, $recordDetails as element(tr)*)
as element(tr)*{

    let $countCheckedRecords := count($recordDetails)
    let $invalidValues := $recordDetails[./@isvalid = "false"]

    let $skippedMsg := if ($countCheckedRecords = 0) then "No values found to check" else ""
    let $invalidMsg := if (count($invalidValues) > 0) then concat(" invalid value", substring("s ", number(not(count($invalidValues) > 1)) * 2), " found out of ", $countCheckedRecords, " checked") else ""
    let $validMsg := if (count($invalidValues) = 0) then concat("Checked ", $countCheckedRecords, " value", substring("s", number(not($countCheckedRecords > 1)) * 2), ", all valid") else ""

    return
        html:buildResultRows($ruleCode, $longText, $text, $invalidStrValues, $invalidValues, $valueHeading, $validMsg, $invalidMsg, $skippedMsg, "error",())
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $parentObject as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $limitedIds as xs:string*)
as element(tr)*{
    xmlconv:checkVocabularyConceptValues($source_url, $parentObject, $featureType, $element, $vocabularyUrl, $limitedIds, "")
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $parentObject, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string)
as element(tr)*{
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

declare function xmlconv:getConceptUrlSparql($scheme as xs:string)
as xs:string
{
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl ?label
    WHERE {
      ?concepturl skos:inScheme <", $scheme, ">;
                  skos:prefLabel ?label
    }")
};
declare function xmlconv:getCollectionConceptUrlSparql($collection as xs:string)
as xs:string
{
    concat("PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
    SELECT ?concepturl
    WHERE {
        GRAPH <", $collection, "> {
            <", $collection, "> skos:member ?concepturl .
            ?concepturl a skos:Concept
        }
    }")
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
                <p>This check evaluated the delivery by executing tier-1 tests on air quality zones data in Dataflow B as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
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