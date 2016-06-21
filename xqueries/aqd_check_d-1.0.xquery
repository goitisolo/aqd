xquery version "1.0" encoding "UTF-8";
(:
 : Module Name: Implementing Decision 2011/850/EU: AQ info exchange & reporting (Library module)
 :
 : Version:     $Id$
 : Created:     13 September 2013
 : Copyright:   European Environment Agency
 :)
(:~
 : XQuery script implements dataflow C tier-1 checks as documented in http://taskman.eionet.europa.eu/documents/3 .
 :
 : @author Rait Väli and Enriko Käsper
 : small modification added by Jaume Targa (ETC/ACM) to align with QA document
 :
 :Quality Assurance and Control rules version: 4.0
 :)

module namespace xmlconv = "http://converters.eionet.europa.eu/dataflowD";
import module namespace common = "aqd-common" at "aqd_check_common.xquery";
import module namespace sparqlx = "aqd-sparql" at "aqd-sparql.xquery";
import module namespace labels = "aqd-labels" at "aqd-labels.xquery";
import module namespace html = "aqd-html" at "aqd-html.xquery";
import module namespace vocabulary = "aqd-vocabulary" at "aqd-vocabulary.xquery";
import module namespace dd = "aqd-dd" at "aqd-dd.xquery";
import module namespace geox = "aqd-geo" at "aqd-geo.xquery";

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

declare variable $xmlconv:ISO2_CODES as xs:string* := ("AL", "AD", "AT","BA","BE","BG","CH","CY","CZ","DE","DK","DZ","EE","EG","ES","FI",
    "FR","GB","GR","HR","HU","IE","IL","IS","IT","JO","LB","LI","LT","LU","LV","MA","ME","MK","MT","NL","NO","PL","PS","PT",
     "RO","RS","SE","SI","SK","TN","TR","XK","UK");

declare variable $xmlconv:FEATURE_TYPES := ("aqd:AQD_Network", "aqd:AQD_Station", "aqd:AQD_SamplingPointProcess", "aqd:AQD_Sample",
"aqd:AQD_RepresentativeArea", "aqd:AQD_SamplingPoint");

declare function xmlconv:getErrorTD($errValue,  $element as xs:string, $showMissing as xs:boolean)
as element(td)
{
    let $val := if ($showMissing and string-length($errValue)=0) then "-blank-" else $errValue
    return
        <td title="{ $element }" style="color:red">{
            $val
        }
        </td>
};


declare function xmlconv:getSamplingPointAssessment($inspireId as xs:string, $inspireNamespace as xs:string)
as xs:string
{
    concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
           PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
           PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>
           PREFIX aq: <http://reference.eionet.europa.eu/aq/ontology/>

        SELECT *
            where {
                    ?assessmentRegime a aqd:AQD_AssessmentRegime;
                    aqd:assessmentMethods  ?assessmentMethods .
                    ?assessmentMethods aqd:samplingPointAssessmentMetadata ?samplingPointAssessment .
                    ?samplingPointAssessment aq:inspireId ?inspireId.
                    ?samplingPointAssessment aq:inspireNamespace ?inspireNamespace.
                    FILTER(?inspireId='",$inspireId,"' and ?inspireNamespace='",$inspireNamespace,"')
                  }")
};
declare function xmlconv:getSamplingPointZone($zoneId as xs:string)
as xs:string
{
    concat("PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
            PREFIX cr: <http://cr.eionet.europa.eu/ontologies/contreg.rdf#>
            PREFIX aqd: <http://rdfdata.eionet.europa.eu/airquality/ontology/>

            SELECT *
            WHERE {
                    ?zone a aqd:AQD_Zone;
                    aqd:inspireId ?inspireId .
                    ?inspireId rdfs:label ?inspireLabel
                    FILTER(?inspireLabel = '",$zoneId,"')
                  }")
};

declare function xmlconv:getZonesSparql($nameSpaces as xs:string*)
as xs:string
{
    let $nameSpacesStr :=
        for $nameSpace in $nameSpaces
        return concat("""", $nameSpace, """")

    let $nameSpacesStr :=
        fn:string-join($nameSpacesStr, ",")

    return     concat(
            "PREFIX aqr: <http://reference.eionet.europa.eu/aq/ontology/>

            SELECT ?inspireid
            FROM <http://rdfdata.eionet.europa.eu/airquality/zones.ttl>
            WHERE {
              ?zoneuri a aqr:Zone ;
                        aqr:inspireNamespace ?namespace;
                         aqr:inspireId ?inspireid .
            filter (?namespace in (", $nameSpacesStr,  "))
    } order by ?zoneuri"
    )
};

(: Rule implementations :)
declare function xmlconv:checkReport($source_url as xs:string, $countryCode as xs:string) as element(table) {
let $docRoot := doc($source_url)
(: D1 :)
let $countFeatureTypes :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        count(doc($source_url)//gml:featureMember/descendant::*[name()=$featureType])
let $tblAllFeatureTypes :=
    for $featureType at $pos in $xmlconv:FEATURE_TYPES
    where $countFeatureTypes[$pos] > 0
    return
        <tr>
            <td title="Feature type">{ $featureType }</td>
            <td title="Total number">{$countFeatureTypes[$pos]}</td>
        </tr>

(: D2 :)
let $D2Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(sparqlx:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
    for $zone in $D2Combinations
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))
    return $zone

let $tblD2 :=
    for $rec in $unknownZones
    return
        $rec/@gml:id

(: D3 :)
let $D3Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $nameSpaces := distinct-values($docRoot//base:namespace)
let $zonesSparql := xmlconv:getZonesSparql($nameSpaces)
let $isZonesAvailable := string-length($zonesSparql) > 0 and doc-available(sparqlx:getSparqlEndpointUrl($zonesSparql, "xml"))
let $knownZones := if ($isZonesAvailable ) then distinct-values(data(sparqlx:executeSparqlQuery($zonesSparql)//sparql:binding[@name='inspireid']/sparql:literal)) else ()
let $unknownZones :=
    for $zone in $D3Combinations
    let $id := if (empty($zone/@gml:id)) then "" else data($zone/@gml:id)
    where empty(index-of($knownZones, $id))=false()
    return $zone

let $tblD3 :=
    for $rec in $unknownZones
    return
        $rec/@gml:id

(: D4 :)
let $D4Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $allD4Combinations :=
    for $aqdModel in $D4Combinations
    return concat(data($aqdModel/@gml:id), "#", $aqdModel/ef:inspireId/base:Identifier/base:localId, "#", $aqdModel/ompr:inspireId/base:Identifier/base:localId, "#", $aqdModel/ef:name, "#", $aqdModel/ompr:name )

let $allD4Combinations := fn:distinct-values($allD4Combinations)
let $tblD4 :=
    for $rec in $allD4Combinations
    let $modelType := substring-before($rec, "#")
    let $tmpStr := substring-after($rec, concat($modelType, "#"))
    let $inspireId := substring-before($tmpStr, "#")
    let $tmpInspireId := substring-after($tmpStr, concat($inspireId, "#"))
    let $aqdInspireId := substring-before($tmpInspireId, "#")
    let $tmpEfName := substring-after($tmpInspireId, concat($aqdInspireId, "#"))
    let $efName := substring-before($tmpEfName, "#")
    let $omprName := substring-after($tmpEfName,concat($efName,"#"))
    return
        <tr>
            <td title="gml:id">{common:checkLink($modelType)}</td>
            <td title="ef:inspireId/localId">{common:checkLink($inspireId)}</td>
            <td title="ompr:inspireId/localId">{common:checkLink($aqdInspireId)}</td>
            <td title="ef:name">{common:checkLink($efName)}</td>
            <td title="ompr:name">{common:checkLink($omprName)}</td>
        </tr>

(: D5 :)
let $D5Combinations :=
    for $featureType in $xmlconv:FEATURE_TYPES
    return
        doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

let $gmlIds := $D5Combinations/lower-case(normalize-space(@gml:id))
let $duplicateGmlIds := distinct-values(
        for $id in $D5Combinations/@gml:id
        where string-length(normalize-space($id)) > 0 and count(index-of($gmlIds, lower-case(normalize-space($id)))) > 1
        return
            $id
)
let $efInspireIds := for $id in $D5Combinations/ef:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateefInspireIds := distinct-values(
        for $id in $D5Combinations/ef:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($efInspireIds, lower-case($key))) > 1
        return
            $key
)


let $aqdInspireIds := for $id in $D5Combinations/aqd:inspireId
return
    lower-case(concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
            ", ", normalize-space($id/base:Identifier/base:versionId), "]"))
let $duplicateaqdInspireIds := distinct-values(
        for $id in $D5Combinations/aqd:inspireId
        let $key :=
            concat("[", normalize-space($id/base:Identifier/base:localId), ", ", normalize-space($id/base:Identifier/base:namespace),
                    ", ", normalize-space($id/base:Identifier/base:versionId), "]")
        where  string-length(normalize-space($id/base:Identifier/base:localId)) > 0 and count(index-of($aqdInspireIds, lower-case($key))) > 1
        return
            $key
)


let $countGmlIdDuplicates := count($duplicateGmlIds)
let $countefInspireIdDuplicates := count($duplicateefInspireIds)
let $countaqdInspireIdDuplicates := count($duplicateaqdInspireIds)
let $countD5duplicates := $countGmlIdDuplicates + $countefInspireIdDuplicates + $countaqdInspireIdDuplicates

(: D6 Done by Rait ./ef:inspireId/base:Identifier/base:localId shall be an unique code for AQD_network and unique within the namespace.:)
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
let $countD6duplicates := $countAmInspireIdDuplicates

(: D7 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier/base:namespace)
let  $tblD7 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Network/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
	    <td title="feature">Network(s)</td>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: D7.1 :)
let $invalidNamespaces := common:checkNamespaces($source_url)
(: D8 :)
let $invalidNetworkMedia := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Network", "ef:mediaMonitored", $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI)
(: D9 :)
let $invalidOrganisationalLevel := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Network", "ef:organisationLevel", $vocabulary:ORGANISATIONAL_LEVEL_VOCABULARY)
(: D10 :)
let $invalidNetworkType := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Network", "aqd:networkType", $vocabulary:NETWORK_TYPE_VOCABULARY)

(: D11 :)
let $invalidAQDNetworkBeginPosition := distinct-values($docRoot//aqd:AQD_Network/aqd:operationActivityPeriod/gml:TimePeriod[((gml:beginPosition>=gml:endPosition) and (gml:endPosition!=""))]/../../@gml:id)

(: D12 aqd:AQD_Network/ef:name shall return a string :)
let $D12invalid :=
    for $x in //aqd:AQD_Network[string(ef:name) = ""]
    return
        <tr>
            <td title="base:localId">{$x/ef:inspireId/base:Identifier/string(base:localId)}</td>
        </tr>

(: D14 Done by Rait  :)
let $invalidTimeZone := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Network", "aqd:aggregationTimeZone", $vocabulary:TIMEZONE_VOCABULARY)
(: D15 Done by Rait :)
let $amInspireIds := $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/concat(lower-case(normalize-space(base:namespace)), '##',
        lower-case(normalize-space(base:localId)))

let $duplicateEUStationCode := distinct-values(
        for $identifier in $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier
        where string-length(normalize-space($identifier/base:localId)) > 0 and count(index-of($amInspireIds,
                concat(lower-case(normalize-space($identifier/base:namespace)), '##', lower-case(normalize-space($identifier/base:localId))))) > 1
        return
            concat(normalize-space($identifier/base:namespace), ':', normalize-space($identifier/base:localId))
)
let $countAmInspireIdDuplicates := count($duplicateEUStationCode)
let $countD15duplicates := $countAmInspireIdDuplicates


(:
let $localSamplingPointIds := $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId
let $invalidDuplicateSamplingPointIds :=
    for $idCode in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId
    where
        count(index-of($localSamplingPointIds, normalize-space($idCode))) > 1
    return
        <tr>
            <td title="aqd:AQD_SamplingPoint">{data($idCode/../../../@gml:id)}</td>
            <td title="base:localId">{data($idCode)}</td>
        </tr>
:)


(: D16 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier/base:namespace)

let  $tblD16 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Station/ef:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
	        <td title="feature">Station(s)</td>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>
(: D17 aqd:AQD_Station/ef:name shall return a string :)
let $D17invalid :=
    for $x in //aqd:AQD_Station[ef:name = ""]
    return
    <tr>
        <td title="base:localId">{$x/ef:inspireId/base:Identifier/string(base:localId)}</td>
    </tr>
(: D18 Cross-check with AQD_Network (aqd:AQD_Station/ef:belongsTo shall resolve to a traversable local of global URI to ../AQD_Network) :)
let $aqdNetworkLocal :=
    for $z in $docRoot//aqd:AQD_Network
    let $id := concat(data($z/ef:inspireId/base:Identifier/base:namespace), '/',
            data($z/ef:inspireId/base:Identifier/base:localId))
    return $id

let $D18invalid :=
    for $x in $docRoot//aqd:AQD_Station[not(ef:belongsTo/@xlink:href = $aqdNetworkLocal)]
    return
        <tr>
            <td title="aqd:AQD_Station">{$x/ef:inspireId/base:Identifier/string(base:localId)}</td>
            <td title="ef:belongsTo">{$x/ef:belongsTo/string(@xlink:href)}</td>
        </tr>

(: D19 :)
(:
let $sparqlD19 := xmlconv:getConceptUrlSparql($xmlconv:MEDIA_VALUE_VOCABULARY_BASE_URI)
let $crConcepts := xmlconv:executeSparqlEndpoint($sparqlD19)//sparql:result

let $invalidStationMedia :=
for $rec in doc($source_url)//gml:featureMember/descendant::*[name()='aqd:AQD_Station']

    for $conceptUrl in $rec/child::*[name() = 'ef:mediaMonitored']/@xlink:href
        let $conceptUrl := normalize-space(data($conceptUrl))
        where string-length($conceptUrl) > 0 and not(xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl))

                return
                    <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                        <td title="Feature type">aqd:AQD_Station</td>
                        <td title="gml:id">{data($rec/@gml:id)}</td>
                        <td title="ef:name">{data($rec/ef:name)}</td>
                        <td title="ef:mediaMonitored" style="color:red">{$conceptUrl}</td>
                    </tr>
:)

let $invalidStationMedia := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Station", "ef:mediaMonitored", $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI)

(: D20 ./ef:geometry/gml:Points the srsName attribute shall be a recognisable URN :)
let $D20validURN := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4258", "urn:ogc:def:crs:EPSG::4326")
let $D20invalid :=
    for $x in distinct-values($docRoot//aqd:AQD_Station[count(ef:geometry/gml:Point) > 0 and not(ef:geometry/gml:Point/@srsName = $D20validURN)]/ef:inspireId/base:Identifier/string(base:localId))
    return
        <tr>
            <td title="base:localId">{$x}</td>
        </tr>


(: D21 Done by Rait :)
let $invalidPos_srsDim  := distinct-values($docRoot//aqd:AQD_Station/ef:geometry/gml:Point/gml:pos[@srsDimension != "2"]/
concat(../../../@gml:id, ": srsDimension=", @srsDimension))


let $aqdStationPos :=
    for $allPos in $docRoot//aqd:AQD_Station
    where not(empty($allPos/ef:geometry/gml:Point/gml:pos))
    return concat($allPos/ef:inspireId/base:Identifier/base:namespace,"/",$allPos/ef:inspireId/base:Identifier/base:localId,"|",
        fn:substring-before(data($allPos/ef:geometry/gml:Point/gml:pos), " "), "#", fn:substring-after(data($allPos/ef:geometry/gml:Point/gml:pos), " "))


let $invalidPos_order :=
    for $gmlPos in $docRoot//aqd:AQD_SamplingPoint

        let $samplingPos := data($gmlPos/ef:geometry/gml:Point/gml:pos)
        let $samplingLat := if (not(empty($samplingPos))) then fn:substring-before($samplingPos, " ") else ""
        let $samplingLong := if (not(empty($samplingPos))) then fn:substring-after($samplingPos, " ") else ""


        let $samplingLat := if ($samplingLat castable as xs:decimal) then xs:decimal($samplingLat) else 0.00
        let $samplingLong := if ($samplingLong castable as xs:decimal) then xs:decimal($samplingLong) else 0.00

        return if ($samplingLat < $samplingLong and $countryCode != 'FR')
        then concat($gmlPos/@gml:id, " : lat=" , string($samplingLat), " :long=", string($samplingLong)) else ()


let $invalidPosD21 := (($invalidPos_srsDim), ($invalidPos_order))

(: D23 Done by Rait :)
    let $allEfOperationActivityPeriod :=
        for $allOperationActivityPeriod in $docRoot//gml:featureMember/aqd:AQD_Station/ef:operationalActivityPeriod
        where ($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)!="unknown"]
                or fn:string-length($allOperationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) > 0)
        return $allOperationActivityPeriod

    let $allInvalidEfOperationActivityPeriod :=
            for $operationActivityPeriod in  $allEfOperationActivityPeriod
            where ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition < $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition)and ($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition!="")
    return
        <tr>
            <td title="aqd:AQD_Station">{data($operationActivityPeriod/../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
        </tr>



(: D24 Done by Rait:)
let $allUnknownEfOperationActivityPeriodD24 :=
    for $operationActivityPeriod in $docRoot//gml:featureMember/aqd:AQD_Station/ef:operationalActivityPeriod
    where $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)="unknown"]
            or fn:string-length($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) = 0
    return
        <tr>
            <td title="aqd:AQD_Station">{data($operationActivityPeriod/../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
        </tr>
(: D26 Done by Rait:)

let $localEUStationCode := $docRoot//gml:featureMember/aqd:AQD_Station/upper-case(normalize-space(aqd:EUStationCode))
let $invalidDuplicateLocalIds :=
    for $EUStationCode in $docRoot//gml:featureMember/aqd:AQD_Station/aqd:EUStationCode
    where
    count(index-of($localEUStationCode, upper-case(normalize-space($EUStationCode)))) > 1 or
     (
     count(index-of($xmlconv:ISO2_CODES , substring(upper-case(normalize-space($EUStationCode)), 1, 2))) = 0
     )
    return
        <tr>
            <td title="aqd:AQD_Station">{data($EUStationCode/../@gml:id)}</td>
            <td title="aqd:EUStationCode">{data($EUStationCode)}</td>
        </tr>

(: D27 :)
let $invalidMeteoParams :=xmlconv:checkVocabulariesConceptEquipmentValues($source_url, "aqd:AQD_Station", "aqd:meteoParams", $vocabulary:METEO_PARAMS_VOCABULARY, "collection")

(: D28 :)
let $invalidAreaClassification := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_Station", "aqd:areaClassification", $vocabulary:AREA_CLASSIFICATION_VOCABULARY)
(: D29 :)

let $allDispersionLocal :=
for $rec in $docRoot//aqd:AQD_Station/aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionLocal
return
<tr>{$rec}</tr>
let $invalidDispersionLocal := xmlconv:checkVocabularyConceptValues4($source_url, "aqd:AQD_Station", "aqd:dispersionLocal", $vocabulary:DISPERSION_LOCAL_VOCABULARY)

(: D30 :)
let $invalidDispersionRegional := xmlconv:checkVocabularyConceptValues4($source_url, "aqd:AQD_Station", "aqd:dispersionRegional", $vocabulary:DISPERSION_REGIONAL_VOCABULARY)
let $allDispersionRegional :=
for $rec in $docRoot//aqd:AQD_Station/aqd:dispersionSituation/aqd:DispersionSituation/aqd:dispersionRegional
return
<tr>{$rec}</tr>

(: D31 Done by Rait:)
let $localSamplingPointIds := $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId
let $invalidDuplicateSamplingPointIds :=
    for $idCode in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId
    where
        count(index-of($localSamplingPointIds, normalize-space($idCode))) > 1
    return
        <tr>
            <td title="aqd:AQD_SamplingPoint">{data($idCode/../../../@gml:id)}</td>
            <td title="base:localId">{data($idCode)}</td>
        </tr>

(: D32 :)

let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_SamplingPoint//base:Identifier/base:namespace)

let  $tblD32 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_SamplingPoint//base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
	    <td title="feature">SamplingPoint(s)</td>
	    <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: D33 :)
let $invalidSamplingPointMedia := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_SamplingPoint", "ef:mediaMonitored", $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI)

(: D34 :)
(:let $allGeometryPoint :=
    for $rec in $docRoot//aqd:AQD_SamplingPoint/ef:geometry/gml:Point
    return <tr>{$rec}</tr>:)

let $D34validURN := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4258", "urn:ogc:def:crs:EPSG::4326")
let $D34invalid :=
    for $x in distinct-values($docRoot//aqd:AQD_SamplingPoint[count(ef:geometry/gml:Point) > 0 and not(ef:geometry/gml:Point/@srsName = $D34validURN)]/ef:inspireId/base:Identifier/string(base:localId))
    return
        <tr>
            <td title="base:localId">{$x}</td>
        </tr>


(: D35 :)
let $invalidPos  :=
    for $x in $docRoot/gml:featureMember//aqd:AQD_SamplingPoint
        let $invalidOrder :=
            for $i in $x/ef:geometry/gml:Point/gml:pos
                let $latlongToken := tokenize($i,"\s+")
                let $lat := number($latlongToken[1])
                let $long := number($latlongToken[2])
            where ($long > $lat)
            return 1
    where ($x/ef:geometry/gml:Point/gml:pos/@srsDimension != "2" or $invalidOrder = 1)
    return
        <tr>
            <td title="base:localId">{string($x/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="@srsDimension">{string($x/ef:geometry/gml:Point/gml:pos/@srsDimension)}</td>
            <td title="Pos">{string($x/ef:geometry/gml:Point/gml:pos)}</td>
        </tr>

(: D36 :)

let $approximity := 0.0003

(: StationID|long#lat :)
let $aqdStationPos :=
    for $allPos in $docRoot//aqd:AQD_Station
    where not(empty($allPos/ef:geometry/gml:Point/gml:pos))
    return concat($allPos/ef:inspireId/base:Identifier/base:namespace,"/",$allPos/ef:inspireId/base:Identifier/base:localId,"|",
        fn:substring-before(data($allPos/ef:geometry/gml:Point/gml:pos), " "), "#", fn:substring-after(data($allPos/ef:geometry/gml:Point/gml:pos), " "))


let $invalidSamplingPointPos :=
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

        return if (abs($samplingLong - $stationLong) > $approximity
        or abs($samplingLat - $stationLat) > $approximity) then $gmlPos/@gml:id else ()
(: D37 :)
(: check for invalid data or if beginPosition > endPosition :)
let $invalidPosition  :=
    for $timePeriod in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:observingTime/gml:TimePeriod
        (: XQ does not support 24h that is supported by xml schema validation :)
        (: TODO: comment by sofiageo - the above statement is not true, fix this if necessary :)
        let $beginDate := substring(normalize-space($timePeriod/gml:beginPosition),1,10)
        let $endDate := substring(normalize-space($timePeriod/gml:endPosition),1,10)
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
                <td title="aqd:AQD_Station">{data($timePeriod/../../../../@gml:id)}</td>
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
            if ($period/gml:endPosition castable as xs:dateTime and $observingCapabilities[$pos+1]/gml:beginPosition castable as xs:dateTime) then
                 if (xs:dateTime($period/gml:endPosition) > xs:dateTime($observingCapabilities[$pos+1]/gml:beginPosition)) then fn:false() else fn:true()
            else
                fn:true()
        else
            fn:true()

       return if ($ok) then () else

            <tr>
                <td title="aqd:AQD_Station">{data($period/../../../../@gml:id)}</td>
                <td title="gml:TimePeriod">{data($period/@gml:id)}</td>
                <td title="gml:beginPosition">{$period/gml:beginPosition}</td>
                <td title="gml:endPosition">{$period/gml:endPosition}</td>
            </tr>


let $allObservingCapabilityPeriod := (($invalidPosition), ($overlappingPeriods))


(: D40 :)
(:let $invalidObservedProperty := xmlconv:checkVocabularyConceptValues($source_url, "ef:ObservingCapability", "ef:observedProperty", $vocabulary:POLLUTANT_VOCABULARY):)

let $D40invalid :=
    for $x in $docRoot//aqd:AQD_SamplingPoint
    where (not($x/ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href = $dd:VALIDPOLLUTANTS)) or
            (count(distinct-values(data($x/ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href))) > 1)
    return
        <tr>
            <td title="base:localId">{$x/ef:inspireId/base:Identifier/string(base:localId)}</td>
        </tr>

(: D41
let $aqdSampleLocal :=
    for $allSampleLocal in $docRoot//aqd:AQD_Sample
    return $allSampleLocal/@gml:id

let $invalideFeatureOfInterest :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
    where empty(index-of($aqdSampleLocal,fn:normalize-space(fn:substring-after($x/@xlink:href,"/"))))
    return
    <tr>
        <td title="aqd:AQD_SamplingPoint">{data($x/../../../@gml:id)}</td>
        <td title="ef:featureOfInterest">{data(fn:normalize-space(fn:substring-after($x/@xlink:href,"/")))}</td>
    </tr>
:)

(: D41 Updated by Jaume Targa following working logic of D44 :)
let $aqdSampleLocal :=
    for $z in $docRoot//aqd:AQD_Sample
    let $id := concat(data($z/aqd:inspireId/base:Identifier/base:namespace), '/',
        data($z/aqd:inspireId/base:Identifier/base:localId))
    return $id

let $invalideFeatureOfInterest :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest
    where empty(index-of($aqdSampleLocal,fn:normalize-space($x/@xlink:href)))
    return
    <tr>
      <td title="aqd:AQD_SamplingPoint">{data($x/../@gml:id)}</td>
      <td title="ef:featureOfInterest">{data(fn:normalize-space($x/@xlink:href))}</td>
    </tr>


(: D42 :)
let $aqdProcessLocal :=
    for $allProcessLocal in $docRoot//aqd:AQD_SamplingPointProcess
    let $id := concat(data($allProcessLocal/ompr:inspireId/base:Identifier/base:namespace),
        '/', data($allProcessLocal/ompr:inspireId/base:Identifier/base:localId))
    return $id

let $invalidEfprocedure :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:observingCapability/ef:ObservingCapability/ef:procedure
    where empty(index-of($aqdProcessLocal,fn:normalize-space($x/@xlink:href)))
    return
    <tr>
      <td title="aqd:AQD_SamplingPoint">{data($x/../../../@gml:id)}</td>
      <td title="ef:procedure">{data(fn:normalize-space($x/@xlink:href))}</td>
    </tr>

(: D43 Updated by Jaume Targa following working logic of D44 :)
let $aqdStationLocal :=
    for $z in $docRoot//aqd:AQD_Station
    let $id := concat(data($z/ef:inspireId/base:Identifier/base:namespace), '/',
        data($z/ef:inspireId/base:Identifier/base:localId))
    return $id

let $invalidEfbroader :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:broader
    where empty(index-of($aqdStationLocal,fn:normalize-space($x/@xlink:href)))
    return
    <tr>
      <td title="aqd:AQD_SamplingPoint">{data($x/../@gml:id)}</td>
      <td title="ef:broader">{data(fn:normalize-space($x/@xlink:href))}</td>
    </tr>

(: D44 :)
let $aqdNetworkLocal :=
    for $z in $docRoot//aqd:AQD_Network
    let $id := concat(data($z/ef:inspireId/base:Identifier/base:namespace), '/',
        data($z/ef:inspireId/base:Identifier/base:localId))
    return $id

let $invalidEfbelongsTo :=
    for $x in $docRoot//aqd:AQD_SamplingPoint/ef:belongsTo
    where empty(index-of($aqdNetworkLocal,fn:normalize-space($x/@xlink:href)))
    return
    <tr>
      <td title="aqd:AQD_SamplingPoint">{data($x/../@gml:id)}</td>
      <td title="ef:belongsTo">{data(fn:normalize-space($x/@xlink:href))}</td>
    </tr>

(: D44b :)
let $invalidStationEfbelongsTo :=
    for $x in $docRoot//aqd:AQD_Station/ef:belongsTo
    where empty(index-of($aqdNetworkLocal,fn:normalize-space($x/@xlink:href)))
    return
    <tr>
      <td title="aqd:AQD_Station">{data($x/../@gml:id)}</td>
      <td title="ef:belongsTo">{data(fn:normalize-space($x/@xlink:href))}</td>
    </tr>

(: D45 :)
(: Find all period with out end period :)
let $allNotNullEndOperationActivityPeriods :=
    for $allOperationActivityPeriod in $docRoot//aqd:AQD_SamplingPoint/ef:operationalActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod
    where ($allOperationActivityPeriod/gml:endPosition[normalize-space(@indeterminatePosition)!="unknown"]
            or fn:string-length($allOperationActivityPeriod/gml:endPosition) > 0)

    return $allOperationActivityPeriod

let $allOperationActivitPeriod :=
    for $operationActivitPeriod in $allNotNullEndOperationActivityPeriods
    where ((xs:dateTime($operationActivitPeriod/gml:endPosition) < xs:dateTime($operationActivitPeriod/gml:beginPosition)))
    return
        <tr>
            <td title="aqd:AQD_Station">{data($operationActivitPeriod/../../../../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($operationActivitPeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$operationActivitPeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$operationActivitPeriod/gml:endPosition}</td>
        </tr>

(: D46 :)
let $allUnknownEfOperationActivityPeriod :=
    for $operationActivityPeriod in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint/ef:operationalActivityPeriod
    where $operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition[normalize-space(@indeterminatePosition)="unknown"]
            or fn:string-length($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition) = 0
    return
        <tr>
            <td title="aqd:AQD_SamplingPoint">{data($operationActivityPeriod/../@gml:id)}</td>
            <td title="gml:TimePeriod">{data($operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/@gml:id)}</td>
            <td title="gml:beginPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:beginPosition}</td>
            <td title="gml:endPosition">{$operationActivityPeriod/ef:OperationalActivityPeriod/ef:activityTime/gml:TimePeriod/gml:endPosition}</td>
        </tr>

(:D50 Done by Rait:)
let $invalidStationClassificationLink :=
    for $allLinks in $docRoot//gml:featureMember/aqd:AQD_SamplingPoint
    where not(substring($allLinks/aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href,1,fn:string-length("http://dd.eionet.europa.eu/vocabulary/aq/stationclassification"))="http://dd.eionet.europa.eu/vocabulary/aq/stationclassification")
    return
        <tr>
            <td title="gml:id">{data($allLinks/@gml:id)}</td>
            <td title="xlink:href">{data($allLinks/aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href)}</td>
        </tr>

(: D51 :)
let $environmentalObjectiveCombinations :=
    doc("http://dd.eionet.europa.eu/vocabulary/aq/environmentalobjective/rdf")

let $D51invalid := for $x in $docRoot//aqd:AQD_SamplingPoint/aqd:environmentalObjective/aqd:EnvironmentalObjective
    let $pollutant := string($x/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href)
    let $objectiveType := string($x/aqd:objectiveType/@xlink:href)
    let $reportingMetric := string($x/aqd:reportingMetric/@xlink:href)
    let $protectionTarget := string($x/aqd:protectionTarget/@xlink:href)
    return
        if (not($environmentalObjectiveCombinations//skos:Concept[prop:relatedPollutant/@rdf:resource = $pollutant and prop:hasProtectionTarget/@rdf:resource = $protectionTarget
                and prop:hasObjectiveType/@rdf:resource = $objectiveType and prop:hasReportingMetric/@rdf:resource = $reportingMetric]))
        then
            <tr>
                <td title="base:localId">{string($x/../../ef:inspireId/base:Identifier/base:localId)}</td>
                <td title="ef:observedProperty">{string($x/../../ef:observingCapability/ef:ObservingCapability/ef:observedProperty/@xlink:href)}</td>
                <td title="aqd:objectiveType">{string($x/aqd:objectiveType/@xlink:href)}</td>
                <td title="aqd:reportingMetric">{string($x/aqd:reportingMetric/@xlink:href)}</td>
                <td title="aqd:protectionTarget">{string($x/aqd:protectionTarget/@xlink:href)}</td>
            </tr>
        else
            ()

(: D53 Done by Rait :)
let $allInvalidZoneXlinks :=
    for $invalidZoneXlinks in $docRoot//aqd:AQD_SamplingPoint/aqd:zone[not(@nilReason='inapplicable')]
     where
        count(sparqlx:executeSparqlQuery(xmlconv:getSamplingPointZone(string($invalidZoneXlinks/@xlink:href)))/*) = 0
    return
        <tr>
            <td title="gml:id">{data($invalidZoneXlinks/../@gml:id)}</td>
            <td title="aqd:zone">{data($invalidZoneXlinks/@xlink:href)}</td>
        </tr>

(: D54 Done by Rait :)
let $localSamplingPointProcessIds := $docRoot//gml:featureMember/aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier
let $invalidDuplicateSamplingPointProcessIds :=
    for $idSamplingPointProcessCode in $docRoot//gml:featureMember/aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier
    where
        count(index-of($localSamplingPointProcessIds/base:localId, normalize-space($idSamplingPointProcessCode/base:localId))) > 1 and
                count(index-of($localSamplingPointProcessIds/base:namespace, normalize-space($idSamplingPointProcessCode/base:namespace))) > 1
    return
        <tr>
            <td title="aqd:AQD_SamplingPointProcess">{data($idSamplingPointProcessCode/../../@gml:id)}</td>
            <td title="base:localId">{data($idSamplingPointProcessCode/base:localId)}</td>
            <td title="base:namespace">{data($idSamplingPointProcessCode/base:namespace)}</td>
        </tr>

(: D55 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier/base:namespace)
let $tblD55 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_SamplingPointProcess/ompr:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
  	    <td title="feature">SamplingPointProcess(es)</td>
	    <td title="base:namespace">{$id}</td>
            <td title="unique localId">{count($localId)}</td>
        </tr>


(: D56 Done by Rait :)
let $allInvalidMeasurementType
     := xmlconv:checkVocabularyConceptValues($source_url, "aqd:AQD_SamplingPointProcess", "aqd:measurementType", $vocabulary:MEASUREMENTTYPE_VOCABULARY)


(: D57 :)
let $allConceptUrl57 :=
for $process in doc($source_url)//aqd:AQD_SamplingPointProcess
    let $measurementType := data($process/aqd:measurementType/@xlink:href)
    let $measurementMethod := data($process/aqd:measurementMethod/aqd:MeasurementMethod/aqd:measurementMethod/@xlink:href)
    let $samplingMethod := data($process/aqd:samplingMethod/aqd:SamplingMethod/aqd:samplingMethod/@xlink:href)
    let $analyticalTechnique := data($process/aqd:analyticalTechnique/aqd:AnalyticalTechnique/aqd:analyticalTechnique/@xlink:href)
    where ($measurementType  = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/automatic' or
         $measurementType = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/remote')
         and (
            string-length($samplingMethod) > 0 or string-length($analyticalTechnique) > 0 or not(xmlconv:isValidConceptCode($measurementMethod,$vocabulary:MEASUREMENTMETHOD_VOCABULARY))
            )

    return
        <tr>
            <td title="aqd:AQD_SamplingPointProcess">{data($process/@gml:id)}</td>
            <td title="aqd:measurementType">{$measurementType}</td>
            <td title="aqd:measurementMethod">{$measurementMethod}</td>
            <td title="aqd:samplingMethod">{$samplingMethod}</td>
            <td title="aqd:analyticalTechnique">{$analyticalTechnique}</td>
        </tr>

(: D58 Done by Rait :)
let $allConceptUrl58 :=
    for $conceptUrl in doc($source_url)//gml:featureMember/aqd:AQD_SamplingPointProcess/aqd:measurementType/@xlink:href
    where $conceptUrl = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/active' or
            $conceptUrl = 'http://dd.eionet.europa.eu/vocabulary/aq/measurementtype/passive'
    return $conceptUrl

let $elementsIncluded :=
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

(: D59 Done by Rait:)
let  $allInvalidAnalyticalTechnique
    := xmlconv:checkVocabularyaqdAnalyticalTechniqueValues($source_url, "aqd:AQD_SamplingPointProcess", "aqd:analyticalTechnique", $vocabulary:ANALYTICALTECHNIQUE_VOCABULARY, "")

(: D60a  :)
let  $allInvalid60a
    := xmlconv:checkVocabularyConceptEquipmentValues($source_url, "aqd:AQD_SamplingPointProcess", "aqd:measurementEquipment", $vocabulary:MEASUREMENTEQUIPMENT_VOCABULARY, "")

(: D60b :)
let  $allInvalid60b
    := xmlconv:checkVocabularyConceptEquipmentValues($source_url, "aqd:AQD_SamplingPointProcess", "aqd:samplingEquipment", $vocabulary:SAMPLINGEQUIPMENT_VOCABULARY, "")

(: D63 :)
let  $allInvalid63
    := xmlconv:checkVocabularyConceptValuesUom($source_url, "aqd:DataQuality", "aqd:detectionLimit", $vocabulary:UOM_CONCENTRATION_VOCABULARY)

(: Block for D67 to D70 Jaume Targa:)

(: Original from D52

let $allProcNotMatchingCondition70 :=
for $proc in $docRoot//aqd:AQD_SamplingPointProcess
let $demonstrated := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href)
let $demonstrationReport := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport)
let $documentation := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:documentation)
let $qaReport := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:qaReport)

    where fn:string-length($qaReport) = 0 or fn:string-length($documentation) = 0 or fn:string-length($demonstrationReport) = 0
        or not(xmlconv:isValidConceptCode($demonstrated, $xmlconv:EQUIVALENCEDEMONSTRATED_VOCABULARY))

return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))


let $allInvalidTrueUsedAQD70 :=
    for $invalidTrueUsedAQD70 in $docRoot//aqd:AQD_SamplingPoint
        let $procIds70 := data($invalidTrueUsedAQD70/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed70 := $invalidTrueUsedAQD70/aqd:usedAQD = true()

    for $procId70 in $procIds70
    return
        if ($aqdUsed70  and  not(empty(index-of($allProcNotMatchingCondition70, $procId70)))) then
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD70/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD70/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD70/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{$procId70}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD70/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>

        </tr>
        else ()
:)


(: D67 Jaume Targa :)

let $allProcNotMatchingCondition67 :=
for $proc in $docRoot//aqd:AQD_SamplingPointProcess
let $demonstrated := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href)
let $demonstrationReport := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport)

where not(xmlconv:isValidConceptCode($demonstrated, $vocabulary:EQUIVALENCEDEMONSTRATED_VOCABULARY))

return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))


let $allInvalidTrueUsedAQD67 :=
    for $invalidTrueUsedAQD67 in $docRoot//aqd:AQD_SamplingPoint
        let $procIds67 := data($invalidTrueUsedAQD67/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed67 := $invalidTrueUsedAQD67/aqd:usedAQD = true()

    for $procId67 in $procIds67
    return
        if ($aqdUsed67  and  not(empty(index-of($allProcNotMatchingCondition67, $procId67)))) then
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD67/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD67/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD67/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{$procId67}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD67/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>

        </tr>
        else ()

(: D68 Jaume Targa :)
let $allProcNotMatchingCondition68 :=
for $proc in $docRoot//aqd:AQD_SamplingPointProcess
let $demonstrated := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:equivalenceDemonstrated/@xlink:href)
let $demonstrationReport := data($proc/aqd:equivalenceDemonstration/aqd:EquivalenceDemonstration/aqd:demonstrationReport)

where ($demonstrated = 'http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/yes' and fn:string-length($demonstrationReport) = 0)

return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))


let $allInvalidTrueUsedAQD68 :=
    for $invalidTrueUsedAQD68 in $docRoot//aqd:AQD_SamplingPoint
        let $procIds68 := data($invalidTrueUsedAQD68/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)
        let $aqdUsed68 := $invalidTrueUsedAQD68/aqd:usedAQD = true()

    for $procId68 in $procIds68
    return
        if ($aqdUsed68  and  not(empty(index-of($allProcNotMatchingCondition68, $procId68)))) then
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD68/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD68/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD68/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{$procId68}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD68/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>

        </tr>
        else ()



(: D69 Jaume Targa :)
let $allProcNotMatchingCondition69 :=
    for $proc in $docRoot//aqd:AQD_SamplingPointProcess
        let $documentation := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:documentation)
        let $qaReport := data($proc/aqd:dataQuality/aqd:DataQuality/aqd:qaReport)
    where (string-length($documentation) = 0) and (string-length($qaReport) = 0)
    return concat(data($proc/ompr:inspireId/base:Identifier/base:namespace), '/' , data($proc/ompr:inspireId/base:Identifier/base:localId))

let $allInvalidTrueUsedAQD69 :=
    for $invalidTrueUsedAQD69 in $docRoot//aqd:AQD_SamplingPoint[aqd:usedAQD = "true" and ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href = $allProcNotMatchingCondition69]
    return
        <tr>
            <td title="gml:id">{data($invalidTrueUsedAQD69/@gml:id)}</td>
            <td title="base:localId">{data($invalidTrueUsedAQD69/ef:inspireId/base:Identifier/base:localId)}</td>
            <td title="base:namespace">{data($invalidTrueUsedAQD69/ef:inspireId/base:Identifier/base:namespace)}</td>
            <td title="ef:procedure">{string($invalidTrueUsedAQD69/ef:observingCapability/ef:ObservingCapability/ef:procedure/@xlink:href)}</td>
            <td title="ef:ObservingCapability">{data($invalidTrueUsedAQD69/ef:observingCapability/ef:ObservingCapability/@gml:id)}</td>
        </tr>

(: D71 :)
let $localSampleIds := $docRoot//gml:featureMember/aqd:AQD_Sample/aqd:inspireId/base:Identifier
let $invalidDuplicateSampleIds :=
    for $idSampleCode in $docRoot//gml:featureMember/aqd:AQD_Sample/aqd:inspireId/base:Identifier
    where
        count(index-of($localSampleIds/base:localId, normalize-space($idSampleCode/base:localId))) > 1 and
                count(index-of($localSampleIds/base:namespace, normalize-space($idSampleCode/base:namespace))) > 1
    return
        <tr>
            <td title="aqd:AQD_Sample">{data($idSampleCode/../../@gml:id)}</td>
            <td title="base:localId">{data($idSampleCode/base:localId)}</td>
            <td title="base:namespace">{data($idSampleCode/base:namespace)}</td>
        </tr>

(: D72 :)
let $allBaseNamespace := distinct-values($docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:namespace)

let $tblD72 :=
    for $id in $allBaseNamespace
    let $localId := $docRoot//aqd:AQD_Sample/aqd:inspireId/base:Identifier[base:namespace = $id]/base:localId
    return
        <tr>
            <td title="base:namespace">{$id}</td>
            <td title="base:localId">{count($localId)}</td>
        </tr>

(: D73 :)
let $allGmlPoint := $docRoot//aqd:AQD_Sample/sams:shape/gml:Point
let $D73validURN := ("urn:ogc:def:crs:EPSG::3035", "urn:ogc:def:crs:EPSG::4258", "urn:ogc:def:crs:EPSG::4326")
let $D73invalid :=
    for $point in $docRoot//aqd:AQD_Sample/sams:shape/gml:Point[not(@srsName = $D73validURN)]
    return
        <tr>
            <td title="aqd:AQD_Sample">{data($point/../../aqd:inspireId/base:Identifier/base:localId)}</td>
            <td title="gml:Point">{data($point/@gml:id)}</td>
            <td title="gml:Point/@srsName">{data($point/@srsName)}</td>
        </tr>
let $strErr73 := for $tr in $D73invalid
return data($tr/td[@title='aqd:AQD_Sample'])

let $isInvalidInvalidD73 := if (count($allGmlPoint) > 0) then fn:true() else fn:false()
let $errLevelD73 := if (count($allGmlPoint) > 0) then "error" else "warning"
let $errMsg73  := if (count($allGmlPoint) > 0) then " errors found" else " gml:Point elements found"

(: D74 :)
let $invalidPointDimension  := distinct-values($docRoot//aqd:AQD_Sample/sams:shape/gml:Point[@srsDimension != "2"]/
concat(../@gml:id, ": srsDimension=", @srsDimension))

(: D75 :)
let $approximity := 0.0003

(: SampleID|long#lat :)
let $aqdSampleMap := map:merge((
    for $allPos in $docRoot//aqd:AQD_Sample[not(sams:shape/gml:Point/gml:pos = "")]
        let $id := concat($allPos/aqd:inspireId/base:Identifier/base:namespace,"/",$allPos/aqd:inspireId/base:Identifier/base:localId)
        let $pos := $allPos/sams:shape/gml:Point/string(gml:pos)
    return map:entry($id, $pos)
))

let $D75invalid :=
    for $x in $docRoot//aqd:AQD_SamplingPoint[not(ef:geometry/gml:Point/gml:pos = "")]
        let $samplingPos := $x/ef:geometry/gml:Point/string(gml:pos)
        let $xlink := $x/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/string(@xlink:href)
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

    return
        if (abs($samplingLong - $sampleLong) > $approximity or abs($samplingLat - $sampleLat) > $approximity) then
            $x/ef:inspireId/base:Identifier/string(base:localId)
        else
            ()

(: D76 :)
let $sampleDistanceMap :=
    map:merge((
        for $x in $docRoot//aqd:AQD_Sample[not(string(aqd:buildingDistance) = "")]
        let $id := concat($x/aqd:inspireId/base:Identifier/base:namespace, "/", $x/aqd:inspireId/base:Identifier/base:localId)
        let $distance := string($x/aqd:buildingDistance)
        return map:entry($id, $distance)
    ))
let $D76invalid :=
    for $x in $docRoot//aqd:AQD_SamplingPoint[aqd:relevantEmissions/aqd:RelevantEmissions/aqd:stationClassification/@xlink:href = "http://dd.eionet.europa.eu/vocabulary/aq/stationclassification/traffic"]
    let $xlink := string($x/ef:observingCapability/ef:ObservingCapability/ef:featureOfInterest/@xlink:href)
    let $distance := map:get($sampleDistanceMap, $xlink)
    return
        if ($distance castable as xs:double) then
            ()
        else
            <tr>
                <td title="base:localId">{$x/ef:inspireId/base:Identifier/string(base:localId)}</td>
            </tr>


(: D78 :)
let $invalidInletHeigh :=
for $inletHeigh in  $docRoot//aqd:AQD_Sample/aqd:inletHeight
    return if (($inletHeigh/@uom != "http://dd.eionet.europa.eu/vocabulary/uom/length/m") or (common:is-a-number(data($inletHeigh))=false())) then $inletHeigh/../@gml:id else ()

return
    <table style="border-collapse:collapse;display:inline">
        <colgroup>
            <col width="15px" style="text-align:center"/>
            <col width="500px" style="text-align:left"/>
            <col width="350px" style="text-align:left"/>
            <col width="*"/>
        </colgroup>
        {html:buildResultRows_D("D1", $labels:D1, $labels:D1_SHORT, (), (), "", string(sum($countFeatureTypes)), "", "","error", $tblAllFeatureTypes)}
        {html:buildResultRows_D("D2", $labels:D2, $labels:D2_SHORT, (), (), "", string(count($tblD2)), "", "","error",())}
        {html:buildResultRows_D("D3", $labels:D3, $labels:D3_SHORT, (), (), "", string(count($tblD3)), "", "","error",())}
        {html:buildResultRows_D("D4", $labels:D4, $labels:D4_SHORT, (), (), "", string(count($tblD4)), "", "","error",$tblD4)}
        <tr>
            <tr style="border-top:1px solid #666666">
                <td style="vertical-align:top;">{ html:getBullet("D5", if ($countD5duplicates = 0) then "info" else "error") }</td>
                <th style="vertical-align:top;text-align:left">{ $labels:D5 }</th>
                <td style="vertical-align:top;">{
                    if ($countD5duplicates = 0) then
                        "All Ids are unique"
                    else
                        concat($countD5duplicates, " duplicate", substring("s ", number(not($countD5duplicates > 1)) * 2) ,"found") }</td>
            </tr>
            {
                if ($countGmlIdDuplicates > 0) then
                    <tr style="font-size: 0.9em;color:grey;">
                        <td colspan="2" style="text-align:right;vertical-align:top;">aqd:AQD_Model/@gml:id - </td>
                        <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateGmlIds, ", ")}</td>
                    </tr>
                else
                    ()
            }
            {
                if ($countefInspireIdDuplicates > 0) then
                    <tr style="font-size: 0.9em;color:grey;">
                        <td colspan="2" style="text-align:right;vertical-align:top;">ef:inspireId - </td>
                        <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateefInspireIds, ", ")}</td>
                    </tr>
                else
                    ()
            }
            {
                if ($countaqdInspireIdDuplicates > 0) then
                    <tr style="font-size: 0.9em;color:grey;">
                        <td colspan="2" style="text-align:right;vertical-align:top;">aqd:inspireId - </td>
                        <td style="font-style:italic;vertical-align:top;">{ string-join($duplicateaqdInspireIds, ", ")}</td>
                    </tr>
                else
                    ()
            }
        </tr>
	<tr style="border-top:2px solid #666666">
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
	</tr>
	<tr style="border-top:0px solid #666666">
            <th colspan="2" style="vertical-align:top;text-align:left">Specific checks on AQD_Network feature(s) within this XML</th>
            <td style="vertical-align:top;"></td>
	</tr>

        <tr style="border-top:1px solid #666666">
            <td style="vertical-align:top;">{ html:getBullet("D6", if ($countD6duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;text-align:left">{ $labels:D6 }</th>
            <td style="vertical-align:top;">{
                if ($countD6duplicates = 0) then
                    <span style="font-size:1.3em;">All Ids are unique</span>
                else
                    concat($countD6duplicates, " error", substring("s ", number(not($countD6duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {html:buildResultRows_D("D7", $labels:D7, $labels:D7_SHORT, (), (), "", string(count($tblD7)), "", "","error",$tblD7)}
        {html:buildResultRows_D("D7.1", $labels:D7.1, $labels:D7.1_SHORT, $invalidNamespaces, (), "base:Identifier/base:namespace", "All values are valid", " invalid namespaces", "", "error", ())}
        {html:buildResultRowsWithTotalCount_D("D8", <span>The content of aqd:AQD_Network/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI }">{ $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI }</a></span>, $labels:PLACEHOLDER,
            (), (), "ef:mediaMonitored", "", "", "", "warning",$invalidNetworkMedia)}
        {html:buildResultRowsWithTotalCount_D("D9", <span>The content of aqd:AQD_Network/ef:organisationLevel shall resolve to any concept in
            <a href="{ $vocabulary:ORGANISATIONAL_LEVEL_VOCABULARY }">{ $vocabulary:ORGANISATIONAL_LEVEL_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
                (), (), "ef:organisationLevel", "", "", "","warning", $invalidOrganisationalLevel)}
        {html:buildResultRowsWithTotalCount_D("D10", <span>The content of aqd:AQD_Network/aqd:networkType shall resolve to any concept in
            <a href="{ $vocabulary:NETWORK_TYPE_VOCABULARY }">{ $vocabulary:NETWORK_TYPE_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
                (), (), "aqd:networkType", "", "", "","warning", $invalidNetworkType)}
        {html:buildResultRows_D("D11", $labels:D11, $labels:D11_SHORT, $invalidAQDNetworkBeginPosition, () , "aqd:AQD_Network/@gml:id", "All attributes are valid", " invalid attribute ", "","error", ())}
        {html:buildResultRows_D("D12", $labels:D12, $labels:D12_SHORT, $D12invalid, () , "aqd:AQD_Network/ef:inspireId/base:Identifier/base:localId", "All attributes are valid", " invalid attribute ", "","error", ())}
        {html:buildResultRowsWithTotalCount_D("D14", <span>The content of /aqd:AQD_Network/aqd:aggregationTimeZone attribute shall resolve to a valid code in
            <a href="{ $vocabulary:TIMEZONE_VOCABULARY }">{ $vocabulary:TIMEZONE_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
                (), (), "aqd:aggregationTimeZone", "", "", "","error",$invalidTimeZone)}
        <tr style="border-top:2px solid #666666">
                <td style="vertical-align:top;"></td>
                <td style="vertical-align:top;"></td>
                <td style="vertical-align:top;"></td>
        </tr>
        <tr style="border-top:0px solid #666666">
                <th colspan="2" style="vertical-align:top;text-align:left">Specific checks on AQD_Station feature(s) within this XML</th>
                <td style="vertical-align:top;"></td>
        </tr>
        <tr style="border-top:1px solid #666666">
            <td style="vertical-align:top;">{ html:getBullet("D15", if ($countD15duplicates = 0) then "info" else "error") }</td>
            <th style="vertical-align:top;text-align:left">aqd:AQD_Station/ef:inspireId/base:Identifier/base:localId shall be an unique code within namespace</th>
            <td style="vertical-align:top;">{
                if ($countD15duplicates = 0) then
                    <span style="font-size:1.3em;">All Ids are unique</span>
                else
                    concat($countD15duplicates, " error", substring("s ", number(not($countD15duplicates > 1)) * 2) ,"found") }</td>
        </tr>
        {html:buildResultRows_D("D16", $labels:D16, $labels:D16_SHORT, (), (), "", string(count($tblD16)), "", "","error",$tblD16)}
        {html:buildResultRows_D("D17", $labels:D17, $labels:D17_SHORT, (), (), "", "All values are valid", "", "","warning", $D17invalid)}
        {html:buildResultRows_D("D18", $labels:D18, $labels:D18_SHORT, (), (), "", "All values are valid", "", "","warning", $D18invalid)}
        {html:buildResultRowsWithTotalCount_D("D19", <span>The content of /aqd:AQD_Station/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI }">{ $vocabulary:MEDIA_VALUE_VOCABULARY_BASE_URI }</a></span>, $labels:PLACEHOLDER,
            (), (), "ef:mediaMonitored", "", "", "","warning", $invalidStationMedia)}
        {html:buildResultRows_D("D20", $labels:D20, $labels:D20_SHORT, (), (), "aqd:AQD_Station/ef:inspireId/base:Identifier/base:localId","All smsName attributes are valid"," invalid attribute","", "warning", $D20invalid)}
        {html:buildResultRows_D("D21", $labels:D21, $labels:D21_SHORT, $invalidPosD21, () , "aqd:AQD_Zone/@gml:id", "All srsDimension attributes resolve to ""2""", " invalid attribute", "","error",())}
        {html:buildResultRows_D("D23", $labels:D23, $labels:D23_SHORT, (), $allInvalidEfOperationActivityPeriod, "", fn:string(count($allInvalidEfOperationActivityPeriod)), "", "","error", ())}
        {html:buildResultRows_D("D24", $labels:D24, $labels:D24_SHORT, (), $allUnknownEfOperationActivityPeriodD24, "", string(count($allUnknownEfOperationActivityPeriodD24)), "", "","warning",(), fn:false())}
        {html:buildResultRows_D("D26", $labels:D26, $labels:D26_SHORT, (), $invalidDuplicateLocalIds, "", "All station codes are valid", " invalid station codes", "","error", ())}
        {html:buildResultRowsWithTotalCount_D("D27", <span>The content of aqd:AQD_Station/aqd:meteoParams shall resolve to any concept in
            <a href="{ $vocabulary:METEO_PARAMS_VOCABULARY[1] }">{ $vocabulary:METEO_PARAMS_VOCABULARY[1] }</a>,
            <a href="{ $vocabulary:METEO_PARAMS_VOCABULARY[2] }">{ $vocabulary:METEO_PARAMS_VOCABULARY[2] }</a>,
            <a href="{ $vocabulary:METEO_PARAMS_VOCABULARY[3] }">{ $vocabulary:METEO_PARAMS_VOCABULARY[3] }</a></span>, $labels:PLACEHOLDER,
                (), (), "aqd:meteoParams", "", "", "","warning",$invalidMeteoParams)}
        {html:buildResultRowsWithTotalCount_D("D28", <span>The content of aqd:AQD_Station/aqd:areaClassification shall resolve to any concept in
            <a href="{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY }">{ $vocabulary:AREA_CLASSIFICATION_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
            (), (), "aqd:areaClassification", "", "", "","error", $invalidAreaClassification)}
        {html:buildResultRowsWithTotalCount_D("D29", <span>The content of aqd:AQD_Station/aqd:dispersionLocal shall resolve to any concept in
            <a href="{ $vocabulary:DISPERSION_LOCAL_VOCABULARY }">{ $vocabulary:DISPERSION_LOCAL_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
            $invalidDispersionLocal, (), "aqd:dispersionLocal", "", "", "","warning", $allDispersionLocal)}
        {html:buildResultRowsWithTotalCount_D("D30", <span>The content of aqd:AQD_Station/aqd:dispersionRegional shall resolve to any concept in
            <a href="{ $vocabulary:DISPERSION_REGIONAL_VOCABULARY }">{ $vocabulary:DISPERSION_REGIONAL_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
            $invalidDispersionRegional, (), "aqd:dispersionRegional", "", "", "","warning", $allDispersionRegional)}
        <tr style="border-top:2px solid #666666">
                <td style="vertical-align:top;"></td>
                <td style="vertical-align:top;"></td>
                <td style="vertical-align:top;"></td>
        </tr>
        <tr style="border-top:0px solid #666666">
                <th colspan="2" style="vertical-align:top;text-align:left">{ $labels:D30 }</th>
                <td style="vertical-align:top;"></td>
        </tr>
        {html:buildResultRows_D("D31", $labels:D31, $labels:D31_SHORT, (), $invalidDuplicateSamplingPointIds, "", concat(string(count($invalidDuplicateSamplingPointIds))," errors found.") , "", "","error", ())}
        {html:buildResultRows_D("D32", $labels:D32, $labels:D32_SHORT, (), (), "", string(count($tblD32)), "", "","error",$tblD32)}
        {html:buildResultRowsWithTotalCount_D("D33", <span>The content of aqd:AQD_SamplingPoint/ef:mediaMonitored shall resolve to any concept in
            <a href="{ $vocabulary:MEDIA_VALUE_VOCABULARY }">{ $vocabulary:MEDIA_VALUE_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
            (), (), "ef:mediaMonitored", "", "", "","warning", $invalidSamplingPointMedia)}
        {html:buildResultRows_D("D34", $labels:D34, $labels:D34_SHORT, (), (), "", "All values are valid", "", "", "error", $D34invalid)}
        {html:buildResultRows_D("D35", $labels:D35, $labels:D35_SHORT, (), () , "aqd:AQD_SamplingPoint/ef:inspireId/base:Identifier/base:localId", "All srsDimension attributes resolve to ""2""", " invalid elements", "","error", $invalidPos)}
        {html:buildResultRows_D("D36", $labels:D36, $labels:D36_SHORT, $invalidSamplingPointPos, () , "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning",())}
        {html:buildResultRows_D("D37", $labels:D37, $labels:D37_SHORT, (), $allObservingCapabilityPeriod, "", concat(fn:string(count($allObservingCapabilityPeriod))," errors found"), "", "","error", ())}
        {html:buildResultRows_D("D40", <span>The content of ../ef:observedProperty shall resolve to a valid code within
            <a href="{ $vocabulary:POLLUTANT_VOCABULARY }">{ $vocabulary:POLLUTANT_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
                (), (), "ef:observedProperty", "All values are valid", "invalid pollutant", "","error", $D40invalid)}
        <tr style="border-top:2px solid #666666">
            <th colspan="3" style="vertical-align:top;text-align:left">Internal XML cross-checks between AQD_SamplingPoint and AQD_Sample;AQD_SamplingPointProcess;AQD_Station;AQD_Network</th>
        </tr>
        <tr style="border-top:0px solid #666666">
            <td colspan="3" style="vertical-align:top;text-align:left">Please note that the qa might give you warning if different features have been submitted in separate XMLs</td>
        </tr>
        {html:buildResultRows_D("D41", $labels:D41, $labels:D41_SHORT, (),$invalideFeatureOfInterest,"aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning", ())}
        {html:buildResultRows_D("D42", $labels:D42, $labels:D42_SHORT, (),$invalidEfprocedure, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning", ())}
        {html:buildResultRows_D("D43", $labels:D43, $labels:D43_SHORT, (),$invalidEfbroader, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning", ())}
        {html:buildResultRows_D("D44", $labels:D44, $labels:D44_SHORT, (),$invalidEfbelongsTo, "aqd:AQD_SamplingPoint/@gml:id", "All attributes are valid", " invalid attribute", "","warning", ())}
        {html:buildResultRows_D("D44b", $labels:D44b, $labels:D44b_SHORT, (),$invalidStationEfbelongsTo, "aqd:AQD_Station/@gml:id", "All attributes are valid", " invalid attribute", "","warning", ())}
	      <tr style="border-top:2px solid #666666">
            <th colspan="3" style="vertical-align:top;text-align:left"></th>
        </tr>
        {html:buildResultRows_D("D45", $labels:D45, $labels:D45_SHORT, (), $allOperationActivitPeriod, "", concat(fn:string(count($allOperationActivitPeriod))," errors found"), "", "", "error",())}
        {html:buildResultRows_D("D46", $labels:D46, $labels:D46_SHORT, (), $allUnknownEfOperationActivityPeriod, "", "", "", "","info", ())}
        {html:buildResultRows_D("D50", $labels:D50, $labels:D50_SHORT, (), $invalidStationClassificationLink, "", concat(fn:string(count($invalidStationClassificationLink))," errors found"), "", "","error", ())}
        {html:buildResultRows_D("D51", $labels:D51, $labels:D51_SHORT, (), $D51invalid, "", concat(fn:string(count($D51invalid))," errors found"), " invalid attribute", "", "warning",())}
        {html:buildResultRows_D("D53", $labels:D53, $labels:D53_SHORT, (), $allInvalidZoneXlinks, "", concat(fn:string(count( $allInvalidZoneXlinks))," errors found"), " invalid attribute", "", "error",())}
        {html:buildResultRows_D("D54", $labels:D54, $labels:D54_SHORT, (), $invalidDuplicateSamplingPointProcessIds, "", concat(string(count($invalidDuplicateSamplingPointProcessIds))," errors found.") , " invalid attribute", "","error", ())}
        <tr style="border-top:2px solid #666666">
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
            <td style="vertical-align:top;"></td>
        </tr>
        <tr style="border-top:0px solid #666666">
            <th colspan="2" style="vertical-align:top;text-align:left">Specific checks on AQD_SamplingPointProcess feature(s) within this XML</th>
            <td style="vertical-align:top;"></td>
        </tr>
        {html:buildResultRows_D("D55", $labels:D55, $labels:D55_SHORT, (), (), "", string(count($tblD55)), "", "","info",$tblD55)}
        {html:buildResultRowsWithTotalCount_D("D56", <span>./aqd:measurementType shall resolve to
            <a href="{ $vocabulary:MEASUREMENTTYPE_VOCABULARY }">{ $vocabulary:MEASUREMENTTYPE_VOCABULARY }</a>/[concept]</span>, $labels:PLACEHOLDER,
                (), (), "aqd:measurementType", "", "", "","error", $allInvalidMeasurementType)}
        {html:buildResultRows_D("D57", <span>If ./aqd:measurementType resolves to ./measurementtype/automatic or ./measurementtype/remote,
            aqd:measurementMethod shall be included and resolve to any concept in
            <a href="{ $vocabulary:MEASUREMENTMETHOD_VOCABULARY }">{ $vocabulary:MEASUREMENTMETHOD_VOCABULARY }</a> AND /aqd:samplingMethod and ./aqd:analyticalTechnique SHALL NOT BE PROVIDED</span>, $labels:PLACEHOLDER,
                (), $allConceptUrl57, "", concat(string(count($allConceptUrl57)), " errors found"), "", "", "error", ())}
        {html:buildResultRows_D("D58", $labels:D58, $labels:D58_SHORT, (), $elementsIncluded, "", concat(fn:string(count($elementsIncluded))," errors found"), " invalid attribute", "","warning", ())}
        {html:buildResultRowsWithTotalCount_D("D59", <span>The content of /aqd:AQD_SamplingPointProcess/aqd:analyticalTechnique shall resolve to any concept in
            <a href="{ $vocabulary:ANALYTICALTECHNIQUE_VOCABULARY }">{ $vocabulary:ANALYTICALTECHNIQUE_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
                (), (), "aqd:analyticalTechnique", "", "", "","error",$allInvalidAnalyticalTechnique )}
        {html:buildResultRowsWithTotalCount_D("D60a", <span>The content of ./aqd:AQD_SamplingPointProcess/aqd:measurementType shall resolve to any concept in
            <a href="{ $vocabulary:MEASUREMENTEQUIPMENT_VOCABULARY }">{ $vocabulary:MEASUREMENTEQUIPMENT_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
                (), (), "aqd:measurementEquipment", "", "", "","error",$allInvalid60a )}
        {html:buildResultRowsWithTotalCount_D("D60b", <span>The content of ./aqd:AQD_SamplingPointProcess/aqd:samplingEquipment shall resolve to any concept in
            <a href="{ $vocabulary:SAMPLINGEQUIPMENT_VOCABULARY }">{ $vocabulary:SAMPLINGEQUIPMENT_VOCABULARY }</a></span>, $labels:PLACEHOLDER,
                (), (), "aqd:samplingEquipment", "", "", "","error",$allInvalid60b )}
        <!--{xmlconv:buildResultRows("D61", "Total number ./aqd:dataQuality/aqd:DataQuality/aqd:detectionLimit witch does not contain an integer, fixed point or floating point number ",
                (), $allInvalid61, "", concat(fn:string(count($allInvalid61))," errors found"), "", "", ())}-->
        {html:buildResultRowsWithTotalCount_D("D63", <span>Where ./aqd:detectionLimit is resolved uom link resolving to any concept in <a href="{ $vocabulary:UOM_CONCENTRATION_VOCABULARY }">{ $vocabulary:UOM_CONCENTRATION_VOCABULARY }</a> shall be provided</span>, $labels:PLACEHOLDER,
                (), (), "aqd:detectionLimit", "", "", "","error",$allInvalid63 )}
	      <tr style="border-top:1px solid #666666">
            <th colspan="3" style="vertical-align:top;text-align:left">Checks on SamplingPointProcess(es) where the xlinked SamplingPoint has aqd:AQD_SamplingPoint/aqd:usedAQD equals TRUE (D67 to D70): </th>
        </tr>
        {html:buildResultRows_D("D67", concat('SamplingPointProcess(es) with incorrect code for Equivalence demonstration',
		' (http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/) ',''), $labels:PLACEHOLDER,
                (), $allInvalidTrueUsedAQD67, "", concat(fn:string(count($allInvalidTrueUsedAQD67))," errors found"), "", "", "warning",())}
        {html:buildResultRows_D("D68", concat('SamplingPointProcess(es) declared as an equivalent method” ',
                'i.e. http://dd.eionet.europa.eu/vocabulary/aq/equivalencedemonstrated/yes ',
                'but /aqd:demonstrationReport not provided. '), $labels:PLACEHOLDER,
                        (), $allInvalidTrueUsedAQD68, "", concat(fn:string(count($allInvalidTrueUsedAQD68))," errors found"), "", "", "warning",())}
        {html:buildResultRows_D("D69", $labels:D69, $labels:D69_SHORT, (), $allInvalidTrueUsedAQD69, "", concat(fn:string(count($allInvalidTrueUsedAQD69))," errors found"), "", "", "warning",())}
        <tr style="border-top:2px solid #666666">
                <td style="vertical-align:top;"></td>
                <td style="vertical-align:top;"></td>
                <td style="vertical-align:top;"></td>
        </tr>
        <tr style="border-top:0px solid #666666">
                <th colspan="2" style="vertical-align:top;text-align:left">Specific checks on AQD_Sample feature(s) within this XML</th>
                <td style="vertical-align:top;"></td>
        </tr>
        {html:buildResultRows_D("D71", $labels:D71, $labels:D71_SHORT, (),$invalidDuplicateSampleIds, "", concat(string(count($invalidDuplicateSampleIds))," errors found.") , "", "","error", ())}
        {html:buildResultRows_D("D72", $labels:D72, $labels:D72_SHORT, (), (), "", string(count($tblD72)), "", "","error",$tblD72)}
        {html:buildResultRows_D("D73", $labels:D73, $labels:D73_SHORT, $strErr73 ,(), "", concat(string(count($D73invalid)), $errMsg73), "", "",$errLevelD73, $D73invalid, $isInvalidInvalidD73 )}
        {html:buildResultRows_D("D74", $labels:D74, $labels:D74_SHORT, $invalidPointDimension,(), "aqd:AQD_Sample/@gml:id","All srsDimension attributes are valid"," invalid attribute","","error", ())}
        {html:buildResultRows_D("D75", $labels:D75, $labels:D75_SHORT, $D75invalid,(), "aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:localId", "All attributes are valid", " invalid attribute","","warning", ())}
        {html:buildResultRows_D("D76", $labels:D76, $labels:D76_SHORT, (), (), "aqd:AQD_Sample/aqd:inspireId/base:Identifier/base:localId", "All attributes are valid", " invalid attribute","","warning", $D76invalid)}
        {html:buildResultRows_D("D78", $labels:D78, $labels:D78_SHORT, $invalidInletHeigh,(), "aqd:AQD_Sample/@gml:id","All values are valid"," invalid attribute","", "warning",())}
        <tr style="border-top:3px solid #666666">
                <td style="vertical-align:top;"></td>
                <td style="vertical-align:top;"></td>
                <td style="vertical-align:top;"></td>
        </tr>

        <!--{xmlconv:buildResultRowsWithTotalCount("D67", <span>The content of ./aqd:AQD_SamplingPoint/aqd:samplingEquipment shall resolve to any concept in
            <a href="{ $xmlconv:UOM_CONCENTRATION_VOCABULARY }">{ $xmlconv:UOM_CONCENTRATION_VOCABULARY }</a></span>,
                (), (), "aqd:samplingEquipment", "", "", "",$allInvalid67 )} -->
    </table>
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string) as element(tr)* {
    xmlconv:checkVocabularyConceptValues($source_url, $featureType, $element, $vocabularyUrl, "")
};

declare function xmlconv:checkVocabularyConceptValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)

        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]

        for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href
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

(: TODO add attribute as method param :)
declare function xmlconv:checkVocabularyConceptValuesUom($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string) as element(tr)* {
    if(doc-available($source_url)) then
        let $sparql := xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]/@uom
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0
        return
            <tr isvalid="{ xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl) }">
                <td title="Feature type">{ $featureType }</td>
                <td title="gml:id">{data($rec/@gml:id)}</td>
                <td title="{ $element }" style="color:red">{$conceptUrl}</td>
            </tr>
    else
        ()
};

declare function xmlconv:checkVocabularyConceptValues2($source_url as xs:string, $concept , $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string)
as element(tr)*{
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
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
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)

        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]
        where  not(xmlconv:isMatchingVocabCode($crConcepts, normalize-space($conceptUrl/@xlink:href)))

        return
            $conceptUrl
        else
            ()
};


declare function xmlconv:isValidConceptCode($conceptUrl as xs:string?, $vocabularyUrl as xs:string) as xs:boolean {
    let $conceptUrl := if (empty($conceptUrl)) then "" else $conceptUrl
    let $sparql := xmlconv:getConceptUrlSparql($vocabularyUrl)
    let $crConcepts := sparqlx:executeSparqlQuery($sparql)
    return xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl)
};

declare function xmlconv:checkVocabularyConceptValues4($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string) as element(tr)* {

    if(doc-available($source_url)) then
        let $sparql := xmlconv:getConceptUrlSparql($vocabularyUrl)
        let $crConcepts := sparqlx:executeSparqlQuery($sparql)
        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec//child::*[name() = $element]/@xlink:href
        let $conceptUrl := normalize-space($conceptUrl)
        where string-length($conceptUrl) > 0 and not(xmlconv:isMatchingVocabCode($crConcepts, $conceptUrl))
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


declare function xmlconv:checkVocabularyaqdAnalyticalTechniqueValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string)
as element(tr)*{
    if(doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
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

declare function xmlconv:checkVocabulariesConceptEquipmentValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrls as xs:string*, $vocabularyType as xs:string)
as element(tr)* {
    if(doc-available($source_url)) then
      let $crConcepts :=
        for $vocabularyUrl in  $vocabularyUrls
            let $sparql := xmlconv:getConceptUrlSparql($vocabularyUrl)
            return
                sparqlx:executeSparqlQuery($sparql)

        for $rec in doc($source_url)//gml:featureMember/descendant::*[name()=$featureType]
        for $conceptUrl in $rec/child::*[name() = $element]/@xlink:href
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



declare function xmlconv:checkVocabularyConceptEquipmentValues($source_url as xs:string, $featureType as xs:string, $element as xs:string, $vocabularyUrl as xs:string, $vocabularyType as xs:string)
as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
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
declare function xmlconv:checkMeasurementMethodLinkValues($source_url as xs:string, $concept,$featureType as xs:string,  $vocabularyUrl as xs:string, $vocabularyType as xs:string) as element(tr)* {
    if (doc-available($source_url)) then
        let $sparql :=
            if ($vocabularyType = "collection") then
                xmlconv:getCollectionConceptUrlSparql($vocabularyUrl)
            else
                xmlconv:getConceptUrlSparql($vocabularyUrl)
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



declare function xmlconv:getConceptUrlSparql($scheme as xs:string) as xs:string {
    (: Quick fix for #69944. :)
    if ($scheme = "http://inspire.ec.europa.eu/codelist/MediaValue/") then
        concat("PREFIX dcterms: <http://purl.org/dc/terms/>
                PREFIX owl: <http://www.w3.org/2002/07/owl#>
                PREFIX skos: <http://www.w3.org/2004/02/skos/core#>
                    SELECT ?concepturl ?label
                    WHERE {
                    {
                      ?concepturl skos:inScheme <", $scheme, ">;
                                  skos:prefLabel ?label
                    } UNION {
                      ?other skos:inScheme <", $scheme, ">;
                                  skos:prefLabel ?label;
                                  dcterms:replaces ?concepturl
                    }
                }")
    else                   
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
        <h2>Check environmental monitoring feature types - Dataflow D</h2>
        {

        if ( $countFeatures = 0) then
            <p>No environmental monitoring feature type elements ({string-join($xmlconv:FEATURE_TYPES, ", ")}) found from this XML.</p>
        else
        <div>
            {
                if ($result//div/@class = 'error') then
                    <div>
                        <p class="error" style="color:red"><strong>This XML file did NOT pass the following crucial check(s): {string-join($result//div[@class = 'error'], ',')}</strong></p>
                        <p style="color:red">Please pay attention that QA rules D1-D4 concern all monitoring (measurement) feature types, QA rules D5 - D14 concern AQD_Networks, QA rules D15 - D30 concern AQD_Stations, QA rules D31 - D53 concern AQD_SamplingPoints, QA rules D54 - D70 concern AQD_SamplingPointProcesses, QA rules D71 - D77 concern AQD_Samples, QA rules D78 - D85 concern AQD_RepresentativeAreas.</p>
                        <p style="color:red">Please pay attention that QA rules M1 - M5 concern all monitoring (model) feature types, QA rules M6 - M26 concern AQD_Models, QA rules M27 - M39 concern AQD_ModelProcesses, QA rules M40 - M45 concern AQD_ModelAreas.</p>
                    </div>
                else
                    <p>This XML file passed all crucial checks.</p>
            }

            {
                if ($result//div/@class = 'warning') then
                    <div>
                        <p class="warning" style="color:orange"><strong>This XML file generated warnings during the following check(s): {string-join($result//div[@class = 'warning'], ',')}</strong></p>
                        <p style="color:grey">Please pay attention that QA rules D1-D4 concern all monitoring (measurement) feature types, QA rules D5 - D14 concern AQD_Networks, QA rules D15 - D30 concern AQD_Stations, QA rules D31 - D53 concern AQD_SamplingPoints, QA rules D54 - D70 concern AQD_SamplingPointProcesses, QA rules D71 - D77 concern AQD_Samples, QA rules D78 - D85 concern AQD_RepresentativeAreas.</p>
                        <p style="color:grey">Please pay attention that QA rules M1 - M5 concern all monitoring (model) feature types, QA rules M6 - M26 concern AQD_Models, QA rules M27 - M39 concern AQD_ModelProcesses, QA rules M40 - M45 concern AQD_ModelAreas.</p>
                    </div>
                else
                    ()
            }
            <p>This feedback report provides a summary overview of feature types reported and some consistency checks defined in Dataflow D as specified in <a href="http://www.eionet.europa.eu/aqportal/qaqc/">e-reporting QA/QC rules documentation</a>.</p>
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

declare function xmlconv:aproceed ($source_url, $countryCode ) {

let $docRoot := doc($source_url)

let $invalidPos_srsDim  := distinct-values($docRoot//aqd:AQD_Station/ef:geometry/gml:Point/gml:pos[@srsDimension != "2"]/
concat(../../../@gml:id, ": srsDimension=", @srsDimension))


let $aqdStationPos :=
    for $allPos in $docRoot//aqd:AQD_Station
    where not(empty($allPos/ef:geometry/gml:Point/gml:pos))
    return concat($allPos/ef:inspireId/base:Identifier/base:namespace,"/",$allPos/ef:inspireId/base:Identifier/base:localId,"|",
        fn:substring-before(data($allPos/ef:geometry/gml:Point/gml:pos), " "), "#", fn:substring-after(data($allPos/ef:geometry/gml:Point/gml:pos), " "))


let $invalidPos_order :=
    for $gmlPos in $docRoot//aqd:AQD_SamplingPoint
        let $samplingPos := data($gmlPos/ef:geometry/gml:Point/gml:pos)
        let $samplingLat := if (not(empty($samplingPos))) then fn:substring-before($samplingPos, " ") else ""
        let $samplingLong := if (not(empty($samplingPos))) then fn:substring-after($samplingPos, " ") else ""

        let $samplingLat := if ($samplingLat castable as xs:decimal) then xs:decimal($samplingLat) else 0.00
        let $samplingLong := if ($samplingLong castable as xs:decimal) then xs:decimal($samplingLong) else 0.00

        return if ($samplingLat < $samplingLong and $countryCode != 'FR')
        then concat($gmlPos/@gml:id, " : lat=" , string($samplingLat), " :long=", string($samplingLong)) else ()

let $invalidPosD21 := (($invalidPos_srsDim), ($invalidPos_order))

return data($invalidPos_order )
};